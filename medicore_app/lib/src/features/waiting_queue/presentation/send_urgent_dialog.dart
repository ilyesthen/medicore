import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import 'waiting_queue_provider.dart';
import '../../../core/generated/medicore.pb.dart';

/// Dialog for sending a patient to urgences - with room selection
class SendUrgentDialog extends ConsumerStatefulWidget {
  final Patient patient;
  final List<Room> availableRooms;
  final String currentUserId;
  final String currentUserName;

  const SendUrgentDialog({
    super.key,
    required this.patient,
    required this.availableRooms,
    required this.currentUserId,
    required this.currentUserName,
  });

  @override
  ConsumerState<SendUrgentDialog> createState() => _SendUrgentDialogState();
}

class _SendUrgentDialogState extends ConsumerState<SendUrgentDialog> {
  String? _selectedMotif;
  Room? _selectedRoom;
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

    if (_selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sélectionnez une salle'),
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
        roomId: _selectedRoom!.id,
        roomName: _selectedRoom!.name,
        motif: _selectedMotif!,
        sentByUserId: widget.currentUserId,
        sentByUserName: widget.currentUserName,
        isUrgent: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('🚨 URGENCE: ${widget.patient.firstName} ${widget.patient.lastName} → ${_selectedRoom!.name}'),
                ),
              ],
            ),
            backgroundColor: MediCoreColors.criticalRed,
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
        width: 500,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.criticalRed, width: 3),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Expanded(
                    child: Text(
                      '🚨 URGENCE',
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

            // Patient info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5), // Light red background
                border: const Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person, color: MediCoreColors.criticalRed),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Patient', style: MediCoreTypography.label),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.patient.firstName} ${widget.patient.lastName}',
                          style: MediCoreTypography.body.copyWith(fontWeight: FontWeight.bold, color: MediCoreColors.criticalRed),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Room selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Salle de destination', style: MediCoreTypography.label.copyWith(fontWeight: FontWeight.w600, color: MediCoreColors.criticalRed)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: MediCoreColors.criticalRed.withOpacity(0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Column(
                      children: widget.availableRooms.map((room) {
                        final isSelected = _selectedRoom?.id == room.id;
                        return InkWell(
                          onTap: () => setState(() => _selectedRoom = room),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? MediCoreColors.criticalRed.withOpacity(0.1) : null,
                              border: Border(
                                bottom: BorderSide(color: MediCoreColors.steelOutline.withOpacity(0.5), width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: isSelected ? MediCoreColors.criticalRed : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Icon(Icons.meeting_room, color: isSelected ? MediCoreColors.criticalRed : Colors.grey, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  room.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? MediCoreColors.criticalRed : MediCoreColors.deepNavy,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Motif selection
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Motif de consultation', style: MediCoreTypography.label.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    height: 250,
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? MediCoreColors.criticalRed.withOpacity(0.1) : null,
                              border: Border(
                                bottom: BorderSide(color: MediCoreColors.steelOutline.withOpacity(0.5), width: 0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                                  size: 18,
                                  color: isSelected ? MediCoreColors.criticalRed : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  motif,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                    color: isSelected ? MediCoreColors.criticalRed : MediCoreColors.deepNavy,
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
                        : const Icon(Icons.warning_amber, size: 18),
                    label: Text(_isSending ? 'Envoi...' : 'ENVOYER URGENCE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MediCoreColors.criticalRed,
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
