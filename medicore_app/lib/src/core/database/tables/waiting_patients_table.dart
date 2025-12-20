import 'package:drift/drift.dart';

/// Waiting patients queue table
/// Tracks patients waiting for consultation in each room
class WaitingPatients extends Table {
  /// Unique queue entry ID
  IntColumn get id => integer().autoIncrement()();
  
  /// Patient code (FK to patients table)
  IntColumn get patientCode => integer()();
  
  /// Patient first name (cached for performance)
  TextColumn get patientFirstName => text()();
  
  /// Patient last name (cached for performance)
  TextColumn get patientLastName => text()();
  
  /// Patient birth date (cached for age calculation)
  DateTimeColumn get patientBirthDate => dateTime().nullable()();
  
  /// Patient age (used when birthDate is not available)
  IntColumn get patientAge => integer().nullable()();
  
  /// Patient creation date (for dynamic age calculation when birthDate is null)
  DateTimeColumn get patientCreatedAt => dateTime().nullable()();
  
  /// Whether this is an urgent case
  BoolColumn get isUrgent => boolean().withDefault(const Constant(false))();
  
  /// Whether this is a dilatation request (doctor → nurse)
  BoolColumn get isDilatation => boolean().withDefault(const Constant(false))();
  
  /// Dilatation type: 'skiacol', 'od', 'og', 'odg'
  TextColumn get dilatationType => text().nullable()();
  
  /// Room ID where patient is waiting
  TextColumn get roomId => text()();
  
  /// Room name (cached)
  TextColumn get roomName => text()();
  
  /// Motif de consultation (reason for visit)
  TextColumn get motif => text()();
  
  /// User ID who sent the patient (nurse)
  TextColumn get sentByUserId => text()();
  
  /// User name who sent (cached)
  TextColumn get sentByUserName => text()();
  
  /// Timestamp when patient was sent to queue
  DateTimeColumn get sentAt => dateTime()();
  
  /// Whether doctor has checked/starred this patient
  BoolColumn get isChecked => boolean().withDefault(const Constant(false))();
  
  /// Active flag (false when patient consultation started or removed)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  
  /// Whether nurse has been notified (for badge/sound)
  BoolColumn get isNotified => boolean().withDefault(const Constant(false))();
}
