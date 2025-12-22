import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/ui/data_grid.dart';
import '../../../core/ui/notification_badge.dart';
import '../../../core/utils/keyboard_shortcuts.dart';
import '../../patients/data/age_calculator_service.dart';
import '../../../core/api/realtime_sync_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../patients/presentation/patients_provider.dart';
import '../../patients/presentation/patient_form_dialog.dart';
import '../../messages/presentation/messages_provider.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../messages/presentation/receive_messages_dialog.dart';
import '../../messages/services/notification_service.dart';
import '../../honoraires/presentation/honoraires_dialog.dart';
import '../../comptabilite/presentation/comptabilite_dialog.dart';
import '../../consultation/presentation/patient_consultation_page.dart';
import '../../waiting_queue/presentation/waiting_queue_provider.dart';
import '../../waiting_queue/presentation/waiting_queue_dialog.dart';
import '../../waiting_queue/presentation/urgences_dialog.dart';
import '../../waiting_queue/presentation/dilatation_dialog.dart';
import '../../rooms/presentation/rooms_provider.dart';
import '../../appointments/presentation/appointments_dialog.dart';
import '../../surgery_planning/presentation/surgery_planning_dialog.dart';
import '../../../core/generated/medicore.pb.dart';

/// Doctor/Assistant dashboard with enterprise messaging integration
class DoctorDashboard extends ConsumerStatefulWidget {
  const DoctorDashboard({super.key});

  @override
  ConsumerState<DoctorDashboard> createState() => _DoctorDashboardState();
}

class _DoctorDashboardState extends ConsumerState<DoctorDashboard> {
  final NotificationService _notificationService = NotificationService();
  int _previousUnreadCount = 0;
  int _previousWaitingCount = -1; // Start at -1 to skip first load
  bool _hasPlayedLoginSound = false;

