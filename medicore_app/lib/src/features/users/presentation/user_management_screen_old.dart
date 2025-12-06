import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_pane.dart';
import '../../../core/ui/cockpit_button.dart';
import '../../../core/ui/data_grid.dart';
import 'users_provider.dart';
import '../data/models/user_model.dart';
import '../data/models/template_model.dart';
import 'user_form_dialog.dart';
import 'template_form_dialog.dart';

/// User and template management screen with CRUD operations
class UserManagementScreen extends ConsumerWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersListProvider);
    final templates = ref.watch(templatesListProvider);
    
    // Filter out admin from the list
    final regularUsers = users.where((u) => u.id != 'admin').toList();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CockpitPane(
        title: 'Gestion des Utilisateurs et Modèles',
        actions: [
          CockpitButton(
            label: 'CRÉER MODÈLE',
            icon: Icons.add_box,
            onPressed: () {
              _showTemplateDialog(context, ref, null);
            },
          ),
          const SizedBox(width: 12),
          CockpitButton(
            label: 'CRÉER UTILISATEUR',
            icon: Icons.person_add,
            onPressed: () {
              _showUserDialog(context, ref, null);
            },
          ),
        ],
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stats
                  Row(
                    children: [
                      _buildStatCard(
                        'Total',
                        regularUsers.length.toString(),
                        Icons.people,
                        MediCoreColors.professionalBlue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Depuis Modèles',
                        regularUsers.where((u) => u.isTemplateUser).length.toString(),
                        Icons.folder_special,
                        MediCoreColors.warningOrange,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        'Permanents',
                        regularUsers.where((u) => !u.isTemplateUser).length.toString(),
                        Icons.verified_user,
                        MediCoreColors.healthyGreen,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Users data grid
                  Expanded(
                    child: DataGrid(
                      headers: const [
                        'NOM',
                        'RÔLE',
                        'TYPE',
                        'POURCENTAGE',
                        'CRÉÉ LE',
                        'ACTIONS',
                      ],
                      rows: regularUsers.map((user) {
                        return [
                          user.name,
                          user.role,
                          user.isTemplateUser ? 'Modèle' : 'Permanent',
                          user.percentage != null
                              ? '${user.percentage!.toStringAsFixed(0)}%'
                              : '—',
                          _formatDate(user.createdAt),
                          '', // Actions handled separately
                        ];
                      }).toList(),
                      onRowTap: (index) {
                        _showUserDialog(context, ref, regularUsers[index]);
                      },
                      customCellBuilder: (rowIndex, columnIndex, value) {
                        if (columnIndex == 5) {
                          // Actions column
                          final user = regularUsers[rowIndex];
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
                                  _showUserDialog(context, ref, user);
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
                                  _confirmDeleteUser(context, ref, user);
                                },
                              ),
                            ],
                          );
                        }
                        
                        // Percentage column with color
                        if (columnIndex == 3 && value != '—') {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: MediCoreColors.warningOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              value,
                              style: MediCoreTypography.dataCell.copyWith(
                                color: MediCoreColors.warningOrange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }
                        
                        // Type column with color
                        if (columnIndex == 2) {
                          final isTemplate = value == 'Modèle';
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: (isTemplate
                                      ? MediCoreColors.warningOrange
                                      : MediCoreColors.healthyGreen)
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              value,
                              style: MediCoreTypography.dataCell.copyWith(
                                color: isTemplate
                                    ? MediCoreColors.warningOrange
                                    : MediCoreColors.healthyGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
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

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: MediCoreTypography.pageTitle.copyWith(
                    color: color,
                    fontSize: 24,
                  ),
                ),
                Text(
                  label,
                  style: MediCoreTypography.label.copyWith(
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, User? user) {
    showDialog(
      context: context,
      builder: (context) => UserFormDialog(user: user),
    );
  }

  void _confirmDeleteUser(BuildContext context, WidgetRef ref, User user) {
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
          'Voulez-vous vraiment supprimer l\'utilisateur "${user.name}" ?',
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
                await ref.read(usersListProvider.notifier).deleteUser(user.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Utilisateur supprimé: ${user.name}'),
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
