import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import '../database/app_database.dart' show Message;

/// Remote Messages Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only
class RemoteMessagesRepository {
  final MediCoreClient _client;
  
  // Active streams for real-time updates
  final Map<String, StreamController<List<Message>>> _roomStreams = {};
  final Map<String, Timer> _roomTimers = {};
  
  RemoteMessagesRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance;

  /// Send a message
  Future<Message> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    required String direction,
    int? patientCode,
    String? patientName,
  }) async {
    try {
      final request = CreateMessageRequest(
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        direction: direction,
        patientCode: patientCode,
        patientName: patientName,
      );
      
      final id = await _client.createMessage(request);
      
      return Message(
        id: id,
        roomId: roomId,
        senderId: senderId,
        senderName: senderName,
        senderRole: senderRole,
        content: content,
        direction: direction,
        isRead: false,
        sentAt: DateTime.now(),
        readAt: null,
        patientCode: patientCode,
        patientName: patientName,
      );
    } catch (e) {
      print('❌ [RemoteMessages] sendMessage failed: $e');
      rethrow;
    }
  }

  /// Watch unread messages for a nurse (multiple rooms)
  Stream<List<Message>> watchUnreadMessagesForNurse(List<String> roomIds) {
    final key = 'nurse_${roomIds.join('_')}';
    
    if (!_roomStreams.containsKey(key)) {
      _roomStreams[key] = StreamController<List<Message>>.broadcast();
      
      // Fetch immediately, then poll every 2 seconds
      Future<void> fetchMessages() async {
        try {
          final allMessages = <Message>[];
          for (final roomId in roomIds) {
            final response = await _client.getMessagesByRoom(roomId);
            allMessages.addAll(
              response.messages
                .where((m) => m.direction == 'to_nurse' && !m.isRead)
                .map(_grpcMessageToLocal)
            );
          }
          _roomStreams[key]?.add(allMessages);
        } catch (e) {
          print('❌ [RemoteMessages] poll failed: $e');
          _roomStreams[key]?.add([]); // Emit empty on error
        }
      }
      
      // Immediate fetch
      fetchMessages();
      
      // Poll every 2 seconds for real-time updates
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
    }
    
    return _roomStreams[key]!.stream;
  }

  /// Watch unread messages for a doctor (single room)
  Stream<List<Message>> watchUnreadMessagesForDoctor(String roomId) {
    final key = 'doctor_$roomId';
    
    if (!_roomStreams.containsKey(key)) {
      _roomStreams[key] = StreamController<List<Message>>.broadcast();
      
      // Fetch immediately, then poll every 2 seconds
      Future<void> fetchMessages() async {
        try {
          final response = await _client.getMessagesByRoom(roomId);
          final unread = response.messages
            .where((m) => m.direction == 'to_doctor' && !m.isRead)
            .map(_grpcMessageToLocal)
            .toList();
          _roomStreams[key]?.add(unread);
        } catch (e) {
          print('❌ [RemoteMessages] poll failed: $e');
          _roomStreams[key]?.add([]); // Emit empty on error
        }
      }
      
      // Immediate fetch
      fetchMessages();
      
      // Poll every 2 seconds for real-time updates
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
    }
    
    return _roomStreams[key]!.stream;
  }

  /// Watch all messages for a room
  Stream<List<Message>> watchMessagesForRoom(String roomId) {
    final key = 'all_$roomId';
    
    if (!_roomStreams.containsKey(key)) {
      _roomStreams[key] = StreamController<List<Message>>.broadcast();
      
      // Fetch immediately, then poll every 2 seconds
      Future<void> fetchMessages() async {
        try {
          final response = await _client.getMessagesByRoom(roomId);
          _roomStreams[key]?.add(response.messages.map(_grpcMessageToLocal).toList());
        } catch (e) {
          print('❌ [RemoteMessages] poll failed: $e');
          _roomStreams[key]?.add([]); // Emit empty on error
        }
      }
      
      // Immediate fetch
      fetchMessages();
      
      // Poll every 2 seconds for real-time updates
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
    }
    
    return _roomStreams[key]!.stream;
  }

  /// Mark message as read
  Future<void> markAsRead(int messageId) async {
    try {
      await _client.markMessageAsRead(messageId);
    } catch (e) {
      print('❌ [RemoteMessages] markAsRead failed: $e');
    }
  }

  /// Mark all messages as read for nurse (all rooms, to_nurse direction)
  Future<void> markAllAsReadForNurse(List<String> roomIds) async {
    for (final roomId in roomIds) {
      try {
        await _client.markAllMessagesAsRead(roomId, 'to_nurse');
      } catch (e) {
        print('❌ [RemoteMessages] markAllAsReadForNurse failed: $e');
      }
    }
  }

  /// Mark all messages as read for doctor (single room, to_doctor direction)
  Future<void> markAllAsReadForDoctor(String roomId) async {
    try {
      await _client.markAllMessagesAsRead(roomId, 'to_doctor');
    } catch (e) {
      print('❌ [RemoteMessages] markAllAsReadForDoctor failed: $e');
    }
  }

  /// Get unread count for nurse
  Future<int> getUnreadCountForNurse(List<String> roomIds) async {
    int count = 0;
    for (final roomId in roomIds) {
      try {
        final response = await _client.getMessagesByRoom(roomId);
        count += response.messages.where((m) => m.direction == 'to_nurse' && !m.isRead).length;
      } catch (e) {
        // Ignore errors for count
      }
    }
    return count;
  }

  /// Get unread count for doctor
  Future<int> getUnreadCountForDoctor(String roomId) async {
    try {
      final response = await _client.getMessagesByRoom(roomId);
      return response.messages.where((m) => m.direction == 'to_doctor' && !m.isRead).length;
    } catch (e) {
      return 0;
    }
  }

  /// Delete a message
  Future<void> deleteMessage(int id) async {
    await _client.deleteMessage(id);
  }

  /// Convert GrpcMessage to local Message model
  Message _grpcMessageToLocal(GrpcMessage grpc) {
    return Message(
      id: grpc.id,
      roomId: grpc.roomId,
      senderId: grpc.senderId,
      senderName: grpc.senderName,
      senderRole: grpc.senderRole,
      content: grpc.content,
      direction: grpc.direction,
      isRead: grpc.isRead,
      sentAt: DateTime.tryParse(grpc.sentAt) ?? DateTime.now(),
      readAt: null,
      patientCode: grpc.patientCode,
      patientName: grpc.patientName,
    );
  }

  void dispose() {
    for (final timer in _roomTimers.values) {
      timer.cancel();
    }
    for (final controller in _roomStreams.values) {
      controller.close();
    }
    _roomTimers.clear();
    _roomStreams.clear();
  }
}
