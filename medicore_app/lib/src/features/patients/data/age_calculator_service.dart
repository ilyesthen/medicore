import '../../../core/database/app_database.dart';
import 'package:drift/drift.dart';

/// Service to calculate and update patient ages based on creation date
class AgeCalculatorService {
  final AppDatabase _db;

  AgeCalculatorService([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Calculate current age from creation date (creation date = birthday)
  int calculateAgeFromCreationDate(DateTime creationDate) {
    final today = DateTime.now();
    int age = today.year - creationDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (today.month < creationDate.month ||
        (today.month == creationDate.month && today.day < creationDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Update all patient ages based on their creation dates
  /// Should be run on app startup or periodically
  Future<int> updateAllPatientAges() async {
    final patients = await _db.select(_db.patients).get();
    int updatedCount = 0;

    for (final patient in patients) {
      // Calculate age from creation date
      final calculatedAge = calculateAgeFromCreationDate(patient.createdAt);
      
      // Only update if age has changed
      if (patient.age != calculatedAge) {
        await (_db.update(_db.patients)
              ..where((p) => p.code.equals(patient.code)))
            .write(PatientsCompanion(
          age: Value(calculatedAge),
        ));
        updatedCount++;
      }
    }

    return updatedCount;
  }

  /// Get patient with updated age (without saving to database)
  Patient getPatientWithUpdatedAge(Patient patient) {
    final newAge = calculateAgeFromCreationDate(patient.createdAt);
    
    return Patient(
      code: patient.code,
      barcode: patient.barcode,
      createdAt: patient.createdAt,
      firstName: patient.firstName,
      lastName: patient.lastName,
      age: newAge,
      dateOfBirth: patient.dateOfBirth,
      address: patient.address,
      phoneNumber: patient.phoneNumber,
      otherInfo: patient.otherInfo,
      updatedAt: patient.updatedAt,
      needsSync: patient.needsSync,
    );
  }
}
