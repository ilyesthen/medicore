import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/remote_users_repository.dart';
import '../api/remote_patients_repository.dart';
import '../api/remote_rooms_repository.dart';
import '../api/remote_messages_repository.dart';
import '../api/remote_waiting_queue_repository.dart';

/// Repository Factory
/// Professional Client-Server Architecture - All data access is REMOTE only
/// This is the SINGLE SOURCE OF TRUTH for repository instantiation
class RepositoryFactory {
  static RepositoryFactory? _instance;
  static RepositoryFactory get instance => _instance ??= RepositoryFactory._();
  
  RepositoryFactory._();
  
  // ==================== USERS ====================
  
  /// Get users repository (always remote)
  RemoteUsersRepository getUsersRepository() {
    return RemoteUsersRepository();
  }
  
  // ==================== PATIENTS ====================
  
  /// Get patients repository (always remote)
  RemotePatientsRepository getPatientsRepository() {
    return RemotePatientsRepository();
  }
  
  // ==================== ROOMS ====================
  
  /// Get rooms repository (always remote)
  RemoteRoomsRepository getRoomsRepository() {
    return RemoteRoomsRepository();
  }
  
  // ==================== MESSAGES ====================
  
  /// Get messages repository (always remote)
  RemoteMessagesRepository getMessagesRepository() {
    return RemoteMessagesRepository();
  }
  
  // ==================== WAITING QUEUE ====================
  
  /// Get waiting queue repository (always remote)
  RemoteWaitingQueueRepository getWaitingQueueRepository() {
    return RemoteWaitingQueueRepository();
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for repository factory
final repositoryFactoryProvider = Provider<RepositoryFactory>((ref) {
  return RepositoryFactory.instance;
});
