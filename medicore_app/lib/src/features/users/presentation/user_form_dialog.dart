import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_input.dart';
import '../../../core/ui/cockpit_button.dart';
import '../../../core/constants/app_constants.dart';
import 'users_provider.dart';
import '../data/models/user_model.dart';
import '../../../core/types/proto_types.dart';

/// Dialog for creating or editing a user
class UserFormDialog extends ConsumerStatefulWidget {
  final User? user; // Null for create, populated for edit

  const UserFormDialog({super.key, this.user});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late TextEditingController _percentageController;
  
  String? _selectedRole;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _selectedRole = widget.user?.role;
    _passwordController = TextEditingController(text: widget.user?.password ?? '');
    _percentageController = TextEditingController(
      text: widget.user?.percentage?.toStringAsFixed(0) ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
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
      final percentage = _percentageController.text.isNotEmpty
          ? double.tryParse(_percentageController.text)
          : null;

      if (widget.user == null) {
        // Create new user
        await ref.read(usersListProvider.notifier).createUser(
              name: _nameController.text.trim(),
              role: _selectedRole!,
              password: _passwordController.text,
              percentage: percentage,
            );
      } else {
        // Update existing user
        await ref.read(usersListProvider.notifier).updateUser(
              widget.user!.copyWith(
                name: _nameController.text.trim(),
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
              widget.user == null
                  ? 'Utilisateur créé avec succès'
                  : 'Utilisateur mis à jour',
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
    final isEdit = widget.user != null;

    return AlertDialog(
      backgroundColor: MediCoreColors.paperWhite,
      contentPadding: EdgeInsets.zero,
      content: Container(
        width: 500,
        constraints: const BoxConstraints(maxHeight: 600),
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
                    isEdit ? Icons.edit : Icons.person_add,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isEdit ? 'Modifier Utilisateur' : 'Créer Utilisateur',
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
                      CockpitInput(
                        label: 'Nom complet',
                        hint: 'Ex: Jean Dupont',
                        controller: _nameController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Le nom est requis';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
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
                                items: AppConstants.userRoles.map((role) {
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
                                    // Clear percentage if not an assistant role
                                    if (value != null && !AppConstants.assistantRoles.contains(value)) {
                                      _percentageController.clear();
                                    }
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
                        hint: 'Mot de passe de connexion',
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
                      
                      // Only show percentage for Assistant roles
                      if (_selectedRole != null && AppConstants.assistantRoles.contains(_selectedRole)) ...[
                        CockpitInput(
                          label: 'Pourcentage',
                          hint: 'Ex: 50',
                          controller: _percentageController,
                          keyboardType: TextInputType.number,
                          validator: (value) {
                            if (value != null && value.isNotEmpty) {
                              final num = double.tryParse(value);
                              if (num == null || num < 0 || num > 100) {
                                return 'Doit être entre 0 et 100';
                              }
                            }
                            return null;
                          },
                        ),
                        
                        const SizedBox(height: 12),
                        
                        Container(
                          padding: const EdgeInsets.all(12),
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
                                  'Le pourcentage est requis pour les assistants',
                                  style: MediCoreTypography.label.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
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
