import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/database/app_database.dart';

/// Repository for storing nurse room preferences and tracking room usage
/// Preferences are stored in the database so they persist per nurse across all machines
class NursePreferencesRepository {
  static const String _activeNursesKey = 'active_nurses';
  static bool _tableCreated = false;

  /// Ensure the nurse_preferences table exists
  Future<void> _ensureTableExists() async {
    if (_tableCreated) return;
    final db = AppDatabase.instance;
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS nurse_preferences (
        nurse_id TEXT,
        box_index INTEGER,
        room_id TEXT,
        PRIMARY KEY(nurse_id, box_index)
      )
    ''');
    _tableCreated = true;
  }

  /// Get the room preferences for a nurse
  /// Returns a list of 3 room IDs (or nulls) representing which rooms to show in each box
  Future<List<String?>> getNurseRoomPreferences(String nurseId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.getNurseRoomPreferences(nurseId);
      } catch (e) {
        print('❌ [NursePreferencesRepository] Remote getNurseRoomPreferences failed: $e');
        return [null, null, null];
      }
    }
    
    // Admin mode: use database
    await _ensureTableExists();
    final db = AppDatabase.instance;
    final results = await db.customSelect(
      'SELECT box_index, room_id FROM nurse_preferences WHERE nurse_id = ? ORDER BY box_index',
      variables: [Variable.withString(nurseId)],
    ).get();
    
    final rooms = <String?>[null, null, null];
    for (final row in results) {
      final boxIndex = row.read<int>('box_index');
      final roomId = row.read<String?>('room_id');
      if (boxIndex >= 0 && boxIndex < 3) {
        rooms[boxIndex] = roomId;
      }
    }
    return rooms;
  }

  /// Get all room IDs currently in use by any nurse
  Future<Set<String>> getRoomsInUse() async {
    // Client mode: get active nurses from remote and then their preferences
    if (!GrpcClientConfig.isServer) {
      try {
        final activeNurses = await MediCoreClient.instance.getActiveNurses();
        final roomsInUse = <String>{};
        for (final nurseId in activeNurses) {
          final rooms = await getNurseRoomPreferences(nurseId);
          roomsInUse.addAll(rooms.whereType<String>());
        }
        return roomsInUse;
      } catch (e) {
        print('❌ [NursePreferencesRepository] Remote getRoomsInUse failed: $e');
        return {};
      }
    }
    
    // Admin mode: get from database (rooms from active nurses)
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.markNurseActive(nurseId);
        return;
      } catch (e) {
        print('❌ [NursePreferencesRepository] Remote markNurseActive failed: $e');
        return;
      }
    }
    // Active nurses still use SharedPreferences (session-based, not persistent)
    final prefs = await SharedPreferences.getInstance();
    final activeNurses = prefs.getStringList(_activeNursesKey) ?? [];
    if (!activeNurses.contains(nurseId)) {
      activeNurses.add(nurseId);
      await prefs.setStringList(_activeNursesKey, activeNurses);
    }
  }

  /// Mark a nurse as inactive (logged out)
  Future<void> markNurseInactive(String nurseId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.markNurseInactive(nurseId);
        return;
      } catch (e) {
        print('❌ [NursePreferencesRepository] Remote markNurseInactive failed: $e');
        return;
      }
    }
    // Active nurses still use SharedPreferences (session-based, not persistent)
    final prefs = await SharedPreferences.getInstance();
    final activeNurses = prefs.getStringList(_activeNursesKey) ?? [];
    activeNurses.remove(nurseId);
    await prefs.setStringList(_activeNursesKey, activeNurses);
  }

  /// Save room preferences for a nurse - PERSISTENT in database
  Future<void> saveNurseRoomPreferences(
    String nurseId,
    List<String?> roomIds,
  ) async {
    if (roomIds.length != 3) {
      throw ArgumentError('Must provide exactly 3 room IDs');
    }

    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.saveNurseRoomPreferences(nurseId, roomIds);
        return;
      } catch (e) {
        print('❌ [NursePreferencesRepository] Remote saveNurseRoomPreferences failed: $e');
        return;
      }
    }

    // Admin mode: save to database for persistence
    await _ensureTableExists();
    final db = AppDatabase.instance;
    
    // Clear existing preferences for this nurse
    await db.customStatement(
      'DELETE FROM nurse_preferences WHERE nurse_id = ?',
      [nurseId],
    );
    
    // Insert new preferences
    for (int i = 0; i < 3; i++) {
      if (roomIds[i] != null) {
        await db.customStatement(
          'INSERT INTO nurse_preferences (nurse_id, box_index, room_id) VALUES (?, ?, ?)',
          [nurseId, i, roomIds[i]],
        );
      }
    }
    print('✓ Saved nurse room preferences for $nurseId: $roomIds');
  }

  /// Clear preferences for a nurse
  Future<void> clearNurseRoomPreferences(String nurseId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.clearNurseRoomPreferences(nurseId);
        return;
      } catch (e) {
        print('❌ [NursePreferencesRepository] Remote clearNurseRoomPreferences failed: $e');
        return;
      }
    }
    
    // Admin mode: clear from database
    await _ensureTableExists();
    final db = AppDatabase.instance;
    await db.customStatement(
      'DELETE FROM nurse_preferences WHERE nurse_id = ?',
      [nurseId],
    );
    print('✓ Cleared nurse room preferences for $nurseId');
  }
}
