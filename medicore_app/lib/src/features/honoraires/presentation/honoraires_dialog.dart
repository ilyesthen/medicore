import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../users/data/users_repository.dart';
import '../../users/data/models/template_model.dart';
import 'medical_acts_provider.dart';
import 'medical_act_form_dialog.dart';
import '../../../core/generated/medicore.pb.dart';

/// Honoraires (Fees) dialog with role-based views
class HonorairesDialog extends ConsumerStatefulWidget {
  const HonorairesDialog({super.key});

  @override
  ConsumerState<HonorairesDialog> createState() => _HonorairesDialogState();
}

class _HonorairesDialogState extends ConsumerState<HonorairesDialog> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userRole = authState.user?.role ?? '';
    final medicalActsAsync = ref.watch(medicalActsListProvider);

    // Determine view based on role
    final isDoctor = userRole.contains('Docteur') || userRole.contains('Dr') || userRole.contains('Médecin');
    final isAssistant = userRole.contains('Assistant');
    final isNurse = userRole.contains('Infirmier') || userRole.contains('Infirmière');

    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: isNurse ? 1200 : (isAssistant ? 900 : 800),
        height: 700,
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
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'HONORAIRES - ACTES PRATIQUÉS',
                    style: MediCoreTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  if (isDoctor) ...[
                    ElevatedButton.icon(
                      onPressed: () => _showAddActDialog(context),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('NOUVEL ACTE'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: MediCoreColors.healthyGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: medicalActsAsync.when(
                data: (acts) {
                  if (isDoctor) {
                    return _DoctorView(acts: acts);
                  } else if (isAssistant) {
                    return _AssistantView(acts: acts);
                  } else if (isNurse) {
                    return _NurseView(acts: acts);
                  } else {
                    return _DoctorView(acts: acts); // Default view
                  }
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
                error: (error, stack) => Center(
                  child: Text('Erreur: $error'),
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

  void _showAddActDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const MedicalActFormDialog(),
    );
  }
}

/// Doctor view - Full CRUD capabilities
class _DoctorView extends ConsumerWidget {
  final List<MedicalAct> acts;

  const _DoctorView({required this.acts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Container(
        margin: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: MediCoreColors.steelOutline,
            width: 2,
          ),
        ),
        child: Table(
          border: TableBorder.symmetric(
            inside: const BorderSide(
              color: MediCoreColors.steelOutline,
              width: 1,
            ),
          ),
          columnWidths: const {
            0: FixedColumnWidth(80),   // ID
            1: FlexColumnWidth(3),     // Acte Pratiqué
            2: FixedColumnWidth(180),  // Honoraire
            3: FixedColumnWidth(120),  // Actions
          },
          children: [
            // Header
            TableRow(
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
              ),
              children: [
                _buildHeaderCell('ID'),
                _buildHeaderCell('ACTE PRATIQUÉ'),
                _buildHeaderCell('HONORAIRE À ENCAISSER'),
                _buildHeaderCell('ACTIONS'),
              ],
            ),
            // Data rows
            ...acts.map((act) => _buildDoctorDataRow(context, ref, act)),
          ],
        ),
      ),
    );
  }

  TableRow _buildDoctorDataRow(BuildContext context, WidgetRef ref, MedicalAct act) {
    return TableRow(
      children: [
        _buildDataCell(act.id.toString(), align: TextAlign.center),
        _buildDataCell(act.name),
        _buildDataCell(_formatAmount(act.feeAmount), align: TextAlign.right),
        _buildActionsCell(context, ref, act),
      ],
    );
  }

  Widget _buildActionsCell(BuildContext context, WidgetRef ref, MedicalAct act) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, size: 18),
            color: MediCoreColors.professionalBlue,
            onPressed: () => _showEditDialog(context, act),
            tooltip: 'Modifier',
          ),
          IconButton(
            icon: const Icon(Icons.delete, size: 18),
            color: MediCoreColors.criticalRed,
            onPressed: () => _confirmDelete(context, ref, act),
            tooltip: 'Supprimer',
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, MedicalAct act) {
    showDialog(
      context: context,
      builder: (context) => MedicalActFormDialog(act: act),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, MedicalAct act) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MediCoreColors.paperWhite,
        title: Text(
          'Confirmer la suppression',
          style: MediCoreTypography.sectionHeader,
        ),
        content: Text(
          'Voulez-vous vraiment supprimer l\'acte "${act.name}" ?',
          style: MediCoreTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(medicalActsRepositoryProvider).deleteMedicalAct(act.id);
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MediCoreColors.criticalRed,
            ),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: MediCoreTypography.button.copyWith(
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {TextAlign align = TextAlign.left}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: MediCoreTypography.body.copyWith(fontSize: 13),
        textAlign: align,
      ),
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} DA';
  }
}

/// Assistant view - Read-only with their share column
class _AssistantView extends ConsumerWidget {
  final List<MedicalAct> acts;

