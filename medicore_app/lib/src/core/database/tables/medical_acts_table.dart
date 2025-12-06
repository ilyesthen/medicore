import 'package:drift/drift.dart';

/// Medical acts table for fee management (Honoraires)
class MedicalActs extends Table {
  /// Unique act ID (sequential, important for other features)
  IntColumn get id => integer().autoIncrement()();
  
  /// Act name/description (e.g., "CONSULTATION +FO", "OCT", etc.)
  TextColumn get name => text()();
  
  /// Fee amount in DA (Dinar Algérien)
  IntColumn get feeAmount => integer()();
  
  /// Display order for the list
  IntColumn get displayOrder => integer()();
  
  /// When the act was created
  DateTimeColumn get createdAt => dateTime()();
  
  /// When the act was last modified
  DateTimeColumn get updatedAt => dateTime()();
  
  /// Whether this act is active (soft delete)
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}
