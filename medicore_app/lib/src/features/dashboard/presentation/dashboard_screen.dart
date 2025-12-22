import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/cockpit_pane.dart';
import '../../auth/presentation/auth_provider.dart';
import '../core/types/proto_types.dart';

/// Main dashboard screen - shows after login
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return Scaffold(
      backgroundColor: MediCoreColors.canvasGrey,
      body: Column(
        children: [
          // Top header bar
          Container(
            height: 60,
            decoration: const BoxDecoration(
              color: MediCoreColors.deepNavy,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // App title
                Text(
                  'Thaziri',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                  ),
                ),
                
                const Spacer(),
                
                // User info
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: MediCoreColors.professionalBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: MediCoreColors.professionalBlue,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        authState.user?.name.toUpperCase() ?? 'USER',
                        style: MediCoreTypography.button.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Logout button
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: Center(
              child: Container(
                width: 600,
                height: 400,
                margin: const EdgeInsets.all(40),
                child: CockpitPane(
                  title: 'Welcome Dashboard',
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Welcome icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: MediCoreColors.healthyGreen.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: MediCoreColors.healthyGreen,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            size: 48,
                            color: MediCoreColors.healthyGreen,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Main message
                        Text(
                          'Hi Boss! 👋',
                          style: MediCoreTypography.pageTitle.copyWith(
                            color: MediCoreColors.deepNavy,
                            fontSize: 36,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Subtitle
                        Text(
                          'System is ready for your command',
                          style: MediCoreTypography.body.copyWith(
                            color: MediCoreColors.professionalBlue,
                            fontSize: 16,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Status indicator
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: MediCoreColors.canvasGrey,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: MediCoreColors.steelOutline,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: MediCoreColors.healthyGreen,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'All Systems Operational',
                                style: MediCoreTypography.body.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
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
            ),
          ),
        ],
      ),
    );
  }
}
