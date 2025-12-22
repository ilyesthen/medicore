/// DELETED - Use RemoteRoomsRepository instead
class RoomsRepository {
  RoomsRepository(_) {
    throw UnimplementedError('RoomsRepository deleted - use RemoteRoomsRepository');
  }
  
  Future<List<dynamic>> getAllRooms() => throw UnimplementedError();
  Future<dynamic> getRoomById(String id) => throw UnimplementedError();
  Future<dynamic> createRoom({required String name}) => throw UnimplementedError();
  Future<void> updateRoom(dynamic room) => throw UnimplementedError();
  Future<void> deleteRoom(String id) => throw UnimplementedError();
}
