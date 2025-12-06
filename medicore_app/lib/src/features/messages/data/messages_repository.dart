import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

/// Repository for message operations
class MessagesRepository {
  final AppDatabase _db;

  MessagesRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Send a message
  Future<Message> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    required String direction, // 'to_nurse' or 'to_doctor'
    int? patientCode, // Optional: linked patient code (from consultation page)
    String? patientName, // Optional: linked patient name (from consultation page)
  }) async {
    final now = DateTime.now();
    
    final companion = MessagesCompanion.insert(
      roomId: roomId,
      senderId: senderId,
      senderName: senderName,
      senderRole: senderRole,
      content: content,
      direction: direction,
      sentAt: now,
      isRead: const Value(false),
      patientCode: Value(patientCode),
      patientName: Value(patientName),
    );

    final id = await _db.into(_db.messages).insert(companion);
    return (await getMessage(id))!;
  }

  /// Get a specific message
  Future<Message?> getMessage(int id) async {
    return await (_db.select(_db.messages)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get unread messages for a nurse (for specific rooms)
  Stream<List<Message>> watchUnreadMessagesForNurse(List<String> roomIds) {
    print('🔍 QUERY: Fetching unread messages for nurse in rooms $roomIds (direction: to_nurse)');
    
    return (_db.select(_db.messages)
          ..where((m) => 
              m.direction.equals('to_nurse') & 
              m.isRead.equals(false) &
              m.roomId.isIn(roomIds))
          ..orderBy([(m) => OrderingTerm.desc(m.sentAt)]))
        .watch()
        .map((messages) {
          print('📊 QUERY RESULT: Found ${messages.length} messages for nurse in rooms $roomIds');
          for (final msg in messages) {
            print('   ✉️  ID: ${msg.id}, From: ${msg.senderName}, Content: ${msg.content}, Direction: ${msg.direction}');
          }
          return messages;
        });
  }

  /// Get unread messages for a doctor (for specific room)
  Stream<List<Message>> watchUnreadMessagesForDoctor(String roomId) {
    print('🔍 QUERY: Fetching unread messages for doctor in room $roomId (direction: to_doctor)');
    
    return (_db.select(_db.messages)
          ..where((m) => 
              m.direction.equals('to_doctor') & 
              m.isRead.equals(false) &
              m.roomId.equals(roomId))
          ..orderBy([(m) => OrderingTerm.desc(m.sentAt)]))
        .watch()
        .map((messages) {
          print('📊 QUERY RESULT: Found ${messages.length} messages for doctor in room $roomId');
          for (final msg in messages) {
            print('   ✉️  ID: ${msg.id}, From: ${msg.senderName}, Content: ${msg.content}, Direction: ${msg.direction}');
          }
          return messages;
        });
  }

  /// Get all messages for a room (for viewing history)
  Stream<List<Message>> watchMessagesForRoom(String roomId) {
    return (_db.select(_db.messages)
          ..where((m) => m.roomId.equals(roomId))
          ..orderBy([(m) => OrderingTerm.desc(m.sentAt)]))
        .watch();
  }

  /// Delete message when read (no history kept)
  Future<void> markAsRead(int messageId) async {
    await deleteMessage(messageId);
  }

  /// Delete all messages for a nurse (for specific rooms) - no history
  Future<void> markAllAsReadForNurse(List<String> roomIds) async {
    await (_db.delete(_db.messages)
          ..where((m) => 
              m.direction.equals('to_nurse') & 
              m.roomId.isIn(roomIds)))
        .go();
  }

  /// Delete all messages for a doctor (for specific room) - no history
  Future<void> markAllAsReadForDoctor(String roomId) async {
    await (_db.delete(_db.messages)
          ..where((m) => 
              m.direction.equals('to_doctor') & 
              m.roomId.equals(roomId)))
        .go();
  }

  /// Get unread count for nurse
  Future<int> getUnreadCountForNurse(List<String> roomIds) async {
    final query = _db.selectOnly(_db.messages)
      ..addColumns([_db.messages.id.count()])
      ..where(_db.messages.direction.equals('to_nurse') & 
              _db.messages.isRead.equals(false) &
              _db.messages.roomId.isIn(roomIds));
    
    final result = await query.getSingleOrNull();
    return result?.read(_db.messages.id.count()) ?? 0;
  }

  /// Get unread count for doctor
  Future<int> getUnreadCountForDoctor(String roomId) async {
    final query = _db.selectOnly(_db.messages)
      ..addColumns([_db.messages.id.count()])
      ..where(_db.messages.direction.equals('to_doctor') & 
              _db.messages.isRead.equals(false) &
              _db.messages.roomId.equals(roomId));
    
    final result = await query.getSingleOrNull();
    return result?.read(_db.messages.id.count()) ?? 0;
  }

  /// Delete a message
  Future<void> deleteMessage(int id) async {
    await (_db.delete(_db.messages)
          ..where((m) => m.id.equals(id)))
        .go();
  }
}
