import 'package:drift/drift.dart';

/// Rooms table - Medical/operational rooms in the facility
class Rooms extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {id};
}
