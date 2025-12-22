import 'dart:async';
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
  final FocusNode _focusNode = FocusNode();
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Stop notification sound when dialog opens (user is viewing dilatations)
    _notificationService.stopNotificationSound();
    
    // Update timer every second
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    
    // Request focus for keyboard navigation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
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
          _openPatientFile(context, ref, patients[_selectedIndex]);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dilatationPatientsAsync = widget.singleRoomId != null
        ? ref.watch(dilatationPatientsProvider(widget.singleRoomId!))
        : ref.watch(allDilatationPatientsProvider(widget.roomIds));
    final filters = ref.watch(dilatationQueueFilterProvider);
    
    // Get filtered patients for keyboard navigation
    final filteredPatients = dilatationPatientsAsync.whenOrNull(
      data: (patients) => applyWaitingQueueFilters(patients, filters),
    ) ?? [];

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: (event) => _handleKeyEvent(event, filteredPatients),
      child: Dialog(
        backgroundColor: MediCoreColors.canvasGrey,
        child: Container(
          width: 1000,
          height: 650,
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
            dilatationPatientsAsync.when(
              data: (patients) => WaitingQueueFilterBar(
                accentColor: MediCoreColors.healthyGreen,
                filterProvider: dilatationQueueFilterProvider,
                patients: patients,
                motifLabel: 'types',
              ),
              loading: () => const SizedBox(height: 52),
              error: (_, __) => const SizedBox(height: 52),
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
                  final filteredPatients = applyWaitingQueueFilters(patients, filters);
                  
                  if (filteredPatients.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle, size: 64, color: MediCoreColors.healthyGreen),
                          const SizedBox(height: 16),
                          Text(
                            patients.isEmpty 
                                ? 'Aucune dilatation en cours'
                                : 'Aucun résultat pour les filtres',
                            style: TextStyle(
                              color: patients.isEmpty ? MediCoreColors.healthyGreen : Colors.grey[600], 
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredPatients.length,
                    itemBuilder: (context, index) {
                      final patient = filteredPatients[index];
                      DateTime now = DateTime.now();
                      DateTime sentAt = DateTime.tryParse(patient.sentAt)?.toLocal() ?? DateTime.now();
                      return _DilatationPatientRow(
                        patient: patient,
                        isDoctor: widget.isDoctor,
                        isSelected: index == _selectedIndex,
                        onOpenFile: () => _openPatientFile(context, ref, patient),
                        onTap: () => setState(() => _selectedIndex = index),
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
      ),
    );
  }

  Future<void> _openPatientFile(BuildContext context, WidgetRef ref, WaitingPatient waitingPatient) async {
    // Get the full patient data
    // TODO: Implement with gRPC
    Patient? patient;

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
  final bool isSelected;
  final VoidCallback onOpenFile;
  final VoidCallback? onTap;

  const _DilatationPatientRow({
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

  String _formatTimer(String sentAt) {
    final now = DateTime.now();
    final difference = now.difference(DateTime.tryParse(sentAt) ?? DateTime.now());
    
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    final seconds = difference.inSeconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor(String sentAt) {
    final minutesSince = DateTime.now().difference(DateTime.tryParse(sentAt) ?? DateTime.now()).inMinutes;
    if (minutesSince >= 30) return MediCoreColors.criticalRed;
    if (minutesSince >= 15) return Colors.orange;
    return MediCoreColors.healthyGreen;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    DateTime now = DateTime.now();
    DateTime sentAt = DateTime.tryParse(patient.sentAt)?.toLocal() ?? DateTime.now();
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: isSelected 
              ? const Color(0xFFE3F2FD) // Blue highlight when selected by keyboard
              : patient.isChecked 
                  ? const Color(0xFFC8E6C9) // Light green highlight when checked
                  : const Color(0xFFF1F8E9), // Very light green background
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
      ),
    );
  }
}
