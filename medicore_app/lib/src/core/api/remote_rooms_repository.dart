import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import 'realtime_sync_service.dart';

/// Remote Rooms Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only
class RemoteRoomsRepository {
  final MediCoreClient _client;
  
  // Cache for performance
  List<Room> _cachedRooms = [];
  DateTime? _lastFetch;
  
  // SSE callback for real-time updates
  void Function()? _sseCallback;
  bool _sseRegistered = false;

  RemoteRoomsRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance {
    _registerSSE();
  }

  void _registerSSE() {
    if (_sseRegistered) return;
    _sseCallback = () {
      clearCache();
    };
    RealtimeSyncService.instance.onRoomRefresh(_sseCallback!);
    _sseRegistered = true;
  }

  void dispose() {
    if (_sseCallback != null) {
      RealtimeSyncService.instance.removeRoomRefresh(_sseCallback!);
      _sseCallback = null;
    }
    _sseRegistered = false;
  }

  /// Get all rooms
  Future<List<Room>> getAllRooms() async {
    // Use cache if fresh (less than 30 seconds old)
    if (_cachedRooms.isNotEmpty && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age.inSeconds < 30) {
        return _cachedRooms;
      }
    }
    
    try {
      final response = await _client.getAllRooms();
      _cachedRooms = response.rooms.map(_grpcRoomToLocal).toList();
      _lastFetch = DateTime.now();
      return _cachedRooms;
    } catch (e) {
      print('❌ [RemoteRooms] getAllRooms failed: $e');
      return _cachedRooms; // Return cached on error
    }
  }

  /// Get room by ID
  Future<Room?> getRoomById(String id) async {
    // Try cache first
    final cached = _cachedRooms.where((r) => r.id == id).firstOrNull;
    if (cached != null) return cached;
    
    try {
      // Rooms use string IDs locally but int on server
      final intId = int.tryParse(id);
      if (intId == null) {
        // Search in cache by name or return null
        await getAllRooms();
        return _cachedRooms.where((r) => r.id == id).firstOrNull;
      }
      
      final grpcRoom = await _client.getRoomById(intId);
      return grpcRoom != null ? _grpcRoomToLocal(grpcRoom) : null;
    } catch (e) {
      print('❌ [RemoteRooms] getRoomById failed: $e');
      return null;
    }
  }

  /// Create a new room
  Future<Room> createRoom({required String name}) async {
    try {
      final request = CreateRoomRequest(name: name, type: 'consultation');
      final id = await _client.createRoom(request);
      
      final room = Room(
        id: id.toString(),
        name: name,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        needsSync: false,
      );
      
      // Update cache
      _cachedRooms.add(room);
      
      return room;
    } catch (e) {
      print('❌ [RemoteRooms] createRoom failed: $e');
      rethrow;
    }
  }

  /// Update an existing room
  Future<void> updateRoom(Room room) async {
    try {
      final grpcRoom = GrpcRoom(
        id: int.tryParse(room.id) ?? 0,
        name: room.name,
        type: 'consultation',
      );
      await _client.updateRoom(grpcRoom);
      
      // Update cache
      final index = _cachedRooms.indexWhere((r) => r.id == room.id);
      if (index >= 0) {
        _cachedRooms[index] = room;
      }
    } catch (e) {
      print('❌ [RemoteRooms] updateRoom failed: $e');
      rethrow;
    }
  }

  /// Delete a room
  Future<void> deleteRoom(String id) async {
    try {
      final intId = int.tryParse(id) ?? 0;
      await _client.deleteRoom(intId);
      
      // Update cache
      _cachedRooms.removeWhere((r) => r.id == id);
    } catch (e) {
      print('❌ [RemoteRooms] deleteRoom failed: $e');
      rethrow;
    }
  }

  /// Clear cache (force refresh on next call)
  void clearCache() {
    print('🔄 [RemoteRooms] Cache cleared via SSE');
    _cachedRooms.clear();
    _lastFetch = null;
  }

  /// Convert GrpcRoom to local Room model
  Room _grpcRoomToLocal(GrpcRoom grpc) {
    // Use stringId for proper ID handling (local DB uses strings)
    final roomId = grpc.stringId.isNotEmpty 
        ? grpc.stringId 
        : grpc.id.toString();
    
    return Room(
      id: roomId,
      name: grpc.name,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      needsSync: false,
    );
  }
}
