import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import '../../features/users/data/models/user_model.dart';
import '../../features/users/data/models/template_model.dart';

/// Remote Users Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only
class RemoteUsersRepository {
  final MediCoreClient _client;

  RemoteUsersRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance;

  /// Get all users from server
  Future<List<User>> getAllUsers() async {
    final response = await _client.getAllUsers();
    return response.users.map(_grpcUserToModel).toList();
  }

  /// Get user by ID
  Future<User?> getUserById(String id) async {
    // Parse ID - local uses string, server may use int
    final intId = int.tryParse(id);
    if (intId == null) {
      // Try by username instead
      final user = await _client.getUserByUsername(id);
      return user != null ? _grpcUserToModel(user) : null;
    }
    final user = await _client.getUserById(intId);
    return user != null ? _grpcUserToModel(user) : null;
  }

  /// Get user by name (for login)
  Future<User?> getUserByName(String name) async {
    final user = await _client.getUserByUsername(name);
    return user != null ? _grpcUserToModel(user) : null;
  }

  /// Create new user (admin function - may not work in client mode)
  Future<User> createUser({
    required String name,
    required String role,
    required String password,
    double? percentage,
    bool isTemplateUser = false,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    
    final request = CreateUserRequest(
      username: name,
      fullName: name,
      role: role,
      passwordHash: password,
      percentage: percentage,
    );
    
    await _client.createUser(request);
    
    return User(
      id: id,
      name: name,
      role: role,
      password: password,
      percentage: percentage,
      isTemplateUser: isTemplateUser,
    );
  }

  /// Update existing user
  Future<User> updateUser(User user) async {
    final grpcUser = GrpcUser(
      id: int.tryParse(user.id) ?? 0,
      username: user.name,
      fullName: user.name,
      role: user.role,
      passwordHash: user.password,
      percentage: user.percentage,
    );
    
    await _client.updateUser(grpcUser);
    return user;
  }

  /// Delete user
  Future<void> deleteUser(String id) async {
    final intId = int.tryParse(id) ?? 0;
    await _client.deleteUser(intId);
  }

  /// Get all templates (stub - not implemented yet)
  Future<List<UserTemplate>> getAllTemplates() async {
    // TODO: Implement template support in gRPC
    return [];
  }

  /// Create new template (stub - not implemented yet)
  Future<UserTemplate> createTemplate({
    required String role,
    required String password,
    required double percentage,
  }) async {
    // TODO: Implement template support in gRPC
    throw UnimplementedError('Template creation not implemented in gRPC mode');
  }

  /// Update existing template (stub - not implemented yet)
  Future<void> updateTemplate(UserTemplate template) async {
    // TODO: Implement template support in gRPC
    throw UnimplementedError('Template update not implemented in gRPC mode');
  }

  /// Delete template (stub - not implemented yet)
  Future<void> deleteTemplate(String templateId) async {
    // TODO: Implement template support in gRPC
    throw UnimplementedError('Template deletion not implemented in gRPC mode');
  }

  /// Convert GrpcUser to local User model
  User _grpcUserToModel(GrpcUser grpcUser) {
    // Use stringId for the local User model (local DB uses string IDs)
    final userId = grpcUser.stringId.isNotEmpty 
        ? grpcUser.stringId 
        : (grpcUser.id > 0 ? grpcUser.id.toString() : grpcUser.username);
    
    return User(
      id: userId,
      name: grpcUser.fullName.isNotEmpty ? grpcUser.fullName : grpcUser.username,
      role: grpcUser.role,
      password: grpcUser.passwordHash,
      percentage: grpcUser.percentage,
      isTemplateUser: false,
    );
  }
}
