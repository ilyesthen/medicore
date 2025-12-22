import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/remote_messages_repository.dart';
import '../../../core/types/proto_types.dart';

/// Abstract interface for message operations
abstract class IRemoteMessagesRepository {
  Future<Message> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    required String direction,
    int? patientCode,
    String? patientName,
  });
  Stream<List<Message>> watchUnreadMessagesForNurse(List<String> roomIds);
  Stream<List<Message>> watchUnreadMessagesForDoctor(String roomId);
  Stream<List<Message>> watchMessagesForRoom(String roomId);
  Future<void> markAsRead(int messageId);
  Future<void> markAllAsReadForNurse(List<String> roomIds);
  Future<void> markAllAsReadForDoctor(String roomId);
  Future<int> getUnreadCountForNurse(List<String> roomIds);
  Future<int> getUnreadCountForDoctor(String roomId);
  Future<void> deleteMessage(int id);
}

/// Local messages adapter
class LocalMessagesAdapter implements IRemoteMessagesRepository {
  final RemoteMessagesRepository _local;
  LocalMessagesAdapter(this._local);
  
  @override
  Future<Message> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    required String direction,
    int? patientCode,
    String? patientName,
  }) => _local.sendMessage(
    roomId: roomId,
    senderId: senderId,
    senderName: senderName,
    senderRole: senderRole,
    content: content,
    direction: direction,
    patientCode: patientCode,
    patientName: patientName,
  );
  
  @override
  Stream<List<Message>> watchUnreadMessagesForNurse(List<String> roomIds) => 
    _local.watchUnreadMessagesForNurse(roomIds);
  
  @override
  Stream<List<Message>> watchUnreadMessagesForDoctor(String roomId) => 
    _local.watchUnreadMessagesForDoctor(roomId);
  
  @override
  Stream<List<Message>> watchMessagesForRoom(String roomId) => 
    _local.watchMessagesForRoom(roomId);
  
  @override
  Future<void> markAsRead(int messageId) => _local.markAsRead(messageId);
  
  @override
  Future<void> markAllAsReadForNurse(List<String> roomIds) => 
    _local.markAllAsReadForNurse(roomIds);
  
  @override
  Future<void> markAllAsReadForDoctor(String roomId) => 
    _local.markAllAsReadForDoctor(roomId);
  
  @override
  Future<int> getUnreadCountForNurse(List<String> roomIds) => 
    _local.getUnreadCountForNurse(roomIds);
  
  @override
  Future<int> getUnreadCountForDoctor(String roomId) => 
    _local.getUnreadCountForDoctor(roomId);
  
  @override
  Future<void> deleteMessage(int id) => _local.deleteMessage(id);
}

/// Remote messages adapter
class RemoteMessagesAdapter implements IRemoteMessagesRepository {
  final RemoteMessagesRepository _remote;
  RemoteMessagesAdapter(this._remote);
  
  @override
  Future<Message> sendMessage({
    required String roomId,
    required String senderId,
    required String senderName,
    required String senderRole,
    required String content,
    required String direction,
    int? patientCode,
    String? patientName,
  }) => _remote.sendMessage(
    roomId: roomId,
    senderId: senderId,
    senderName: senderName,
    senderRole: senderRole,
    content: content,
    direction: direction,
    patientCode: patientCode,
    patientName: patientName,
  );
  
  @override
  Stream<List<Message>> watchUnreadMessagesForNurse(List<String> roomIds) => 
    _remote.watchUnreadMessagesForNurse(roomIds);
  
  @override
  Stream<List<Message>> watchUnreadMessagesForDoctor(String roomId) => 
    _remote.watchUnreadMessagesForDoctor(roomId);
  
  @override
  Stream<List<Message>> watchMessagesForRoom(String roomId) => 
    _remote.watchMessagesForRoom(roomId);
  
  @override
  Future<void> markAsRead(int messageId) => _remote.markAsRead(messageId);
  
