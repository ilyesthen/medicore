import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Repository for medications
class MedicationsRepository {
  final AppDatabase _db;
  
  MedicationsRepository([AppDatabase? db]) : _db = db ?? AppDatabase();
  
  /// Get all medications sorted by usage count (most used first)
  Future<List<Medication>> getAllSortedByUsage() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      return await _fetchMedicationsRemote();
    }
    return await (_db.select(_db.medications)
      ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
    ).get();
  }
  
  /// Search medications by code (starts with)
  Future<List<Medication>> searchByCode(String query) async {
    if (query.isEmpty) return getAllSortedByUsage();
    
    // Client mode: use remote search
    if (!GrpcClientConfig.isServer) {
      return await _searchMedicationsRemote(query);
    }
    
    return await (_db.select(_db.medications)
      ..where((t) => t.code.lower().like('${query.toLowerCase()}%'))
      ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
    ).get();
  }
  
  // Remote helpers
  Future<List<Medication>> _fetchMedicationsRemote() async {
    try {
      final response = await MediCoreClient.instance.getAllMedications();
      return _mapMedicationsFromJson(response['medications'] as List<dynamic>? ?? []);
    } catch (e) {
      print('❌ [MedicationsRepository] Remote fetch failed: $e');
      return [];
    }
  }
  
  Future<List<Medication>> _searchMedicationsRemote(String query) async {
    try {
      final response = await MediCoreClient.instance.searchMedications(query);
      return _mapMedicationsFromJson(response['medications'] as List<dynamic>? ?? []);
    } catch (e) {
      print('❌ [MedicationsRepository] Remote search failed: $e');
      return [];
    }
  }
  
  List<Medication> _mapMedicationsFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) {
      final m = json as Map<String, dynamic>;
      return Medication(
        id: m['id'] as int,
        originalId: m['original_id'] as int?,
        code: m['name'] as String? ?? m['code'] as String? ?? '',
        prescription: m['dosage'] as String? ?? m['prescription'] as String? ?? '',
        usageCount: m['usage_count'] as int? ?? 0,
        nature: m['nature'] as String? ?? 'O',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }).toList();
  }
  
  /// Increment usage count when medication is used
  Future<void> incrementUsage(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.incrementMedicationUsage(id);
        return;
      } catch (e) {
        print('❌ [MedicationsRepository] Remote incrementUsage failed: $e');
        return;
      }
    }
    await _db.customStatement(
      'UPDATE medications SET usage_count = usage_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }
  
  /// Set usage count (user editable)
  Future<void> setUsageCount(int id, int count) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.setMedicationUsageCount(id, count);
        return;
      } catch (e) {
        print('❌ [MedicationsRepository] Remote setUsageCount failed: $e');
        return;
      }
    }
    await (_db.update(_db.medications)
      ..where((t) => t.id.equals(id))
    ).write(MedicationsCompanion(
      usageCount: Value(count),
      updatedAt: Value(DateTime.now()),
    ));
  }
  
  /// Get medication by ID
  Future<Medication?> getById(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getMedicationById(id);
        if (response.isEmpty) return null;
        return Medication(
          id: response['id'] as int,
          originalId: response['original_id'] as int?,
          code: response['code'] as String? ?? '',
          prescription: response['prescription'] as String? ?? '',
          usageCount: response['usage_count'] as int? ?? 0,
          nature: response['nature'] as String? ?? 'O',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } catch (e) {
        print('❌ [MedicationsRepository] Remote getById failed: $e');
        return null;
      }
    }
    return await (_db.select(_db.medications)
      ..where((t) => t.id.equals(id))
    ).getSingleOrNull();
  }
  
  /// Get count of medications
  Future<int> getCount() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.getMedicationCount();
      } catch (e) {
        print('❌ [MedicationsRepository] Remote getCount failed: $e');
        return 0;
      }
    }
    return await _db.medications.count().getSingle();
  }
}

/// Provider
final medicationsRepositoryProvider = Provider<MedicationsRepository>((ref) {
  return MedicationsRepository();
});

/// Provider for all medications sorted by usage
final medicationsProvider = FutureProvider<List<Medication>>((ref) async {
  final repo = ref.watch(medicationsRepositoryProvider);
  return repo.getAllSortedByUsage();
});

/// Provider for medication search
final medicationSearchProvider = FutureProvider.family<List<Medication>, String>((ref, query) async {
  final repo = ref.watch(medicationsRepositoryProvider);
  return repo.searchByCode(query);
});
