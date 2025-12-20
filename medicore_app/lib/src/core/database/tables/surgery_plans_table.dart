import 'package:drift/drift.dart';

/// Surgery Plans table - stores scheduled surgeries for patients
/// Clinic name: Thaziri
class SurgeryPlans extends Table {
  /// Unique surgery plan ID (auto-increment)
  IntColumn get id => integer().autoIncrement()();
  
  /// Scheduled date for surgery
  DateTimeColumn get surgeryDate => dateTime()();
  
  /// Scheduled hour (e.g., "08:00", "09:30")
  TextColumn get surgeryHour => text()();
  
  /// Patient code (linked to patients table)
  IntColumn get patientCode => integer()();
  
  /// Patient first name (cached for display)
  TextColumn get patientFirstName => text()();
  
  /// Patient last name (cached for display)
  TextColumn get patientLastName => text()();
  
  /// Patient age (cached for display)
  IntColumn get patientAge => integer().nullable()();
  
  /// Patient phone number (cached for display)
  TextColumn get patientPhone => text().nullable()();
  
  /// Type of surgery - predefined options:
  /// - Cataracte - phacoemulsification
  /// - Cataracte - EEC
  /// - ICL
  /// - DCR
  /// - Sondage sous AG
  /// - Entropion
  /// - ECTROPION
  /// - PTOSIS - Résection RPS
  /// - Custom (user can add their own)
  TextColumn get surgeryType => text()();
  
  /// Eye to operate: 'OD' (right), 'OG' (left), 'ODG' (both)
  TextColumn get eyeToOperate => text()();
  
  /// Puissance de l'implant (power of implant)
  TextColumn get implantPower => text().nullable()();
  
  /// Tarif (price/fee)
  IntColumn get tarif => integer().nullable()();
  
  /// Payment status: 'pending', 'partial', 'paid'
  TextColumn get paymentStatus => text().withDefault(const Constant('pending'))();
  
  /// Amount remaining to pay (for partial payments)
  IntColumn get amountRemaining => integer().nullable()();
  
  /// Surgery status: 'scheduled', 'done', 'cancelled'
  TextColumn get surgeryStatus => text().withDefault(const Constant('scheduled'))();
  
  /// Whether patient came for surgery (set to true when done)
  BoolColumn get patientCame => boolean().withDefault(const Constant(false))();
  
  /// Notes (optional)
  TextColumn get notes => text().nullable()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Who created this surgery plan
  TextColumn get createdBy => text().nullable()();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  
  /// Sync flag for cloud/LAN sync
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
}
