import 'package:drift/drift.dart';

/// Appointments table - stores scheduled patient appointments
/// Patients here are NOT in the main patients table until they are confirmed
class Appointments extends Table {
  /// Unique appointment ID (auto-increment)
  IntColumn get id => integer().autoIncrement()();
  
  /// Appointment date (the day the patient is expected)
  DateTimeColumn get appointmentDate => dateTime()();
  
  /// Patient first name
  TextColumn get firstName => text()();
  
  /// Patient last name
  TextColumn get lastName => text()();
  
  /// Age (optional)
  IntColumn get age => integer().nullable()();
  
  /// Date of birth (optional)
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  
  /// Phone number (optional but recommended for appointments)
  TextColumn get phoneNumber => text().nullable()();
  
  /// Address (optional)
  TextColumn get address => text().nullable()();
  
  /// Other info/notes (optional)
  TextColumn get notes => text().nullable()();
  
  /// If this appointment was created from an existing patient, store their code
  /// This allows us to link back to the patient without duplicating
  IntColumn get existingPatientCode => integer().nullable()();
  
  /// Whether the patient was added to the main patients table
  BoolColumn get wasAdded => boolean().withDefault(const Constant(false))();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Who created this appointment
  TextColumn get createdBy => text().nullable()();
}
