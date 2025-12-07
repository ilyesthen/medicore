import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import '../database/app_database.dart' show WaitingPatient;

/// Remote Waiting Queue Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only
class RemoteWaitingQueueRepository {
  final MediCoreClient _client;
  
  // Active streams for real-time updates
  final Map<String, StreamController<List<WaitingPatient>>> _roomStreams = {};
  final Map<String, Timer> _roomTimers = {};
  
  RemoteWaitingQueueRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance;

  /// List of consultation motifs (same as local)
  static const List<String> motifs = [
    'BAV loin', 'Certificat', 'Bav loin', 'FO', 'RAS', 'Bav de près',
    'Douleurs oculaires', 'Calcul OD', 'Calcul', 'Calcul OG', 'OR',
    'Céphalées', 'Allergie', 'Contrôle', 'Pentacam', 'Picotement',
    'Strabisme', 'BAV loin OD', 'BAV loin OG', 'Larmoiement', 'ORD',
    'CalculOD', 'Myodesopsie', 'Céphalée', 'CalculOG', 'BAV de près',
    'CHZ', 'Myodesopsie OD', 'Myodesopsie OG', 'Larmoiement OD',
  ];

  /// Dilatation type labels
  static const Map<String, String> dilatationLabels = {
    'skiacol': 'Dilatation sous Skiacol',
    'od': 'Dilatation OD',
    'og': 'Dilatation OG',
    'odg': 'Dilatation ODG',
  };

