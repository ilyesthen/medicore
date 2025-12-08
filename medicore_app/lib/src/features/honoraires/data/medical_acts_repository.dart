import 'dart:async';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Repository for medical acts (Honoraires) operations
class MedicalActsRepository {
  final AppDatabase _db;

  MedicalActsRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Watch all active medical acts
  Stream<List<MedicalAct>> watchAllMedicalActs() {
    // Client mode: poll remote
    if (!GrpcClientConfig.isServer) {
      return _watchMedicalActsRemote();
    }
    return (_db.select(_db.medicalActs)
          ..where((act) => act.isActive.equals(true))
          ..orderBy([(act) => OrderingTerm.asc(act.displayOrder)]))
        .watch();
  }

  /// Get all active medical acts (non-stream)
  Future<List<MedicalAct>> getAllMedicalActs() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      return await _fetchMedicalActsRemote();
    }
    return await (_db.select(_db.medicalActs)
          ..where((act) => act.isActive.equals(true))
          ..orderBy([(act) => OrderingTerm.asc(act.displayOrder)]))
        .get();
  }
  
  // Remote helpers
  Stream<List<MedicalAct>> _watchMedicalActsRemote() async* {
    yield await _fetchMedicalActsRemote();
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      yield await _fetchMedicalActsRemote();
    }
  }
  
  Future<List<MedicalAct>> _fetchMedicalActsRemote() async {
    try {
      final response = await MediCoreClient.instance.getAllMedicalActs();
      final acts = (response['acts'] as List<dynamic>?) ?? [];
      return acts.map((a) => MedicalAct(
        id: a['id'] as int,
        name: a['name'] as String,
        feeAmount: a['fee_amount'] as int,
        displayOrder: a['display_order'] as int? ?? 0,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      )).toList();
    } catch (e) {
      print('❌ [MedicalActsRepository] Remote fetch failed: $e');
      return [];
    }
  }

  /// Get a specific medical act by ID
  Future<MedicalAct?> getMedicalAct(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getMedicalActById(id);
        if (response.isEmpty) return null;
        return MedicalAct(
          id: response['id'] as int,
          name: response['name'] as String,
          feeAmount: response['fee_amount'] as int,
          displayOrder: response['display_order'] as int? ?? 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        print('❌ [MedicalActsRepository] Remote getMedicalAct failed: $e');
        return null;
      }
    }
    
    return await (_db.select(_db.medicalActs)
          ..where((act) => act.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new medical act
  Future<MedicalAct> createMedicalAct({
    required String name,
    required int feeAmount,
  }) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final id = await MediCoreClient.instance.createMedicalAct(name: name, feeAmount: feeAmount);
        return MedicalAct(
          id: id,
          name: name,
          feeAmount: feeAmount,
          displayOrder: 0,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        print('❌ [MedicalActsRepository] Remote create failed: $e');
        rethrow;
      }
    }
    
    // Get the highest display order
    final query = _db.selectOnly(_db.medicalActs)
      ..addColumns([_db.medicalActs.displayOrder.max()]);
    final result = await query.getSingleOrNull();
    final maxOrder = result?.read(_db.medicalActs.displayOrder.max()) ?? 0;

    final now = DateTime.now();
    final companion = MedicalActsCompanion.insert(
      name: name,
      feeAmount: feeAmount,
      displayOrder: maxOrder + 1,
      createdAt: now,
      updatedAt: now,
    );

    final id = await _db.into(_db.medicalActs).insert(companion);
    return (await getMedicalAct(id))!;
  }

  /// Update an existing medical act
  Future<void> updateMedicalAct({
    required int id,
    required String name,
    required int feeAmount,
  }) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.updateMedicalAct(id: id, name: name, feeAmount: feeAmount);
        return;
      } catch (e) {
        print('❌ [MedicalActsRepository] Remote update failed: $e');
        rethrow;
      }
    }
    
    await (_db.update(_db.medicalActs)
          ..where((act) => act.id.equals(id)))
        .write(MedicalActsCompanion(
      name: Value(name),
      feeAmount: Value(feeAmount),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Delete a medical act (soft delete)
  Future<void> deleteMedicalAct(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deleteMedicalAct(id);
        return;
      } catch (e) {
        print('❌ [MedicalActsRepository] Remote delete failed: $e');
        rethrow;
      }
    }
    
    await (_db.update(_db.medicalActs)
          ..where((act) => act.id.equals(id)))
        .write(MedicalActsCompanion(
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Reorder medical acts
  Future<void> reorderMedicalActs(List<int> orderedIds) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.reorderMedicalActs(orderedIds);
        return;
      } catch (e) {
        print('❌ [MedicalActsRepository] Remote reorder failed: $e');
        rethrow;
      }
    }
    
    for (int i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.medicalActs)
            ..where((act) => act.id.equals(orderedIds[i])))
          .write(MedicalActsCompanion(
        displayOrder: Value(i + 1),
        updatedAt: Value(DateTime.now()),
      ));
    }
  }

  /// Calculate assistant share based on percentage
  int calculateAssistantShare(int feeAmount, double percentage) {
    return (feeAmount * (percentage / 100)).round();
  }
}
