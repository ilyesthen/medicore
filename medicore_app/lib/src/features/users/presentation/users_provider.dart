import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/users_repository.dart';
import '../data/models/user_model.dart';
import '../data/models/template_model.dart';

export '../data/users_repository.dart';

/// Users repository provider - Global singleton
final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository();
});

/// All users provider
final usersListProvider = StateNotifierProvider<UsersNotifier, List<User>>((ref) {
  return UsersNotifier(ref.read(usersRepositoryProvider));
});

/// Users notifier
class UsersNotifier extends StateNotifier<List<User>> {
  final UsersRepository _repository;
  
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

/// All templates provider
final templatesListProvider = StateNotifierProvider<TemplatesNotifier, List<UserTemplate>>((ref) {
  return TemplatesNotifier(ref.read(usersRepositoryProvider));
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
