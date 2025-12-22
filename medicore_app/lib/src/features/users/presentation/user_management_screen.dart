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
import '../../../core/types/proto_types.dart';

/// User and template management screen - both in one view
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
                  'Utilisateurs',
                  regularUsers.length.toString(),
                  Icons.people,
                  MediCoreColors.professionalBlue,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Modèles',
                  templates.length.toString(),
                  Icons.folder_special,
                  MediCoreColors.warningOrange,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Depuis Modèles',
                  regularUsers.where((u) => u.isTemplateUser).length.toString(),
                  Icons.verified_user,
                  MediCoreColors.healthyGreen,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Templates section
            Row(
              children: [
                const Icon(
                  Icons.folder_special,
                  size: 18,
                  color: MediCoreColors.deepNavy,
                ),
                const SizedBox(width: 8),
                Text(
                  'MODÈLES (Assistant 1 & 2 uniquement)',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    fontSize: 14,
                    color: MediCoreColors.deepNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              decoration: BoxDecoration(
                border: Border.all(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
                color: Colors.white,
              ),
              child: templates.isEmpty
                  ? Center(
                      child: Text(
                        'Aucun modèle créé',
                        style: MediCoreTypography.body.copyWith(
                          color: Colors.grey[500],
                        ),
                      ),
                    )
                  : DataGrid(
                      headers: const [
                        'RÔLE',
                        'POURCENTAGE',
                        'CRÉÉ LE',
                        'ACTIONS',
                      ],
                      rows: templates.map((template) {
                        return [
                          template.role,
                          '${template.percentage.toStringAsFixed(0)}%',
                          _formatDate(template.createdAt),
                          '',
                        ];
                      }).toList(),
                      onRowTap: (index) {
                        _showTemplateDialog(context, ref, templates[index]);
                      },
                      customCellBuilder: (rowIndex, columnIndex, value) {
                        if (columnIndex == 3) {
                          final template = templates[rowIndex];
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
                                  _showTemplateDialog(context, ref, template);
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
                                  _confirmDeleteTemplate(context, ref, template);
                                },
                              ),
                            ],
                          );
                        }
                        if (columnIndex == 1) {
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
                        return null;
                      },
                    ),
            ),
            
            const SizedBox(height: 24),
            
            // Users section
            Row(
              children: [
                const Icon(
                  Icons.people,
                  size: 18,
                  color: MediCoreColors.deepNavy,
                ),
                const SizedBox(width: 8),
                Text(
                  'UTILISATEURS',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    fontSize: 14,
                    color: MediCoreColors.deepNavy,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Users data grid
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                  color: Colors.white,
                ),
                child: regularUsers.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun utilisateur créé',
                          style: MediCoreTypography.body.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      )
                    : DataGrid(
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

  void _showTemplateDialog(BuildContext context, WidgetRef ref, UserTemplate? template) {
    showDialog(
      context: context,
      builder: (context) => TemplateFormDialog(template: template),
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

  void _confirmDeleteTemplate(BuildContext context, WidgetRef ref, UserTemplate template) {
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
          'Voulez-vous vraiment supprimer le modèle "${template.role}" ?',
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
                await ref.read(templatesListProvider.notifier).deleteTemplate(template.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Modèle supprimé: ${template.role}'),
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
