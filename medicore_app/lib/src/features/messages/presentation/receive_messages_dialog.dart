import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../rooms/presentation/rooms_provider.dart';
import '../services/notification_service.dart';
import 'messages_provider.dart';
import '../../../core/generated/medicore.pb.dart';

/// Receive messages dialog - different UI for nurses vs doctors
class ReceiveMessagesDialog extends ConsumerStatefulWidget {
  final String? doctorRoomId; // For doctors (single room)
  final List<String>? nurseRoomIds; // For nurses (3 rooms)

  const ReceiveMessagesDialog({
    super.key,
    this.doctorRoomId,
    this.nurseRoomIds,
  });

  @override
  ConsumerState<ReceiveMessagesDialog> createState() => _ReceiveMessagesDialogState();
}

class _ReceiveMessagesDialogState extends ConsumerState<ReceiveMessagesDialog> {
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Stop notification sound when dialog opens
    _notificationService.stopNotificationSound();
  }

  @override
  Widget build(BuildContext context) {
    final isNurse = widget.nurseRoomIds != null;

    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: isNurse ? 1000 : 600,
        height: 600,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.inbox,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'MESSAGES REÇUS',
                    style: MediCoreTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: isNurse
                  ? _NurseMessagesView(roomIds: widget.nurseRoomIds!)
                  : _DoctorMessagesView(roomId: widget.doctorRoomId!),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => _markAllAsRead(),
                    icon: const Icon(Icons.done_all),
                    label: const Text('TOUT MARQUER COMME LU'),
                    style: TextButton.styleFrom(
                      foregroundColor: MediCoreColors.healthyGreen,
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('FERMER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MediCoreColors.deepNavy,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _markAllAsRead() async {
    // Stop notification sound immediately
    _notificationService.stopNotificationSound();
    
    final isNurse = widget.nurseRoomIds != null;
    
    if (isNurse) {
      await ref.read(messagesRepositoryProvider)
          .markAllAsReadForNurse(widget.nurseRoomIds!);
    } else {
      await ref.read(messagesRepositoryProvider)
          .markAllAsReadForDoctor(widget.doctorRoomId!);
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }
}

/// Nurse view - 3 room boxes side by side
class _NurseMessagesView extends ConsumerWidget {
  final List<String> roomIds;

  const _NurseMessagesView({required this.roomIds});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRooms = ref.watch(roomsListProvider);
    final messagesAsync = ref.watch(nurseUnreadMessagesProvider(roomIds));

    return messagesAsync.when(
      data: (allMessages) {
        final rooms = allRooms
            .where((room) => roomIds.contains(room.id))
            .toList();

        return Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: rooms.map((room) {
              final roomMessages = allMessages
                  .where((msg) => msg.roomId == room.id)
                  .toList();
              final isLast = room == rooms.last;

              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: isLast ? 0 : 16),
                  child: _RoomMessagesBox(
                    room: room,
                    messages: roomMessages,
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }
}

/// Room messages box for nurse
class _RoomMessagesBox extends StatelessWidget {
  final Room room;
  final List<Message> messages;

  const _RoomMessagesBox({
    required this.room,
    required this.messages,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(
          color: MediCoreColors.steelOutline,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Room header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: MediCoreColors.deepNavy,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.meeting_room,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    room.name.toUpperCase(),
                    style: MediCoreTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: messages.isNotEmpty
                        ? MediCoreColors.criticalRed
                        : MediCoreColors.healthyGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    messages.length.toString(),
                    style: MediCoreTypography.button.copyWith(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Aucun message',
                          style: MediCoreTypography.label.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      return _MessageItem(message: messages[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Doctor view - simple list
class _DoctorMessagesView extends ConsumerWidget {
  final String roomId;

  const _DoctorMessagesView({required this.roomId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(doctorUnreadMessagesProvider(roomId));

    return messagesAsync.when(
      data: (messages) {
        if (messages.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 20),
                Text(
                  'Aucun message',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vous n\'avez pas de nouveaux messages',
                  style: MediCoreTypography.label.copyWith(
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            // Doctor doesn't see patient info
            return _MessageItem(message: messages[index], showPatientInfo: false);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Erreur: $error')),
    );
  }
}

/// Individual message item
class _MessageItem extends StatelessWidget {
  final Message message;
  final bool showPatientInfo; // Only nurses see patient info

  const _MessageItem({
    required this.message,
    this.showPatientInfo = true, // Nurses see it by default
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('HH:mm');
    final hasPatient = message.patientName != null && message.patientName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MediCoreColors.professionalBlue.withOpacity(0.1),
        border: Border.all(
          color: MediCoreColors.professionalBlue.withOpacity(0.3),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender info
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: MediCoreColors.professionalBlue,
              ),
              const SizedBox(width: 6),
              Text(
                message.senderName,
                style: MediCoreTypography.button.copyWith(
                  fontSize: 12,
                  color: MediCoreColors.professionalBlue,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '(${message.senderRole})',
                style: MediCoreTypography.label.copyWith(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Text(
                timeFormat.format(message.sentAt),
                style: MediCoreTypography.label.copyWith(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Message content
          Text(
            message.content,
            style: MediCoreTypography.body.copyWith(
              fontSize: 13,
            ),
          ),
          // Patient info (only for nurse view, when message has linked patient)
          if (showPatientInfo && hasPatient) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: MediCoreColors.healthyGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: MediCoreColors.healthyGreen.withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 14,
                    color: MediCoreColors.healthyGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Patient: ${message.patientName}',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 11,
                      color: MediCoreColors.healthyGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
