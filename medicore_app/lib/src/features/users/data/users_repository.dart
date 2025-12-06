import '../../../core/database/app_database.dart';
import '../../../core/database/dao/users_dao.dart';
import '../../../core/database/dao/templates_dao.dart';
import 'models/user_model.dart';
import 'models/template_model.dart';
import 'package:drift/drift.dart';

/// Users and Templates Repository
/// Manages CRUD operations using Drift database
class UsersRepository {
  final AppDatabase _database;
  late final UsersDao _usersDao;
  late final TemplatesDao _templatesDao;
  
  UsersRepository([AppDatabase? database]) 
      : _database = database ?? AppDatabase() {
    _usersDao = UsersDao(_database);
    _templatesDao = TemplatesDao(_database);
  }
  
  // ========== USER MANAGEMENT ==========
  
  /// Get all users
  Future<List<User>> getAllUsers() async {
    final entities = await _usersDao.getAllUsers();
    return entities.map(_entityToModel).toList();
  }
  
  /// Get user by ID
  Future<User?> getUserById(String id) async {
    final entity = await _usersDao.getUserById(id);
    return entity != null ? _entityToModel(entity) : null;
  }
  
  /// Get user by name (for login)
  Future<User?> getUserByName(String name) async {
    final entity = await _usersDao.getUserByName(name);
    return entity != null ? _entityToModel(entity) : null;
  }
  
  /// Create new user
  Future<User> createUser({
    required String name,
    required String role,
    required String password,
    double? percentage,
    bool isTemplateUser = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: role,
      password: password,
      percentage: percentage,
      isTemplateUser: isTemplateUser,
    );
    
    await _usersDao.insertUser(_modelToCompanion(user));
    return user;
  }
  
  /// Update existing user
  Future<User> updateUser(User user) async {
    final entity = _modelToEntity(user);
    await _usersDao.updateUser(entity);
    return user;
  }
  
  /// Delete user
  Future<void> deleteUser(String id) async {
    await _usersDao.deleteUser(id);
  }
  
  // ========== TEMPLATE MANAGEMENT ==========
  
  /// Get users created from templates
  Future<List<User>> getTemplateUsers() async {
    final entities = await _usersDao.getTemplateUsers();
    return entities.map(_entityToModel).toList();
  }
  
  /// Get permanent users (not from templates, excluding admin)
  Future<List<User>> getPermanentUsers() async {
    final entities = await _usersDao.getPermanentUsers();
    return entities.where((e) => e.id != 'admin').map(_entityToModel).toList();
  }
  
  /// Get all templates
  Future<List<UserTemplate>> getAllTemplates() async {
    final entities = await _templatesDao.getAllTemplates();
    return entities.map(_templateEntityToModel).toList();
  }
  
  /// Get template by ID
  Future<UserTemplate?> getTemplateById(String id) async {
    final entity = await _templatesDao.getTemplateById(id);
    return entity != null ? _templateEntityToModel(entity) : null;
  }
  
  /// Create new template
  Future<UserTemplate> createTemplate({
    required String role,
    required String password,
    required double percentage,
  }) async {
    final template = UserTemplate(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      role: role,
      password: password,
      percentage: percentage,
    );
    
    await _templatesDao.insertTemplate(_templateModelToCompanion(template));
    return template;
  }
  
  /// Update existing template
  Future<UserTemplate> updateTemplate(UserTemplate template) async {
    final entity = _templateModelToEntity(template);
    await _templatesDao.updateTemplate(entity);
    return template;
  }
  
  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    await _templatesDao.deleteTemplate(templateId);
  }
  
  /// Create user from template
  Future<User> createUserFromTemplate({
    required String templateId,
    required String userName,
  }) async {
    final template = await getTemplateById(templateId);
    if (template == null) {
      throw Exception('Template non trouvé');
    }
    
    // Validate name (at least 2 words)
    final nameParts = userName.trim().split(RegExp(r'\s+'));
    if (nameParts.length < 2) {
      throw Exception('Le nom doit contenir au moins 2 mots');
    }
    
    final user = template.createUser(userName);
    await _usersDao.insertUser(_modelToCompanion(user));
    return user;
  }
  
  // ========== CONVERTERS ==========
  
  /// Convert UserEntity to User model
  User _entityToModel(UserEntity entity) {
    return User(
      id: entity.id,
      name: entity.name,
      role: entity.role,
      password: entity.passwordHash,
      percentage: entity.percentage,
      isTemplateUser: entity.isTemplateUser,
      createdAt: entity.createdAt,
    );
  }
  
  /// Convert User model to UserEntity
  UserEntity _modelToEntity(User model) {
    return UserEntity(
      id: model.id,
      name: model.name,
      role: model.role,
      passwordHash: model.password,
      percentage: model.percentage,
      isTemplateUser: model.isTemplateUser,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: null,
      lastSyncedAt: null,
      syncVersion: 1,
      needsSync: true,
    );
  }
  
  /// Convert User model to UsersCompanion
  UsersCompanion _modelToCompanion(User model) {
    return UsersCompanion.insert(
      id: model.id,
      name: model.name,
      role: model.role,
      passwordHash: model.password,
      percentage: Value(model.percentage),
      isTemplateUser: Value(model.isTemplateUser),
      createdAt: Value(model.createdAt),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    );
  }
  
  /// Convert TemplateEntity to UserTemplate model
  UserTemplate _templateEntityToModel(TemplateEntity entity) {
    return UserTemplate(
      id: entity.id,
      role: entity.role,
      password: entity.passwordHash,
      percentage: entity.percentage,
      createdAt: entity.createdAt,
    );
  }
  
  /// Convert UserTemplate model to TemplateEntity
  TemplateEntity _templateModelToEntity(UserTemplate model) {
    return TemplateEntity(
      id: model.id,
      role: model.role,
      passwordHash: model.password,
      percentage: model.percentage,
      createdAt: model.createdAt,
      updatedAt: DateTime.now(),
      deletedAt: null,
      lastSyncedAt: null,
      syncVersion: 1,
      needsSync: true,
    );
  }
  
  /// Convert UserTemplate model to TemplatesCompanion
  TemplatesCompanion _templateModelToCompanion(UserTemplate model) {
    return TemplatesCompanion.insert(
      id: model.id,
      role: model.role,
      passwordHash: model.password,
      percentage: model.percentage,
      createdAt: Value(model.createdAt),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    );
  }
}
