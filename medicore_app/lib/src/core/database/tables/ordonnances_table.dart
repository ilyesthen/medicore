import 'package:drift/drift.dart';

/// Ordonnances/Documents table - stores all medical documents
/// Including prescriptions, certificates, reports, etc.
class Ordonnances extends Table {
  /// Unique record ID from XML (N__Enr.)
  IntColumn get id => integer().autoIncrement()();
  
  /// Original record number from import
  IntColumn get originalId => integer().nullable()();
  
  /// Patient code (CDEP)
  IntColumn get patientCode => integer()();
  
  /// Document date (DATEORD)
  DateTimeColumn get documentDate => dateTime().nullable()();
  
  /// Patient age at time of document (AG2)
  IntColumn get patientAge => integer().nullable()();
  
  /// Sequence/visit number (SEQ)
  IntColumn get sequence => integer().withDefault(const Constant(1))();
  
  /// Combined sequence + patient code (SEQPAT)
  TextColumn get seqPat => text().nullable()();
  
  /// Doctor name (MEDCIN)
  TextColumn get doctorName => text().nullable()();
  
  /// Amount (SMONT)
  RealColumn get amount => real().withDefault(const Constant(0))();
  
  /// Primary document content (STRAIT) - preserves formatting
  TextColumn get content1 => text().nullable()();
  
  /// Primary document type (ACTEX) - e.g., ORDONNANCE, CERTIFICAT MEDICAL
  TextColumn get type1 => text().withDefault(const Constant('ORDONNANCE'))();
  
  /// Secondary document content (strait1) - preserves formatting
  TextColumn get content2 => text().nullable()();
  
  /// Secondary document type (ACTEX1)
  TextColumn get type2 => text().nullable()();
  
  /// Third document content (strait2) - preserves formatting
  TextColumn get content3 => text().nullable()();
  
  /// Third document type (ACTEX2)
  TextColumn get type3 => text().nullable()();
  
  /// Additional notes (strait3)
  TextColumn get additionalNotes => text().nullable()();
  
  /// Report title (titre_cr) - e.g., COMPTE RENDU D'OCT
  TextColumn get reportTitle => text().nullable()();
  
  /// Referred by (ADressé_par)
  TextColumn get referredBy => text().nullable()();
  
  /// RDV flag (rdvle)
  IntColumn get rdvFlag => integer().withDefault(const Constant(0))();
  
  /// RDV date (datele)
  TextColumn get rdvDate => text().nullable()();
  
  /// RDV day (jourle)
  TextColumn get rdvDay => text().nullable()();
  
  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
