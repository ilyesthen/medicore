import 'dart:async';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';
import '../../../core/api/realtime_sync_service.dart';

/// Repository for message operations
class MessagesRepository {
  final AppDatabase _db;
  
  // Remote polling streams cache
  final Map<String, StreamController<List<Message>>> _remoteStreams = {};
  final Map<String, Timer> _remoteTimers = {};

  MessagesRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();
  
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
  
  /// Dispose remote streams
  void dispose() {
    for (final timer in _remoteTimers.values) {
      timer.cancel();
    }
    for (final controller in _remoteStreams.values) {
      controller.close();
    }
    _remoteTimers.clear();
    _remoteStreams.clear();
  }

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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
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
        final id = await MediCoreClient.instance.createMessage(request);
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
        print('❌ [MessagesRepository] Remote sendMessage failed: $e');
        rethrow;
      }
    }
    
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getMessageById(id);
        if (response.isEmpty) return null;
        
        // Parse JSON response to Message
        return Message(
          id: response['id'] as int,
          roomId: response['room_id'] as String? ?? '',
          senderId: response['sender_id'] as String? ?? '',
          senderName: response['sender_name'] as String? ?? '',
          senderRole: response['sender_role'] as String? ?? '',
          content: response['content'] as String? ?? '',
          direction: response['direction'] as String? ?? '',
          isRead: response['is_read'] as bool? ?? false,
          sentAt: DateTime.tryParse(response['sent_at'] as String? ?? '') ?? DateTime.now(),
          readAt: null,
          patientCode: response['patient_code'] as int?,
          patientName: response['patient_name'] as String?,
        );
      } catch (e) {
        print('❌ [MessagesRepository] Remote getMessage failed: $e');
        return null;
      }
    }
    
    return await (_db.select(_db.messages)
          ..where((m) => m.id.equals(id)))
        .getSingleOrNull();
  }

  /// Get unread messages for a nurse (for specific rooms)
  /// Uses polling for both client AND server mode to detect changes from Go server
  Stream<List<Message>> watchUnreadMessagesForNurse(List<String> roomIds) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return _watchMessagesRemote('nurse_${roomIds.join('_')}', roomIds, 'to_nurse');
    }
    
    // Server/Admin mode: use local DB with polling to detect Go server changes
    return _watchMessagesLocalWithPolling('nurse_${roomIds.join('_')}', roomIds, 'to_nurse');
  }
  
  /// Local stream with polling to detect changes from Go server
  Stream<List<Message>> _watchMessagesLocalWithPolling(String key, List<String> roomIds, String direction) {
    if (!_remoteStreams.containsKey(key)) {
      _remoteStreams[key] = StreamController<List<Message>>.broadcast();
      
      Future<void> fetchMessages() async {
        try {
          final messages = await (_db.select(_db.messages)
                ..where((m) => 
                    m.direction.equals(direction) & 
                    m.isRead.equals(false) &
                    m.roomId.isIn(roomIds))
                ..orderBy([(m) => OrderingTerm.desc(m.sentAt)]))
              .get();
          _remoteStreams[key]?.add(messages);
        } catch (e) {
          print('❌ [MessagesRepository] Local poll failed: $e');
          _remoteStreams[key]?.add([]);
        }
      }
      
      // Immediate fetch
      fetchMessages();
      
      // Poll every 2 seconds to detect Go server changes quickly
      _remoteTimers[key] = Timer.periodic(const Duration(seconds: 2), (_) => fetchMessages());
    }
    
    return _remoteStreams[key]!.stream;
  }
  
  /// Remote stream for messages with SSE support
  Stream<List<Message>> _watchMessagesRemote(String key, List<String> roomIds, String direction) {
    if (!_remoteStreams.containsKey(key)) {
      _remoteStreams[key] = StreamController<List<Message>>.broadcast();
      
      Future<void> fetchMessages() async {
        try {
          final allMessages = <Message>[];
          for (final roomId in roomIds) {
            final response = await MediCoreClient.instance.getMessagesByRoom(roomId);
            allMessages.addAll(
              response.messages
                .where((m) => m.direction == direction && !m.isRead)
                .map(_grpcMessageToLocal)
            );
          }
          _remoteStreams[key]?.add(allMessages);
        } catch (e) {
          print('❌ [MessagesRepository] Remote poll failed: $e');
          _remoteStreams[key]?.add([]);
        }
      }
      
      // Register SSE callback for instant refresh
      void sseCallback(String? roomId) {
        if (roomId == null || roomIds.contains(roomId)) {
          fetchMessages();
        }
      }
      RealtimeSyncService.instance.onMessageRefresh(sseCallback);
      
      // Immediate fetch
      fetchMessages();
      
      // Fallback poll every 10 seconds (SSE handles real-time)
      _remoteTimers[key] = Timer.periodic(const Duration(seconds: 10), (_) => fetchMessages());
    }
    
    return _remoteStreams[key]!.stream;
  }

  /// Get unread messages for a doctor (for specific room)
  /// Uses polling for both client AND server mode to detect changes from Go server
  Stream<List<Message>> watchUnreadMessagesForDoctor(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      return _watchMessagesRemote('doctor_$roomId', [roomId], 'to_doctor');
    }
    
    // Server/Admin mode: use local DB with polling to detect Go server changes
    return _watchMessagesLocalWithPolling('doctor_$roomId', [roomId], 'to_doctor');
  }

  /// Get all messages for a room (for viewing history)
  /// Uses polling for both modes to detect Go server changes
  Stream<List<Message>> watchMessagesForRoom(String roomId) {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      final key = 'all_$roomId';
      if (!_remoteStreams.containsKey(key)) {
        _remoteStreams[key] = StreamController<List<Message>>.broadcast();
        
        Future<void> fetchMessages() async {
          try {
            final response = await MediCoreClient.instance.getMessagesByRoom(roomId);
            _remoteStreams[key]?.add(response.messages.map(_grpcMessageToLocal).toList());
          } catch (e) {
            print('❌ [MessagesRepository] Remote poll failed: $e');
            _remoteStreams[key]?.add([]);
          }
        }
        
        fetchMessages();
        _remoteTimers[key] = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
      }
      return _remoteStreams[key]!.stream;
    }
    
    // Server/Admin mode: use local DB with polling to detect Go server changes
    final key = 'all_local_$roomId';
    if (!_remoteStreams.containsKey(key)) {
      _remoteStreams[key] = StreamController<List<Message>>.broadcast();
      
      Future<void> fetchMessages() async {
        try {
          final messages = await (_db.select(_db.messages)
                ..where((m) => m.roomId.equals(roomId))
                ..orderBy([(m) => OrderingTerm.desc(m.sentAt)]))
              .get();
          _remoteStreams[key]?.add(messages);
        } catch (e) {
          print('❌ [MessagesRepository] Local poll failed: $e');
          _remoteStreams[key]?.add([]);
        }
      }
      
      fetchMessages();
      _remoteTimers[key] = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
    }
    return _remoteStreams[key]!.stream;
  }

  /// Delete message when read (no history kept)
  Future<void> markAsRead(int messageId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.markMessageAsRead(messageId);
        return;
      } catch (e) {
        print('❌ [MessagesRepository] Remote markAsRead failed: $e');
        rethrow;
      }
    }
    
    await deleteMessage(messageId);
  }

  /// Delete all messages for a nurse (for specific rooms) - no history
  Future<void> markAllAsReadForNurse(List<String> roomIds) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        for (final roomId in roomIds) {
          await MediCoreClient.instance.markAllMessagesAsRead(roomId, 'to_nurse');
        }
        return;
      } catch (e) {
        print('❌ [MessagesRepository] Remote markAllAsReadForNurse failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.messages)
          ..where((m) => 
              m.direction.equals('to_nurse') & 
              m.roomId.isIn(roomIds)))
        .go();
  }

  /// Delete all messages for a doctor (for specific room) - no history
  Future<void> markAllAsReadForDoctor(String roomId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.markAllMessagesAsRead(roomId, 'to_doctor');
        return;
      } catch (e) {
        print('❌ [MessagesRepository] Remote markAllAsReadForDoctor failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.messages)
          ..where((m) => 
              m.direction.equals('to_doctor') & 
              m.roomId.equals(roomId)))
        .go();
  }

  /// Get unread count for nurse
  Future<int> getUnreadCountForNurse(List<String> roomIds) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        int count = 0;
        for (final roomId in roomIds) {
          final response = await MediCoreClient.instance.getMessagesByRoom(roomId);
          count += response.messages.where((m) => m.direction == 'to_nurse' && !m.isRead).length;
        }
        return count;
      } catch (e) {
        print('❌ [MessagesRepository] Remote getUnreadCountForNurse failed: $e');
        return 0;
      }
    }
    
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getMessagesByRoom(roomId);
        return response.messages.where((m) => m.direction == 'to_doctor' && !m.isRead).length;
      } catch (e) {
        print('❌ [MessagesRepository] Remote getUnreadCountForDoctor failed: $e');
        return 0;
      }
    }
    
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deleteMessage(id);
        return;
      } catch (e) {
        print('❌ [MessagesRepository] Remote deleteMessage failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.messages)
          ..where((m) => m.id.equals(id)))
        .go();
  }
}
