import 'package:drift/drift.dart';

/// Payments table for accounting (Comptabilité)
/// Tracks all payments made by doctors for medical acts performed on patients
class Payments extends Table {
  /// Unique payment ID (sequential, auto-increment)
  IntColumn get id => integer().autoIncrement()();
  
  /// Medical act ID from medical_acts table
  IntColumn get medicalActId => integer()();
  
  /// Medical act name (stored for data integrity and performance)
  /// Even if the act is modified later, this preserves historical data
  TextColumn get medicalActName => text()();
  
  /// Amount charged in DA (stored from medical_acts at time of payment)
  IntColumn get amount => integer()();
  
  /// User ID who performed/recorded the payment
  TextColumn get userId => text()();
  
  /// User name (stored for reporting, even if user is deleted later)
  TextColumn get userName => text()();
  
  /// Patient code (foreign key to patients table)
  IntColumn get patientCode => integer()();
  
  /// Patient first name (stored for reporting)
  TextColumn get patientFirstName => text()();
  
  /// Patient last name (stored for reporting)
  TextColumn get patientLastName => text()();
  
  /// Payment date and time (with hours for morning/afternoon filtering)
  /// Morning: before 13:00 (1 PM)
  /// Afternoon: 13:00 (1 PM) and later
  DateTimeColumn get paymentTime => dateTime()();
  
  /// When this payment record was created
  DateTimeColumn get createdAt => dateTime()();
  
  /// When this payment record was last modified
  DateTimeColumn get updatedAt => dateTime()();
  
  /// Sync flag for multi-PC synchronization
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  
  /// Soft delete flag (preserves data integrity for accounting)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
