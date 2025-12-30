import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_model.dart';
import '../data/models/template_model.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/api/remote_users_repository.dart';
import '../../../core/types/proto_types.dart';

export '../data/users_repository.dart';

/// Abstract interface for user operations
/// Manages user operations via server REST API
abstract class IRemoteUsersRepository {
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

/// Local repository adapter - wraps RemoteUsersRepository to implement IRemoteUsersRepository
class LocalUsersAdapter implements IRemoteUsersRepository {
  final RemoteUsersRepository _local;
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

/// Remote repository adapter - wraps RemoteUsersRepository to implement IRemoteUsersRepository
class RemoteUsersAdapter implements IRemoteUsersRepository {
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

/// Users repository provider - All instances use server REST API
final usersRepositoryProvider = Provider<IRemoteUsersRepository>((ref) {
  print('✓ [RemoteUsersRepository] Using server REST API');
  return RemoteUsersAdapter(RemoteUsersRepository());
});

/// All users provider
final usersListProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier(ref.read(usersRepositoryProvider));
});

/// Users notifier
class UsersNotifier extends StateNotifier<List<User>> {
  final IRemoteUsersRepository _repository;
  
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

/// All templates provider - uses server REST API
final templatesListProvider = StateNotifierProvider<TemplatesNotifier, List<UserTemplate>>((ref) {
  return TemplatesNotifier(RemoteUsersRepository());
});

/// Templates notifier
class TemplatesNotifier extends StateNotifier<List<UserTemplate>> {
  final RemoteUsersRepository _repository;
  
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
