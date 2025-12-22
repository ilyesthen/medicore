import 'dart:async';
import '../generated/medicore.pb.dart' as pb;
import 'medicore_client.dart';
import 'realtime_sync_service.dart';

/// Remote Rooms Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only
class RemoteRoomsRepository {
  final MediCoreClient _client;
  
  // Cache for performance
  List<pb.GrpcRoom> _cachedRooms = [];
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
  Future<List<pb.GrpcRoom>> getAllRooms() async {
    // Use cache if fresh (less than 30 seconds old)
    if (_cachedRooms.isNotEmpty && _lastFetch != null) {
      final age = DateTime.now().difference(_lastFetch!);
      if (age.inSeconds < 30) {
        return _cachedRooms;
      }
    }
    
    try {
      final response = await _client.getAllRooms();
      _cachedRooms = response.rooms;
      _lastFetch = DateTime.now();
      return _cachedRooms;
    } catch (e) {
      print('❌ [RemoteRooms] getAllRooms failed: $e');
      return _cachedRooms; // Return cached on error
    }
  }

  /// Get room by ID
  Future<pb.GrpcRoom?> getRoomById(String id) async {
    // Try cache first
    final cached = _cachedRooms.where((r) => r.id.toString() == id).firstOrNull;
    if (cached != null) return cached;
    
    try {
      // Rooms use string IDs locally but int on server
      final intId = int.tryParse(id);
      if (intId == null) {
        // Search in cache by name or return null
        await getAllRooms();
        return _cachedRooms.where((r) => r.id.toString() == id).firstOrNull;
      }
      
      final grpcRoom = await _client.getRoomById(intId);
      return grpcRoom;
    } catch (e) {
      print('❌ [RemoteRooms] getRoomById failed: $e');
      return null;
    }
  }

  /// Create a new room
  Future<pb.GrpcRoom> createRoom({required String name}) async {
    try {
      final request = pb.CreateRoomRequest(name: name, type: 'consultation');
      final id = await _client.createRoom(request);
      
      final room = pb.GrpcRoom(
        id: id,
        stringId: id.toString(),
        name: name,
        type: 'consultation',
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
  Future<void> updateRoom(pb.GrpcRoom room) async {
    try {
      final grpcRoom = pb.GrpcRoom(
        id: room.id,
        stringId: room.stringId,
        name: room.name,
        type: room.type,
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
      _cachedRooms.removeWhere((r) => r.id.toString() == id);
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

}
