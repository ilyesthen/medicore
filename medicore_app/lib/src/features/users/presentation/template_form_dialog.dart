import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_input.dart';
import '../../../core/ui/cockpit_button.dart';
import '../../../core/constants/app_constants.dart';
import 'users_provider.dart';
import '../data/models/template_model.dart';

/// Dialog for creating or editing a template
class TemplateFormDialog extends ConsumerStatefulWidget {
  final UserTemplate? template; // Null for create, populated for edit

  const TemplateFormDialog({super.key, this.template});

  @override
  ConsumerState<TemplateFormDialog> createState() => _TemplateFormDialogState();
}

class _TemplateFormDialogState extends ConsumerState<TemplateFormDialog> {
  late TextEditingController _passwordController;
  late TextEditingController _percentageController;
  
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.template?.role;
    _passwordController = TextEditingController(text: widget.template?.password ?? '');
    _percentageController = TextEditingController(
      text: widget.template?.percentage.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedRole == null) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un rôle'),
            backgroundColor: MediCoreColors.criticalRed,
          ),
        );
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final percentage = double.parse(_percentageController.text);

      if (widget.template == null) {
        // Create new template
        await ref.read(templatesListProvider.notifier).createTemplate(
              role: _selectedRole!,
              password: _passwordController.text,
              percentage: percentage,
            );
      } else {
        // Update existing template
        await ref.read(templatesListProvider.notifier).updateTemplate(
              widget.template!.copyWith(
                role: _selectedRole!,
                password: _passwordController.text,
                percentage: percentage,
              ),
            );
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.template == null
                  ? 'Modèle créé avec succès'
                  : 'Modèle mis à jour',
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
    final isEdit = widget.template != null;

    return AlertDialog(
      backgroundColor: MediCoreColors.paperWhite,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 500),
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
                    isEdit ? Icons.edit : Icons.add_box,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Modifier Modèle' : 'Créer Modèle',
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
                                'Modèles uniquement pour Assistant 1 et Assistant 2',
                                style: MediCoreTypography.label.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Role dropdown
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rôle',
                            style: MediCoreTypography.label.copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: MediCoreColors.inputBackground,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: MediCoreColors.inputBorder,
                                width: 1,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRole,
                                hint: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Sélectionnez un rôle',
                                    style: MediCoreTypography.inputField.copyWith(
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ),
                                isExpanded: true,
                                icon: const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: Icon(
                                    Icons.arrow_drop_down,
                                    color: MediCoreColors.professionalBlue,
                                  ),
                                ),
                                items: AppConstants.assistantRoles.map((role) {
                                  return DropdownMenuItem(
                                    value: role,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        role,
                                        style: MediCoreTypography.inputField,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedRole = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CockpitInput(
                        label: 'Mot de passe',
                        hint: 'Mot de passe pour ce rôle',
                        controller: _passwordController,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le mot de passe est requis';
                          }
                          if (value.length < 4) {
                            return 'Le mot de passe doit avoir au moins 4 caractères';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      CockpitInput(
                        label: 'Pourcentage',
                        hint: 'Ex: 50',
                        controller: _percentageController,
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le pourcentage est requis';
                          }
                          final num = double.tryParse(value);
                          if (num == null || num < 0 || num > 100) {
                            return 'Doit être entre 0 et 100';
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
