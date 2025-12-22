import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import 'medical_acts_provider.dart';
import '../core/types/proto_types.dart';

/// Form dialog for adding/editing medical acts (Doctor only)
class MedicalActFormDialog extends ConsumerStatefulWidget {
  final MedicalAct? act;

  const MedicalActFormDialog({super.key, this.act});

  @override
  ConsumerState<MedicalActFormDialog> createState() => _MedicalActFormDialogState();
}

class _MedicalActFormDialogState extends ConsumerState<MedicalActFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _feeController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.act?.name ?? '');
    _feeController = TextEditingController(
      text: widget.act != null ? widget.act!.feeAmount.toString() : '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  bool get _isEditing => widget.act != null;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(30),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                children: [
                  Icon(
                    _isEditing ? Icons.edit : Icons.add_circle,
                    color: MediCoreColors.professionalBlue,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _isEditing ? 'MODIFIER L\'ACTE' : 'NOUVEL ACTE',
                    style: MediCoreTypography.pageTitle.copyWith(fontSize: 20),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Act name field
              Text(
                'Nom de l\'acte',
                style: MediCoreTypography.sectionHeader.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Ex: CONSULTATION +FO, OCT, etc.',
                  hintStyle: MediCoreTypography.body.copyWith(
                    color: Colors.grey[400],
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: MediCoreColors.steelOutline,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: MediCoreColors.professionalBlue,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: MediCoreTypography.body,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Le nom de l\'acte est obligatoire';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Fee amount field
              Text(
                'Honoraire à encaisser (DA)',
                style: MediCoreTypography.sectionHeader.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _feeController,
                decoration: InputDecoration(
                  hintText: 'Ex: 2000, 8000, etc.',
                  hintStyle: MediCoreTypography.body.copyWith(
                    color: Colors.grey[400],
                  ),
                  suffixText: 'DA',
                  suffixStyle: MediCoreTypography.body.copyWith(
                    color: MediCoreColors.professionalBlue,
                    fontWeight: FontWeight.w600,
                  ),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: MediCoreColors.steelOutline,
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: MediCoreColors.professionalBlue,
                      width: 2,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: MediCoreTypography.body,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'L\'honoraire est obligatoire';
                  }
                  final amount = int.tryParse(value);
                  if (amount == null || amount < 0) {
                    return 'Montant invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'ANNULER',
                      style: MediCoreTypography.button.copyWith(
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _saveAct,
                    icon: Icon(_isEditing ? Icons.save : Icons.add, size: 18),
                    label: Text(_isEditing ? 'ENREGISTRER' : 'AJOUTER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MediCoreColors.professionalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveAct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _nameController.text.trim();
    final feeAmount = int.parse(_feeController.text.trim());
    final repository = ref.read(medicalActsRepositoryProvider);

    try {
      if (_isEditing) {
        await repository.updateMedicalAct(
          id: widget.act!.id,
          name: name,
          feeAmount: feeAmount,
        );
      } else {
        await repository.createMedicalAct(
          name: name,
          feeAmount: feeAmount,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Acte modifié avec succès'
                  : 'Acte ajouté avec succès',
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
    }
  }
}
