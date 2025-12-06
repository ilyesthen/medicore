import 'package:drift/drift.dart';

/// Patients table definition
class Patients extends Table {
  /// Patient code (sequential number, shown in N° column)
  IntColumn get code => integer()();
  
  /// Unique barcode (8 characters like "0v4c+wLj")
  TextColumn get barcode => text().withLength(min: 8, max: 8).unique()();
  
  /// Date of creation
  DateTimeColumn get createdAt => dateTime()();
  
  /// First name (required)
  TextColumn get firstName => text()();
  
  /// Last name (required)
  TextColumn get lastName => text()();
  
  /// Age (optional)
  IntColumn get age => integer().nullable()();
  
  /// Date of birth (optional, for age calculation)
  DateTimeColumn get dateOfBirth => dateTime().nullable()();
  
  /// Address (optional)
  TextColumn get address => text().nullable()();
  
  /// Phone number (optional)
  TextColumn get phoneNumber => text().nullable()();
  
  /// Other info (optional)
  TextColumn get otherInfo => text().nullable()();
  
  /// Last update timestamp
  DateTimeColumn get updatedAt => dateTime()();
  
  /// Sync flag for cloud/LAN sync
  BoolColumn get needsSync => boolean().withDefault(const Constant(true))();
  
  @override
  Set<Column> get primaryKey => {code};
}
