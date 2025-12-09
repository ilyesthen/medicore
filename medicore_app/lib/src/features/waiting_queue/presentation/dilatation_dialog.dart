import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../patients/data/patients_repository.dart';
import '../../consultation/presentation/patient_consultation_page.dart';
import '../../messages/services/notification_service.dart';
import '../data/waiting_queue_repository.dart';
import 'waiting_queue_provider.dart';

/// Dialog showing dilatation patients for nurse (from all rooms)
class DilatationDialog extends ConsumerStatefulWidget {
  final List<String> roomIds;
  final bool isDoctor;
  final String? singleRoomId;

  const DilatationDialog({
    super.key,
    required this.roomIds,
    this.isDoctor = false,
    this.singleRoomId,
  });

  @override
  ConsumerState<DilatationDialog> createState() => _DilatationDialogState();
}

class _DilatationDialogState extends ConsumerState<DilatationDialog> {
  Timer? _timer;
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    // Stop notification sound when dialog opens (user is viewing dilatations)
    _notificationService.stopNotificationSound();
    
    // Update timer every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dilatationPatientsAsync = widget.singleRoomId != null
        ? ref.watch(dilatationPatientsProvider(widget.singleRoomId!))
        : ref.watch(allDilatationPatientsProvider(widget.roomIds));

    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: 950,
        height: 550,
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.healthyGreen, width: 3),
        ),
        child: Column(
          children: [
            // Header - GREEN for dilatation
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: MediCoreColors.healthyGreen,
                border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.opacity, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    '💊 DILATATIONS',
                    style: MediCoreTypography.pageTitle.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  dilatationPatientsAsync.when(
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
              color: const Color(0xFF2E7D32), // Dark green
              child: Row(
                children: [
                  _HeaderCell('✓', width: 50),
                  _HeaderCell('TIMER', width: 90),
                  _HeaderCell('SALLE', width: 100),
                  _HeaderCell('NOM', flex: 2),
                  _HeaderCell('ÂGE', width: 60),
                  _HeaderCell('DILATATION', flex: 2),
                  if (widget.isDoctor) _HeaderCell('OUVRIR', width: 80),
                  _HeaderCell('', width: 50), // Delete
                ],
              ),
            ),

            // Table content
            Expanded(
              child: dilatationPatientsAsync.when(
                data: (patients) {
                  if (patients.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: MediCoreColors.healthyGreen),
                          SizedBox(height: 16),
                          Text('Aucune dilatation en cours', style: TextStyle(color: MediCoreColors.healthyGreen, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: patients.length,
                    itemBuilder: (context, index) {
                      final patient = patients[index];
                      return _DilatationPatientRow(
                        patient: patient,
                        isDoctor: widget.isDoctor,
                        onOpenFile: () => _openPatientFile(context, ref, patient),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: MediCoreColors.healthyGreen)),
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

class _DilatationPatientRow extends ConsumerWidget {
  final WaitingPatient patient;
  final bool isDoctor;
  final VoidCallback onOpenFile;

  const _DilatationPatientRow({
    required this.patient,
    required this.isDoctor,
    required this.onOpenFile,
  });

  String _getAge() {
    if (patient.patientBirthDate != null) {
      final now = DateTime.now();
      int age = now.year - patient.patientBirthDate!.year;
      if (now.month < patient.patientBirthDate!.month || 
          (now.month == patient.patientBirthDate!.month && now.day < patient.patientBirthDate!.day)) {
        age--;
      }
      return '$age';
    }
    if (patient.patientAge != null) {
      return '${patient.patientAge}';
    }
    return '-';
  }

  String _formatTimer(DateTime sentAt) {
    final now = DateTime.now();
    final difference = now.difference(sentAt);
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor(DateTime sentAt) {
    final minutes = DateTime.now().difference(sentAt).inMinutes;
    if (minutes >= 30) return MediCoreColors.criticalRed;
    if (minutes >= 15) return Colors.orange;
    return MediCoreColors.healthyGreen;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: patient.isChecked 
            ? const Color(0xFFC8E6C9) // Light green highlight when checked
            : const Color(0xFFF1F8E9), // Very light green background
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

          // Timer - live counting
          SizedBox(
            width: 90,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTimerColor(patient.sentAt).withOpacity(0.1),
                  border: Border.all(color: _getTimerColor(patient.sentAt), width: 1.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _formatTimer(patient.sentAt),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: _getTimerColor(patient.sentAt),
                  ),
                ),
              ),
            ),
          ),

          // Room
          SizedBox(
            width: 100,
            child: Center(
              child: Text(
                patient.roomName,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                overflow: TextOverflow.ellipsis,
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
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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

          // Dilatation type
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: MediCoreColors.healthyGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  patient.motif,
                  style: const TextStyle(
                    fontSize: 12,
                    color: MediCoreColors.healthyGreen,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Open file (doctor only)
          if (isDoctor)
            SizedBox(
              width: 80,
              child: Center(
                child: IconButton(
                  icon: const Icon(Icons.folder_open, color: MediCoreColors.healthyGreen),
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
                          Icon(Icons.opacity, color: MediCoreColors.healthyGreen),
                          SizedBox(width: 8),
                          Text('Supprimer Dilatation'),
                        ],
                      ),
                      content: Text('Retirer ${patient.patientFirstName} ${patient.patientLastName} de la liste?'),
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
