import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import 'patients_provider.dart';
import '../core/types/proto_types.dart';

/// Dialog for creating or editing a patient
class PatientFormDialog extends ConsumerStatefulWidget {
  final Patient? patient;

  const PatientFormDialog({
    super.key,
    this.patient,
  });

  @override
  ConsumerState<PatientFormDialog> createState() => _PatientFormDialogState();
}

class _PatientFormDialogState extends ConsumerState<PatientFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otherInfoController = TextEditingController();

  final _firstNameFocus = FocusNode();
  final _lastNameFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _otherInfoFocus = FocusNode();

  DateTime? _dateOfBirth;
  bool _useAgeInput = true; // Toggle between age input and date of birth
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      _firstNameController.text = widget.patient!.firstName;
      _lastNameController.text = widget.patient!.lastName;
      _ageController.text = widget.patient!.age?.toString() ?? '';
      _addressController.text = widget.patient!.address ?? '';
      _phoneController.text = widget.patient!.phoneNumber ?? '';
      _otherInfoController.text = widget.patient!.otherInfo ?? '';
      _dateOfBirth = widget.patient!.dateOfBirth;
      _useAgeInput = widget.patient!.dateOfBirth == null;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _otherInfoController.dispose();
    _firstNameFocus.dispose();
    _lastNameFocus.dispose();
    _ageFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    _otherInfoFocus.dispose();
    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: MediCoreColors.professionalBlue,
              onPrimary: Colors.white,
              surface: MediCoreColors.paperWhite,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      setState(() {
        _dateOfBirth = date;
        // Calculate and display age
        final age = _calculateAge(date);
        _ageController.text = age.toString();
      });
    }
  }

  int _calculateAge(DateTime dateOfBirth) {
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Parse age input - accepts number or date format (dd/mm/yyyy or d/m/yyyy)
  /// Returns calculated age if date, or null if invalid
  int? _parseAgeInput(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    
    // First try as a number
    final directAge = int.tryParse(trimmed);
    if (directAge != null) return directAge;
    
    // Try parsing as date (dd/mm/yyyy or d/m/yyyy)
    final parts = trimmed.split('/');
    if (parts.length == 3) {
      final day = int.tryParse(parts[0]);
      final month = int.tryParse(parts[1]);
      final year = int.tryParse(parts[2]);
      
      if (day != null && month != null && year != null) {
        try {
          final dob = DateTime(year, month, day);
          if (dob.isBefore(DateTime.now())) {
            _dateOfBirth = dob;  // Store the date of birth
            return _calculateAge(dob);
          }
        } catch (_) {}
      }
    }
    
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final repository = ref.read(patientsRepositoryProvider);

    final age = _ageController.text.isEmpty 
        ? null 
        : int.tryParse(_ageController.text);

    // Parse age - could be number or date format
    final parsedAge = _parseAgeInput(_ageController.text);
    final finalAge = parsedAge ?? age;
    
    // Default address to "Batna" if empty
    final address = _addressController.text.trim().isEmpty 
        ? 'Batna' 
        : _addressController.text.trim();
    
    // Capture values before closing dialog
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final phone = _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim();
    final otherInfo = _otherInfoController.text.trim().isEmpty ? null : _otherInfoController.text.trim();
    final dateOfBirth = _dateOfBirth;
    
    if (widget.patient == null) {
      // CREATE: Close dialog IMMEDIATELY (no waiting)
      Navigator.of(context).pop(true);
      
      // Create in background - don't await
      repository.createPatient(
        firstName: firstName,
        lastName: lastName,
        age: finalAge,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phone,
        otherInfo: otherInfo,
      ).catchError((e) {
        print('❌ Create patient failed: $e');
      });
    } else {
      // UPDATE: Close dialog IMMEDIATELY (no waiting)
      Navigator.of(context).pop(true);
      
      // Update in background - don't await
      repository.updatePatient(
        code: widget.patient!.code,
        firstName: firstName,
        lastName: lastName,
        age: finalAge,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phone,
        otherInfo: otherInfo,
      ).catchError((e) {
        print('❌ Update patient failed: $e');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        // F1 to focus on other info
        const SingleActivator(LogicalKeyboardKey.f1): () {
          _otherInfoFocus.requestFocus();
        },
      },
      child: Focus(
        autofocus: true,
        child: Dialog(
          backgroundColor: MediCoreColors.paperWhite,
          child: Container(
            width: 600,
            constraints: const BoxConstraints(maxHeight: 700),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
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
                        widget.patient == null ? Icons.person_add : Icons.edit,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        widget.patient == null 
                            ? 'NOUVEAU PATIENT' 
                            : 'MODIFIER PATIENT',
                        style: MediCoreTypography.pageTitle.copyWith(
                          color: Colors.white,
                          fontSize: 20,
                        ),
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
                          // Last name (required) - moved first
                          _buildTextField(
                            controller: _lastNameController,
                            focusNode: _lastNameFocus,
                            label: 'Nom *',
                            isRequired: true,
                            nextFocus: _firstNameFocus,
                          ),

                          const SizedBox(height: 16),

                          // First name (required)
                          _buildTextField(
                            controller: _firstNameController,
                            focusNode: _firstNameFocus,
                            label: 'Prénom *',
                            isRequired: true,
                            nextFocus: _ageFocus,
                          ),

                          const SizedBox(height: 16),

                          // Age / Date of birth
                          Row(
                            children: [
                              Expanded(
                                child: _useAgeInput
                                    ? _buildTextField(
                                        controller: _ageController,
                                        focusNode: _ageFocus,
                                        label: 'Âge',
                                        keyboardType: TextInputType.number,
                                        nextFocus: _addressFocus,
                                      )
                                    : _buildDateField(),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _useAgeInput = !_useAgeInput;
                                  });
                                },
                                icon: Icon(
                                  _useAgeInput 
                                      ? Icons.calendar_today 
                                      : Icons.numbers,
                                  size: 16,
                                ),
                                label: Text(_useAgeInput ? 'Date' : 'Âge'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: MediCoreColors.professionalBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Address
                          _buildTextField(
                            controller: _addressController,
                            focusNode: _addressFocus,
                            label: 'Adresse',
                            nextFocus: _phoneFocus,
                          ),

                          const SizedBox(height: 16),

                          // Phone number
                          _buildTextField(
                            controller: _phoneController,
                            focusNode: _phoneFocus,
                            label: 'Téléphone',
                            keyboardType: TextInputType.phone,
                            nextFocus: _otherInfoFocus,
                          ),

                          const SizedBox(height: 16),

                          // Other info (multiline)
                          _buildTextField(
                            controller: _otherInfoController,
                            focusNode: _otherInfoFocus,
                            label: 'Autres informations (F1)',
                            maxLines: 4,
                            onSubmit: _submitForm,
                          ),

                          const SizedBox(height: 8),

                          // Required fields note
                          Text(
                            '* Champs obligatoires',
                            style: MediCoreTypography.label.copyWith(
                              color: Colors.grey[600],
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Actions
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: MediCoreColors.steelOutline,
                        width: 1,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting 
                            ? null 
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          'ANNULER',
                          style: MediCoreTypography.button.copyWith(
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MediCoreColors.professionalBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                widget.patient == null 
                                    ? 'CRÉER' 
                                    : 'ENREGISTRER',
                                style: MediCoreTypography.button,
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    bool isRequired = false,
    TextInputType? keyboardType,
    FocusNode? nextFocus,
    int maxLines = 1,
    VoidCallback? onSubmit,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: MediCoreTypography.body,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: MediCoreTypography.label,
        filled: true,
        fillColor: MediCoreColors.inputBackground,
        border: OutlineInputBorder(
          borderSide: const BorderSide(color: MediCoreColors.inputBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: MediCoreColors.inputBorder),
          borderRadius: BorderRadius.circular(4),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(
            color: MediCoreColors.professionalBlue,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: MediCoreColors.criticalRed),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      validator: isRequired
          ? (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Ce champ est obligatoire';
              }
              return null;
            }
          : null,
      onFieldSubmitted: (_) {
        if (onSubmit != null) {
          onSubmit();
        } else if (nextFocus != null) {
          nextFocus.requestFocus();
        }
      },
    );
  }

  Widget _buildDateField() {
    return InkWell(
      onTap: _selectDateOfBirth,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date de naissance',
          labelStyle: MediCoreTypography.label,
          filled: true,
          fillColor: MediCoreColors.inputBackground,
          border: OutlineInputBorder(
            borderSide: const BorderSide(color: MediCoreColors.inputBorder),
            borderRadius: BorderRadius.circular(4),
          ),
          suffixIcon: const Icon(Icons.calendar_today),
        ),
        child: Text(
          _dateOfBirth == null
              ? 'Sélectionner une date'
              : DateFormat('dd/MM/yyyy').format(_dateOfBirth!),
          style: MediCoreTypography.body.copyWith(
            color: _dateOfBirth == null ? Colors.grey : Colors.black,
          ),
        ),
      ),
    );
  }
}
