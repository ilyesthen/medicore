import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

/// Repository for medications
class MedicationsRepository {
  final AppDatabase _db;
  
  MedicationsRepository([AppDatabase? db]) : _db = db ?? AppDatabase();
  
  /// Get all medications sorted by usage count (most used first)
  Future<List<Medication>> getAllSortedByUsage() async {
    return await (_db.select(_db.medications)
      ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
    ).get();
  }
  
  /// Search medications by code (starts with)
  Future<List<Medication>> searchByCode(String query) async {
    if (query.isEmpty) return getAllSortedByUsage();
    
    return await (_db.select(_db.medications)
      ..where((t) => t.code.lower().like('${query.toLowerCase()}%'))
      ..orderBy([(t) => OrderingTerm.desc(t.usageCount)])
    ).get();
  }
  
  /// Increment usage count when medication is used
  Future<void> incrementUsage(int id) async {
    await _db.customStatement(
      'UPDATE medications SET usage_count = usage_count + 1, updated_at = ? WHERE id = ?',
      [DateTime.now().toIso8601String(), id],
    );
  }
  
  /// Set usage count (user editable)
  Future<void> setUsageCount(int id, int count) async {
    await (_db.update(_db.medications)
      ..where((t) => t.id.equals(id))
    ).write(MedicationsCompanion(
      usageCount: Value(count),
      updatedAt: Value(DateTime.now()),
    ));
  }
  
  /// Get medication by ID
  Future<Medication?> getById(int id) async {
    return await (_db.select(_db.medications)
      ..where((t) => t.id.equals(id))
    ).getSingleOrNull();
  }
  
  /// Get count of medications
  Future<int> getCount() async {
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
