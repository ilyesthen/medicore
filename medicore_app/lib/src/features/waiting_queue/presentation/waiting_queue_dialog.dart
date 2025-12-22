import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../patients/data/age_calculator_service.dart';
import '../../consultation/presentation/patient_consultation_page.dart';
import '../../messages/services/notification_service.dart';
import 'waiting_queue_provider.dart';
import 'waiting_queue_filters.dart';
import '../../../core/types/proto_types.dart';

/// Dialog showing waiting patients for a specific room
class WaitingQueueDialog extends ConsumerStatefulWidget {
  final Room room;
  final bool isDoctor;

  const WaitingQueueDialog({
    super.key,
    required this.room,
    this.isDoctor = false,
  });

  @override
  ConsumerState<WaitingQueueDialog> createState() => _WaitingQueueDialogState();
}

class _WaitingQueueDialogState extends ConsumerState<WaitingQueueDialog> {
  final NotificationService _notificationService = NotificationService();
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Stop notification sound when viewing waiting patients list
    _notificationService.stopNotificationSound();
    // Request focus for keyboard navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event, List<WaitingPatient> patients) {
    if (event is KeyDownEvent && patients.isNotEmpty) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() {
          _selectedIndex = (_selectedIndex - 1).clamp(0, patients.length - 1);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        setState(() {
          _selectedIndex = (_selectedIndex + 1).clamp(0, patients.length - 1);
        });
      } else if (event.logicalKey == LogicalKeyboardKey.enter) {
        if (widget.isDoctor && _selectedIndex < patients.length) {
          _openPatientFile(context, patients[_selectedIndex]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final waitingPatientsAsync = ref.watch(waitingPatientsProvider(widget.room.id));
    final filters = ref.watch(waitingQueueFilterProvider);
    
    // Get filtered patients for keyboard navigation
    final filteredPatients = waitingPatientsAsync.whenOrNull(
      data: (patients) => applyWaitingQueueFilters(patients, filters),
    ) ?? [];

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) => _handleKeyEvent(event, filteredPatients),
      child: Dialog(
        backgroundColor: MediCoreColors.canvasGrey,
        child: Container(
        width: 950,
        height: 600,
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
                    '📋 EN ATTENTE CONSULTATION - ${widget.room.name}',
                    style: MediCoreTypography.pageTitle.copyWith(color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
                  waitingPatientsAsync.when(
                    data: (patients) {
                      final filtered = applyWaitingQueueFilters(patients, filters);
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${filtered.length}/${patients.length} patient(s)',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      );
                    },
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

            // Filter bar
            waitingPatientsAsync.when(
              data: (patients) => WaitingQueueFilterBar(
                accentColor: const Color(0xFFF57C00),
                filterProvider: waitingQueueFilterProvider,
                patients: patients,
                motifLabel: 'motifs',
              ),
              loading: () => const SizedBox(height: 52),
              error: (_, __) => const SizedBox(height: 52),
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
                  if (widget.isDoctor) _HeaderCell('OUVRIR', width: 80),
                  _HeaderCell('', width: 50), // Delete
                ],
              ),
            ),

            // Table content
            Expanded(
              child: waitingPatientsAsync.when(
                data: (patients) {
                  final filteredPatients = applyWaitingQueueFilters(patients, filters);
                  
                  if (filteredPatients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hourglass_empty, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            patients.isEmpty 
                                ? 'Aucun patient en attente'
                                : 'Aucun résultat pour les filtres',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      return _PatientRow(
                        patient: patient,
                        isDoctor: widget.isDoctor,
                        isSelected: index == _selectedIndex,
                        onOpenFile: () => _openPatientFile(context, patient),
                        onTap: () => setState(() => _selectedIndex = index),
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
      ),
    );
  }

  Future<void> _openPatientFile(BuildContext context, WaitingPatient waitingPatient) async {
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
  final bool isSelected;
  final VoidCallback onOpenFile;
  final VoidCallback? onTap;

  const _PatientRow({
    required this.patient,
    required this.isDoctor,
    this.isSelected = false,
    required this.onOpenFile,
    this.onTap,
  });

  String _getAge() {
    final age = patient.currentAge;
    return age?.toString() ?? '-';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFormat = DateFormat('HH:mm');

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFE3F2FD) // Blue highlight when selected by keyboard
              : patient.isChecked 
                  ? const Color(0xFFFFF9C4) // Yellow highlight when checked
                  : Colors.transparent,
          border: Border(
            bottom: const BorderSide(color: MediCoreColors.steelOutline, width: 0.5),
            left: isSelected ? const BorderSide(color: Color(0xFF1976D2), width: 3) : BorderSide.none,
          ),
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
      ),
    );
  }
}
