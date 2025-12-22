import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Simple stub for nurse preferences (room selections)
class NursePreferencesRepository {
  /// Save nurse room preferences
  Future<void> saveNurseRoomPreferences(String userId, List<String?> roomIds) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'nurse_rooms_$userId';
    await prefs.setStringList(key, roomIds.map((id) => id ?? '').toList());
  }

  /// Get nurse room preferences
  Future<List<String?>> getNurseRoomPreferences(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'nurse_rooms_$userId';
    final saved = prefs.getStringList(key);
    if (saved == null) return [null, null, null];
    return saved.map((s) => s.isEmpty ? null : s).toList();
  }

  /// Get rooms currently in use by other nurses
  Future<List<String>> getRoomsInUse() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('nurse_rooms_'));
    final roomsInUse = <String>[];
    for (final key in keys) {
      final rooms = prefs.getStringList(key) ?? [];
      roomsInUse.addAll(rooms.where((r) => r.isNotEmpty));
    }
    return roomsInUse;
  }
}
