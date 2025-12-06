import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../rooms/presentation/rooms_provider.dart';
import 'messages_provider.dart';

/// Send message dialog with templates sidebar
class SendMessageDialog extends ConsumerStatefulWidget {
  final String? preSelectedRoomId; // For doctors (fixed room)
  final List<String>? availableRoomIds; // For nurses (choose from their 3 rooms)
  
  // Optional: For messages sent from consultation page (legacy params for backward compat)
  final String? roomId;
  final String? senderId;
  final String? senderName;
  final String? senderRole;
  
  // Patient info (only when sent from consultation page)
  final int? patientCode;
  final String? patientName;

  const SendMessageDialog({
    super.key,
    this.preSelectedRoomId,
    this.availableRoomIds,
    this.roomId,
    this.senderId,
    this.senderName,
    this.senderRole,
    this.patientCode,
    this.patientName,
  });

  @override
  ConsumerState<SendMessageDialog> createState() => _SendMessageDialogState();
}

class _SendMessageDialogState extends ConsumerState<SendMessageDialog> {
  final _messageController = TextEditingController();
  String? _selectedRoomId;
  Room? _selectedRoom;

  @override
  void initState() {
    super.initState();
    // Support both preSelectedRoomId and roomId params
    _selectedRoomId = widget.preSelectedRoomId ?? widget.roomId;
    if (_selectedRoomId != null) {
      _loadRoomInfo();
    }
  }

  Future<void> _loadRoomInfo() async {
    if (_selectedRoomId != null) {
      final rooms = ref.read(roomsListProvider);
      final room = rooms.cast<Room?>().firstWhere(
        (r) => r?.id == _selectedRoomId,
        orElse: () => null,
      );
      if (room != null && mounted) {
        setState(() => _selectedRoom = room);
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _addTemplate(String template) {
    final currentText = _messageController.text;
    if (currentText.isEmpty) {
      _messageController.text = template;
    } else {
      _messageController.text = '$currentText\n$template';
    }
    // Move cursor to end
    _messageController.selection = TextSelection.fromPosition(
      TextPosition(offset: _messageController.text.length),
    );
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le message ne peut pas être vide')),
      );
      return;
    }

    if (_selectedRoomId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner une salle')),
      );
      return;
    }

    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    final user = authState.user!;
    // Check for both nurse variants (male/female)
    final isNurse = user.role == 'Infirmière' || user.role == 'Infirmier';
    final direction = isNurse ? 'to_doctor' : 'to_nurse';

    // Debug logging
    print('📧 SENDING MESSAGE:');
    print('   Room ID: $_selectedRoomId');
    print('   Sender: ${user.name} (${user.role})');
    print('   Direction: $direction');
    print('   Content: ${_messageController.text.trim()}');
    if (widget.patientName != null) {
      print('   Patient: ${widget.patientName} (code: ${widget.patientCode})');
    }

    try {
      final message = await ref.read(messagesRepositoryProvider).sendMessage(
        roomId: _selectedRoomId!,
        senderId: user.id,
        senderName: user.name,
        senderRole: user.role,
        content: _messageController.text.trim(),
        direction: direction,
        patientCode: widget.patientCode,
        patientName: widget.patientName,
      );

      print('✅ MESSAGE SENT SUCCESSFULLY:');
      print('   Message ID: ${message.id}');
      print('   Room: ${message.roomId}');
      print('   Direction: ${message.direction}');

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Message envoyé avec succès')),
        );
      }
    } catch (e) {
      print('❌ ERROR SENDING MESSAGE: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final templatesAsync = ref.watch(messageTemplatesListProvider);

    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: 900,
        height: 600,
        child: Row(
          children: [
            // Left side - Message composition
            Expanded(
              flex: 3,
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
                          Icons.send,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'ENVOYER UN MESSAGE',
                          style: MediCoreTypography.pageTitle.copyWith(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Room selector (for nurses only)
                  if (widget.availableRoomIds != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: MediCoreColors.steelOutline,
                            width: 1,
                          ),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Salle de destination:',
                            style: MediCoreTypography.sectionHeader.copyWith(
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _RoomSelector(
                            availableRoomIds: widget.availableRoomIds!,
                            selectedRoomId: _selectedRoomId,
                            onRoomSelected: (roomId, room) {
                              setState(() {
                                _selectedRoomId = roomId;
                                _selectedRoom = room;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else if (_selectedRoom != null) ...[
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: MediCoreColors.professionalBlue.withOpacity(0.1),
                        border: const Border(
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
                            color: MediCoreColors.professionalBlue,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Salle: ${_selectedRoom!.name}',
                            style: MediCoreTypography.sectionHeader.copyWith(
                              fontSize: 14,
                              color: MediCoreColors.professionalBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Message text area
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: TextField(
                        controller: _messageController,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        style: MediCoreTypography.body.copyWith(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Tapez votre message ici ou cliquez sur un modèle à droite...',
                          hintStyle: MediCoreTypography.body.copyWith(
                            color: Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MediCoreColors.steelOutline,
                              width: 2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(
                              color: MediCoreColors.professionalBlue,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'ANNULER',
                            style: MediCoreTypography.button.copyWith(
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send, size: 18),
                          label: const Text('ENVOYER'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: MediCoreColors.professionalBlue,
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

            // Right side - Templates
            Container(
              width: 300,
              decoration: const BoxDecoration(
                color: MediCoreColors.canvasGrey,
                border: Border(
                  left: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Templates header
                  Container(
                    padding: const EdgeInsets.all(16),
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
                        const Text(
                          '📋',
                          style: TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Modèles de messages',
                          style: MediCoreTypography.sectionHeader.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Templates list
                  Expanded(
                    child: templatesAsync.when(
                      data: (templates) => ListView.builder(
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _TemplateItem(
                            template: template,
                            onTap: () => _addTemplate(template.content),
                          );
                        },
                      ),
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (error, stack) => Center(
                        child: Text('Erreur: $error'),
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
}

/// Room selector for nurses
class _RoomSelector extends ConsumerWidget {
  final List<String> availableRoomIds;
  final String? selectedRoomId;
  final Function(String, Room) onRoomSelected;

  const _RoomSelector({
    required this.availableRoomIds,
    required this.selectedRoomId,
    required this.onRoomSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allRooms = ref.watch(roomsListProvider);
    final availableRooms = allRooms
        .where((room) => availableRoomIds.contains(room.id))
        .toList();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: availableRooms.map((room) {
        final isSelected = selectedRoomId == room.id;
        return InkWell(
          onTap: () => onRoomSelected(room.id, room),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? MediCoreColors.professionalBlue
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? MediCoreColors.professionalBlue
                    : MediCoreColors.steelOutline,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.meeting_room,
                  size: 16,
                  color: isSelected ? Colors.white : MediCoreColors.deepNavy,
                ),
                const SizedBox(width: 8),
                Text(
                  room.name,
                  style: MediCoreTypography.button.copyWith(
                    fontSize: 12,
                    color: isSelected ? Colors.white : MediCoreColors.deepNavy,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Template item widget
class _TemplateItem extends StatelessWidget {
  final MessageTemplate template;
  final VoidCallback onTap;

  const _TemplateItem({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
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
              Icons.add_circle_outline,
              color: MediCoreColors.professionalBlue,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                template.content,
                style: MediCoreTypography.body.copyWith(
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
