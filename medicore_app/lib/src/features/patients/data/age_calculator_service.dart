import '../../../core/types/proto_types.dart';

/// Service to calculate and update patient ages based on creation date
class AgeCalculatorService {
  // final AppDatabase _db;

  AgeCalculatorService();

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
    // AppDatabase not available - this would need to be implemented with repository
    return 0;
  }

  /// Get patient with updated age (without saving to database)
  Patient getPatientWithUpdatedAge(Patient patient) {
    final currentAge = calculateCurrentAge(
      dateOfBirth: patient.dateOfBirth != null ? DateTime.tryParse(patient.dateOfBirth!) : null,
      storedAge: patient.age,
      createdAt: patient.createdAt != null ? DateTime.tryParse(patient.createdAt!) : null,
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
      phone: patient.phone,
      notes: patient.notes,
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
    dateOfBirth: dateOfBirth != null ? DateTime.tryParse(dateOfBirth!) : null,
    storedAge: age,
    createdAt: createdAt != null ? DateTime.tryParse(createdAt!) : null,
  );
}

/// Extension on WaitingPatient to easily get current calculated age
extension WaitingPatientAgeExtension on WaitingPatient {
  /// Get the current age calculated dynamically
  int? get currentAge {
    // GrpcWaitingPatient doesn't have patientBirthDate or patientCreatedAt
    // Just return the stored age
    return patientAge;
  }
}