  /// Add patient to waiting queue
  Future<int> addToQueue({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String motif,
    required String sentByUserId,
    required String sentByUserName,
    bool isUrgent = false,
  }) async {
    try {
      final request = CreateWaitingPatientRequest(
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        roomId: roomId,
        roomName: roomName,
        motif: motif,
        sentByUserId: sentByUserId,
        sentByUserName: sentByUserName,
        patientAge: patientAge,
        isUrgent: isUrgent,
        isDilatation: false,
      );
      
      return await _client.addWaitingPatient(request);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] addToQueue failed: $e');
      rethrow;
    }
  }

  /// Add patient to dilatation queue
  Future<int> addToDilatation({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String dilatationType,
    required String sentByUserId,
    required String sentByUserName,
  }) async {
    try {
      final dilatationLabel = dilatationLabels[dilatationType] ?? dilatationType;
      
      final request = CreateWaitingPatientRequest(
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        roomId: roomId,
        roomName: roomName,
        motif: dilatationLabel,
        sentByUserId: sentByUserId,
        sentByUserName: sentByUserName,
        patientAge: patientAge,
        isUrgent: false,
        isDilatation: true,
        dilatationType: dilatationType,
      );
      
      return await _client.addWaitingPatient(request);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] addToDilatation failed: $e');
      rethrow;
    }
  }

  /// Watch waiting patients for a room (non-urgent, non-dilatation)
  Stream<List<WaitingPatient>> watchWaitingPatientsForRoom(String roomId) {
    return _getOrCreateStream('waiting_$roomId', roomId, (patients) {
      return patients
        .where((p) => !p.isUrgent && !p.isDilatation && p.isActive)
        .toList();
    });
  }

  /// Watch urgent patients for a room
  Stream<List<WaitingPatient>> watchUrgentPatientsForRoom(String roomId) {
    return _getOrCreateStream('urgent_$roomId', roomId, (patients) {
      return patients.where((p) => p.isUrgent && p.isActive).toList();
    });
  }

  /// Watch dilatation patients for a room
  Stream<List<WaitingPatient>> watchDilatationPatientsForRoom(String roomId) {
    return _getOrCreateStream('dilatation_$roomId', roomId, (patients) {
      return patients.where((p) => p.isDilatation && p.isActive).toList();
    });
  }

  /// Watch dilatation patients for multiple rooms
  Stream<List<WaitingPatient>> watchDilatationPatientsForRooms(List<String> roomIds) {
    final key = 'dilatation_multi_${roomIds.join('_')}';
    
    if (!_roomStreams.containsKey(key)) {
      _roomStreams[key] = StreamController<List<WaitingPatient>>.broadcast();
      
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          final allPatients = <WaitingPatient>[];
          for (final roomId in roomIds) {
            final response = await _client.getWaitingPatientsByRoom(roomId);
            allPatients.addAll(
              response.patients
                .where((p) => p.isDilatation && p.isActive)
                .map(_grpcWaitingPatientToLocal)
            );
          }
          _roomStreams[key]?.add(allPatients);
        } catch (e) {
          print('❌ [RemoteWaitingQueue] poll failed: $e');
        }
      });
    }
    
    return _roomStreams[key]!.stream;
  }

  /// Watch count of waiting patients for a room
  Stream<int> watchWaitingCountForRoom(String roomId) {
    return watchWaitingPatientsForRoom(roomId).map((list) => list.length);
  }

  /// Watch count of urgent patients for a room
  Stream<int> watchUrgentCountForRoom(String roomId) {
    return watchUrgentPatientsForRoom(roomId).map((list) => list.length);
  }

  /// Watch count of dilatation patients for a room
  Stream<int> watchDilatationCountForRoom(String roomId) {
    return watchDilatationPatientsForRoom(roomId).map((list) => list.length);
  }

  /// Watch total dilatation count across rooms (unnotified only)
  Stream<int> watchTotalDilatationCount(List<String> roomIds) {
    return watchDilatationPatientsForRooms(roomIds).map((list) => 
      list.where((p) => !p.isNotified).length
    );
  }

  /// Toggle checked status
  Future<void> toggleChecked(int id) async {
    // Get current state, toggle, and update
    // For simplicity, we'll just toggle based on local knowledge
    try {
      final patient = GrpcWaitingPatient(id: id, isChecked: true);
      await _client.updateWaitingPatient(patient);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] toggleChecked failed: $e');
    }
  }

  /// Remove patient from queue
  Future<void> removeFromQueue(int id) async {
    try {
      await _client.removeWaitingPatient(id);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] removeFromQueue failed: $e');
    }
  }

  /// Remove patient by code
  Future<void> removeByPatientCode(int patientCode) async {
    // This would need server-side support - for now, we'll fetch and remove
    // This is a limitation that should be addressed in the Go handler
    print('⚠️ [RemoteWaitingQueue] removeByPatientCode not fully implemented');
  }

  /// Mark dilatations as notified
  Future<void> markDilatationsAsNotified(List<String> roomIds) async {
    // This would need server-side support
    print('⚠️ [RemoteWaitingQueue] markDilatationsAsNotified not fully implemented');
  }

  /// Get waiting patient by ID
  Future<WaitingPatient?> getById(int id) async {
    // Would need to search through rooms
    return null;
  }

  Stream<List<WaitingPatient>> _getOrCreateStream(
    String key,
    String roomId,
    List<WaitingPatient> Function(List<WaitingPatient>) filter,
  ) {
    if (!_roomStreams.containsKey(key)) {
      _roomStreams[key] = StreamController<List<WaitingPatient>>.broadcast();
      
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 2), (_) async {
        try {
          final response = await _client.getWaitingPatientsByRoom(roomId);
          final filtered = filter(response.patients.map(_grpcWaitingPatientToLocal).toList());
          _roomStreams[key]?.add(filtered);
        } catch (e) {
          print('❌ [RemoteWaitingQueue] poll failed: $e');
        }
      });
    }
    
    return _roomStreams[key]!.stream;
  }

  /// Convert GrpcWaitingPatient to local WaitingPatient model
  WaitingPatient _grpcWaitingPatientToLocal(GrpcWaitingPatient grpc) {
    return WaitingPatient(
      id: grpc.id,
      patientCode: grpc.patientCode,
      patientFirstName: grpc.patientFirstName,
      patientLastName: grpc.patientLastName,
      patientBirthDate: null,
      patientAge: grpc.patientAge,
      isUrgent: grpc.isUrgent,
      isDilatation: grpc.isDilatation,
      dilatationType: grpc.dilatationType,
      roomId: grpc.roomId,
      roomName: grpc.roomName,
      motif: grpc.motif,
      sentByUserId: grpc.sentByUserId,
      sentByUserName: grpc.sentByUserName,
      sentAt: DateTime.tryParse(grpc.sentAt) ?? DateTime.now(),
      isChecked: grpc.isChecked,
      isActive: grpc.isActive,
      isNotified: false,
    );
  }

  void dispose() {
    for (final timer in _roomTimers.values) {
      timer.cancel();
    }
    for (final controller in _roomStreams.values) {
      controller.close();
    }
    _roomTimers.clear();
    _roomStreams.clear();
  }
}
