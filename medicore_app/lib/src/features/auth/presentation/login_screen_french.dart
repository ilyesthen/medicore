import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_input.dart';
import '../../../core/ui/cockpit_button.dart';
import 'auth_provider.dart';
import '../../users/presentation/users_provider.dart';
import '../../users/data/models/user_model.dart';
import '../../users/data/models/template_model.dart';
import '../../../core/types/proto_types.dart';

/// Professional French login screen with template support
class LoginScreenFrench extends ConsumerStatefulWidget {
  const LoginScreenFrench({super.key});

  @override
  ConsumerState<LoginScreenFrench> createState() => _LoginScreenFrenchState();
}

class _LoginScreenFrenchState extends ConsumerState<LoginScreenFrench> {
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  User? _selectedUser;
  UserTemplate? _selectedTemplate;
  bool _isAssistant = false;
  bool _isCreatingFromTemplate = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    setState(() => _errorMessage = null);
    
    if (_isAssistant) {
      // Template-based registration flow
      if (_selectedTemplate == null) {
        setState(() => _errorMessage = 'Veuillez sélectionner un modèle');
        return;
      }
      
      if (!_isCreatingFromTemplate) {
        // Show name input
        setState(() => _isCreatingFromTemplate = true);
        return;
      }
      
      // Validate name (at least 2 words)
      final name = _nameController.text.trim();
      final nameParts = name.split(RegExp(r'\s+'));
      if (nameParts.length < 2) {
        setState(() => _errorMessage = 'Le nom doit contenir au moins 2 mots');
        return;
      }
      
      // Create user from template (admin-only feature)
      try {
        // Templates only work in admin mode - use local repository directly
        final usersRepo = UsersRepository();
        final newUser = await usersRepo.createUserFromTemplate(
          templateId: _selectedTemplate!.id,
          userName: name,
        );
        
        // Refresh users list
        await ref.read(usersListProvider.notifier).loadUsers();
        
        // Auto-login the new user
        await ref.read(authStateProvider.notifier).login(
          newUser.name,
          newUser.password,
        );
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      }
    } else {
      // Normal login
      if (_selectedUser == null) {
        setState(() => _errorMessage = 'Veuillez sélectionner un utilisateur');
        return;
      }
      
      if (_passwordController.text.isEmpty) {
        setState(() => _errorMessage = 'Veuillez entrer le mot de passe');
        return;
      }
      
      await ref.read(authStateProvider.notifier).login(
        _selectedUser!.name,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final users = ref.watch(usersListProvider);
    final templates = ref.watch(templatesListProvider);

    return Scaffold(
      backgroundColor: MediCoreColors.canvasGrey,
      body: Center(
        child: Container(
          width: 500,
          constraints: const BoxConstraints(maxHeight: 700),
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: MediCoreColors.paperWhite,
            border: Border.all(
              color: MediCoreColors.steelOutline,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
                blurRadius: 12,
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: const BoxDecoration(
                    color: MediCoreColors.deepNavy,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'THAZIRI',
                        style: MediCoreTypography.pageTitle.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Système de Gestion Médicale',
                        style: MediCoreTypography.body.copyWith(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Title
                Text(
                  _isCreatingFromTemplate 
                      ? 'Créer Votre Compte'
                      : 'Connexion au Système',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    color: MediCoreColors.deepNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Assistant checkbox
                if (!_isCreatingFromTemplate)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MediCoreColors.canvasGrey,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MediCoreColors.steelOutline,
                      ),
                    ),
                    child: CheckboxListTile(
                      value: _isAssistant,
                      onChanged: (value) {
                        setState(() {
                          _isAssistant = value ?? false;
                          _selectedUser = null;
                          _selectedTemplate = null;
                          _errorMessage = null;
                        });
                      },
                      title: Text(
                        'Êtes-vous un assistant ?',
                        style: MediCoreTypography.label.copyWith(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      activeColor: MediCoreColors.professionalBlue,
                    ),
                  ),
                
                // Content based on flow
                if (!_isAssistant && !_isCreatingFromTemplate) ...[
                  // Normal user selection
                  Text(
                    'Sélectionnez votre nom',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: MediCoreColors.inputBackground,
                      border: Border.all(
                        color: MediCoreColors.inputBorder,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final isSelected = _selectedUser?.id == user.id;
                        
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedUser = user;
                              _errorMessage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? MediCoreColors.professionalBlue.withOpacity(0.1)
                                  : null,
                              border: Border(
                                bottom: BorderSide(
                                  color: MediCoreColors.inputBorder,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            child: Row(
                              children: [
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: MediCoreColors.professionalBlue,
                                    size: 18,
                                  ),
                                if (isSelected) const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user.name,
                                        style: MediCoreTypography.body.copyWith(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        user.role,
                                        style: MediCoreTypography.label.copyWith(
                                          fontSize: 11,
                                          color: MediCoreColors.professionalBlue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (user.isTemplateUser)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: MediCoreColors.warningOrange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${user.percentage?.toStringAsFixed(0)}%',
                                      style: MediCoreTypography.label.copyWith(
                                        fontSize: 10,
                                        color: MediCoreColors.warningOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    enabled: !authState.isLoading,
                    obscureText: true,
                    style: MediCoreTypography.inputField,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: MediCoreTypography.label,
                      filled: true,
                      fillColor: MediCoreColors.inputBackground,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: MediCoreColors.inputBorder,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: MediCoreColors.inputBorder,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: const BorderSide(
                          color: MediCoreColors.deepNavy,
                          width: 2,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _handleContinue(),
                  ),
                ] else if (_isAssistant && !_isCreatingFromTemplate) ...[
                  // Template selection
                  Text(
                    'Choisissez votre rôle',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 250,
                    decoration: BoxDecoration(
                      color: MediCoreColors.inputBackground,
                      border: Border.all(
                        color: MediCoreColors.inputBorder,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: templates.isEmpty
                        ? Center(
                            child: Text(
                              'Aucun modèle disponible',
                              style: MediCoreTypography.label.copyWith(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: templates.length,
                            itemBuilder: (context, index) {
                              final template = templates[index];
                              final isSelected = _selectedTemplate?.id == template.id;
                              
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedTemplate = template;
                                    _errorMessage = null;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? MediCoreColors.professionalBlue.withOpacity(0.1)
                                        : null,
                                    border: Border(
                                      bottom: BorderSide(
                                        color: MediCoreColors.inputBorder,
                                        width: 0.5,
                                      ),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      if (isSelected)
                                        const Icon(
                                          Icons.check_circle,
                                          color: MediCoreColors.professionalBlue,
                                          size: 18,
                                        ),
                                      if (isSelected) const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          template.role,
                                          style: MediCoreTypography.body.copyWith(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: MediCoreColors.warningOrange.withOpacity(0.2),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${template.percentage.toStringAsFixed(0)}%',
                                          style: MediCoreTypography.label.copyWith(
                                            fontSize: 11,
                                            color: MediCoreColors.warningOrange,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ] else if (_isCreatingFromTemplate) ...[
                  // Name input for template users
                  Text(
                    'Entrez votre nom complet',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
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
                            'Minimum 2 mots (ex: Jean Dupont)',
                            style: MediCoreTypography.label.copyWith(
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  CockpitInput(
                    label: 'Nom complet',
                    hint: 'Prénom Nom',
                    controller: _nameController,
                    enabled: true,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: MediCoreColors.professionalBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MediCoreColors.professionalBlue.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rôle sélectionné:',
                          style: MediCoreTypography.label.copyWith(
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedTemplate?.role ?? '',
                          style: MediCoreTypography.body.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: MediCoreColors.deepNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Error message
                if (_errorMessage != null || authState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MediCoreColors.criticalRed.withOpacity(0.1),
                      border: Border.all(
                        color: MediCoreColors.criticalRed,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: MediCoreColors.criticalRed,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage ?? authState.errorMessage ?? '',
                            style: MediCoreTypography.body.copyWith(
                              color: MediCoreColors.criticalRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Continue button
                SizedBox(
                  height: 44,
                  child: authState.isLoading
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
                          label: _isCreatingFromTemplate 
                              ? 'CRÉER LE COMPTE'
                              : 'CONTINUER',
                          icon: Icons.arrow_forward,
                          onPressed: _handleContinue,
                        ),
                ),
                
                // Back button for template flow
                if (_isCreatingFromTemplate) ...[
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _isCreatingFromTemplate = false;
                        _nameController.clear();
                        _errorMessage = null;
                      });
                    },
                    child: Text(
                      'Retour',
                      style: MediCoreTypography.body.copyWith(
                        color: MediCoreColors.professionalBlue,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
