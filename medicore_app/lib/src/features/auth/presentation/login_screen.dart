import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_input.dart';
import '../../../core/ui/cockpit_button.dart';
import 'auth_provider.dart';

/// Professional login screen with Cockpit design
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    if (_formKey.currentState?.validate() ?? false) {
      ref.read(authStateProvider.notifier).login(
        _usernameController.text,
        _passwordController.text,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: MediCoreColors.canvasGrey,
      body: Center(
        child: Container(
          width: 450,
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
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Deep Navy background
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 32),
                  decoration: const BoxDecoration(
                    color: MediCoreColors.deepNavy,
                  ),
                  child: Column(
                    children: [
                      Text(
                        'MediCore',
                        style: MediCoreTypography.pageTitle.copyWith(
                          color: Colors.white,
                          fontSize: 32,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Medical Management System',
                        style: MediCoreTypography.body.copyWith(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Login title
                Text(
                  'System Login',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    color: MediCoreColors.deepNavy,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 24),
                
                // Username field
                CockpitInput(
                  label: 'Username',
                  hint: 'Enter username',
                  controller: _usernameController,
                  enabled: !authState.isLoading,
                ),
                
                const SizedBox(height: 16),
                
                // Password field
                TextFormField(
                  controller: _passwordController,
                  enabled: !authState.isLoading,
                  obscureText: true,
                  style: MediCoreTypography.inputField,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: MediCoreTypography.label,
                    hintText: 'Enter password',
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
                        width: 1,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: const BorderSide(
                        color: MediCoreColors.inputBorder,
                        width: 1,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Password is required';
                    }
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                
                const SizedBox(height: 24),
                
                // Error message
                if (authState.errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: MediCoreColors.criticalRed.withOpacity(0.1),
                      border: Border.all(
                        color: MediCoreColors.criticalRed,
                        width: 1,
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
                            authState.errorMessage!,
                            style: MediCoreTypography.body.copyWith(
                              color: MediCoreColors.criticalRed,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Login button
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
                          label: 'LOGIN',
                          icon: Icons.login,
                          onPressed: _handleLogin,
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Hint text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: MediCoreColors.canvasGrey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Default Credentials:\nUsername: admin\nPassword: 1234',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 11,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