  @override
  Future<void> markAllAsReadForNurse(List<String> roomIds) => 
    _remote.markAllAsReadForNurse(roomIds);
  
  @override
  Future<void> markAllAsReadForDoctor(String roomId) => 
    _remote.markAllAsReadForDoctor(roomId);
  
  @override
  Future<int> getUnreadCountForNurse(List<String> roomIds) => 
    _remote.getUnreadCountForNurse(roomIds);
  
  @override
  Future<int> getUnreadCountForDoctor(String roomId) => 
    _remote.getUnreadCountForDoctor(roomId);
  
  @override
  Future<void> deleteMessage(int id) => _remote.deleteMessage(id);
}

// Singleton instances to prevent multiple SSE registrations
RemoteMessagesRepository? _remoteMessagesRepo;
RemoteMessagesRepository? _localMessagesRepo;

/// Messages repository provider - switches between local and remote
final messagesRepositoryProvider = Provider<IRemoteMessagesRepository>((ref) {
  if (GrpcClientConfig.isServer) {
    print('✓ [RemoteMessagesRepository] Using LOCAL database (Admin mode)');
    _localMessagesRepo ??= RemoteMessagesRepository();
    return LocalMessagesAdapter(_localMessagesRepo!);
  } else {
    print('✓ [RemoteMessagesRepository] Using REMOTE API (Client mode)');
    _remoteMessagesRepo ??= RemoteMessagesRepository();
    return RemoteMessagesAdapter(_remoteMessagesRepo!);
  }
});

/// Message templates repository provider (stub - templates not yet implemented)
/// All message templates stream provider
final messageTemplatesListProvider = StreamProvider<List<MessageTemplate>>((ref) {
  // Return empty stream for now - templates feature not yet implemented  
  return Stream.value([]);
});

/// Audio player for notifications
final audioPlayerProvider = Provider<AudioPlayer>((ref) {
  final player = AudioPlayer();
  return player;
});

/// Unread count provider for nurse (based on their rooms)
final nurseUnreadCountProvider = StreamProvider.family<int, List<String>>((ref, roomIds) async* {
  final repository = ref.watch(messagesRepositoryProvider);
  
  print('👩‍⚕️ NURSE watching unread messages for rooms: $roomIds');
  
  await for (final messages in repository.watchUnreadMessagesForNurse(roomIds)) {
    print('📬 NURSE received ${messages.length} unread messages for rooms $roomIds');
    if (messages.isNotEmpty) {
      for (final msg in messages) {
        print('   - Message ID: ${msg.id}, From: ${msg.senderName}, Direction: ${msg.direction}');
      }
    }
    yield messages.length;
  }
});

/// Unread count provider for doctor (based on their room)
final doctorUnreadCountProvider = StreamProvider.family<int, String>((ref, roomId) async* {
  final repository = ref.watch(messagesRepositoryProvider);
  
  print('👨‍⚕️ DOCTOR watching unread messages for room: $roomId');
  
  await for (final messages in repository.watchUnreadMessagesForDoctor(roomId)) {
    print('📬 DOCTOR received ${messages.length} unread messages for room $roomId');
    if (messages.isNotEmpty) {
      for (final msg in messages) {
        print('   - Message ID: ${msg.id}, From: ${msg.senderName}, Direction: ${msg.direction}');
      }
    }
    yield messages.length;
  }
});

/// Unread messages for nurse
final nurseUnreadMessagesProvider = StreamProvider.family<List<Message>, List<String>>((ref, roomIds) {
  final repository = ref.watch(messagesRepositoryProvider);
  return repository.watchUnreadMessagesForNurse(roomIds);
});

/// Unread messages for doctor
final doctorUnreadMessagesProvider = StreamProvider.family<List<Message>, String>((ref, roomId) {
  final repository = ref.watch(messagesRepositoryProvider);
  return repository.watchUnreadMessagesForDoctor(roomId);
});
