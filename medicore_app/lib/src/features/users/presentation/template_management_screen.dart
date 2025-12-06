import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_pane.dart';
import '../../../core/ui/cockpit_button.dart';
import '../../../core/ui/data_grid.dart';
import 'users_provider.dart';
import '../data/models/template_model.dart';
import 'template_form_dialog.dart';

/// Template management screen with CRUD operations
class TemplateManagementScreen extends ConsumerWidget {
  const TemplateManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesListProvider);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: CockpitPane(
        title: 'Modèles d\'Utilisateurs',
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
                      'Cliquez sur "CRÉER MODÈLE" pour commencer',
                      style: MediCoreTypography.body.copyWith(
                        color: Colors.grey[500],
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 500,
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
                                'Qu\'est-ce qu\'un modèle ?',
                                style: MediCoreTypography.sectionHeader.copyWith(
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Un modèle permet aux assistants de créer rapidement leur compte lors de la première connexion.\n\n'
                            'Le modèle contient:\n'
                            '• Un rôle prédéfini\n'
                            '• Un mot de passe\n'
                            '• Un pourcentage\n\n'
                            'L\'assistant entre simplement son nom complet et son compte est créé automatiquement.',
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
                  // Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: MediCoreColors.professionalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MediCoreColors.professionalBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.folder_special,
                          color: MediCoreColors.professionalBlue,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              templates.length.toString(),
                              style: MediCoreTypography.pageTitle.copyWith(
                                color: MediCoreColors.professionalBlue,
                                fontSize: 24,
                              ),
                            ),
                            Text(
                              'Modèles disponibles',
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
                  
                  // Templates data grid
                  Expanded(
                    child: DataGrid(
                      headers: const [
                        'RÔLE',
                        'MOT DE PASSE',
                        'POURCENTAGE',
                        'CRÉÉ LE',
                        'ACTIONS',
                      ],
                      rows: templates.map((template) {
                        return [
                          template.role,
                          '••••••', // Hide password
                          '${template.percentage.toStringAsFixed(0)}%',
                          _formatDate(template.createdAt),
                          '', // Actions handled separately
                        ];
                      }).toList(),
                      onRowTap: (index) {
                        _showTemplateDialog(context, ref, templates[index]);
                      },
                      customCellBuilder: (rowIndex, columnIndex, value) {
                        if (columnIndex == 4) {
                          // Actions column
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
                                  _confirmDelete(context, ref, template);
                                },
                              ),
                            ],
                          );
                        }
                        
                        // Percentage column with color
                        if (columnIndex == 2) {
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
                ],
              ),
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

  void _confirmDelete(BuildContext context, WidgetRef ref, UserTemplate template) {
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
