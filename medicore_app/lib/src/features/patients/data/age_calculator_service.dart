import '../../../core/database/app_database.dart';
import 'package:drift/drift.dart';
import '../../../core/generated/medicore.pb.dart';

/// Service to calculate and update patient ages based on creation date
class AgeCalculatorService {
  final AppDatabase _db;

  AgeCalculatorService([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Calculate age from a birth date to today
  static int calculateAgeFromDate(DateTime birthDate) {
    final today = DateTime.now();
    int age = today.year - birthDate.year;
    
    // Check if birthday hasn't occurred this year yet
    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }
    
    return age;
  }

  /// Calculate current age for a patient
  /// - If dateOfBirth is set: calculate from dateOfBirth
  /// - If only age is set: use createdAt as reference + stored age to derive synthetic birthday
  ///   Example: If patient was created on 2024-01-15 with age 30, 
  ///   synthetic birthday = 1994-01-15, so on 2025-01-15 they will be 31
  static int? calculateCurrentAge({
    DateTime? dateOfBirth,
    int? storedAge,
    required DateTime createdAt,
  }) {
    // Case 1: Has actual date of birth - calculate directly
    if (dateOfBirth != null) {
      return calculateAgeFromDate(dateOfBirth);
    }
    
    // Case 2: Has stored age - derive synthetic birthday from createdAt
    if (storedAge != null) {
      // Synthetic birthday = createdAt minus storedAge years
      final syntheticBirthday = DateTime(
        createdAt.year - storedAge,
        createdAt.month,
        createdAt.day,
      );
      return calculateAgeFromDate(syntheticBirthday);
    }
    
    // Case 3: No age info
    return null;
  }

  /// Update all patient ages based on their creation dates
  /// Should be run on app startup or periodically
  Future<int> updateAllPatientAges() async {
    final patients = await _db.select(_db.patients).get();
    int updatedCount = 0;

    for (final patient in patients) {
      // Skip patients with dateOfBirth - they don't need stored age updates
      if (patient.dateOfBirth != null) continue;
      
      // Skip patients without stored age
      if (patient.age == null) continue;
      
      // For patients with only stored age, we DON'T update the stored age
      // The stored age is the "age at creation" - it's a reference value
      // Current age is calculated dynamically in the UI
    }

    return updatedCount;
  }

  /// Get patient with updated age (without saving to database)
  Patient getPatientWithUpdatedAge(Patient patient) {
    final currentAge = calculateCurrentAge(
      dateOfBirth: patient.dateOfBirth,
      storedAge: patient.age,
      createdAt: patient.createdAt,
    );
    
    return Patient(
      code: patient.code,
      barcode: patient.barcode,
      createdAt: patient.createdAt,
      firstName: patient.firstName,
      lastName: patient.lastName,
      age: currentAge,
      dateOfBirth: patient.dateOfBirth,
      address: patient.address,
      phoneNumber: patient.phoneNumber,
      otherInfo: patient.otherInfo,
      updatedAt: patient.updatedAt,
      needsSync: patient.needsSync,
    );
  }
}

/// Extension on Patient to easily get current calculated age
extension PatientAgeExtension on Patient {
  /// Get the current age calculated dynamically
  /// - If dateOfBirth is set: calculate from dateOfBirth
  /// - If only age is set: calculate based on createdAt + stored age
  int? get currentAge => AgeCalculatorService.calculateCurrentAge(
    dateOfBirth: dateOfBirth,
    storedAge: age,
    createdAt: createdAt,
  );
}

/// Extension on WaitingPatient to easily get current calculated age
extension WaitingPatientAgeExtension on WaitingPatient {
  /// Get the current age calculated dynamically
  /// - If patientBirthDate is set: calculate from patientBirthDate
  /// - If only patientAge is set: calculate based on patientCreatedAt + stored age
  int? get currentAge {
    // If we have a birth date, calculate from it
    if (patientBirthDate != null) {
      return AgeCalculatorService.calculateAgeFromDate(patientBirthDate!);
    }
    
    // If we have stored age and creation date, calculate dynamically
    if (patientAge != null && patientCreatedAt != null) {
      return AgeCalculatorService.calculateCurrentAge(
        dateOfBirth: null,
        storedAge: patientAge,
        createdAt: patientCreatedAt!,
      );
    }
    
    // Fallback to stored age (for legacy data without createdAt)
    return patientAge;
  }
}
