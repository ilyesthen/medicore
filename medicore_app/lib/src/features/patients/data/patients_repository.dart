import 'dart:math';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

/// Repository for patient data operations
class PatientsRepository {
  final AppDatabase _db;

  PatientsRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Generate unique 8-character barcode
  Future<String> _generateUniqueBarcode() async {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+';
    final random = Random();
    
    while (true) {
      final barcode = List.generate(
        8,
        (index) => chars[random.nextInt(chars.length)],
      ).join();
      
      // Check if barcode already exists
      final existing = await (_db.select(_db.patients)
            ..where((p) => p.barcode.equals(barcode)))
          .getSingleOrNull();
      
      if (existing == null) {
        return barcode;
      }
    }
  }

  /// Get next patient code (sequential)
  Future<int> _getNextPatientCode() async {
    final query = _db.selectOnly(_db.patients)
      ..addColumns([_db.patients.code.max()]);
    final result = await query.getSingleOrNull();
    final maxCode = result?.read(_db.patients.code.max());
    return (maxCode ?? 0) + 1;
  }

  /// Calculate age from date of birth
  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Get all patients with smart ordering:
  /// - Today's patients first (newest code first for easy access)
  /// - Then all other patients (oldest code first)
  Stream<List<Patient>> watchAllPatients() async* {
    await for (final _ in _db.select(_db.patients).watch()) {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get today's patients (newest first)
      final todayPatients = await (_db.select(_db.patients)
            ..where((p) => 
                p.createdAt.isBiggerOrEqualValue(todayStart) &
                p.createdAt.isSmallerThanValue(todayEnd))
            ..orderBy([(p) => OrderingTerm.desc(p.code)]))
          .get();

      // Get all other patients (oldest first)
      final otherPatients = await (_db.select(_db.patients)
            ..where((p) => p.createdAt.isSmallerThanValue(todayStart))
            ..orderBy([(p) => OrderingTerm.asc(p.code)]))
          .get();

      // Combine: today's patients first, then others
      yield [...todayPatients, ...otherPatients];
    }
  }

  /// Get patient by code
  Future<Patient?> getPatientByCode(int code) async {
    return await (_db.select(_db.patients)
          ..where((p) => p.code.equals(code)))
        .getSingleOrNull();
  }

  /// Search patients by name (first, last, or both with space)
  /// Also respects smart ordering (today's patients first)
  Stream<List<Patient>> searchPatients(String query) async* {
    if (query.isEmpty) {
      yield* watchAllPatients();
      return;
    }

    final lowerQuery = query.toLowerCase().trim();
    
    await for (final _ in _db.select(_db.patients).watch()) {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      List<Patient> todayResults = [];
      List<Patient> otherResults = [];

      // Check if query contains space (searching both names)
      if (lowerQuery.contains(' ')) {
        final parts = lowerQuery.split(' ');
        final part1 = parts[0];
        final part2 = parts.sublist(1).join(' ');
        
        // Today's patients matching search
        todayResults = await (_db.select(_db.patients)
              ..where((p) =>
                  (p.createdAt.isBiggerOrEqualValue(todayStart) &
                   p.createdAt.isSmallerThanValue(todayEnd)) &
                  ((p.firstName.lower().like('%$part1%') & p.lastName.lower().like('%$part2%')) |
                   (p.firstName.lower().like('%$part2%') & p.lastName.lower().like('%$part1%'))))
              ..orderBy([(p) => OrderingTerm.desc(p.code)]))
            .get();

        // Other patients matching search
        otherResults = await (_db.select(_db.patients)
              ..where((p) =>
                  p.createdAt.isSmallerThanValue(todayStart) &
                  ((p.firstName.lower().like('%$part1%') & p.lastName.lower().like('%$part2%')) |
                   (p.firstName.lower().like('%$part2%') & p.lastName.lower().like('%$part1%'))))
              ..orderBy([(p) => OrderingTerm.asc(p.code)]))
            .get();
      } else {
        // Check if query is a valid patient code (number)
        final queryAsCode = int.tryParse(query);
        
        // Single word search - today's patients
        if (queryAsCode != null) {
          // Search by code only
          todayResults = await (_db.select(_db.patients)
                ..where((p) =>
                    (p.createdAt.isBiggerOrEqualValue(todayStart) &
                     p.createdAt.isSmallerThanValue(todayEnd)) &
                    p.code.equals(queryAsCode))
                ..orderBy([(p) => OrderingTerm.desc(p.code)]))
              .get();
          
          otherResults = await (_db.select(_db.patients)
                ..where((p) =>
                    p.createdAt.isSmallerThanValue(todayStart) &
                    p.code.equals(queryAsCode))
                ..orderBy([(p) => OrderingTerm.asc(p.code)]))
              .get();
        } else {
          // Search by name only
          todayResults = await (_db.select(_db.patients)
                ..where((p) =>
                    (p.createdAt.isBiggerOrEqualValue(todayStart) &
                     p.createdAt.isSmallerThanValue(todayEnd)) &
                    (p.firstName.lower().like('%$lowerQuery%') |
                     p.lastName.lower().like('%$lowerQuery%')))
                ..orderBy([(p) => OrderingTerm.desc(p.code)]))
              .get();

          otherResults = await (_db.select(_db.patients)
                ..where((p) =>
                    p.createdAt.isSmallerThanValue(todayStart) &
                    (p.firstName.lower().like('%$lowerQuery%') |
                     p.lastName.lower().like('%$lowerQuery%')))
                ..orderBy([(p) => OrderingTerm.asc(p.code)]))
              .get();
        }
      }

      // Combine: today's matches first, then others
      yield [...todayResults, ...otherResults];
    }
  }

