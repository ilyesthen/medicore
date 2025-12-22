import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../data/waiting_queue_repository.dart';
import 'waiting_queue_provider.dart';
import '../../../core/generated/medicore.pb.dart';

/// Dialog for sending a patient to a room's waiting queue
class SendPatientDialog extends ConsumerStatefulWidget {
  final Patient patient;
  final Room room;
  final String currentUserId;
  final String currentUserName;

  const SendPatientDialog({
    super.key,
    required this.patient,
    required this.room,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  ConsumerState<SendPatientDialog> createState() => _SendPatientDialogState();
}

class _SendPatientDialogState extends ConsumerState<SendPatientDialog> {
  String? _selectedMotif;
  bool _isSending = false;

  Future<void> _sendPatient() async {
    if (_selectedMotif == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez un motif de consultation'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final repository = ref.read(waitingQueueRepositoryProvider);
      await repository.addToQueue(
        patientCode: widget.patient.code,
        patientFirstName: widget.patient.firstName,
        patientLastName: widget.patient.lastName,
        patientBirthDate: widget.patient.dateOfBirth,
        patientAge: widget.patient.age,
        roomId: widget.room.id,
        roomName: widget.room.name,
        motif: _selectedMotif!,
        sentByUserId: widget.currentUserId,
        sentByUserName: widget.currentUserName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.patient.firstName} ${widget.patient.lastName} envoyé à ${widget.room.name}'),
            backgroundColor: MediCoreColors.healthyGreen,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.steelOutline, width: 2),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                color: MediCoreColors.professionalBlue,
                border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.send, color: Colors.white, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'ENVOYER PATIENT',
                      style: MediCoreTypography.pageTitle.copyWith(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Patient & Room info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: MediCoreColors.paneTitleBar,
                border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient', style: MediCoreTypography.label),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.patient.firstName} ${widget.patient.lastName}',
                          style: MediCoreTypography.body.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: MediCoreColors.steelOutline),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Destination', style: MediCoreTypography.label),
                        const SizedBox(height: 4),
                        Text(
                          widget.room.name,
                          style: MediCoreTypography.body.copyWith(
                            fontWeight: FontWeight.bold,
                            color: MediCoreColors.professionalBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Motif selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motif de consultation', style: MediCoreTypography.label.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: MediCoreColors.steelOutline),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: WaitingQueueRepository.motifs.length,
                      itemBuilder: (context, index) {
                        final motif = WaitingQueueRepository.motifs[index];
                        final isSelected = _selectedMotif == motif;
                        return InkWell(
                          onTap: () => setState(() => _selectedMotif = motif),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? MediCoreColors.professionalBlue.withOpacity(0.1) : null,
                              border: Border(
                                bottom: BorderSide(color: MediCoreColors.steelOutline.withOpacity(0.5), width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: isSelected ? MediCoreColors.professionalBlue : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  motif,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? MediCoreColors.professionalBlue : MediCoreColors.deepNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _isSending ? null : _sendPatient,
                    icon: _isSending
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 18),
                    label: Text(_isSending ? 'Envoi...' : 'Envoyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MediCoreColors.professionalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
}
