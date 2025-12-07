import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/remote_rooms_repository.dart';
import '../data/rooms_repository.dart';

/// Abstract interface for room operations
abstract class IRoomsRepository {
  Future<List<Room>> getAllRooms();
  Future<Room?> getRoomById(String id);
  Future<Room> createRoom({required String name});
  Future<void> updateRoom(Room room);
  Future<void> deleteRoom(String id);
}

/// Local rooms adapter
class LocalRoomsAdapter implements IRoomsRepository {
  final RoomsRepository _local;
  LocalRoomsAdapter(this._local);
  
  @override
  Future<List<Room>> getAllRooms() => _local.getAllRooms();
  
  @override
  Future<Room?> getRoomById(String id) => _local.getRoomById(id);
  
  @override
  Future<Room> createRoom({required String name}) => _local.createRoom(name: name);
  
  @override
  Future<void> updateRoom(Room room) => _local.updateRoom(room);
  
  @override
  Future<void> deleteRoom(String id) => _local.deleteRoom(id);
}

/// Remote rooms adapter
class RemoteRoomsAdapter implements IRoomsRepository {
  final RemoteRoomsRepository _remote;
  RemoteRoomsAdapter(this._remote);
  
  @override
  Future<List<Room>> getAllRooms() => _remote.getAllRooms();
  
  @override
  Future<Room?> getRoomById(String id) => _remote.getRoomById(id);
  
  @override
  Future<Room> createRoom({required String name}) => _remote.createRoom(name: name);
  
  @override
  Future<void> updateRoom(Room room) => _remote.updateRoom(room);
  
  @override
  Future<void> deleteRoom(String id) => _remote.deleteRoom(id);
}

/// Rooms repository provider - switches between local and remote
final roomsRepositoryProvider = Provider<IRoomsRepository>((ref) {
  if (GrpcClientConfig.isServer) {
    print('✓ [RoomsRepository] Using LOCAL database (Admin mode)');
    return LocalRoomsAdapter(RoomsRepository(AppDatabase.instance));
  } else {
    print('✓ [RoomsRepository] Using REMOTE API (Client mode)');
    return RemoteRoomsAdapter(RemoteRoomsRepository());
  }
});

/// Rooms list provider
final roomsListProvider = StateNotifierProvider<RoomsNotifier, List<Room>>((ref) {
  final repository = ref.watch(roomsRepositoryProvider);
  return RoomsNotifier(repository);
});

/// Rooms state notifier
class RoomsNotifier extends StateNotifier<List<Room>> {
  final IRoomsRepository _repository;

  RoomsNotifier(this._repository) : super([]) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      await loadRooms();
    } catch (e) {
      print('❌ RoomsNotifier init error: $e');
    }
  }

  /// Load all rooms from database
  Future<void> loadRooms() async {
    try {
      state = await _repository.getAllRooms();
    } catch (e) {
      print('❌ loadRooms error: $e');
      state = [];
    }
  }

  /// Create a new room
  Future<void> createRoom({
    required String name,
  }) async {
    await _repository.createRoom(name: name);
    await loadRooms();
  }

  /// Update an existing room
  Future<void> updateRoom(Room room) async {
    await _repository.updateRoom(room);
    await loadRooms();
  }

  /// Delete a room
  Future<void> deleteRoom(String id) async {
    await _repository.deleteRoom(id);
    await loadRooms();
  }
}
