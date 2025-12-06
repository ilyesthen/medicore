import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../users/presentation/user_management_screen.dart';
import '../../rooms/presentation/room_management_screen.dart';
import '../../admin/presentation/import_patients_dialog.dart';

/// Admin dashboard with user, template, and room management
class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({super.key});

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  'Thaziri Admin',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: MediCoreColors.warningOrange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: MediCoreColors.warningOrange,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'ADMIN',
                    style: MediCoreTypography.label.copyWith(
                      color: MediCoreColors.warningOrange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
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
                        authState.user?.name.toUpperCase() ?? 'ADMIN',
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
                  tooltip: 'Déconnexion',
                  onPressed: () {
                    ref.read(authStateProvider.notifier).logout();
                  },
                ),
              ],
            ),
          ),
          
          // Tab bar
          Container(
            decoration: const BoxDecoration(
              color: MediCoreColors.paperWhite,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 2,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: MediCoreColors.deepNavy,
              unselectedLabelColor: MediCoreColors.professionalBlue,
              labelStyle: MediCoreTypography.button.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: MediCoreTypography.button.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              indicator: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.deepNavy,
                    width: 3,
                  ),
                ),
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.people),
                  text: 'UTILISATEURS & MODÈLES',
                ),
                Tab(
                  icon: Icon(Icons.meeting_room),
                  text: 'SALLES',
                ),
                Tab(
                  icon: Icon(Icons.upload_file),
                  text: 'IMPORTS',
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                const UserManagementScreen(),
                const RoomManagementScreen(),
                _buildImportsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImportsTab() {
    return Container(
      color: MediCoreColors.canvasGrey,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'IMPORTATION DE DONNÉES',
                style: MediCoreTypography.pageTitle.copyWith(
                  fontSize: 24,
                  color: MediCoreColors.deepNavy,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Importer des données depuis des fichiers XML',
                style: MediCoreTypography.body.copyWith(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Patients Import Card
              _buildImportCard(
                icon: Icons.people,
                title: 'IMPORTER PATIENTS',
                description: 'Importer la liste des patients depuis un fichier XML',
                color: MediCoreColors.professionalBlue,
                onPressed: () => _showImportPatientsDialog(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MediCoreColors.steelOutline,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(width: 20),
                
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: MediCoreTypography.sectionHeader.copyWith(
                          fontSize: 18,
                          color: MediCoreColors.deepNavy,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: MediCoreTypography.body.copyWith(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: color,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showImportPatientsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const ImportPatientsDialog(),
    );
  }
}
