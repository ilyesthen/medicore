import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import 'realtime_sync_service.dart';

/// Remote Waiting Queue Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only - now with SSE-powered instant updates!
class RemoteWaitingQueueRepository {
  final MediCoreClient _client;
  
  // Active streams for real-time updates
  final Map<String, StreamController<List<WaitingPatient>>> _roomStreams = {};
  final Map<String, Timer> _roomTimers = {};
  
  // SSE callback for instant refresh
  void Function(String? roomId)? _sseRefreshCallback;
  
  RemoteWaitingQueueRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance {
    // Register for SSE waiting queue events for instant updates
    _sseRefreshCallback = (roomId) => _forceRefreshAllRooms(roomId);
    RealtimeSyncService.instance.onWaitingRefresh(_sseRefreshCallback!);
  }

  /// List of consultation motifs (same as local)
  static const List<String> motifs = [
    'Consultation', 'BAV loin', 'Certificat', 'Bav loin', 'FO', 'RAS', 'Bav de près',
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
      print('📤 [RemoteWaitingQueue] Adding patient $patientCode to room $roomId (age: $patientAge)');
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
      
      final result = await _client.addWaitingPatient(request);
      print('✅ [RemoteWaitingQueue] Patient added with ID: $result');
      
      // Force immediate refresh of all streams for this room
      _forceRefreshRoom(roomId);
      
      return result;
    } catch (e) {
      print('❌ [RemoteWaitingQueue] addToQueue failed: $e');
      rethrow;
    }
  }
  
  /// Force refresh all streams for a room
  void _forceRefreshRoom(String roomId) {
    // Refresh all related streams immediately
    for (final key in _roomStreams.keys.where((k) => k.contains(roomId))) {
      _refreshStreamKey(key, roomId);
    }
  }

  /// Force refresh all active rooms (called by SSE)
  void _forceRefreshAllRooms(String? targetRoomId) {
    print('🔄 [RemoteWaitingQueue] SSE triggered instant refresh for room: $targetRoomId');
    
    if (targetRoomId != null) {
      // Refresh specific room
      _forceRefreshRoom(targetRoomId);
    } else {
      // Refresh all active streams
      for (final key in _roomStreams.keys.toList()) {
        // Extract room ID from key
        final roomId = _extractRoomIdFromKey(key);
        if (roomId != null) {
          _refreshStreamKey(key, roomId);
        }
      }
    }
  }

  /// Extract room ID from stream key
  String? _extractRoomIdFromKey(String key) {
    // Keys are like: waiting_room1, urgent_room1, dilatation_room1, dilatation_multi_room1_room2
    if (key.startsWith('waiting_')) return key.substring('waiting_'.length);
    if (key.startsWith('urgent_')) return key.substring('urgent_'.length);
    if (key.startsWith('dilatation_') && !key.startsWith('dilatation_multi_')) {
      return key.substring('dilatation_'.length);
    }
    return null;
  }

  /// Refresh a specific stream key
  void _refreshStreamKey(String key, String roomId) {
    // Fetch immediately (no need to restart timer - SSE handles real-time)
    Future<void> fetchData() async {
      try {
        final response = await _client.getWaitingPatientsByRoom(roomId);
        final patients = response.patients.map(_grpcWaitingPatientToLocal).toList();
        
        if (key.startsWith('waiting_')) {
          _roomStreams[key]?.add(patients.where((p) => !p.isUrgent && !p.isDilatation && p.isActive).toList());
        } else if (key.startsWith('urgent_')) {
          _roomStreams[key]?.add(patients.where((p) => p.isUrgent && p.isActive).toList());
        } else if (key.startsWith('dilatation_')) {
          _roomStreams[key]?.add(patients.where((p) => p.isDilatation && p.isActive).toList());
        }
      } catch (e) {
        print('❌ [RemoteWaitingQueue] Refresh failed: $e');
      }
    }
    fetchData();
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
      print('📤 [RemoteWaitingQueue] Adding dilatation patient $patientCode to room $roomId');
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
      
      final result = await _client.addWaitingPatient(request);
      print('✅ [RemoteWaitingQueue] Dilatation patient added with ID: $result');
      
      // Force immediate refresh
      _forceRefreshRoom(roomId);
      
      return result;
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
      
      Future<void> fetchData() async {
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
          _roomStreams[key]?.add([]); // Emit empty on error
        }
      }
      
      // Fetch immediately!
      fetchData();
      
      // Then poll every 2 seconds
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
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
    try {
      final patient = GrpcWaitingPatient(id: id, isChecked: true);
      await _client.updateWaitingPatient(patient);
      // Force immediate refresh (don't wait for SSE)
      _forceRefreshAllRooms(null);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] toggleChecked failed: $e');
    }
  }

  /// Remove patient from queue
  Future<void> removeFromQueue(int id) async {
    try {
      await _client.removeWaitingPatient(id);
      // Force immediate refresh (don't wait for SSE)
      _forceRefreshAllRooms(null);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] removeFromQueue failed: $e');
    }
  }

  /// Remove patient by code
  Future<void> removeByPatientCode(int patientCode) async {
    try {
      await _client.removeWaitingPatientByCode(patientCode);
      // Force immediate refresh (don't wait for SSE)
      _forceRefreshAllRooms(null);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] removeByPatientCode failed: $e');
    }
  }

  /// Mark dilatations as notified
  Future<void> markDilatationsAsNotified(List<String> roomIds) async {
    try {
      await _client.markDilatationsAsNotified(roomIds);
      // Force immediate refresh (don't wait for SSE)
      _forceRefreshAllRooms(null);
    } catch (e) {
      print('❌ [RemoteWaitingQueue] markDilatationsAsNotified failed: $e');
    }
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
      
      // Fetch function - reusable
      Future<void> fetchData() async {
        try {
          final response = await _client.getWaitingPatientsByRoom(roomId);
          final filtered = filter(response.patients.map(_grpcWaitingPatientToLocal).toList());
          _roomStreams[key]?.add(filtered);
        } catch (e) {
          print('❌ [RemoteWaitingQueue] poll failed: $e');
          _roomStreams[key]?.add([]); // Emit empty on error
        }
      }
      
      // IMPORTANT: Fetch immediately, don't wait for timer!
      fetchData();
      
      // Then poll every 2 seconds
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 5), (_) => fetchData());
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
      isNotified: grpc.isNotified,
    );
  }

  void dispose() {
    // Unregister SSE callback
    if (_sseRefreshCallback != null) {
      RealtimeSyncService.instance.removeWaitingRefresh(_sseRefreshCallback!);
    }
    
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
