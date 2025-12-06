import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart' show Room;
import 'rooms_provider.dart';

/// Dialog for selecting a room on login
class RoomSelectionDialog extends ConsumerStatefulWidget {
  final String userName;
  final String userRole;
  final Function(Room) onRoomSelected;

  const RoomSelectionDialog({
    super.key,
    required this.userName,
    required this.userRole,
    required this.onRoomSelected,
  });

  @override
  ConsumerState<RoomSelectionDialog> createState() => _RoomSelectionDialogState();
}

class _RoomSelectionDialogState extends ConsumerState<RoomSelectionDialog> {
  Room? _selectedRoom;

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(roomsListProvider);

    return WillPopScope(
      onWillPop: () async => false, // Prevent dismissal by back button
      child: AlertDialog(
        backgroundColor: MediCoreColors.paperWhite,
        contentPadding: EdgeInsets.zero,
        content: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 600),
          decoration: BoxDecoration(
            border: Border.all(
              color: MediCoreColors.steelOutline,
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                      Icons.meeting_room,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sélection de salle',
                            style: MediCoreTypography.sectionHeader.copyWith(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.userName} - ${widget.userRole}',
                            style: MediCoreTypography.label.copyWith(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: rooms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune salle disponible',
                              style: MediCoreTypography.sectionHeader.copyWith(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Contactez l\'administrateur pour créer des salles',
                              style: MediCoreTypography.body.copyWith(
                                color: Colors.grey[500],
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: BoxDecoration(
                                color: MediCoreColors.canvasGrey,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 16,
                                    color: MediCoreColors.professionalBlue,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Choisissez la salle dans laquelle vous allez travailler',
                                      style: MediCoreTypography.label.copyWith(
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Room selection cards
                            ...rooms.map((room) {
                              final isSelected = _selectedRoom?.id == room.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRoom = room;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? MediCoreColors.professionalBlue.withOpacity(0.1)
                                          : MediCoreColors.inputBackground,
                                      border: Border.all(
                                        color: isSelected
                                            ? MediCoreColors.professionalBlue
                                            : MediCoreColors.inputBorder,
                                        width: isSelected ? 2 : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          isSelected
                                              ? Icons.radio_button_checked
                                              : Icons.radio_button_unchecked,
                                          color: isSelected
                                              ? MediCoreColors.professionalBlue
                                              : Colors.grey,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            room.name,
                                            style: MediCoreTypography.inputField.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? MediCoreColors.deepNavy
                                                  : Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
              ),
              
              // Actions
              if (rooms.isNotEmpty)
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
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _selectedRoom == null
                          ? null
                          : () {
                              widget.onRoomSelected(_selectedRoom!);
                              Navigator.of(context).pop();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MediCoreColors.professionalBlue,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'CONFIRMER LA SALLE',
                        style: MediCoreTypography.button.copyWith(
                          color: _selectedRoom == null
                              ? Colors.grey[600]
                              : Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
