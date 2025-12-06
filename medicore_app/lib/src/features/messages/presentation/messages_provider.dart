import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/database/app_database.dart';
import '../data/messages_repository.dart';
import '../data/message_templates_repository.dart';

/// Messages repository provider
final messagesRepositoryProvider = Provider<MessagesRepository>((ref) {
  return MessagesRepository();
});

/// Message templates repository provider
final messageTemplatesRepositoryProvider = Provider<MessageTemplatesRepository>((ref) {
  return MessageTemplatesRepository();
});

/// All message templates stream provider
final messageTemplatesListProvider = StreamProvider<List<MessageTemplate>>((ref) {
  final repository = ref.watch(messageTemplatesRepositoryProvider);
  return repository.watchAllTemplates();
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
