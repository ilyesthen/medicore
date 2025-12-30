import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/remote_users_repository.dart';
import '../api/remote_patients_repository.dart';
import '../api/remote_rooms_repository.dart';
import '../api/remote_messages_repository.dart';
import '../api/remote_waiting_queue_repository.dart';

/// Repository Factory - PRO ARCHITECTURE
/// ALL instances connect to the Go server via REST API
/// There is no local database mode - everyone uses the server
class RepositoryFactory {
  static RepositoryFactory? _instance;
  static RepositoryFactory get instance => _instance ??= RepositoryFactory._();
  
  RepositoryFactory._();
  
  // ==================== USERS ====================
  
  /// Get users repository - always uses server
  RemoteUsersRepository getUsersRepository() {
    return RemoteUsersRepository();
  }
  
  // ==================== PATIENTS ====================
  
  /// Get patients repository - always uses server
  RemotePatientsRepository getPatientsRepository() {
    return RemotePatientsRepository();
  }
  
  // ==================== ROOMS ====================
  
  /// Get rooms repository - always uses server
  RemoteRoomsRepository getRoomsRepository() {
    return RemoteRoomsRepository();
  }
  
  // ==================== MESSAGES ====================
  
  /// Get messages repository - always uses server
  RemoteMessagesRepository getMessagesRepository() {
    return RemoteMessagesRepository();
  }
  
  // ==================== WAITING QUEUE ====================
  
  /// Get waiting queue repository - always uses server
  RemoteWaitingQueueRepository getWaitingQueueRepository() {
    return RemoteWaitingQueueRepository();
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for repository factory
final repositoryFactoryProvider = Provider<RepositoryFactory>((ref) {
  return RepositoryFactory.instance;
});

/// Provider for users repository
final usersRepositoryProvider = Provider<RemoteUsersRepository>((ref) {
  return RemoteUsersRepository();
});

/// Provider for patients repository
final patientsRepositoryProvider = Provider<RemotePatientsRepository>((ref) {
  return RemotePatientsRepository();
});

/// Provider for rooms repository
final roomsRepositoryProvider = Provider<RemoteRoomsRepository>((ref) {
  return RemoteRoomsRepository();
});

/// Provider for messages repository
final messagesRepositoryProvider = Provider<RemoteMessagesRepository>((ref) {
  return RemoteMessagesRepository();
});

/// Provider for waiting queue repository
final waitingQueueRepositoryProvider = Provider<RemoteWaitingQueueRepository>((ref) {
  return RemoteWaitingQueueRepository();
});
