import '../../../core/database/app_database.dart';
import '../../../core/database/dao/users_dao.dart';
import '../../../core/database/dao/templates_dao.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllUsers();
        return response.users.map((u) => User(
          id: u.stringId.isNotEmpty ? u.stringId : u.id.toString(),
          name: u.fullName.isNotEmpty ? u.fullName : u.username,
          role: u.role,
          password: u.passwordHash,
          percentage: u.percentage,
          isTemplateUser: false,
        )).toList();
      } catch (e) {
        print('❌ [UsersRepository] Remote getAllUsers failed: $e');
        return [];
      }
    }
    final entities = await _usersDao.getAllUsers();
    return entities.map(_entityToModel).toList();
  }
  
  /// Get user by ID
  Future<User?> getUserById(String id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final intId = int.tryParse(id);
        if (intId != null) {
          final user = await MediCoreClient.instance.getUserById(intId);
          if (user != null) {
            return User(
              id: user.stringId.isNotEmpty ? user.stringId : user.id.toString(),
              name: user.fullName.isNotEmpty ? user.fullName : user.username,
              role: user.role,
              password: user.passwordHash,
              percentage: user.percentage,
              isTemplateUser: false,
            );
          }
        }
        // Fallback: try by username
        final user = await MediCoreClient.instance.getUserByUsername(id);
        if (user != null) {
          return User(
            id: user.stringId.isNotEmpty ? user.stringId : user.id.toString(),
            name: user.fullName.isNotEmpty ? user.fullName : user.username,
            role: user.role,
            password: user.passwordHash,
            percentage: user.percentage,
            isTemplateUser: false,
          );
        }
        return null;
      } catch (e) {
        print('❌ [UsersRepository] Remote getUserById failed: $e');
        return null;
      }
    }
    final entity = await _usersDao.getUserById(id);
    return entity != null ? _entityToModel(entity) : null;
  }
  
  /// Get user by name (for login)
  Future<User?> getUserByName(String name) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final user = await MediCoreClient.instance.getUserByUsername(name);
        if (user != null) {
          return User(
            id: user.stringId.isNotEmpty ? user.stringId : user.id.toString(),
            name: user.fullName.isNotEmpty ? user.fullName : user.username,
            role: user.role,
            password: user.passwordHash,
            percentage: user.percentage,
            isTemplateUser: false,
          );
        }
        return null;
      } catch (e) {
        print('❌ [UsersRepository] Remote getUserByName failed: $e');
        return null;
      }
    }
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
    final user = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: role,
      password: password,
      percentage: percentage,
      isTemplateUser: isTemplateUser,
    );
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final request = CreateUserRequest(
          username: name,
          fullName: name,
          role: role,
          passwordHash: password,
          percentage: percentage,
        );
        await MediCoreClient.instance.createUser(request);
        return user;
      } catch (e) {
        print('❌ [UsersRepository] Remote createUser failed: $e');
        rethrow;
      }
    }
    
    await _usersDao.insertUser(_modelToCompanion(user));
    return user;
  }
  
  /// Update existing user
  Future<User> updateUser(User user) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final grpcUser = GrpcUser(
          id: int.tryParse(user.id) ?? 0,
          stringId: user.id,
          username: user.name,
          fullName: user.name,
          role: user.role,
          passwordHash: user.password,
          percentage: user.percentage,
        );
        await MediCoreClient.instance.updateUser(grpcUser);
        return user;
      } catch (e) {
        print('❌ [UsersRepository] Remote updateUser failed: $e');
        rethrow;
      }
    }
    
    final entity = _modelToEntity(user);
    await _usersDao.updateUser(entity);
    return user;
  }
  
  /// Delete user
  Future<void> deleteUser(String id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final intId = int.tryParse(id) ?? 0;
        await MediCoreClient.instance.deleteUser(intId);
        return;
      } catch (e) {
        print('❌ [UsersRepository] Remote deleteUser failed: $e');
        rethrow;
      }
    }
    
    await _usersDao.deleteUser(id);
  }
  
  // ========== TEMPLATE MANAGEMENT ==========
  
  /// Get users created from templates
  Future<List<User>> getTemplateUsers() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getTemplateUsers();
        return response.users.map((u) => User(
          id: u.stringId.isNotEmpty ? u.stringId : u.id.toString(),
          name: u.fullName.isNotEmpty ? u.fullName : u.username,
          role: u.role,
          password: u.passwordHash,
          percentage: u.percentage,
          isTemplateUser: true,
        )).toList();
      } catch (e) {
        print('❌ [UsersRepository] Remote getTemplateUsers failed: $e');
        return [];
      }
    }
    final entities = await _usersDao.getTemplateUsers();
    return entities.map(_entityToModel).toList();
  }
  
  /// Get permanent users (not from templates, excluding admin)
  Future<List<User>> getPermanentUsers() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getPermanentUsers();
        return response.users.map((u) => User(
          id: u.stringId.isNotEmpty ? u.stringId : u.id.toString(),
          name: u.fullName.isNotEmpty ? u.fullName : u.username,
          role: u.role,
          password: u.passwordHash,
          percentage: u.percentage,
          isTemplateUser: false,
        )).toList();
      } catch (e) {
        print('❌ [UsersRepository] Remote getPermanentUsers failed: $e');
        return [];
      }
    }
    final entities = await _usersDao.getPermanentUsers();
    return entities.where((e) => e.id != 'admin').map(_entityToModel).toList();
  }
  
  /// Get all templates
  Future<List<UserTemplate>> getAllTemplates() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllUserTemplates();
        final templates = (response['templates'] as List<dynamic>?) ?? [];
        return templates.map((t) {
          final json = t as Map<String, dynamic>;
          return UserTemplate(
            id: json['id'] as String,
            role: json['role'] as String,
            password: json['password_hash'] as String,
            percentage: (json['percentage'] as num).toDouble(),
          );
        }).toList();
      } catch (e) {
        print('❌ [UsersRepository] Remote getAllTemplates failed: $e');
        return [];
      }
    }
    final entities = await _templatesDao.getAllTemplates();
    return entities.map(_templateEntityToModel).toList();
  }
  
  /// Get template by ID
  Future<UserTemplate?> getTemplateById(String id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getUserTemplateById(id);
        if (response.isEmpty) return null;
        return UserTemplate(
          id: response['id'] as String,
          role: response['role'] as String,
          password: response['password_hash'] as String? ?? '',
          percentage: (response['percentage'] as num?)?.toDouble() ?? 0.0,
          createdAt: DateTime.tryParse(response['created_at'] as String? ?? '') ?? DateTime.now(),
        );
      } catch (e) {
        print('❌ [UsersRepository] Remote getTemplateById failed: $e');
        return null;
      }
    }
    
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
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.createUserTemplate(
          id: template.id,
          role: role,
          passwordHash: password,
          percentage: percentage,
        );
        return template;
      } catch (e) {
        print('❌ [UsersRepository] Remote createTemplate failed: $e');
        rethrow;
      }
    }
    
    await _templatesDao.insertTemplate(_templateModelToCompanion(template));
    return template;
  }
  
  /// Update existing template
  Future<UserTemplate> updateTemplate(UserTemplate template) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.updateUserTemplate(
          id: template.id,
          role: template.role,
          passwordHash: template.password,
          percentage: template.percentage,
        );
        return template;
      } catch (e) {
        print('❌ [UsersRepository] Remote updateTemplate failed: $e');
        rethrow;
      }
    }
    
    final entity = _templateModelToEntity(template);
    await _templatesDao.updateTemplate(entity);
    return template;
  }
  
  /// Delete template
  Future<void> deleteTemplate(String templateId) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deleteUserTemplate(templateId);
        return;
      } catch (e) {
        print('❌ [UsersRepository] Remote deleteTemplate failed: $e');
        rethrow;
      }
    }
    
    await _templatesDao.deleteTemplate(templateId);
  }
  
  /// Create user from template
  Future<User> createUserFromTemplate({
    required String templateId,
    required String userName,
  }) async {
    // Validate name (at least 2 words)
    final nameParts = userName.trim().split(RegExp(r'\s+'));
    if (nameParts.length < 2) {
      throw Exception('Le nom doit contenir au moins 2 mots');
    }
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final userId = DateTime.now().millisecondsSinceEpoch.toString();
        final response = await MediCoreClient.instance.createUserFromTemplate(
          templateId: templateId,
          userName: userName,
          userId: userId,
        );
        return User(
          id: response['id'] as String,
          name: response['username'] as String,
          role: response['role'] as String,
          password: response['password_hash'] as String,
          percentage: (response['percentage'] as num?)?.toDouble(),
          isTemplateUser: true,
        );
      } catch (e) {
        print('❌ [UsersRepository] Remote createUserFromTemplate failed: $e');
        rethrow;
      }
    }
    
    final template = await getTemplateById(templateId);
    if (template == null) {
      throw Exception('Template non trouvé');
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
