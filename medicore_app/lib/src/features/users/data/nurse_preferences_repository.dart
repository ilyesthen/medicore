import 'package:shared_preferences/shared_preferences.dart';

/// Repository for storing nurse room preferences and tracking room usage
class NursePreferencesRepository {
  static const String _keyPrefix = 'nurse_room_prefs_';
  static const String _activeNursesKey = 'active_nurses';

  /// Get the room preferences for a nurse
  /// Returns a list of 3 room IDs (or nulls) representing which rooms to show in each box
  Future<List<String?>> getNurseRoomPreferences(String nurseId) async {
    final prefs = await SharedPreferences.getInstance();
    final room1 = prefs.getString('${_keyPrefix}${nurseId}_box1');
    final room2 = prefs.getString('${_keyPrefix}${nurseId}_box2');
    final room3 = prefs.getString('${_keyPrefix}${nurseId}_box3');
    return [room1, room2, room3];
  }

  /// Get all room IDs currently in use by any nurse
  Future<Set<String>> getRoomsInUse() async {
    final prefs = await SharedPreferences.getInstance();
    final activeNurses = prefs.getStringList(_activeNursesKey) ?? [];
    final roomsInUse = <String>{};

    for (final nurseId in activeNurses) {
      final rooms = await getNurseRoomPreferences(nurseId);
      roomsInUse.addAll(rooms.whereType<String>());
    }

    return roomsInUse;
  }

  /// Mark a nurse as active (logged in)
  Future<void> markNurseActive(String nurseId) async {
    final prefs = await SharedPreferences.getInstance();
    final activeNurses = prefs.getStringList(_activeNursesKey) ?? [];
    if (!activeNurses.contains(nurseId)) {
      activeNurses.add(nurseId);
      await prefs.setStringList(_activeNursesKey, activeNurses);
    }
  }

  /// Mark a nurse as inactive (logged out)
  Future<void> markNurseInactive(String nurseId) async {
    final prefs = await SharedPreferences.getInstance();
    final activeNurses = prefs.getStringList(_activeNursesKey) ?? [];
    activeNurses.remove(nurseId);
    await prefs.setStringList(_activeNursesKey, activeNurses);
  }

  /// Save room preferences for a nurse
  Future<void> saveNurseRoomPreferences(
    String nurseId,
    List<String?> roomIds,
  ) async {
    if (roomIds.length != 3) {
      throw ArgumentError('Must provide exactly 3 room IDs');
    }

    final prefs = await SharedPreferences.getInstance();
    
    for (int i = 0; i < 3; i++) {
      final key = '${_keyPrefix}${nurseId}_box${i + 1}';
      if (roomIds[i] != null) {
        await prefs.setString(key, roomIds[i]!);
      } else {
        await prefs.remove(key);
      }
    }
  }

  /// Clear preferences for a nurse
  Future<void> clearNurseRoomPreferences(String nurseId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('${_keyPrefix}${nurseId}_box1');
    await prefs.remove('${_keyPrefix}${nurseId}_box2');
    await prefs.remove('${_keyPrefix}${nurseId}_box3');
  }
}
