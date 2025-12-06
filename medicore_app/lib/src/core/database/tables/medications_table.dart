import 'package:drift/drift.dart';

/// Medications/Preparations table
/// Stores medication templates with usage count
class Medications extends Table {
  /// Unique ID
  IntColumn get id => integer().autoIncrement()();
  
  /// Original ID from import (IDPREPA)
  IntColumn get originalId => integer().nullable()();
  
  /// Code/Name for search (CODELIB)
  TextColumn get code => text()();
  
  /// Full prescription text with formatting (LIBPREP)
  TextColumn get prescription => text()();
  
  /// Usage count - editable by user (NBPRES)
  IntColumn get usageCount => integer().withDefault(const Constant(0))();
  
  /// Nature: O = Ordonnance, N = Other (bilan, etc)
  TextColumn get nature => text().withDefault(const Constant('O'))();
  
  /// Timestamps
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
