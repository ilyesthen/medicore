import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import 'realtime_sync_service.dart';

/// Remote Messages Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only - now with SSE-powered instant updates!
class RemoteMessagesRepository {
  final MediCoreClient _client;
  
  // Active streams for real-time updates
  final Map<String, StreamController<List<Message>>> _roomStreams = {};
  final Map<String, Timer> _roomTimers = {};
  
  // SSE callback for instant refresh
  void Function(String? roomId)? _sseRefreshCallback;
  
  RemoteMessagesRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance {
    // Register for SSE message events for instant updates
    _sseRefreshCallback = (roomId) => _forceRefreshAllStreams(roomId);
    RealtimeSyncService.instance.onMessageRefresh(_sseRefreshCallback!);
  }

  /// Force refresh all active message streams (called by SSE)
  void _forceRefreshAllStreams(String? targetRoomId) {
    print('🔄 [RemoteMessages] SSE triggered instant refresh for room: $targetRoomId');
    
    for (final key in _roomStreams.keys.toList()) {
      // Check if this stream is relevant to the target room
      if (targetRoomId == null || key.contains(targetRoomId)) {
        _refreshStreamByKey(key);
      }
    }
  }

  /// Refresh a specific stream by its key
  void _refreshStreamByKey(String key) {
    if (key.startsWith('nurse_')) {
      final roomIdsStr = key.substring('nurse_'.length);
      final roomIds = roomIdsStr.split('_');
      _fetchNurseMessages(key, roomIds);
    } else if (key.startsWith('doctor_')) {
      final roomId = key.substring('doctor_'.length);
      _fetchDoctorMessages(key, roomId);
    } else if (key.startsWith('all_')) {
      final roomId = key.substring('all_'.length);
      _fetchAllMessages(key, roomId);
    }
  }

  Future<void> _fetchNurseMessages(String key, List<String> roomIds) async {
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
      print('❌ [RemoteMessages] refresh failed: $e');
    }
  }

  Future<void> _fetchDoctorMessages(String key, String roomId) async {
    try {
      final response = await _client.getMessagesByRoom(roomId);
      final unread = response.messages
        .where((m) => m.direction == 'to_doctor' && !m.isRead)
        .map(_grpcMessageToLocal)
        .toList();
      _roomStreams[key]?.add(unread);
    } catch (e) {
      print('❌ [RemoteMessages] refresh failed: $e');
    }
  }

  Future<void> _fetchAllMessages(String key, String roomId) async {
    try {
      final response = await _client.getMessagesByRoom(roomId);
      _roomStreams[key]?.add(response.messages.map(_grpcMessageToLocal).toList());
    } catch (e) {
      print('❌ [RemoteMessages] refresh failed: $e');
    }
  }

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
      
      // Fallback poll every 5 seconds (SSE handles real-time updates)
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages());
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
      
      // Fallback poll every 5 seconds (SSE handles real-time updates)
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages());
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
      
      // Fallback poll every 5 seconds (SSE handles real-time updates)
      _roomTimers[key] = Timer.periodic(const Duration(seconds: 5), (_) => fetchMessages());
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
    // Force immediate refresh (don't wait for SSE)
    _forceRefreshAllStreams(null);
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
    // Force immediate refresh of all nurse streams (don't wait for SSE)
    _forceRefreshAllStreams(null);
  }

  /// Mark all messages as read for doctor (single room, to_doctor direction)
  Future<void> markAllAsReadForDoctor(String roomId) async {
    try {
      await _client.markAllMessagesAsRead(roomId, 'to_doctor');
    } catch (e) {
      print('❌ [RemoteMessages] markAllAsReadForDoctor failed: $e');
    }
    // Force immediate refresh (don't wait for SSE)
    _forceRefreshAllStreams(roomId);
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
    // Unregister SSE callback
    if (_sseRefreshCallback != null) {
      RealtimeSyncService.instance.removeMessageRefresh(_sseRefreshCallback!);
    }
    
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
