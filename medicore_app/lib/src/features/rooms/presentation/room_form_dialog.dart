import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_input.dart';
import '../../../core/ui/cockpit_button.dart';
import 'rooms_provider.dart';
import '../core/types/proto_types.dart';

/// Dialog for creating or editing a room
class RoomFormDialog extends ConsumerStatefulWidget {
  final Room? room; // Null for create, populated for edit

  const RoomFormDialog({super.key, this.room});

  @override
  ConsumerState<RoomFormDialog> createState() => _RoomFormDialogState();
}

class _RoomFormDialogState extends ConsumerState<RoomFormDialog> {
  late TextEditingController _nameController;
  
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.room?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (widget.room == null) {
        // Create new room
        await ref.read(roomsListProvider.notifier).createRoom(
              name: _nameController.text.trim(),
            );
      } else {
        // Update existing room
        final updatedRoom = Room(
          id: widget.room!.id,
          name: _nameController.text.trim(),
          createdAt: widget.room!.createdAt,
          updatedAt: DateTime.now(),
          needsSync: true,
        );
        await ref.read(roomsListProvider.notifier).updateRoom(updatedRoom);
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.room == null
                  ? 'Salle créée avec succès'
                  : 'Salle mise à jour',
            ),
            backgroundColor: MediCoreColors.healthyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: MediCoreColors.criticalRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.room != null;

    return AlertDialog(
      backgroundColor: MediCoreColors.paperWhite,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 350),
        decoration: BoxDecoration(
          border: Border.all(
            color: MediCoreColors.steelOutline,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
                  Icon(
                    isEdit ? Icons.edit : Icons.add_location_alt,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Modifier Salle' : 'Créer Salle',
                    style: MediCoreTypography.sectionHeader.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: MediCoreColors.canvasGrey,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              size: 16,
                              color: MediCoreColors.professionalBlue,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Les salles sont utilisées pour organiser les patients et les messages',
                                style: MediCoreTypography.label.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      CockpitInput(
                        label: 'Nom de la salle',
                        hint: 'Ex: Salle 101, Urgences, Radiologie',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Le nom de la salle est requis';
                          }
                          if (value.trim().length < 2) {
                            return 'Le nom doit avoir au moins 2 caractères';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
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
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(
                        'ANNULER',
                        style: MediCoreTypography.button.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 44,
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    MediCoreColors.professionalBlue,
                                  ),
                                ),
                              ),
                            )
                          : CockpitButton(
                              label: isEdit ? 'METTRE À JOUR' : 'CRÉER',
                              icon: isEdit ? Icons.save : Icons.add,
                              onPressed: _submit,
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
}
