import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/data_grid.dart';
import '../../../core/ui/notification_badge.dart';
import '../../../core/utils/keyboard_shortcuts.dart';
import '../../../core/database/app_database.dart';
import '../../patients/data/age_calculator_service.dart';
import '../../../core/api/realtime_sync_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../rooms/presentation/rooms_provider.dart';
import '../../rooms/presentation/room_presence_provider.dart';
import '../../users/data/nurse_preferences_repository.dart';
import '../../patients/presentation/patients_provider.dart';
import '../../patients/presentation/patient_form_dialog.dart';
import '../../messages/presentation/messages_provider.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../messages/presentation/receive_messages_dialog.dart';
import '../../messages/services/notification_service.dart';
import '../../honoraires/presentation/honoraires_dialog.dart';
import '../../comptabilite/presentation/comptabilite_dialog.dart';
import '../../waiting_queue/presentation/waiting_queue_provider.dart';
import '../../waiting_queue/presentation/send_patient_dialog.dart';
import '../../waiting_queue/presentation/waiting_queue_dialog.dart';
import '../../waiting_queue/presentation/send_urgent_dialog.dart';
import '../../waiting_queue/presentation/urgences_dialog.dart';
import '../../waiting_queue/presentation/dilatation_dialog.dart';
import '../../appointments/presentation/appointments_dialog.dart';
import '../../surgery_planning/presentation/surgery_planning_dialog.dart';
import '../../../core/generated/medicore.pb.dart';

/// Nurse dashboard with enterprise 3-room messaging integration
class NurseDashboard extends ConsumerStatefulWidget {
  const NurseDashboard({super.key});

  @override
  ConsumerState<NurseDashboard> createState() => _NurseDashboardState();
}

class _NurseDashboardState extends ConsumerState<NurseDashboard> {
  final _prefsRepo = NursePreferencesRepository();
  final NotificationService _notificationService = NotificationService();
  List<String?> _selectedRoomIds = [null, null, null];
  List<String> _activeRoomIds = [];  // Cached active room IDs for stable provider reference
  bool _isLoading = true;  // Start as true to load preferences first
  int _previousUnreadCount = 0;
  int _previousDilatationCount = -1; // Start at -1 to skip first load
  int _previousWaitingCount = -1; // Start at -1 to skip first load
  bool _hasPlayedLoginSound = false;
  bool _roomsInitialized = false;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    
    // Register as nurse with SSE for real-time notifications
    RealtimeSyncService.instance.setUserRole('nurse');
    
