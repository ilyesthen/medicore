import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

/// Repository for waiting patients queue operations
class WaitingQueueRepository {
  final AppDatabase _database;

  WaitingQueueRepository([AppDatabase? database]) 
      : _database = database ?? AppDatabase();

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
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.equals(roomId))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isUrgent.equals(false))
          ..where((w) => w.isDilatation.equals(false)) // Exclude patients sent to nurse
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }

  /// Watch urgent patients for a specific room
  Stream<List<WaitingPatient>> watchUrgentPatientsForRoom(String roomId) {
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.equals(roomId))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isUrgent.equals(true))
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }

  /// Get count of waiting patients for a room (non-urgent, non-dilatation only)
  Stream<int> watchWaitingCountForRoom(String roomId) {
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
    final now = DateTime.now();
    final dilatationLabel = dilatationLabels[dilatationType] ?? dilatationType;
    
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
    return (_database.select(_database.waitingPatients)
          ..where((w) => w.roomId.equals(roomId))
          ..where((w) => w.isActive.equals(true))
          ..where((w) => w.isDilatation.equals(true))
          ..orderBy([(w) => OrderingTerm.asc(w.sentAt)]))
        .watch();
  }

  /// Get count of dilatation patients for a room
  Stream<int> watchDilatationCountForRoom(String roomId) {
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
    await (_database.update(_database.waitingPatients)
          ..where((w) => w.id.equals(id)))
        .write(const WaitingPatientsCompanion(
          isActive: Value(false),
        ));
  }

  /// Remove patient from queue by patient code (when opening file)
  Future<void> removeByPatientCode(int patientCode) async {
    await (_database.update(_database.waitingPatients)
          ..where((w) => w.patientCode.equals(patientCode))
          ..where((w) => w.isActive.equals(true)))
        .write(const WaitingPatientsCompanion(
          isActive: Value(false),
        ));
  }

  /// Get waiting patient by ID
  Future<WaitingPatient?> getById(int id) async {
    return await (_database.select(_database.waitingPatients)
          ..where((w) => w.id.equals(id)))
        .getSingleOrNull();
  }
}
