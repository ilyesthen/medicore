import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../auth/presentation/auth_provider.dart';
import 'rooms_provider.dart';
import '../../../core/types/proto_types.dart';

/// Full-screen room selection before entering dashboard
class RoomSelectionScreen extends ConsumerStatefulWidget {
  const RoomSelectionScreen({super.key});

  @override
  ConsumerState<RoomSelectionScreen> createState() => _RoomSelectionScreenState();
}

class _RoomSelectionScreenState extends ConsumerState<RoomSelectionScreen> {
  Room? _selectedRoom;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final rooms = ref.watch(roomsListProvider);

    return Scaffold(
      backgroundColor: MediCoreColors.canvasGrey,
      body: Center(
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 700),
          decoration: BoxDecoration(
            color: MediCoreColors.paperWhite,
            border: Border.all(
              color: MediCoreColors.steelOutline,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: MediCoreColors.deepNavy,
                  border: Border(
                    bottom: BorderSide(
                      color: MediCoreColors.steelOutline,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sélection de salle',
                                style: MediCoreTypography.pageTitle.copyWith(
                                  color: Colors.white,
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${authState.user?.name ?? ''} - ${authState.user?.role ?? ''}',
                                style: MediCoreTypography.label.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Content
              Flexible(
                child: rooms.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.all(60),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.meeting_room_outlined,
                              size: 80,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Aucune salle disponible',
                              style: MediCoreTypography.sectionHeader.copyWith(
                                color: Colors.grey[600],
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Contactez l\'administrateur pour créer des salles',
                              style: MediCoreTypography.body.copyWith(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: MediCoreColors.professionalBlue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: MediCoreColors.professionalBlue,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    size: 20,
                                    color: MediCoreColors.professionalBlue,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Choisissez la salle dans laquelle vous allez travailler',
                                      style: MediCoreTypography.body.copyWith(
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Room cards
                            ...rooms.map((room) {
                              final isSelected = _selectedRoom?.id == room.id;
                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _selectedRoom = room;
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(20),
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
                                              : Colors.grey[400],
                                          size: 28,
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            room.name,
                                            style: MediCoreTypography.sectionHeader.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? MediCoreColors.deepNavy
                                                  : Colors.black87,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        if (isSelected)
                                          const Icon(
                                            Icons.check_circle,
                                            color: MediCoreColors.healthyGreen,
                                            size: 24,
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
                  padding: const EdgeInsets.all(24),
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
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _selectedRoom == null
                          ? null
                          : () {
                              ref.read(authStateProvider.notifier).setRoom(_selectedRoom!);
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
                          fontSize: 15,
                          letterSpacing: 0.5,
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
