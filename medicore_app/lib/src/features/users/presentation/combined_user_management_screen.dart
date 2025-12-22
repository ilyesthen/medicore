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
import '../core/types/proto_types.dart';

/// Combined user and template management screen with tabs
class CombinedUserManagementScreen extends ConsumerStatefulWidget {
  const CombinedUserManagementScreen({super.key});

  @override
  ConsumerState<CombinedUserManagementScreen> createState() => _CombinedUserManagementScreenState();
}

class _CombinedUserManagementScreenState extends ConsumerState<CombinedUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Tab bar
          Container(
            decoration: BoxDecoration(
              color: MediCoreColors.paperWhite,
              border: Border.all(
                color: MediCoreColors.steelOutline,
                width: 2,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: MediCoreColors.deepNavy,
              unselectedLabelColor: MediCoreColors.professionalBlue,
              labelStyle: MediCoreTypography.button.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: MediCoreTypography.button.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicator: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.deepNavy,
                    width: 3,
                  ),
                ),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.people),
                  text: 'UTILISATEURS',
                ),
                Tab(
                  icon: Icon(Icons.folder_special),
                  text: 'MODÈLES (Assistants)',
                ),
              ],
            ),
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: const [
                _UsersTab(),
                _TemplatesTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Users tab content
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final users = ref.watch(usersListProvider);
    final regularUsers = users.where((u) => u.id != 'admin').toList();

    return CockpitPane(
      title: 'Utilisateurs du Système',
      showBorder: false,
      actions: [
        CockpitButton(
          label: 'CRÉER UTILISATEUR',
          icon: Icons.person_add,
          onPressed: () {
            _showUserDialog(context, ref, null);
          },
        ),
      ],
      child: regularUsers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun utilisateur créé',
                    style: MediCoreTypography.sectionHeader.copyWith(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cliquez sur "CRÉER UTILISATEUR" pour commencer',
                    style: MediCoreTypography.body.copyWith(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : Column(
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

/// Templates tab content (only for Assistant 1 & 2)
class _TemplatesTab extends ConsumerWidget {
  const _TemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesListProvider);

    return CockpitPane(
      title: 'Modèles pour Assistants',
      showBorder: false,
      actions: [
        CockpitButton(
          label: 'CRÉER MODÈLE',
          icon: Icons.add_box,
          onPressed: () {
            _showTemplateDialog(context, ref, null);
          },
        ),
      ],
      child: templates.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_special_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun modèle créé',
                    style: MediCoreTypography.sectionHeader.copyWith(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Les modèles sont uniquement pour Assistant 1 et Assistant 2',
                    style: MediCoreTypography.body.copyWith(
                      color: Colors.grey[500],
                      fontSize: 13,
                    ),
                  ),
                ],
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
                  '', // Actions
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
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _showTemplateDialog(BuildContext context, WidgetRef ref, UserTemplate? template) {
    showDialog(
      context: context,
      builder: (context) => TemplateFormDialog(template: template),
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
