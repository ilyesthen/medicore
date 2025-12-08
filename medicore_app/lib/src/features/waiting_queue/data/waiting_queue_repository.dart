import 'dart:async';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';

/// Repository for waiting patients queue operations
class WaitingQueueRepository {
  final AppDatabase _database;
  
  // Remote polling streams cache
  final Map<String, StreamController<List<WaitingPatient>>> _remoteStreams = {};
  final Map<String, StreamController<int>> _remoteCountStreams = {};
  final Map<String, Timer> _remoteTimers = {};

  WaitingQueueRepository([AppDatabase? database]) 
      : _database = database ?? AppDatabase();
  
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
  
  /// Dispose remote streams
  void dispose() {
    for (final timer in _remoteTimers.values) {
      timer.cancel();
    }
    for (final controller in _remoteStreams.values) {
      controller.close();
    }
    for (final controller in _remoteCountStreams.values) {
      controller.close();
    }
    _remoteTimers.clear();
    _remoteStreams.clear();
    _remoteCountStreams.clear();
  }

  /// List of consultation motifs in order
  static const List<String> motifs = [
    'BAV loin',
    'Certificat',
    'Bav loin',
    'FO',
    'RAS',
    'Bav de près',
    'Douleurs oculaires',
    'Calcul OD',
    'Calcul',
    'Calcul OG',
    'OR',
    'Céphalées',
    'Allergie',
    'Contrôle',
    'Pentacam',
    'Picotement',
    'Strabisme',
    'BAV loin OD',
    'BAV loin OG',
    'Larmoiement',
    'ORD',
    'CalculOD',
    'Myodesopsie',
    'Céphalée',
    'CalculOG',
    'BAV de près',
    'CHZ',
    'Myodesopsie OD',
    'Myodesopsie OG',
    'Larmoiement OD',
  ];

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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
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
        return await MediCoreClient.instance.addWaitingPatient(request);
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote addToQueue failed: $e');
        rethrow;
      }
    }
    
    final now = DateTime.now();
    
    return await _database.into(_database.waitingPatients).insert(
      WaitingPatientsCompanion.insert(
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        patientBirthDate: Value(patientBirthDate),
        patientAge: Value(patientAge),
        isUrgent: Value(isUrgent),
        roomId: roomId,
        roomName: roomName,
        motif: motif,
        sentByUserId: sentByUserId,
        sentByUserName: sentByUserName,
        sentAt: now,
      ),
    );
  }

  /// Watch waiting patients for a specific room (non-urgent, non-dilatation only)
  Stream<List<WaitingPatient>> watchWaitingPatientsForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return _watchWaitingPatientsRemote('waiting_$roomId', roomId, (p) => !p.isUrgent && !p.isDilatation && p.isActive);
    }
    
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.equals(roomId))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isUrgent.equals(false))
          ..where((w) => w.isDilatation.equals(false)) // Exclude patients sent to nurse
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }
  
  /// Remote polling stream for waiting patients
  Stream<List<WaitingPatient>> _watchWaitingPatientsRemote(
    String key,
    String roomId,
    bool Function(WaitingPatient) filter,
  ) {
    if (!_remoteStreams.containsKey(key)) {
      _remoteStreams[key] = StreamController<List<WaitingPatient>>.broadcast();
      
      Future<void> fetchData() async {
        try {
          final response = await MediCoreClient.instance.getWaitingPatientsByRoom(roomId);
          final filtered = response.patients
            .map(_grpcWaitingPatientToLocal)
            .where(filter)
            .toList();
          _remoteStreams[key]?.add(filtered);
        } catch (e) {
          print('❌ [WaitingQueueRepository] Remote poll failed: $e');
          _remoteStreams[key]?.add([]);
        }
      }
      
      // Immediate fetch
      fetchData();
      
      // Poll every 2 seconds
      _remoteTimers[key] = Timer.periodic(const Duration(seconds: 2), (_) => fetchData());
    }
    
    return _remoteStreams[key]!.stream;
  }

  /// Watch urgent patients for a specific room
  Stream<List<WaitingPatient>> watchUrgentPatientsForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return _watchWaitingPatientsRemote('urgent_$roomId', roomId, (p) => p.isUrgent && p.isActive);
    }
    
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.equals(roomId))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isUrgent.equals(true))
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }

  /// Get count of waiting patients for a room (non-urgent, non-dilatation only)
  Stream<int> watchWaitingCountForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return watchWaitingPatientsForRoom(roomId).map((list) => list.length);
    }
    
    final query = _database.selectOnly(_database.waitingPatients)
      ..addColumns([_database.waitingPatients.id.count()])
      ..where(_database.waitingPatients.roomId.equals(roomId))
      ..where(_database.waitingPatients.isActive.equals(true))
      ..where(_database.waitingPatients.isUrgent.equals(false))
      ..where(_database.waitingPatients.isDilatation.equals(false)); // Exclude patients sent to nurse
    
    return query.watchSingle().map((row) => 
      row.read(_database.waitingPatients.id.count()) ?? 0);
  }

  /// Get count of urgent patients for a room
  Stream<int> watchUrgentCountForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return watchUrgentPatientsForRoom(roomId).map((list) => list.length);
    }
    
    final query = _database.selectOnly(_database.waitingPatients)
      ..addColumns([_database.waitingPatients.id.count()])
      ..where(_database.waitingPatients.roomId.equals(roomId))
      ..where(_database.waitingPatients.isActive.equals(true))
      ..where(_database.waitingPatients.isUrgent.equals(true));
    
    return query.watchSingle().map((row) => 
      row.read(_database.waitingPatients.id.count()) ?? 0);
  }

  /// Dilatation type labels
  static const Map<String, String> dilatationLabels = {
    'skiacol': 'Dilatation sous Skiacol',
    'od': 'Dilatation OD',
    'og': 'Dilatation OG',
    'odg': 'Dilatation ODG',
  };

  /// Add patient to dilatation queue (doctor → nurse)
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
    final dilatationLabel = dilatationLabels[dilatationType] ?? dilatationType;
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
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
        return await MediCoreClient.instance.addWaitingPatient(request);
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote addToDilatation failed: $e');
        rethrow;
      }
    }
    
    final now = DateTime.now();
    
    return await _database.into(_database.waitingPatients).insert(
      WaitingPatientsCompanion.insert(
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        patientBirthDate: Value(patientBirthDate),
        patientAge: Value(patientAge),
        isDilatation: const Value(true),
        dilatationType: Value(dilatationType),
        roomId: roomId,
        roomName: roomName,
        motif: dilatationLabel,
        sentByUserId: sentByUserId,
        sentByUserName: sentByUserName,
        sentAt: now,
      ),
    );
  }

  /// Watch dilatation patients for a specific room
  Stream<List<WaitingPatient>> watchDilatationPatientsForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return _watchWaitingPatientsRemote('dilatation_$roomId', roomId, (p) => p.isDilatation && p.isActive);
    }
    
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.equals(roomId))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isDilatation.equals(true))
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }

  /// Get count of dilatation patients for a room
  Stream<int> watchDilatationCountForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return watchDilatationPatientsForRoom(roomId).map((list) => list.length);
    }
    
    final query = _database.selectOnly(_database.waitingPatients)
      ..addColumns([_database.waitingPatients.id.count()])
      ..where(_database.waitingPatients.roomId.equals(roomId))
      ..where(_database.waitingPatients.isActive.equals(true))
      ..where(_database.waitingPatients.isDilatation.equals(true));
    
    return query.watchSingle().map((row) => 
      row.read(_database.waitingPatients.id.count()) ?? 0);
  }

  /// Watch total dilatation count across multiple rooms (for nurse badge - only unnotified)
  Stream<int> watchTotalDilatationCount(List<String> roomIds) {
    if (roomIds.isEmpty) return Stream.value(0);
    
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return watchDilatationPatientsForRooms(roomIds).map((list) => 
        list.where((p) => !p.isNotified).length
      );
    }
    
    final query = _database.selectOnly(_database.waitingPatients)
      ..addColumns([_database.waitingPatients.id.count()])
      ..where(_database.waitingPatients.roomId.isIn(roomIds))
      ..where(_database.waitingPatients.isActive.equals(true))
      ..where(_database.waitingPatients.isDilatation.equals(true))
      ..where(_database.waitingPatients.isNotified.equals(false));
    
    return query.watchSingle().map((row) => 
      row.read(_database.waitingPatients.id.count()) ?? 0);
  }

  /// Watch dilatation patients across multiple rooms (for nurse)
  Stream<List<WaitingPatient>> watchDilatationPatientsForRooms(List<String> roomIds) {
    if (roomIds.isEmpty) return Stream.value([]);
    
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      final key = 'dilatation_multi_${roomIds.join('_')}';
      if (!_remoteStreams.containsKey(key)) {
        _remoteStreams[key] = StreamController<List<WaitingPatient>>.broadcast();
        
        Future<void> fetchData() async {
          try {
            final allPatients = <WaitingPatient>[];
            for (final roomId in roomIds) {
              final response = await MediCoreClient.instance.getWaitingPatientsByRoom(roomId);
              allPatients.addAll(
                response.patients
                  .where((p) => p.isDilatation && p.isActive)
                  .map(_grpcWaitingPatientToLocal)
              );
            }
            _remoteStreams[key]?.add(allPatients);
          } catch (e) {
            print('❌ [WaitingQueueRepository] Remote poll failed: $e');
            _remoteStreams[key]?.add([]);
          }
        }
        
        fetchData();
        _remoteTimers[key] = Timer.periodic(const Duration(seconds: 2), (_) => fetchData());
      }
      return _remoteStreams[key]!.stream;
    }
    
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.isIn(roomIds))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isDilatation.equals(true))
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }

  /// Mark all dilatations as notified for given rooms (clears badge)
  Future<void> markDilatationsAsNotified(List<String> roomIds) async {
    if (roomIds.isEmpty) return;
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.markDilatationsAsNotified(roomIds);
        return;
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote markDilatationsAsNotified failed: $e');
        rethrow;
      }
    }
    
    await (_database.update(_database.waitingPatients)
          ..where((w) => w.roomId.isIn(roomIds))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isDilatation.equals(true))
          ..where((w) => w.isNotified.equals(false)))
        .write(const WaitingPatientsCompanion(
          isNotified: Value(true),
        ));
  }

  /// Toggle checked status for a waiting patient
  Future<void> toggleChecked(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final patient = GrpcWaitingPatient(id: id, isChecked: true);
        await MediCoreClient.instance.updateWaitingPatient(patient);
        return;
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote toggleChecked failed: $e');
        rethrow;
      }
    }
    
    final patient = await (_database.select(_database.waitingPatients)
          ..where((w) => w.id.equals(id)))
        .getSingleOrNull();
    
    if (patient != null) {
      await (_database.update(_database.waitingPatients)
            ..where((w) => w.id.equals(id)))
          .write(WaitingPatientsCompanion(
            isChecked: Value(!patient.isChecked),
          ));
    }
  }

  /// Remove patient from queue (soft delete)
  Future<void> removeFromQueue(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.removeWaitingPatient(id);
        return;
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote removeFromQueue failed: $e');
        rethrow;
      }
    }
    
    await (_database.update(_database.waitingPatients)
          ..where((w) => w.id.equals(id)))
        .write(const WaitingPatientsCompanion(
          isActive: Value(false),
        ));
  }

  /// Remove patient from queue by patient code (when opening file)
  Future<void> removeByPatientCode(int patientCode) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.removeWaitingPatientByCode(patientCode);
        return;
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote removeByPatientCode failed: $e');
        rethrow;
      }
    }
    
    await (_database.update(_database.waitingPatients)
          ..where((w) => w.patientCode.equals(patientCode))
          ..where((w) => w.isActive.equals(true)))
        .write(const WaitingPatientsCompanion(
          isActive: Value(false),
        ));
  }

  /// Get waiting patient by ID
  Future<WaitingPatient?> getById(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        // Note: No direct API for single patient by ID, would need to search
        // For now, return null as this is rarely called in client mode
        return null;
      } catch (e) {
        print('❌ [WaitingQueueRepository] Remote getById failed: $e');
        return null;
      }
    }
    
    return await (_database.select(_database.waitingPatients)
          ..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }
}
