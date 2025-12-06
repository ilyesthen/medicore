import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

/// Provider for the database instance (visits module)
final _databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Repository for managing patient visits
class VisitsRepository {
  final AppDatabase _db;

  VisitsRepository(this._db);

  /// Get all visits for a specific patient
  Future<List<Visit>> getVisitsForPatient(int patientCode) async {
    return await (_db.select(_db.visits)
          ..where((v) => v.patientCode.equals(patientCode))
          ..where((v) => v.isActive.equals(true))
          ..orderBy([(v) => OrderingTerm.desc(v.visitDate)]))
        .get();
  }

  /// Get visit count for a patient
  Future<int> getVisitCountForPatient(int patientCode) async {
    final count = await (_db.select(_db.visits)
          ..where((v) => v.patientCode.equals(patientCode))
          ..where((v) => v.isActive.equals(true)))
        .get();
    return count.length;
  }

  /// Get a single visit by ID
  Future<Visit?> getVisitById(int id) async {
    return await (_db.select(_db.visits)
          ..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new visit
  Future<int> insertVisit(VisitsCompanion visit) async {
    return await _db.into(_db.visits).insert(visit);
  }

  /// Insert multiple visits (batch import)
  Future<void> insertVisits(List<VisitsCompanion> visits) async {
    await _db.batch((batch) {
      batch.insertAll(_db.visits, visits);
    });
  }

  /// Update an existing visit
  Future<bool> updateVisit(int id, VisitsCompanion visit) async {
    return await (_db.update(_db.visits)..where((v) => v.id.equals(id)))
            .write(visit) >
        0;
  }

  /// Soft delete a visit
  Future<bool> deleteVisit(int id) async {
    return await (_db.update(_db.visits)..where((v) => v.id.equals(id)))
            .write(const VisitsCompanion(isActive: Value(false))) >
        0;
  }

  /// Check if visits exist for a patient
  Future<bool> hasVisitsForPatient(int patientCode) async {
    final result = await (_db.select(_db.visits)
          ..where((v) => v.patientCode.equals(patientCode))
          ..where((v) => v.isActive.equals(true))
          ..limit(1))
        .get();
    return result.isNotEmpty;
  }

  /// Get total visit count in database
  Future<int> getTotalVisitCount() async {
    final count = await (_db.select(_db.visits)
          ..where((v) => v.isActive.equals(true)))
        .get();
    return count.length;
  }

  /// Clear all visits (for reimport)
  Future<int> clearAllVisits() async {
    return await _db.delete(_db.visits).go();
  }
}

/// Provider for visits repository
final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  final db = ref.watch(_databaseProvider);
  return VisitsRepository(db);
});

/// Provider for visits of a specific patient
final patientVisitsProvider = FutureProvider.family<List<Visit>, int>((ref, patientCode) async {
  final repository = ref.watch(visitsRepositoryProvider);
  return repository.getVisitsForPatient(patientCode);
});

/// Provider for visit count of a specific patient
final patientVisitCountProvider = FutureProvider.family<int, int>((ref, patientCode) async {
  final repository = ref.watch(visitsRepositoryProvider);
  return repository.getVisitCountForPatient(patientCode);
});