  /// Create new patient
  Future<Patient> createPatient({
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    final code = await _getNextPatientCode();
    final barcode = await _generateUniqueBarcode();
    final now = DateTime.now();

    // Calculate age from date of birth if provided
    final finalAge = dateOfBirth != null ? _calculateAge(dateOfBirth) : age;

    final companion = PatientsCompanion.insert(
      code: Value(code),
      barcode: barcode,
      createdAt: now,
      firstName: firstName,
      lastName: lastName,
      age: Value(finalAge),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      phoneNumber: Value(phoneNumber),
      otherInfo: Value(otherInfo),
      updatedAt: now,
      needsSync: const Value(true),
    );

    await _db.into(_db.patients).insert(companion);
    return (await getPatientByCode(code))!;
  }

  /// Update patient
  Future<void> updatePatient({
    required int code,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    // Calculate age from date of birth if provided
    final finalAge = dateOfBirth != null ? _calculateAge(dateOfBirth) : age;

    final companion = PatientsCompanion(
      code: Value(code),
      firstName: Value(firstName),
      lastName: Value(lastName),
      age: Value(finalAge),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      phoneNumber: Value(phoneNumber),
      otherInfo: Value(otherInfo),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    );

    await (_db.update(_db.patients)
          ..where((p) => p.code.equals(code)))
        .write(companion);
  }

  /// Delete patient
  Future<void> deletePatient(int code) async {
    await (_db.delete(_db.patients)
          ..where((p) => p.code.equals(code)))
        .go();
  }

  /// Import patient from XML data (used for migration)
  Future<Patient> importPatient({
    required int code,
    required String barcode,
    required DateTime createdAt,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    // Check if patient with this code already exists
    final existing = await getPatientByCode(code);
    if (existing != null) {
      // Update existing patient
      await updatePatient(
        code: code,
        firstName: firstName,
        lastName: lastName,
        age: age,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        otherInfo: otherInfo,
      );
      return (await getPatientByCode(code))!;
    }

    // Insert new patient with specified data
    final companion = PatientsCompanion.insert(
      code: Value(code),
      barcode: barcode,
      createdAt: createdAt,
      firstName: firstName,
      lastName: lastName,
      age: Value(age),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      phoneNumber: Value(phoneNumber),
      otherInfo: Value(otherInfo),
      updatedAt: createdAt,
      needsSync: const Value(false), // Imported data doesn't need sync
    );

    await _db.into(_db.patients).insert(companion);
    return (await getPatientByCode(code))!;
  }

  /// Get total patient count
  Future<int> getPatientCount() async {
    final count = await _db.patients.count().getSingleOrNull();
    return count ?? 0;
  }
}
