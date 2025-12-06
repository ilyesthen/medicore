import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../rooms/presentation/room_selection_screen.dart';
import '../../rooms/presentation/rooms_provider.dart';
import '../../dashboard/presentation/nurse_dashboard.dart';
import '../../dashboard/presentation/doctor_dashboard.dart';
import 'auth_provider.dart';

/// Wrapper that shows room selection screen BEFORE dashboard
class RoomSelectionWrapper extends ConsumerWidget {
  const RoomSelectionWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    // Load rooms in background
    ref.watch(roomsListProvider);
    
    // If user needs to select a room, show selection screen
    if (authState.needsRoomSelection) {
      return const RoomSelectionScreen();
    }
    
    // Otherwise route to appropriate dashboard based on role
    final userRole = authState.user?.role ?? '';
    
    if (userRole == 'Infirmière' || userRole == 'Infirmier') {
      return const NurseDashboard();
    } else if (userRole == 'Médecin' || AppConstants.assistantRoles.contains(userRole)) {
      return const DoctorDashboard();
    }
    
    // Fallback
    return const NurseDashboard();
  }
}
