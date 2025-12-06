import 'package:drift/drift.dart';

/// Visits table for patient consultation history
/// Stores all ophthalmology examination data from visits
class Visits extends Table {
  /// Unique visit ID (auto-increment)
  IntColumn get id => integer().autoIncrement()();
  
  /// Original record number from XML (N__Enr.)
  IntColumn get originalId => integer().nullable()();
  
  /// Patient code (CDEP) - links to patients table
  IntColumn get patientCode => integer()();
  
  /// Visit sequence number (SEQC)
  IntColumn get visitSequence => integer().withDefault(const Constant(1))();
  
  /// Visit date (DATECLI)
  DateTimeColumn get visitDate => dateTime()();
  
  /// Doctor name (MEDCIN)
  TextColumn get doctorName => text()();
  
  /// Reason for visit (MOTIF)
  TextColumn get motif => text().nullable()();
  
  /// Diagnosis (DIIAG)
  TextColumn get diagnosis => text().nullable()();
  
  /// Treatment/Conduct (CAT - Conduite à tenir)
  TextColumn get conduct => text().nullable()();
  
  // ══════════════════════════════════════════════════════════════
  // RIGHT EYE (OD - Oeil Droit)
  // ══════════════════════════════════════════════════════════════
  
  /// S.V - Sans Correction (SCOD)
  TextColumn get odSv => text().nullable()();
  
  /// A.V - Avec Correction (AVOD)
  TextColumn get odAv => text().nullable()();
  
  /// Sphere (p1)
  TextColumn get odSphere => text().nullable()();
  
  /// Cylinder (p2)
  TextColumn get odCylinder => text().nullable()();
  
  /// Axis (AXD)
  TextColumn get odAxis => text().nullable()();
  
  /// VL - Vision de Loin
  TextColumn get odVl => text().nullable()();
  
  /// K1 (K1_D)
  TextColumn get odK1 => text().nullable()();
  
  /// K2 (K2_D)
  TextColumn get odK2 => text().nullable()();
  
  /// R1 (R1_d)
  TextColumn get odR1 => text().nullable()();
  
  /// R2 (R2_d)
  TextColumn get odR2 => text().nullable()();
  
  /// R0 / Rayon (RAYOND)
  TextColumn get odR0 => text().nullable()();
  
  /// Pachymetry (pachy1_D)
  TextColumn get odPachy => text().nullable()();
  
  /// T.O.C - Tension Oculaire (TOOD)
  TextColumn get odToc => text().nullable()();
  
  /// Notes (comentaire_D)
  TextColumn get odNotes => text().nullable()();
  
  /// GONIO (VAD)
  TextColumn get odGonio => text().nullable()();
  
  /// T.O (TOOD - same as TOC for now)
  TextColumn get odTo => text().nullable()();
  
  /// L.A.F - Lampe à Fente (LAF)
  TextColumn get odLaf => text().nullable()();
  
  /// F.O - Fond d'Oeil (FO)
  TextColumn get odFo => text().nullable()();
  
  // ══════════════════════════════════════════════════════════════
  // LEFT EYE (OG - Oeil Gauche)
  // ══════════════════════════════════════════════════════════════
  
  /// S.V - Sans Correction (SCOG)
  TextColumn get ogSv => text().nullable()();
  
  /// A.V - Avec Correction (AVOG)
  TextColumn get ogAv => text().nullable()();
  
  /// Sphere (p3)
  TextColumn get ogSphere => text().nullable()();
  
  /// Cylinder (p5)
  TextColumn get ogCylinder => text().nullable()();
  
  /// Axis (AXG)
  TextColumn get ogAxis => text().nullable()();
  
  /// VL - Vision de Loin
  TextColumn get ogVl => text().nullable()();
  
  /// K1 (K1_G)
  TextColumn get ogK1 => text().nullable()();
  
  /// K2 (K2_G)
  TextColumn get ogK2 => text().nullable()();
  
  /// R1 (R1_G)
  TextColumn get ogR1 => text().nullable()();
  
  /// R2 (R2_G)
  TextColumn get ogR2 => text().nullable()();
  
  /// R0 / Rayon (RAYONG)
  TextColumn get ogR0 => text().nullable()();
  
  /// Pachymetry (pachy1_g)
  TextColumn get ogPachy => text().nullable()();
  
  /// T.O.C - Tension Oculaire (TOOG)
  TextColumn get ogToc => text().nullable()();
  
  /// Notes (commentaire_G)
  TextColumn get ogNotes => text().nullable()();
  
  /// GONIO (VAG)
  TextColumn get ogGonio => text().nullable()();
  
  /// T.O (TOOG - same as TOC for now)
  TextColumn get ogTo => text().nullable()();
  
  /// L.A.F - Lampe à Fente (LAF_G)
  TextColumn get ogLaf => text().nullable()();
  
  /// F.O - Fond d'Oeil (FO_G)
  TextColumn get ogFo => text().nullable()();
  
  // ══════════════════════════════════════════════════════════════
  // SHARED FIELDS
  // ══════════════════════════════════════════════════════════════
  
  /// Addition/EP (EP)
  TextColumn get addition => text().nullable()();
  
  /// D.I.P - Distance Inter-Pupillaire (EP as well, stored separately)
  TextColumn get dip => text().nullable()();
  
  // ══════════════════════════════════════════════════════════════
  // METADATA
  // ══════════════════════════════════════════════════════════════
  
  /// Record creation timestamp
  DateTimeColumn get createdAt => dateTime()();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  /// Sync flag for multi-PC synchronization
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  
  /// Soft delete flag
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
