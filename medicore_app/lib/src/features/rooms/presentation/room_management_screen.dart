import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_pane.dart';
import '../../../core/ui/cockpit_button.dart';
import '../../../core/ui/data_grid.dart';
import 'rooms_provider.dart';
import 'room_form_dialog.dart';
import '../../../core/types/proto_types.dart';

/// Room management screen with CRUD operations
class RoomManagementScreen extends ConsumerWidget {
  const RoomManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rooms = ref.watch(roomsListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CockpitPane(
        title: 'Gestion des Salles',
        actions: [
          CockpitButton(
            label: 'CRÉER SALLE',
            icon: Icons.add_location_alt,
            onPressed: () {
              _showRoomDialog(context, ref, null);
            },
          ),
        ],
        child: rooms.isEmpty
            ? Center(
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
                      'Aucune salle créée',
                      style: MediCoreTypography.sectionHeader.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cliquez sur "CRÉER SALLE" pour commencer',
                      style: MediCoreTypography.body.copyWith(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 550,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: MediCoreColors.canvasGrey,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: MediCoreColors.steelOutline,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.info_outline,
                                size: 20,
                                color: MediCoreColors.professionalBlue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'À propos des salles',
                                style: MediCoreTypography.sectionHeader.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Les salles sont le cœur du système MediCore.\n\n'
                            'Utilisations :\n'
                            '• Organisation des médecins et assistants\n'
                            '• Routage des patients entre les salles\n'
                            '• Gestion des messages en temps réel sur LAN\n'
                            '• Coordination des soins médicaux\n\n'
                            'Les utilisateurs (Médecin, Assistant 1, Assistant 2) devront choisir une salle à chaque connexion.',
                            style: MediCoreTypography.body.copyWith(
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MediCoreColors.professionalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MediCoreColors.professionalBlue.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.meeting_room,
                          color: MediCoreColors.professionalBlue,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              rooms.length.toString(),
                              style: MediCoreTypography.pageTitle.copyWith(
                                color: MediCoreColors.professionalBlue,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              'Salles actives',
                              style: MediCoreTypography.label.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Rooms data grid
                  Expanded(
                    child: DataGrid(
                      headers: const [
                        'NOM DE LA SALLE',
                        'CRÉÉ LE',
                        'ACTIONS',
                      ],
                      rows: rooms.map((room) {
                        return [
                          room.name,
                          'N/A', // room.createdAt not available in GrpcRoom
                          '', // Actions handled separately
                        ];
                      }).toList(),
                      onRowTap: (index) {
                        _showRoomDialog(context, ref, rooms[index]);
                      },
                      customCellBuilder: (rowIndex, columnIndex, value) {
                        if (columnIndex == 2) {
                          // Actions column
                          final room = rooms[rowIndex];
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: MediCoreColors.professionalBlue,
                                ),
                                tooltip: 'Modifier',
                                onPressed: () {
                                  _showRoomDialog(context, ref, room);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  size: 18,
                                  color: MediCoreColors.criticalRed,
                                ),
                                tooltip: 'Supprimer',
                                onPressed: () {
                                  _confirmDelete(context, ref, room);
                                },
                              ),
                            ],
                          );
                        }
                        
                        return null;
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showRoomDialog(BuildContext context, WidgetRef ref, Room? room) {
    showDialog(
      context: context,
      builder: (context) => RoomFormDialog(room: room),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Room room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MediCoreColors.paperWhite,
        title: Text(
          'Confirmer la suppression',
          style: MediCoreTypography.sectionHeader.copyWith(
            color: MediCoreColors.deepNavy,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer la salle "${room.name}" ?\n\nCette action est irréversible.',
          style: MediCoreTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Annuler',
              style: MediCoreTypography.button.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(roomsListProvider.notifier).deleteRoom(room.id.toString());
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Salle supprimée: ${room.name}'),
                      backgroundColor: MediCoreColors.healthyGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: MediCoreColors.criticalRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MediCoreColors.criticalRed,
            ),
            child: Text(
              'Supprimer',
              style: MediCoreTypography.button.copyWith(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