  @override
  void initState() {
    super.initState();
    _notificationService.initialize();
    
    // Register as doctor with SSE for real-time notifications
    RealtimeSyncService.instance.setUserRole('doctor');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    final userRole = authState.user?.role ?? '';
    final patientsAsync = ref.watch(filteredPatientsProvider);
    final selectedPatient = ref.watch(selectedPatientProvider);

    // Register selected room with SSE for targeted notifications
    if (selectedRoom != null) {
      RealtimeSyncService.instance.setActiveRooms([selectedRoom.id]);
    }

    // Watch unread message count for this doctor's room
    final unreadCountAsync = selectedRoom != null
        ? ref.watch(doctorUnreadCountProvider(selectedRoom.id))
        : const AsyncValue.data(0);

    // Watch waiting patients count for this room
    final waitingCountAsync = selectedRoom != null
        ? ref.watch(waitingCountProvider(selectedRoom.id))
        : const AsyncValue.data(0);
    final waitingCount = waitingCountAsync.valueOrNull ?? 0;

    // Watch urgent patients count for this room
    final urgentCountAsync = selectedRoom != null
        ? ref.watch(urgentCountProvider(selectedRoom.id))
        : const AsyncValue.data(0);
    final urgentCount = urgentCountAsync.valueOrNull ?? 0;

    // Watch dilatation count for this room
    final dilatationCountAsync = selectedRoom != null
        ? ref.watch(dilatationCountProvider(selectedRoom.id))
        : const AsyncValue.data(0);
    final dilatationCount = dilatationCountAsync.valueOrNull ?? 0;

    // Extract count value
    final currentCount = unreadCountAsync.asData?.value ?? 0;
    
    print('👨‍⚕️ DOCTOR DASHBOARD: Room = ${selectedRoom?.id}');
    print('👨‍⚕️ DOCTOR DASHBOARD: Unread count = $currentCount (previous: $_previousUnreadCount)');

    // Play notification sound when new message arrives OR on login with unread messages
    if (currentCount > 0) {
      // Play sound on login if there are unread messages
      if (!_hasPlayedLoginSound) {
        print('🔊 DOCTOR: Playing login sound for $currentCount unread messages');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notificationService.playNotificationSound();
        });
        _hasPlayedLoginSound = true;
        _previousUnreadCount = currentCount;
      }
      // Play sound when new message arrives
      else if (currentCount > _previousUnreadCount && _previousUnreadCount >= 0) {
        print('🔊 DOCTOR: Playing new message sound (count increased from $_previousUnreadCount to $currentCount)');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _notificationService.playNotificationSound();
        });
        _previousUnreadCount = currentCount;
      }
    } else if (currentCount == 0 && _previousUnreadCount > 0) {
      // All messages read - stop sound
      print('🔇 DOCTOR: All messages read, stopping sound');
      _notificationService.stopNotificationSound();
      _previousUnreadCount = currentCount;
    } else if (currentCount != _previousUnreadCount) {
      _previousUnreadCount = currentCount;
    }

    // Track waiting count (no sound for doctor - only messages trigger sounds)
    _previousWaitingCount = waitingCount;

    // Get patients list for keyboard navigation
    final patients = patientsAsync.asData?.value ?? [];
    
    return KeyboardShortcutHandler(
      onF1Pressed: () => _showPatientDialog(context, null),
      onF2Pressed: selectedRoom != null
          ? () => _showReceiveMessagesDialog(context, selectedRoom.id)
          : null,
      onF3Pressed: selectedRoom != null
          ? () => _showSendMessageDialog(context, selectedRoom.id)
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
                            userRole.toUpperCase(),
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

                  // Room indicator with change button
                  if (selectedRoom != null)
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: MediCoreColors.professionalBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: MediCoreColors.professionalBlue,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.meeting_room,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'SALLE ACTIVE',
                                      style: MediCoreTypography.label.copyWith(
                                        color: Colors.white.withOpacity(0.7),
                                        fontSize: 9,
                                      ),
                                    ),
                                    Text(
                                      selectedRoom.name,
                                      style: MediCoreTypography.button.copyWith(
                                        color: Colors.white,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          // Change room button
                          SizedBox(
                            width: double.infinity,
                            child: Material(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                              child: InkWell(
                                onTap: () => _showChangeRoomDialog(context, ref),
                                borderRadius: BorderRadius.circular(4),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.swap_horiz, color: Colors.white.withOpacity(0.9), size: 16),
                                      const SizedBox(width: 6),
                                      Text(
                                        'CHANGER DE SALLE',
                                        style: MediCoreTypography.label.copyWith(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 20),
                  const Divider(color: MediCoreColors.steelOutline, height: 1),

                  // Message buttons
                  if (selectedRoom != null) ...[
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
                          // Send Message Button (F3)
                          _MessageButton(
                            icon: Icons.send,
                            label: 'ENVOYER',
                            shortcut: 'F3',
                            color: MediCoreColors.healthyGreen,
                            onPressed: () => _showSendMessageDialog(context, selectedRoom.id),
                          ),
                          const SizedBox(height: 8),
                          // Receive Messages Button (F2) with badge
                          BadgedButton(
                            badgeCount: currentCount,
                            child: _MessageButton(
                              icon: Icons.inbox,
                              label: 'RECEVOIR',
                              shortcut: 'F2',
                              color: MediCoreColors.professionalBlue,
                              onPressed: () => _showReceiveMessagesDialog(context, selectedRoom.id),
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
                      ],
                    ),
                  ),

                  const Divider(color: MediCoreColors.steelOutline, height: 1),

                  // Honoraires and Comptabilité buttons
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
                          color: MediCoreColors.healthyGreen,
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
                  // Top single room box (height 300)
                  Container(
                    height: 300,
                    padding: const EdgeInsets.all(20),
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
                          // Room header
                          Container(
                            padding: const EdgeInsets.all(12),
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
                                  Icons.meeting_room,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  selectedRoom?.name.toUpperCase() ?? 'AUCUNE SALLE',
                                  style: MediCoreTypography.sectionHeader.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Horizontal stats
                          Expanded(
                            child: Row(
                              children: [
                                _HorizontalStatBox(
                                  icon: '📋',
                                  label: 'En attente consultation',
                                  count: waitingCount,
                                  color: const Color(0xFFF57C00), // Orange
                                  onTap: selectedRoom != null ? () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => WaitingQueueDialog(
                                        room: selectedRoom,
                                        isDoctor: true,
                                      ),
                                    );
                                  } : null,
                                ),
                                _HorizontalStatBox(
                                  icon: '💊',
                                  label: 'Dilatations',
                                  count: dilatationCount,
                                  color: MediCoreColors.healthyGreen,
                                  onTap: selectedRoom != null ? () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => DilatationDialog(
                                        roomIds: [selectedRoom.id],
                                        singleRoomId: selectedRoom.id,
                                        isDoctor: true,
                                      ),
                                    );
                                  } : null,
                                ),
                                _HorizontalStatBox(
                                  icon: '🚨',
                                  label: 'Urgences',
                                  count: urgentCount,
                                  color: MediCoreColors.criticalRed,
                                  isLast: true,
                                  onTap: selectedRoom != null ? () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => UrgencesDialog(
                                        room: selectedRoom,
                                        isDoctor: true,
                                      ),
                                    );
                                  } : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
      onRowDoubleTap: (index) {
        // Open consultation page on double-click
        final patient = patients[index];
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PatientConsultationPage(patient: patient),
          ),
        );
      },
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

  void _showSendMessageDialog(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (context) => SendMessageDialog(
        preSelectedRoomId: roomId,
      ),
    );
  }

  void _showReceiveMessagesDialog(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (context) => ReceiveMessagesDialog(
        doctorRoomId: roomId,
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

  void _showChangeRoomDialog(BuildContext context, WidgetRef ref) {
    final roomsAsync = ref.read(roomsListProvider);
    final currentRoom = ref.read(authStateProvider).selectedRoom;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: MediCoreColors.paperWhite,
        title: Row(
          children: [
            const Icon(Icons.swap_horiz, color: MediCoreColors.professionalBlue),
            const SizedBox(width: 8),
            Text('Changer de salle', style: MediCoreTypography.sectionHeader),
          ],
        ),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Salle actuelle: ${currentRoom?.name ?? "Aucune"}',
                style: MediCoreTypography.label.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              Text('Sélectionner une nouvelle salle:', style: MediCoreTypography.body),
              const SizedBox(height: 12),
              ...roomsAsync.map((room) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: room.id == currentRoom?.id 
                      ? MediCoreColors.professionalBlue.withOpacity(0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  child: InkWell(
                    onTap: room.id == currentRoom?.id ? null : () {
                      ref.read(authStateProvider.notifier).setRoom(room);
                      Navigator.of(context).pop();
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: room.id == currentRoom?.id 
                              ? MediCoreColors.professionalBlue 
                              : Colors.grey.shade300,
                          width: room.id == currentRoom?.id ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.meeting_room,
                            color: room.id == currentRoom?.id 
                                ? MediCoreColors.professionalBlue 
                                : Colors.grey[600],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              room.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: room.id == currentRoom?.id ? FontWeight.bold : FontWeight.normal,
                                color: room.id == currentRoom?.id 
                                    ? MediCoreColors.professionalBlue 
                                    : MediCoreColors.deepNavy,
                              ),
                            ),
                          ),
                          if (room.id == currentRoom?.id)
                            const Icon(Icons.check_circle, color: MediCoreColors.professionalBlue, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
            ],
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

/// Horizontal stat box widget
class _HorizontalStatBox extends StatelessWidget {
  final String icon;
  final String label;
  final int count;
  final Color color;
  final bool isLast;
  final VoidCallback? onTap;

  const _HorizontalStatBox({
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
              right: BorderSide(
                color: MediCoreColors.steelOutline,
                width: 1,
              ),
            ),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    icon,
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: MediCoreTypography.label.copyWith(
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  border: Border.all(
                    color: color,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  count.toString(),
                  style: MediCoreTypography.pageTitle.copyWith(
                    color: color,
                    fontSize: 24,
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
    // Initialize with current search value
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
