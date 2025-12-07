import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/grpc_client.dart';
import '../api/medicore_client.dart';
import '../api/remote_users_repository.dart';
import '../api/remote_patients_repository.dart';
import '../api/remote_rooms_repository.dart';
import '../api/remote_messages_repository.dart';
import '../api/remote_waiting_queue_repository.dart';
import '../database/app_database.dart';
import '../../features/users/data/users_repository.dart';
import '../../features/patients/data/patients_repository.dart';
import '../../features/rooms/data/rooms_repository.dart';
import '../../features/messages/data/messages_repository.dart';
import '../../features/waiting_queue/data/waiting_queue_repository.dart';

/// Repository Factory
/// Provides the correct repository implementation based on mode (admin/client)
/// This is the SINGLE SOURCE OF TRUTH for repository instantiation
class RepositoryFactory {
  static RepositoryFactory? _instance;
  static RepositoryFactory get instance => _instance ??= RepositoryFactory._();
  
  RepositoryFactory._();
  
  bool get isAdminMode => GrpcClientConfig.isServer;
  bool get isClientMode => !GrpcClientConfig.isServer;
  
  // ==================== USERS ====================
  
  /// Get users repository
  dynamic getUsersRepository() {
    if (isAdminMode) {
      return UsersRepository();
    } else {
      return RemoteUsersRepository();
    }
  }
  
  // ==================== PATIENTS ====================
  
  /// Get patients repository
  dynamic getPatientsRepository() {
    if (isAdminMode) {
      return PatientsRepository();
    } else {
      return RemotePatientsRepository();
    }
  }
  
  // ==================== ROOMS ====================
  
  /// Get rooms repository
  dynamic getRoomsRepository() {
    if (isAdminMode) {
      return RoomsRepository(AppDatabase.instance);
    } else {
      return RemoteRoomsRepository();
    }
  }
  
  // ==================== MESSAGES ====================
  
  /// Get messages repository
  dynamic getMessagesRepository() {
    if (isAdminMode) {
      return MessagesRepository();
    } else {
      return RemoteMessagesRepository();
    }
  }
  
  // ==================== WAITING QUEUE ====================
  
  /// Get waiting queue repository
  dynamic getWaitingQueueRepository() {
    if (isAdminMode) {
      return WaitingQueueRepository();
    } else {
      return RemoteWaitingQueueRepository();
    }
  }
}

// ==================== RIVERPOD PROVIDERS ====================

/// Provider for checking if in admin mode
final isAdminModeProvider = Provider<bool>((ref) {
  return GrpcClientConfig.isServer;
});

/// Provider for repository factory
final repositoryFactoryProvider = Provider<RepositoryFactory>((ref) {
  return RepositoryFactory.instance;
});
