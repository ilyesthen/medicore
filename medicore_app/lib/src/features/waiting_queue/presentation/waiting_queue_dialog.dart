import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../patients/data/patients_repository.dart';
import '../../consultation/presentation/patient_consultation_page.dart';
import 'waiting_queue_provider.dart';

/// Dialog showing waiting patients for a specific room
class WaitingQueueDialog extends ConsumerWidget {
  final Room room;
  final bool isDoctor;

  const WaitingQueueDialog({
    super.key,
    required this.room,
    this.isDoctor = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingPatientsAsync = ref.watch(waitingPatientsProvider(room.id));

    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: 900,
        height: 550,
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.steelOutline, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: Color(0xFFF57C00), // Orange for waiting
                border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.schedule, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Text(
                    '📋 EN ATTENTE CONSULTATION - ${room.name}',
                    style: MediCoreTypography.pageTitle.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  waitingPatientsAsync.when(
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

            // Table header
            Container(
              height: 40,
              color: MediCoreColors.deepNavy,
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
              child: waitingPatientsAsync.when(
                data: (patients) {
                  if (patients.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Aucun patient en attente', style: TextStyle(color: Colors.grey, fontSize: 16)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return _PatientRow(
                        patient: patient,
                        isDoctor: isDoctor,
                        onOpenFile: () => _openPatientFile(context, ref, patient),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
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

class _PatientRow extends ConsumerWidget {
  final WaitingPatient patient;
  final bool isDoctor;
  final VoidCallback onOpenFile;

  const _PatientRow({
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
            ? const Color(0xFFFFF9C4) // Yellow highlight when checked
            : Colors.transparent,
        border: const Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 0.5)),
      ),
      child: Row(
        children: [
          // Checkbox with star
          SizedBox(
            width: 50,
            child: InkWell(
              onTap: () async {
                final repo = ref.read(waitingQueueRepositoryProvider);
                await repo.toggleChecked(patient.id);
              },
              child: Center(
                child: Icon(
                  patient.isChecked ? Icons.star : Icons.star_border,
                  color: patient.isChecked ? Colors.amber : Colors.grey,
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
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
                style: const TextStyle(fontSize: 13),
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
                style: TextStyle(
                  fontSize: 13,
                  color: MediCoreColors.professionalBlue,
                  fontWeight: FontWeight.w500,
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
                  icon: const Icon(Icons.folder_open, color: MediCoreColors.professionalBlue),
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
                      title: const Text('Supprimer'),
                      content: Text('Retirer ${patient.patientFirstName} ${patient.patientLastName} de la liste d\'attente?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
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
