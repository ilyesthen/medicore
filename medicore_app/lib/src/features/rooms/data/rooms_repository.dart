import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';

/// Repository for room data operations
class RoomsRepository {
  final AppDatabase _db;

  RoomsRepository(this._db);

  /// Get all rooms
  Future<List<Room>> getAllRooms() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllRooms();
        return response.rooms.map(_grpcRoomToLocal).toList();
      } catch (e) {
        print('❌ [RoomsRepository] Remote getAllRooms failed: $e');
        return [];
      }
    }
    
    return await _db.select(_db.rooms).get();
  }
  
  /// Convert GrpcRoom to local Room model
  Room _grpcRoomToLocal(GrpcRoom grpc) {
    final roomId = grpc.stringId.isNotEmpty ? grpc.stringId : grpc.id.toString();
    return Room(
      id: roomId,
      name: grpc.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: false,
    );
  }

  /// Get room by ID
  Future<Room?> getRoomById(String id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final intId = int.tryParse(id);
        if (intId != null) {
          final grpcRoom = await MediCoreClient.instance.getRoomById(intId);
          return grpcRoom != null ? _grpcRoomToLocal(grpcRoom) : null;
        }
        // Fallback: search all rooms by string ID
        final response = await MediCoreClient.instance.getAllRooms();
        final match = response.rooms.where((r) => r.stringId == id).firstOrNull;
        return match != null ? _grpcRoomToLocal(match) : null;
      } catch (e) {
        print('❌ [RoomsRepository] Remote getRoomById failed: $e');
        return null;
      }
    }
    
    return await (_db.select(_db.rooms)
          ..where((r) => r.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new room
  Future<Room> createRoom({
    required String name,
  }) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final request = CreateRoomRequest(name: name, type: 'consultation');
        final id = await MediCoreClient.instance.createRoom(request);
        return Room(
          id: id.toString(),
          name: name,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          needsSync: false,
        );
      } catch (e) {
        print('❌ [RoomsRepository] Remote createRoom failed: $e');
        rethrow;
      }
    }
    
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final grpcRoom = GrpcRoom(
          id: int.tryParse(room.id) ?? 0,
          stringId: room.id,
          name: room.name,
          type: 'consultation',
        );
        await MediCoreClient.instance.updateRoom(grpcRoom);
        return;
      } catch (e) {
        print('❌ [RoomsRepository] Remote updateRoom failed: $e');
        rethrow;
      }
    }
    
    await (_db.update(_db.rooms)..where((r) => r.id.equals(room.id)))
        .write(RoomsCompanion(
          name: Value(room.name),
          updatedAt: Value(DateTime.now()),
          needsSync: const Value(true),
        ));
  }

  /// Delete a room
  Future<void> deleteRoom(String id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final intId = int.tryParse(id) ?? 0;
        await MediCoreClient.instance.deleteRoom(intId);
        return;
      } catch (e) {
        print('❌ [RoomsRepository] Remote deleteRoom failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.rooms)..where((r) => r.id.equals(id))).go();
  }
}
