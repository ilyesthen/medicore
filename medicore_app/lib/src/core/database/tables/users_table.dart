import 'package:drift/drift.dart';

/// Users table - stores all user accounts
@DataClassName('UserEntity')
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get role => text()();
  TextColumn get passwordHash => text()();
  RealColumn get percentage => real().nullable()();
  BoolColumn get isTemplateUser => boolean().withDefault(const Constant(false))();
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
