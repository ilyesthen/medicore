import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../patients/data/patients_repository.dart';
import '../../consultation/presentation/patient_consultation_page.dart';
import 'waiting_queue_provider.dart';

/// Dialog showing urgent patients for a specific room
class UrgencesDialog extends ConsumerWidget {
  final Room room;
  final bool isDoctor;

  const UrgencesDialog({
    super.key,
    required this.room,
    this.isDoctor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final urgentPatientsAsync = ref.watch(urgentPatientsProvider(room.id));

    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: 900,
        height: 550,
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.criticalRed, width: 3),
        ),
        child: Column(
          children: [
            // Header - RED for urgency
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: MediCoreColors.criticalRed,
                border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '🚨 URGENCES - ${room.name}',
                    style: MediCoreTypography.pageTitle.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  urgentPatientsAsync.when(
                    data: (patients) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${patients.length} patient(s)',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    loading: () => const SizedBox(),
                    error: (_, __) => const SizedBox(),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Table header - RED
            Container(
              height: 40,
              color: const Color(0xFF8B0000), // Dark red
              child: Row(
                children: [
                  _HeaderCell('✓', width: 50),
                  _HeaderCell('HEURE', width: 80),
                  _HeaderCell('NOM', flex: 2),
                  _HeaderCell('ÂGE', width: 60),
                  _HeaderCell('MOTIF DE CONSULTATION', flex: 2),
                  if (isDoctor) _HeaderCell('OUVRIR', width: 80),
                  _HeaderCell('', width: 50), // Delete
                ],
              ),
            ),

            // Table content
            Expanded(
              child: urgentPatientsAsync.when(
                data: (patients) {
                  if (patients.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: MediCoreColors.healthyGreen),
                          SizedBox(height: 16),
                          Text('Aucune urgence', style: TextStyle(color: MediCoreColors.healthyGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return _UrgentPatientRow(
                        patient: patient,
                        isDoctor: isDoctor,
                        onOpenFile: () => _openPatientFile(context, ref, patient),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: MediCoreColors.criticalRed)),
                error: (e, _) => Center(child: Text('Erreur: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPatientFile(BuildContext context, WidgetRef ref, WaitingPatient waitingPatient) async {
    // Get the full patient data
    final patientsRepo = PatientsRepository(AppDatabase());
    final patient = await patientsRepo.getPatientByCode(waitingPatient.patientCode);

    if (patient != null) {
      // Remove from queue
      final queueRepo = ref.read(waitingQueueRepositoryProvider);
      await queueRepo.removeFromQueue(waitingPatient.id);

      if (context.mounted) {
        // Close dialog
        Navigator.of(context).pop();

        // Open patient consultation page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PatientConsultationPage(patient: patient),
          ),
        );
      }
    }
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final double? width;

  const _HeaderCell(this.text, {this.flex = 1, this.width});

  @override
  Widget build(BuildContext context) {
    final child = Center(
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
    return width != null
        ? SizedBox(width: width, child: child)
        : Expanded(flex: flex, child: child);
  }
}

class _UrgentPatientRow extends ConsumerWidget {
  final WaitingPatient patient;
  final bool isDoctor;
  final VoidCallback onOpenFile;

  const _UrgentPatientRow({
    required this.patient,
    required this.isDoctor,
    required this.onOpenFile,
  });

  String _getAge() {
    // First try to calculate from birth date
    if (patient.patientBirthDate != null) {
      final now = DateTime.now();
      int age = now.year - patient.patientBirthDate!.year;
      if (now.month < patient.patientBirthDate!.month || 
          (now.month == patient.patientBirthDate!.month && now.day < patient.patientBirthDate!.day)) {
        age--;
      }
      return '$age';
    }
    // Fall back to stored age
    if (patient.patientAge != null) {
      return '${patient.patientAge}';
    }
    return '-';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: patient.isChecked 
            ? const Color(0xFFFFCDD2) // Light red highlight when checked
            : const Color(0xFFFFF5F5), // Very light red background for urgency
        border: const Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 0.5)),
      ),
      child: Row(
        children: [
          // Checkbox with star - red themed
          SizedBox(
            width: 50,
            child: InkWell(
              onTap: () async {
                final repo = ref.read(waitingQueueRepositoryProvider);
                await repo.toggleChecked(patient.id);
              },
              child: Center(
                child: Icon(
                  patient.isChecked ? Icons.warning : Icons.warning_amber_outlined,
                  color: patient.isChecked ? MediCoreColors.criticalRed : Colors.grey,
                  size: 24,
                ),
              ),
            ),
          ),

          // Time
          SizedBox(
            width: 80,
            child: Center(
              child: Text(
                timeFormat.format(patient.sentAt.toLocal()),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: MediCoreColors.criticalRed),
              ),
            ),
          ),

          // Name
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                '${patient.patientLastName} ${patient.patientFirstName}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: MediCoreColors.criticalRed),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Age
          SizedBox(
            width: 60,
            child: Center(
              child: Text(
                _getAge(),
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // Motif
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                patient.motif,
                style: const TextStyle(
                  fontSize: 13,
                  color: MediCoreColors.criticalRed,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),

          // Open file (doctor only)
          if (isDoctor)
            SizedBox(
              width: 80,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.folder_open, color: MediCoreColors.criticalRed),
                  tooltip: 'Ouvrir dossier',
                  onPressed: onOpenFile,
                ),
              ),
            ),

          // Delete
          SizedBox(
            width: 50,
            child: Center(
              child: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                tooltip: 'Supprimer',
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Row(
                        children: [
                          Icon(Icons.warning, color: MediCoreColors.criticalRed),
                          SizedBox(width: 8),
                          Text('Supprimer Urgence'),
                        ],
                      ),
                      content: Text('Retirer ${patient.patientFirstName} ${patient.patientLastName} des urgences?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: MediCoreColors.criticalRed, foregroundColor: Colors.white),
                          child: const Text('Supprimer'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true) {
                    final repo = ref.read(waitingQueueRepositoryProvider);
                    await repo.removeFromQueue(patient.id);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
