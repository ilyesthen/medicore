import 'package:drift/drift.dart';

/// Templates table - stores user templates for quick registration
@DataClassName('TemplateEntity')
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get role => text()();
  TextColumn get passwordHash => text()();
  RealColumn get percentage => real()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  
  // Sync fields for multi-PC synchronization
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();
  BoolColumn get needsSync => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}