  const _AssistantView({required this.acts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    // Get percentage directly from user model
    final assistantPercentage = authState.user?.percentage ?? 0.0;

        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: MediCoreColors.steelOutline,
                width: 2,
              ),
            ),
            child: Table(
              border: TableBorder.symmetric(
                inside: const BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
              columnWidths: const {
                0: FixedColumnWidth(80),   // ID
                1: FlexColumnWidth(3),     // Acte Pratiqué
                2: FixedColumnWidth(180),  // Honoraire
                3: FixedColumnWidth(180),  // Quote-part Assistant
              },
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(
                    color: MediCoreColors.deepNavy,
                  ),
                  children: [
                    _buildHeaderCell('ID'),
                    _buildHeaderCell('ACTE PRATIQUÉ'),
                    _buildHeaderCell('HONORAIRE À ENCAISSER'),
                    _buildHeaderCell('QUOTE-PART ASSISTANT'),
                  ],
                ),
                // Data rows
                ...acts.map((act) => _buildAssistantDataRow(act, assistantPercentage)),
              ],
            ),
          ),
        );
  }

  TableRow _buildAssistantDataRow(MedicalAct act, double percentage) {
    final share = (act.feeAmount * (percentage / 100)).round();

    return TableRow(
      children: [
        _buildDataCell(act.id.toString(), align: TextAlign.center),
        _buildDataCell(act.name),
        _buildDataCell(_formatAmount(act.feeAmount), align: TextAlign.right),
        _buildDataCell(
          _formatAmount(share),
          align: TextAlign.right,
          color: MediCoreColors.healthyGreen,
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: MediCoreTypography.button.copyWith(
          color: Colors.white,
          fontSize: 12,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {TextAlign align = TextAlign.left, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: MediCoreTypography.body.copyWith(
          fontSize: 13,
          color: color,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} DA';
  }
}

/// Nurse view - Read-only with both assistants' share columns
class _NurseView extends ConsumerWidget {
  final List<MedicalAct> acts;

  const _NurseView({required this.acts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<UserTemplate>>(
      future: UsersRepository().getAllTemplates(),
      builder: (context, snapshot) {
        // Find assistant percentages
        double percentage1 = 0.0;
        double percentage2 = 0.0;
        
        if (snapshot.hasData && snapshot.data != null) {
          final templates = snapshot.data!;
          
          try {
            final assistant1 = templates.firstWhere(
              (t) => t.role == 'Assistant 1',
            );
            percentage1 = assistant1.percentage;
          } catch (e) {
            percentage1 = 0.0;
          }
          
          try {
            final assistant2 = templates.firstWhere(
              (t) => t.role == 'Assistant 2',
            );
            percentage2 = assistant2.percentage;
          } catch (e) {
            percentage2 = 0.0;
          }
        }

        return SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: MediCoreColors.steelOutline,
                width: 2,
              ),
            ),
            child: Table(
              border: TableBorder.symmetric(
                inside: const BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
              columnWidths: const {
                0: FixedColumnWidth(70),   // ID
                1: FlexColumnWidth(3),     // Acte Pratiqué
                2: FixedColumnWidth(150),  // Honoraire
                3: FixedColumnWidth(150),  // Quote-part Assistant 1
                4: FixedColumnWidth(150),  // Quote-part Assistant 2
              },
              children: [
                // Header
                TableRow(
                  decoration: const BoxDecoration(
                    color: MediCoreColors.deepNavy,
                  ),
                  children: [
                    _buildHeaderCell('ID'),
                    _buildHeaderCell('ACTE PRATIQUÉ'),
                    _buildHeaderCell('HONORAIRE À ENCAISSER'),
                    _buildHeaderCell('QUOTE-PART ASST. 1'),
                    _buildHeaderCell('QUOTE-PART ASST. 2'),
                  ],
                ),
                // Data rows
                ...acts.map((act) => _buildNurseDataRow(act, percentage1, percentage2)),
              ],
            ),
          ),
        );
      },
    );
  }

  TableRow _buildNurseDataRow(MedicalAct act, double percentage1, double percentage2) {
    final share1 = (act.feeAmount * (percentage1 / 100)).round();
    final share2 = (act.feeAmount * (percentage2 / 100)).round();

    return TableRow(
      children: [
        _buildDataCell(act.id.toString(), align: TextAlign.center),
        _buildDataCell(act.name),
        _buildDataCell(_formatAmount(act.feeAmount), align: TextAlign.right),
        _buildDataCell(
          _formatAmount(share1),
          align: TextAlign.right,
          color: MediCoreColors.professionalBlue,
        ),
        _buildDataCell(
          _formatAmount(share2),
          align: TextAlign.right,
          color: MediCoreColors.healthyGreen,
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: MediCoreTypography.button.copyWith(
          color: Colors.white,
          fontSize: 11,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text, {TextAlign align = TextAlign.left, Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      child: Text(
        text,
        style: MediCoreTypography.body.copyWith(
          fontSize: 13,
          color: color,
          fontWeight: color != null ? FontWeight.w600 : FontWeight.normal,
        ),
        textAlign: align,
      ),
    );
  }

  String _formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} DA';
  }
}
