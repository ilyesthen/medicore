import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

/// Repository for medical acts (Honoraires) operations
class MedicalActsRepository {
  final AppDatabase _db;

  MedicalActsRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Watch all active medical acts
  Stream<List<MedicalAct>> watchAllMedicalActs() {
    return (_db.select(_db.medicalActs)
          ..where((act) => act.isActive.equals(true))
          ..orderBy([(act) => OrderingTerm.asc(act.displayOrder)]))
        .watch();
  }

  /// Get all active medical acts (non-stream)
  Future<List<MedicalAct>> getAllMedicalActs() async {
    return await (_db.select(_db.medicalActs)
          ..where((act) => act.isActive.equals(true))
          ..orderBy([(act) => OrderingTerm.asc(act.displayOrder)]))
        .get();
  }

  /// Get a specific medical act by ID
  Future<MedicalAct?> getMedicalAct(int id) async {
    return await (_db.select(_db.medicalActs)
          ..where((act) => act.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new medical act
  Future<MedicalAct> createMedicalAct({
    required String name,
    required int feeAmount,
  }) async {
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
    await (_db.update(_db.medicalActs)
          ..where((act) => act.id.equals(id)))
        .write(MedicalActsCompanion(
      isActive: const Value(false),
      updatedAt: Value(DateTime.now()),
    ));
  }

  /// Reorder medical acts
  Future<void> reorderMedicalActs(List<int> orderedIds) async {
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
