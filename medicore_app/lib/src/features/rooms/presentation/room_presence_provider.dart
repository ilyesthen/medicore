import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Tracks which users are currently in which rooms
/// Key: roomId, Value: List of user names in that room
class RoomPresenceNotifier extends StateNotifier<Map<String, List<String>>> {
  RoomPresenceNotifier() : super({});

  /// Add a user to a room
  void addUserToRoom(String roomId, String userName) {
    state = {
      ...state,
      roomId: [...(state[roomId] ?? []), userName],
    };
  }

  /// Remove a user from a room
  void removeUserFromRoom(String roomId, String userName) {
    if (!state.containsKey(roomId)) return;
    
    final updatedUsers = state[roomId]!.where((name) => name != userName).toList();
    
    if (updatedUsers.isEmpty) {
      final newState = Map<String, List<String>>.from(state);
      newState.remove(roomId);
      state = newState;
    } else {
      state = {
        ...state,
        roomId: updatedUsers,
      };
    }
  }

  /// Remove a user from all rooms
  void removeUserFromAllRooms(String userName) {
    final newState = <String, List<String>>{};
    
    state.forEach((roomId, users) {
      final filteredUsers = users.where((name) => name != userName).toList();
      if (filteredUsers.isNotEmpty) {
        newState[roomId] = filteredUsers;
      }
    });
    
    state = newState;
  }

  /// Get users in a specific room
  List<String> getUsersInRoom(String roomId) {
    return state[roomId] ?? [];
  }
}

/// Provider for room presence tracking
final roomPresenceProvider = StateNotifierProvider<RoomPresenceNotifier, Map<String, List<String>>>((ref) {
  return RoomPresenceNotifier();
});
