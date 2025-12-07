import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import '../../users/presentation/users_provider.dart';
import '../../users/data/models/user_model.dart';
import '../../../core/database/app_database.dart' show Room;
import '../../../core/constants/app_constants.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/repository/repository_provider.dart';
import '../../rooms/presentation/room_presence_provider.dart';
import '../../users/data/nurse_preferences_repository.dart';

/// Auth repository provider
/// TODO: When gRPC proto is properly generated, use remote repository for client mode
/// For now, both modes use local database (client will sync later)
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Both admin and client use local database for now
  // gRPC sync will be implemented when proto generation is fixed
  print('✓ AuthRepository using LOCAL database');
  return AuthRepository(ref.read(usersRepositoryProvider));
});

/// Auth state provider
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider), ref);
});

/// Authentication state
class AuthState {
  final bool isAuthenticated;
  final User? user;
  final Room? selectedRoom;
  final bool needsRoomSelection;
  final bool isLoading;
  final String? errorMessage;
  
  const AuthState({
    this.isAuthenticated = false,
    this.user,
    this.selectedRoom,
    this.needsRoomSelection = false,
    this.isLoading = false,
    this.errorMessage,
  });
  
  bool get isAdmin => user?.id == 'admin';
  
  /// Check if user requires room selection
  bool get requiresRoomSelection {
    if (user == null) return false;
    return user!.role == 'Médecin' || 
           AppConstants.assistantRoles.contains(user!.role);
  }
  
  AuthState copyWith({
    bool? isAuthenticated,
    User? user,
    Room? selectedRoom,
    bool? needsRoomSelection,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: user ?? this.user,
      selectedRoom: selectedRoom ?? this.selectedRoom,
      needsRoomSelection: needsRoomSelection ?? this.needsRoomSelection,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Auth state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;
  final Ref _ref;
  
  AuthNotifier(this._repository, this._ref) : super(const AuthState());
  
  /// Login with credentials
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      final result = await _repository.login(username, password);
      
      if (result.success && result.user != null) {
        final requiresRoom = result.user!.role == 'Médecin' || 
                             AppConstants.assistantRoles.contains(result.user!.role);
        
        // Mark nurse as active for room exclusivity
        if (result.user!.role == 'Infirmière' || result.user!.role == 'Infirmier') {
          try {
            final prefsRepo = NursePreferencesRepository();
            await prefsRepo.markNurseActive(result.user!.id);
          } catch (e) {
            print('⚠️ Failed to mark nurse active: $e');
          }
        }
        
        state = state.copyWith(
          isAuthenticated: true,
          user: result.user,
          needsRoomSelection: requiresRoom,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result.errorMessage ?? 'Connexion échouée',
        );
      }
    } catch (e) {
      print('❌ Login error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erreur de connexion: $e',
      );
    }
  }
  
  /// Set selected room for user
  void setRoom(Room room) {
    // Remove user from previous room if any
    if (state.selectedRoom != null && state.user != null) {
      _ref.read(roomPresenceProvider.notifier).removeUserFromRoom(
        state.selectedRoom!.id,
        state.user!.name,
      );
    }
    
    // Add user to new room
    if (state.user != null) {
      _ref.read(roomPresenceProvider.notifier).addUserToRoom(
        room.id,
        state.user!.name,
      );
    }
    
    state = state.copyWith(
      selectedRoom: room,
      needsRoomSelection: false,
    );
  }
  
  /// Logout current user
  Future<void> logout() async {
    // Remove user from all rooms
    if (state.user != null) {
      _ref.read(roomPresenceProvider.notifier).removeUserFromAllRooms(state.user!.name);
      
      // Mark nurse as inactive for room exclusivity
      if (state.user!.role == 'Infirmière' || state.user!.role == 'Infirmier') {
        final prefsRepo = NursePreferencesRepository();
        await prefsRepo.markNurseInactive(state.user!.id);
      }
    }
    
    await _repository.logout();
    state = const AuthState();
  }
}
