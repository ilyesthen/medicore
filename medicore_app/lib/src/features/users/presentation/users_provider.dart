import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/users_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/template_model.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/api/remote_users_repository.dart';
import '../../../core/generated/medicore.pb.dart';

export '../data/users_repository.dart';

/// Abstract interface for user operations
/// Allows switching between local (admin) and remote (client) implementations
abstract class IUsersRepository {
  Future<List<User>> getAllUsers();
  Future<User?> getUserById(String id);
  Future<User?> getUserByName(String name);
  Future<User> createUser({
    required String name,
    required String role,
    required String password,
    double? percentage,
    bool isTemplateUser = false,
  });
  Future<User> updateUser(User user);
  Future<void> deleteUser(String id);
}

/// Local repository adapter - wraps UsersRepository to implement IUsersRepository
class LocalUsersAdapter implements IUsersRepository {
  final UsersRepository _local;
  LocalUsersAdapter(this._local);
  
  @override
  Future<List<User>> getAllUsers() => _local.getAllUsers();
  
  @override
  Future<User?> getUserById(String id) => _local.getUserById(id);
  
  @override
  Future<User?> getUserByName(String name) => _local.getUserByName(name);
  
  @override
  Future<User> createUser({
    required String name,
    required String role,
    required String password,
    double? percentage,
    bool isTemplateUser = false,
  }) => _local.createUser(
    name: name,
    role: role,
    password: password,
    percentage: percentage,
    isTemplateUser: isTemplateUser,
  );
  
  @override
  Future<User> updateUser(User user) => _local.updateUser(user);
  
  @override
  Future<void> deleteUser(String id) => _local.deleteUser(id);
}

/// Remote repository adapter - wraps RemoteUsersRepository to implement IUsersRepository
class RemoteUsersAdapter implements IUsersRepository {
  final RemoteUsersRepository _remote;
  RemoteUsersAdapter(this._remote);
  
  @override
  Future<List<User>> getAllUsers() => _remote.getAllUsers();
  
  @override
  Future<User?> getUserById(String id) => _remote.getUserById(id);
  
  @override
  Future<User?> getUserByName(String name) => _remote.getUserByName(name);
  
  @override
  Future<User> createUser({
    required String name,
    required String role,
    required String password,
    double? percentage,
    bool isTemplateUser = false,
  }) => _remote.createUser(
    name: name,
    role: role,
    password: password,
    percentage: percentage,
    isTemplateUser: isTemplateUser,
  );
  
  @override
  Future<User> updateUser(User user) => _remote.updateUser(user);
  
  @override
  Future<void> deleteUser(String id) => _remote.deleteUser(id);
}

/// Users repository provider - Switches between local and remote based on mode
/// ADMIN mode: Uses local SQLite database
/// CLIENT mode: Uses REST API to communicate with admin server
final usersRepositoryProvider = Provider<IUsersRepository>((ref) {
  if (GrpcClientConfig.isServer) {
    // ADMIN MODE: Use local database
    print('✓ [UsersRepository] Using LOCAL database (Admin mode)');
    return LocalUsersAdapter(UsersRepository());
  } else {
    // CLIENT MODE: Use remote REST API
    print('✓ [UsersRepository] Using REMOTE API (Client mode)');
    
    // Initialize client with server host if not already done
    final serverHost = GrpcClientConfig.serverHost;
    MediCoreClient.instance.initialize(host: serverHost);
    
    return RemoteUsersAdapter(RemoteUsersRepository());
  }
});

/// All users provider
final usersListProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier(ref.read(usersRepositoryProvider));
});

/// Users notifier
class UsersNotifier extends StateNotifier<List<User>> {
  final IUsersRepository _repository;
  
  UsersNotifier(this._repository) : super([]) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      await loadUsers();
    } catch (e) {
      print('❌ UsersNotifier init error: $e');
      // Don't crash, just leave empty list
    }
  }
  
  Future<void> loadUsers() async {
    try {
      state = await _repository.getAllUsers();
    } catch (e) {
      print('❌ loadUsers error: $e');
      state = []; // Return empty on error
    }
  }
  
  Future<void> createUser({
    required String name,
    required String role,
    required String password,
    double? percentage,
  }) async {
    await _repository.createUser(
      name: name,
      role: role,
      password: password,
      percentage: percentage,
      isTemplateUser: false,
    );
    loadUsers();
  }
  
  Future<void> updateUser(User user) async {
    await _repository.updateUser(user);
    loadUsers();
  }
  
  Future<void> deleteUser(String userId) async {
    await _repository.deleteUser(userId);
    loadUsers();
  }
}

/// All templates provider (only available in ADMIN mode)
/// Templates are only used for admin functions, so they always use local database
final templatesListProvider = StateNotifierProvider<TemplatesNotifier, List<UserTemplate>>((ref) {
  // Templates only work in admin mode - always use local repository
  return TemplatesNotifier(UsersRepository());
});

/// Templates notifier
class TemplatesNotifier extends StateNotifier<List<UserTemplate>> {
  final UsersRepository _repository;
  
  TemplatesNotifier(this._repository) : super([]) {
    _init();
  }
  
  Future<void> _init() async {
    try {
      await loadTemplates();
    } catch (e) {
      print('❌ TemplatesNotifier init error: $e');
    }
  }
  
  Future<void> loadTemplates() async {
    try {
      state = await _repository.getAllTemplates();
    } catch (e) {
      print('❌ loadTemplates error: $e');
      state = [];
    }
  }
  
  Future<void> createTemplate({
    required String role,
    required String password,
    required double percentage,
  }) async {
    await _repository.createTemplate(
      role: role,
      password: password,
      percentage: percentage,
    );
    loadTemplates();
  }
  
  Future<void> updateTemplate(UserTemplate template) async {
    await _repository.updateTemplate(template);
    loadTemplates();
  }
  
  Future<void> deleteTemplate(String templateId) async {
    await _repository.deleteTemplate(templateId);
    loadTemplates();
  }
}