    // Load saved room preferences on startup
    _loadSavedRoomsOnStartup();
  }
  
  /// Load saved room preferences FIRST, then auto-assign if none saved
  Future<void> _loadSavedRoomsOnStartup() async {
    // Wait a bit for providers to initialize
    await Future.delayed(const Duration(milliseconds: 100));
    
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    print('🔵 NURSE: Loading saved room preferences for ${authState.user!.name}...');
    
    try {
      // Try to load saved preferences from database
      final savedPrefs = await _prefsRepo.getNurseRoomPreferences(authState.user!.id);
      
      if (savedPrefs.any((id) => id != null)) {
        // User has saved preferences - use them!
        print('✅ NURSE: Found saved room preferences: $savedPrefs');
        setState(() {
          _selectedRoomIds = savedPrefs;
          _roomsInitialized = true;
          _isLoading = false;
        });
        _updateActiveRoomIds();
        return;
      }
    } catch (e) {
      print('⚠️ NURSE: Could not load saved preferences: $e');
    }
    
    // No saved preferences - auto-assign first 3 rooms
    print('ℹ️ NURSE: No saved preferences, will auto-assign when rooms load');
    setState(() {
      _isLoading = false;
    });
  }

  void _initializeRooms() {
    if (_roomsInitialized) return;
    
    final authState = ref.read(authStateProvider);
    final allRooms = ref.read(roomsListProvider);
    
    if (authState.user != null && allRooms.isNotEmpty) {
      _roomsInitialized = true;
      
      // Check if we already have preferences loaded
      if (_selectedRoomIds.any((id) => id != null)) {
        print('✅ NURSE: Rooms already initialized from saved preferences');
        _updateActiveRoomIds();
        return;
      }
      
      // Auto-assign first 3 rooms as fallback
      final defaultIds = List.generate(
        3,
        (index) => index < allRooms.length ? allRooms[index].id : null,
      );
      print('✅ NURSE: Auto-assigned rooms (no saved prefs): $defaultIds');
      _selectedRoomIds = defaultIds;
      
      // Update cached active room IDs
      _updateActiveRoomIds();
      
      // Save these as the initial preferences
      _savePreferences();
    }
  }

  void _updateActiveRoomIds() {
    final newActiveIds = _selectedRoomIds.where((id) => id != null).cast<String>().toList();
    // Only update if actually changed to maintain stable reference
    if (_activeRoomIds.length != newActiveIds.length || 
        !_activeRoomIds.every((id) => newActiveIds.contains(id))) {
      if (mounted) {
        setState(() {
          _activeRoomIds = newActiveIds;
        });
      } else {
        _activeRoomIds = newActiveIds;
      }
      print('🔄 NURSE: Updated active room IDs: $_activeRoomIds');
      
      // Register active rooms with SSE for targeted notifications
      RealtimeSyncService.instance.setActiveRooms(newActiveIds);
    }
  }

  Future<void> _savePreferences() async {
    final authState = ref.read(authStateProvider);
    if (authState.user != null) {
      await _prefsRepo.saveNurseRoomPreferences(authState.user!.id, _selectedRoomIds);
      print('💾 NURSE: Saved room preferences: $_selectedRoomIds');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading while loading saved preferences
    if (_isLoading) {
      return Scaffold(
        backgroundColor: MediCoreColors.canvasGrey,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text('Chargement des préférences...', 
                style: MediCoreTypography.body.copyWith(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    
    final authState = ref.watch(authStateProvider);
    final allRooms = ref.watch(roomsListProvider);
    final roomPresence = ref.watch(roomPresenceProvider);
    final patientsAsync = ref.watch(filteredPatientsProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    // Initialize rooms BEFORE watching providers (only if no saved preferences were loaded)
    _initializeRooms();

    // Watch unread message count for nurse's 3 rooms using cached activeRoomIds
    final unreadCountAsync = _activeRoomIds.isNotEmpty
        ? ref.watch(nurseUnreadCountProvider(_activeRoomIds))
        : const AsyncValue.data(0);

    // Extract count value
    final currentCount = unreadCountAsync.asData?.value ?? 0;
    
    print('👩‍⚕️ NURSE DASHBOARD: activeRoomIds = $_activeRoomIds');
    print('👩‍⚕️ NURSE DASHBOARD: Unread count = $currentCount (previous: $_previousUnreadCount)');

    // Play notification sound when new message arrives OR on login with unread messages
    // This runs on every build when count changes
    if (currentCount > 0) {
      // Play sound on login if there are unread messages
      if (!_hasPlayedLoginSound) {
        print('🔊 NURSE: Playing login sound for $currentCount unread messages');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notificationService.playNotificationSound();
        });
        _hasPlayedLoginSound = true;
        _previousUnreadCount = currentCount;
      }
      // Play sound when new message arrives
      else if (currentCount > _previousUnreadCount && _previousUnreadCount >= 0) {
        print('🔊 NURSE: Playing new message sound (count increased from $_previousUnreadCount to $currentCount)');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notificationService.playNotificationSound();
        });
        _previousUnreadCount = currentCount;
      }
    } else if (currentCount == 0 && _previousUnreadCount > 0) {
      // All messages read - stop sound
      print('🔇 NURSE: All messages read, stopping sound');
      _notificationService.stopNotificationSound();
      _previousUnreadCount = currentCount;
    } else if (currentCount != _previousUnreadCount) {
      _previousUnreadCount = currentCount;
    }

    // Watch dilatation count across all nurse rooms
    final dilatationCountAsync = _activeRoomIds.isNotEmpty
        ? ref.watch(totalDilatationCountProvider(_activeRoomIds))
        : const AsyncValue.data(0);
    final dilatationCount = dilatationCountAsync.valueOrNull ?? 0;

    // Play notification sound ONLY when NEW dilatation arrives (not on login)
    if (_previousDilatationCount == -1) {
      // First load - just record the count, don't play sound
      _previousDilatationCount = dilatationCount;
    } else if (dilatationCount > _previousDilatationCount) {
      // New dilatation arrived - play sound
      print('🔊 NURSE: Playing new dilatation sound (count increased from $_previousDilatationCount to $dilatationCount)');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notificationService.playNotificationSound();
      });
      _previousDilatationCount = dilatationCount;
    } else if (dilatationCount == 0 && _previousDilatationCount > 0) {
      // All dilatations cleared - stop sound
      print('🔇 NURSE: All dilatations cleared, stopping sound');
      _notificationService.stopNotificationSound();
      _previousDilatationCount = dilatationCount;
    } else if (dilatationCount != _previousDilatationCount) {
      _previousDilatationCount = dilatationCount;
    }

    // Track waiting count (no sound for nurse waiting patients - only messages and dilatations)
    // The totalWaitingCountProvider is still used for UI display purposes

    // Get rooms for display
    final displayRooms = _selectedRoomIds.map((roomId) {
      if (roomId == null) return null;
      try {
        return allRooms.firstWhere((r) => r.id == roomId);
      } catch (e) {
        return null;
      }
    }).toList();

    // Get patients list for keyboard navigation
    final patients = patientsAsync.asData?.value ?? [];
    
    return KeyboardShortcutHandler(
      onF1Pressed: () => _showPatientDialog(context, null),
      onF2Pressed: _activeRoomIds.isNotEmpty
          ? () => _showReceiveMessagesDialog(context, _activeRoomIds)
          : null,
      onF3Pressed: _activeRoomIds.isNotEmpty
          ? () => _showSendMessageDialog(context, _activeRoomIds)
          : null,
      onF5Pressed: () => _showComptabiliteDialog(context),
      onArrowUpPressed: () => _navigatePatients(patients, -1),
      onArrowDownPressed: () => _navigatePatients(patients, 1),
      child: Scaffold(
        backgroundColor: MediCoreColors.canvasGrey,
        body: Row(
          children: [
            // Left panel - full height
            Container(
              width: 280,
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                border: Border(
                  right: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: MediCoreColors.steelOutline,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'THAZIRI',
                          style: MediCoreTypography.pageTitle.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: MediCoreColors.professionalBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'INFIRMIÈRE',
                            style: MediCoreTypography.label.copyWith(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // User info
                  Container(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.account_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                authState.user?.name ?? 'Utilisateur',
                                style: MediCoreTypography.sectionHeader.copyWith(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                authState.user?.role ?? '',
                                style: MediCoreTypography.label.copyWith(
                                  color: Colors.white.withOpacity(0.7),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: MediCoreColors.steelOutline, height: 1),

                  // Message buttons
                  if (_activeRoomIds.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'MESSAGERIE',
                            style: MediCoreTypography.label.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Send Message Button (F3) - Nurse chooses room
                          _MessageButton(
                            icon: Icons.send,
                            label: 'ENVOYER',
                            shortcut: 'F3',
                            color: MediCoreColors.healthyGreen,
                            onPressed: () => _showSendMessageDialog(context, _activeRoomIds),
                          ),
                          const SizedBox(height: 8),
                          // Receive Messages Button (F2) with badge - Shows total count from all 3 rooms
                          BadgedButton(
                            badgeCount: currentCount,
                            child: _MessageButton(
                              icon: Icons.inbox,
                              label: 'RECEVOIR',
                              shortcut: 'F2',
                              color: MediCoreColors.professionalBlue,
                              onPressed: () => _showReceiveMessagesDialog(context, _activeRoomIds),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Dilatation button with badge
                          Text(
                            'DILATATIONS',
                            style: MediCoreTypography.label.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 10,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          BadgedButton(
                            badgeCount: dilatationCount,
                            badgeColor: MediCoreColors.healthyGreen,
                            child: _MessageButton(
                              icon: Icons.opacity,
                              label: '💊 DILATATIONS',
                              shortcut: '',
                              color: MediCoreColors.healthyGreen,
                              onPressed: () => _showDilatationDialog(context, _activeRoomIds),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(color: MediCoreColors.steelOutline, height: 1),
                  ],

                  // Patient action buttons
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'ACTIONS PATIENT',
                          style: MediCoreTypography.label.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          icon: Icons.person_add,
                          label: 'NOUVEAU',
                          shortcut: 'F1',
                          onPressed: () => _showPatientDialog(context, null),
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.edit,
                          label: 'MODIFIER',
                          isEnabled: selectedPatient != null,
                          onPressed: selectedPatient != null
                              ? () => _showPatientDialog(context, selectedPatient)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.delete,
                          label: 'SUPPRIMER',
                          color: MediCoreColors.criticalRed,
                          isEnabled: selectedPatient != null,
                          onPressed: selectedPatient != null
                              ? () => _confirmDelete(context, selectedPatient)
                              : null,
                        ),
                        const SizedBox(height: 16),
                        // Urgence button
                        _ActionButton(
                          icon: Icons.warning_amber,
                          label: '🚨 URGENCE',
                          color: MediCoreColors.criticalRed,
                          isEnabled: selectedPatient != null && displayRooms.any((r) => r != null),
                          onPressed: selectedPatient != null && displayRooms.any((r) => r != null)
                              ? () => _showSendUrgentDialog(context, selectedPatient, displayRooms)
                              : null,
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: MediCoreColors.steelOutline, height: 1),

                  // Honoraires button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'GESTION',
                          style: MediCoreTypography.label.copyWith(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 10,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _ActionButton(
                          icon: Icons.monetization_on,
                          label: 'HONORAIRES',
                          color: MediCoreColors.professionalBlue,
                          onPressed: () => _showHonorairesDialog(context),
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.account_balance_wallet,
                          label: 'COMPTABILITÉ',
                          color: MediCoreColors.professionalBlue,
                          onPressed: () => _showComptabiliteDialog(context),
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.calendar_month,
                          label: 'RENDEZ-VOUS',
                          color: const Color(0xFF9C27B0),
                          onPressed: () => _showAppointmentsDialog(context),
                        ),
                        const SizedBox(height: 8),
                        _ActionButton(
                          icon: Icons.medical_services,
                          label: 'PROGRAMME OP',
                          color: const Color(0xFF1565C0),
                          onPressed: () => _showSurgeryPlanningDialog(context),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Logout button
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ref.read(authStateProvider.notifier).logout();
                        },
                        icon: const Icon(Icons.logout, size: 18),
                        label: const Text('DÉCONNEXION'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MediCoreColors.criticalRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Column(
                children: [
                  // Top 3 room boxes (height 300)
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: displayRooms.asMap().entries.map((entry) {
                        final index = entry.key;
                        final room = entry.value;
                        final isLast = index == displayRooms.length - 1;
                        final usersInRoom = room != null
                            ? (roomPresence[room.id] ?? <String>[]).cast<String>()
                            : <String>[];

                        return Expanded(
                          child: Container(
                            margin: EdgeInsets.only(right: isLast ? 0 : 16),
                            child: _RoomBox(
                              room: room,
                              roomName: room?.name ?? 'Pas de salle',
                              isActive: room != null,
                              usersInRoom: usersInRoom,
                              onChangeRoom: () => _showRoomSelector(index, allRooms),
                              selectedPatient: selectedPatient,
                              currentUserId: authState.user?.id ?? '',
                              currentUserName: authState.user?.name ?? '',
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Patient table
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: MediCoreColors.paperWhite,
                          border: Border.all(
                            color: MediCoreColors.steelOutline,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Table header with search
                            Container(
                              padding: const EdgeInsets.all(16),
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
                                  const Icon(
                                    Icons.people,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'LISTE DES PATIENTS',
                                    style: MediCoreTypography.sectionHeader.copyWith(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _SearchBar(),
                                  ),
                                  const SizedBox(width: 12),
                                  _SortToggleButton(),
                                ],
                              ),
                            ),

                            // Pagination controls
                            _PaginationControls(),

                            // Patient data grid
                            Expanded(
                              child: patientsAsync.when(
                                data: (patients) => _buildPatientTable(patients),
                                loading: () => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                error: (error, stack) => Center(
                                  child: Text('Erreur: $error'),
                                ),
                              ),
                            ),
                          ],
                        ),
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

  Widget _buildPatientTable(List<Patient> patients) {
    final rows = patients.map((patient) {
      final createdDate = DateFormat('dd/MM/yyyy').format(patient.createdAt);
      return [
        patient.code.toString(),
        createdDate,
        patient.lastName,
        patient.firstName,
        patient.currentAge?.toString() ?? '-',
        patient.address ?? '-',
      ];
    }).toList();

    final selectedPatient = ref.watch(selectedPatientProvider);
    final selectedIndex = selectedPatient != null
        ? patients.indexWhere((p) => p.code == selectedPatient.code)
        : null;

    return DataGrid(
      headers: const [
        'N°',
        'CRÉÉ LE',
        'NOM',
        'PRÉNOM',
        'ÂGE',
        'ADRESSE',
      ],
      rows: rows,
      selectedRowIndex: selectedIndex,
      onRowTap: (index) {
        ref.read(selectedPatientProvider.notifier).state = patients[index];
      },
    );
  }

  Future<void> _showRoomSelector(int boxIndex, List<Room> allRooms) async {
    // Get rooms currently in use by other nurses
    final roomsInUse = await _prefsRepo.getRoomsInUse();
    final authState = ref.read(authStateProvider);

    // Remove current nurse's rooms from "in use" list
    if (authState.user != null) {
      final myRooms = await _prefsRepo.getNurseRoomPreferences(authState.user!.id);
      roomsInUse.removeAll(myRooms.whereType<String>());
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MediCoreColors.paperWhite,
        title: Text(
          'Choisir salle pour Box ${boxIndex + 1}',
          style: MediCoreTypography.sectionHeader,
        ),
        content: SizedBox(
          width: 400,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: allRooms.length,
            itemBuilder: (context, index) {
              final room = allRooms[index];
              final isSelectedByMe = _selectedRoomIds
                  .asMap()
                  .entries
                  .where((e) => e.key != boxIndex)
                  .any((e) => e.value == room.id);

              final isInUseByOthers = roomsInUse.contains(room.id);
              final isDisabled = isSelectedByMe || isInUseByOthers;

              return ListTile(
                enabled: !isDisabled,
                leading: Icon(
                  Icons.meeting_room,
                  color: isDisabled ? Colors.grey : MediCoreColors.professionalBlue,
                ),
                title: Text(
                  room.name,
                  style: MediCoreTypography.body.copyWith(
                    color: isDisabled ? Colors.grey : Colors.black,
                  ),
                ),
                trailing: isSelectedByMe
                    ? Text(
                        'Déjà sélectionnée',
                        style: MediCoreTypography.label.copyWith(
                          color: Colors.grey,
                          fontSize: 11,
                        ),
                      )
                    : isInUseByOthers
                        ? Text(
                            'Utilisée par autre infirmière',
                            style: MediCoreTypography.label.copyWith(
                              color: Colors.orange,
                              fontSize: 11,
                            ),
                          )
                        : null,
                onTap: () {
                  setState(() {
                    _selectedRoomIds[boxIndex] = room.id;
                  });
                  _updateActiveRoomIds();
                  _savePreferences();
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
        ],
      ),
    );
  }

  /// Navigate up/down in patient list using arrow keys
  void _navigatePatients(List<Patient> patients, int direction) {
    if (patients.isEmpty) return;
    
    final currentSelected = ref.read(selectedPatientProvider);
    int currentIndex = currentSelected != null 
        ? patients.indexWhere((p) => p.code == currentSelected.code)
        : -1;
    
    int newIndex;
    if (currentIndex == -1) {
      // No selection - select first or last based on direction
      newIndex = direction > 0 ? 0 : patients.length - 1;
    } else {
      // Move in direction
      newIndex = (currentIndex + direction).clamp(0, patients.length - 1);
    }
    
    ref.read(selectedPatientProvider.notifier).state = patients[newIndex];
  }

  void _showPatientDialog(BuildContext context, Patient? patient) {
    showDialog(
      context: context,
      builder: (context) => PatientFormDialog(patient: patient),
    ).then((result) {
      if (result == true) {
        ref.read(selectedPatientProvider.notifier).state = null;
      }
    });
  }

  void _showSendMessageDialog(BuildContext context, List<String> roomIds) {
    showDialog(
      context: context,
      builder: (context) => SendMessageDialog(
        availableRoomIds: roomIds, // Nurse chooses which room to send to
      ),
    );
  }

  void _showReceiveMessagesDialog(BuildContext context, List<String> roomIds) {
    showDialog(
      context: context,
      builder: (context) => ReceiveMessagesDialog(
        nurseRoomIds: roomIds, // Shows all 3 rooms
      ),
    );
  }

  void _showHonorairesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const HonorairesDialog(),
    );
  }

  void _showComptabiliteDialog(BuildContext context) {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const ComptabiliteDialog(),
    ).then((result) {
      if (result != null && result.containsKey('patientName')) {
        // Set the search filter to the patient name
        final patientName = result['patientName'] as String;
        ref.read(patientSearchProvider.notifier).state = patientName;
        ref.read(currentPageProvider.notifier).state = 0;
      }
    });
  }

  void _showAppointmentsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const AppointmentsDialog(),
    );
  }

  void _showSurgeryPlanningDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SurgeryPlanningDialog(),
    );
  }

  void _showSendUrgentDialog(BuildContext context, Patient patient, List<Room?> rooms) {
    final authState = ref.read(authStateProvider);
    final availableRooms = rooms.whereType<Room>().toList();
    if (availableRooms.isEmpty) return;
    
    showDialog(
      context: context,
      builder: (context) => SendUrgentDialog(
        patient: patient,
        availableRooms: availableRooms,
        currentUserId: authState.user?.id ?? '',
        currentUserName: authState.user?.name ?? '',
      ),
    );
  }

  void _showDilatationDialog(BuildContext context, List<String> roomIds) async {
    // Stop notification sound immediately
    _notificationService.stopNotificationSound();
    
    // Mark all dilatations as notified (clears badge)
    final repo = ref.read(waitingQueueRepositoryProvider);
    await repo.markDilatationsAsNotified(roomIds);
    
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => DilatationDialog(
        roomIds: roomIds,
        isDoctor: false,
      ),
    );
  }

  void _confirmDelete(BuildContext context, Patient patient) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MediCoreColors.paperWhite,
        title: Text(
          'Confirmer la suppression',
          style: MediCoreTypography.sectionHeader,
        ),
        content: Text(
          'Voulez-vous vraiment supprimer le patient ${patient.firstName} ${patient.lastName} ?',
          style: MediCoreTypography.body,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('ANNULER'),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(patientsRepositoryProvider).deletePatient(patient.code);
              ref.read(selectedPatientProvider.notifier).state = null;
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MediCoreColors.criticalRed,
            ),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
  }
}

/// Individual room box widget
class _RoomBox extends ConsumerWidget {
  final Room? room;
  final String roomName;
  final bool isActive;
  final List<String> usersInRoom;
  final VoidCallback onChangeRoom;
  final Patient? selectedPatient;
  final String currentUserId;
  final String currentUserName;

  const _RoomBox({
    required this.room,
    required this.roomName,
    required this.isActive,
    required this.usersInRoom,
    required this.onChangeRoom,
    required this.selectedPatient,
    required this.currentUserId,
    required this.currentUserName,
  });

  void _showSendPatientDialog(BuildContext context) {
    if (room == null || selectedPatient == null) return;
    showDialog(
      context: context,
      builder: (context) => SendPatientDialog(
        patient: selectedPatient!,
        room: room!,
        currentUserId: currentUserId,
        currentUserName: currentUserName,
      ),
    );
  }

  void _showWaitingQueueDialog(BuildContext context) {
    if (room == null) return;
    showDialog(
      context: context,
      builder: (context) => WaitingQueueDialog(room: room!, isDoctor: false),
    );
  }

  void _showUrgencesDialog(BuildContext context) {
    if (room == null) return;
    showDialog(
      context: context,
      builder: (context) => UrgencesDialog(room: room!, isDoctor: false),
    );
  }

  void _showRoomDilatationDialog(BuildContext context, WidgetRef ref) async {
    if (room == null) return;
    
    // Stop notification sound immediately
    NotificationService().stopNotificationSound();
    
    // Mark dilatations as notified for this room
    final repo = ref.read(waitingQueueRepositoryProvider);
    await repo.markDilatationsAsNotified([room!.id]);
    
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (context) => DilatationDialog(
        roomIds: [room!.id],
        singleRoomId: room!.id,
        isDoctor: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final waitingCountAsync = room != null 
        ? ref.watch(waitingCountProvider(room!.id))
        : const AsyncValue<int>.data(0);
    final waitingCount = waitingCountAsync.valueOrNull ?? 0;

    final urgentCountAsync = room != null 
        ? ref.watch(urgentCountProvider(room!.id))
        : const AsyncValue<int>.data(0);
    final urgentCount = urgentCountAsync.valueOrNull ?? 0;

    final dilatationCountAsync = room != null 
        ? ref.watch(dilatationCountProvider(room!.id))
        : const AsyncValue<int>.data(0);
    final roomDilatationCount = dilatationCountAsync.valueOrNull ?? 0;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? MediCoreColors.paperWhite : MediCoreColors.canvasGrey,
        border: Border.all(
          color: isActive
              ? MediCoreColors.steelOutline
              : MediCoreColors.steelOutline.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Room name header with users
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? MediCoreColors.deepNavy
                  : MediCoreColors.deepNavy.withOpacity(0.5),
              border: const Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      isActive ? Icons.meeting_room : Icons.meeting_room_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        roomName.toUpperCase(),
                        style: MediCoreTypography.button.copyWith(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    // Send patient button
                    if (isActive && selectedPatient != null)
                      Tooltip(
                        message: 'Envoyer ${selectedPatient!.firstName}',
                        child: InkWell(
                          onTap: () => _showSendPatientDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: MediCoreColors.healthyGreen,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.send, color: Colors.white, size: 12),
                                SizedBox(width: 4),
                                Text('ENVOYER', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.white, size: 16),
                      onPressed: onChangeRoom,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                // Show logged-in users
                if (usersInRoom.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: MediCoreColors.healthyGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: usersInRoom.map((userName) {
                        return Row(
                          children: [
                            const Icon(Icons.person, color: MediCoreColors.healthyGreen, size: 12),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                userName,
                                style: MediCoreTypography.label.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Stats boxes
          Expanded(
            child: Column(
              children: [
                _StatBox(
                  icon: '📋',
                  label: 'En attente consultation',
                  count: waitingCount,
                  color: const Color(0xFFF57C00), // Orange
                  onTap: isActive ? () => _showWaitingQueueDialog(context) : null,
                ),
                _StatBox(
                  icon: '💊',
                  label: 'Dilatation',
                  count: roomDilatationCount,
                  color: MediCoreColors.healthyGreen,
                  onTap: isActive ? () => _showRoomDilatationDialog(context, ref) : null,
                ),
                _StatBox(
                  icon: '🚨',
                  label: 'Urgences',
                  count: urgentCount,
                  color: MediCoreColors.criticalRed,
                  isLast: true,
                  onTap: isActive ? () => _showUrgencesDialog(context) : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Stat box widget
class _StatBox extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final Color color;
  final bool isLast;
  final VoidCallback? onTap;

  const _StatBox({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.isLast = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: isLast ? null : const Border(
              bottom: BorderSide(
                color: MediCoreColors.steelOutline,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: MediCoreTypography.label.copyWith(
                    fontSize: 10,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  count.toString(),
                  style: MediCoreTypography.button.copyWith(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Message button widget with shortcut indicator
class _MessageButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String shortcut;
  final Color color;
  final VoidCallback onPressed;

  const _MessageButton({
    required this.icon,
    required this.label,
    required this.shortcut,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: MediCoreTypography.button.copyWith(fontSize: 12),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                shortcut,
                style: MediCoreTypography.label.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Action button widget for left panel
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? shortcut;
  final VoidCallback? onPressed;
  final Color? color;
  final bool isEnabled;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.shortcut,
    required this.onPressed,
    this.color,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color ?? MediCoreColors.professionalBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[700],
          disabledForegroundColor: Colors.grey[500],
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: MediCoreTypography.button.copyWith(fontSize: 12),
              ),
            ),
            if (shortcut != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  shortcut!,
                  style: MediCoreTypography.label.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Search bar widget with debouncing for performance
class _SearchBar extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends ConsumerState<_SearchBar> {
  Timer? _debounceTimer;
  final _controller = TextEditingController();
  bool _isUpdatingFromProvider = false;

  @override
  void initState() {
    super.initState();
    _controller.text = '';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    if (_isUpdatingFromProvider) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(patientSearchProvider.notifier).state = value;
      ref.read(currentPageProvider.notifier).state = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen to search provider changes (e.g., from comptabilité click)
    final searchValue = ref.watch(patientSearchProvider);
    if (_controller.text != searchValue) {
      _isUpdatingFromProvider = true;
      _controller.text = searchValue;
      _controller.selection = TextSelection.collapsed(offset: searchValue.length);
      _isUpdatingFromProvider = false;
    }

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onChanged: _onSearchChanged,
              style: MediCoreTypography.body.copyWith(
                color: Colors.white,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: 'Rechercher: Nom, Prénom ou Code...',
                hintStyle: MediCoreTypography.body.copyWith(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          // Clear button when search is active
          if (searchValue.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, color: Colors.white.withOpacity(0.7), size: 18),
              onPressed: () {
                _controller.clear();
                ref.read(patientSearchProvider.notifier).state = '';
                ref.read(currentPageProvider.notifier).state = 0;
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
        ],
      ),
    );
  }
}

/// Pagination controls widget
class _PaginationControls extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPage = ref.watch(currentPageProvider);
    final totalPages = ref.watch(totalPagesProvider);
    final totalPatients = ref.watch(totalPatientsProvider);
    final pageSize = ref.watch(pageSizeProvider);

    final startPatient = (currentPage * pageSize) + 1;
    final endPatient = ((currentPage + 1) * pageSize).clamp(1, totalPatients);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border(
          bottom: BorderSide(
            color: MediCoreColors.steelOutline,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Patients $startPatient-$endPatient sur $totalPatients',
            style: MediCoreTypography.label.copyWith(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: currentPage > 0
                ? () {
                    ref.read(currentPageProvider.notifier).state = currentPage - 1;
                    ref.read(selectedPatientProvider.notifier).state = null;
                  }
                : null,
            icon: const Icon(Icons.chevron_left),
            iconSize: 20,
            color: currentPage > 0 ? MediCoreColors.professionalBlue : Colors.grey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          Text(
            'Page ${currentPage + 1} / $totalPages',
            style: MediCoreTypography.button.copyWith(
              fontSize: 12,
              color: MediCoreColors.deepNavy,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            onPressed: currentPage < totalPages - 1
                ? () {
                    ref.read(currentPageProvider.notifier).state = currentPage + 1;
                    ref.read(selectedPatientProvider.notifier).state = null;
                  }
                : null,
            icon: const Icon(Icons.chevron_right),
            iconSize: 20,
            color: currentPage < totalPages - 1 ? MediCoreColors.professionalBlue : Colors.grey,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

/// Sort toggle button for patient list
class _SortToggleButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final oldestFirst = ref.watch(patientSortOldestFirstProvider);
    
    return Tooltip(
      message: oldestFirst ? 'Trier: Anciens en premier' : 'Trier: Récents en premier',
      child: InkWell(
        onTap: () {
          ref.read(patientSortOldestFirstProvider.notifier).state = !oldestFirst;
          ref.read(currentPageProvider.notifier).state = 0;
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                oldestFirst ? Icons.arrow_upward : Icons.arrow_downward,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                oldestFirst ? 'Ancien → Récent' : 'Récent → Ancien',
                style: MediCoreTypography.label.copyWith(
                  color: Colors.white,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
