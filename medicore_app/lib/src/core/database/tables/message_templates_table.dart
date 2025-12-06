import 'package:drift/drift.dart';

/// Message templates table for quick message sending
class MessageTemplates extends Table {
  /// Unique ID
  IntColumn get id => integer().autoIncrement()();
  
  /// Template text content
  TextColumn get content => text()();
  
  /// Display order
  IntColumn get displayOrder => integer()();
  
  /// Creation timestamp
  DateTimeColumn get createdAt => dateTime()();
  
  /// User who created it (null = system default)
  TextColumn get createdBy => text().nullable()();
}
