import 'package:drift/drift.dart';

/// Messages table for room-based communication
class Messages extends Table {
  /// Unique message ID
  IntColumn get id => integer().autoIncrement()();
  
  /// Room ID where message is sent from/to
  TextColumn get roomId => text()();
  
  /// Sender user ID
  TextColumn get senderId => text()();
  
  /// Sender name (for display)
  TextColumn get senderName => text()();
  
  /// Sender role (for display)
  TextColumn get senderRole => text()();
  
  /// Message content
  TextColumn get content => text()();
  
  /// Message direction: 'to_nurse' or 'to_doctor'
  TextColumn get direction => text()();
  
  /// Whether message has been read
  BoolColumn get isRead => boolean().withDefault(const Constant(false))();
  
  /// When message was sent
  DateTimeColumn get sentAt => dateTime()();
  
  /// When message was read (null if unread)
  DateTimeColumn get readAt => dateTime().nullable()();
  
  /// Patient code (optional - set when message sent from consultation page)
  IntColumn get patientCode => integer().nullable()();
  
  /// Patient name for display (optional - "FirstName LastName")
  TextColumn get patientName => text().nullable()();
}
