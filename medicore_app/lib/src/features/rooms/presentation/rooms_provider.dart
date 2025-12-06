import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/rooms_repository.dart';

/// Provider for the database instance
final _databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Provider for the rooms repository
final _roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  final database = ref.watch(_databaseProvider);
  return RoomsRepository(database);
});

/// Rooms list provider
final roomsListProvider = StateNotifierProvider<RoomsNotifier, List<Room>>((ref) {
  final repository = ref.watch(_roomsRepositoryProvider);
  return RoomsNotifier(repository);
});

/// Rooms state notifier
class RoomsNotifier extends StateNotifier<List<Room>> {
  final RoomsRepository _repository;

  RoomsNotifier(this._repository) : super([]) {
    loadRooms();
  }

  /// Load all rooms from database
  Future<void> loadRooms() async {
    state = await _repository.getAllRooms();
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
