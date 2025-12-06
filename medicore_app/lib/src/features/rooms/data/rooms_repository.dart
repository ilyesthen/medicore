import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';

/// Repository for room data operations
class RoomsRepository {
  final AppDatabase _db;

  RoomsRepository(this._db);

  /// Get all rooms
  Future<List<Room>> getAllRooms() async {
    return await _db.select(_db.rooms).get();
  }

  /// Get room by ID
  Future<Room?> getRoomById(String id) async {
    return await (_db.select(_db.rooms)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new room
  Future<Room> createRoom({
    required String name,
  }) async {
    final roomId = const Uuid().v4();
    final now = DateTime.now();
    
    await _db.into(_db.rooms).insert(
      RoomsCompanion.insert(
        id: roomId,
        name: name,
        createdAt: Value(now),
        updatedAt: Value(now),
        needsSync: const Value(true),
      ),
    );
    
    // Return the created room
    return Room(
      id: roomId,
      name: name,
      createdAt: now,
      updatedAt: now,
      needsSync: true,
    );
  }

  /// Update an existing room
  Future<void> updateRoom(Room room) async {
    await (_db.update(_db.rooms)..where((r) => r.id.equals(room.id)))
        .write(RoomsCompanion(
          name: Value(room.name),
          updatedAt: Value(DateTime.now()),
          needsSync: const Value(true),
        ));
  }

  /// Delete a room
  Future<void> deleteRoom(String id) async {
    await (_db.delete(_db.rooms)..where((r) => r.id.equals(id))).go();
  }
}
