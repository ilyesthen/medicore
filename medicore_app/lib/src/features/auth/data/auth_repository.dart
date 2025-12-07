import '../../users/data/users_repository.dart';
import '../../users/data/models/user_model.dart';
import '../../../core/repository/data_repository.dart';
import '../../../core/api/grpc_client.dart';

/// Authentication Repository
/// Handles login/logout with user system
/// Works in both admin mode (local DB) and client mode (gRPC)
class AuthRepository {
  final UsersRepository? _usersRepository;
  final DataRepository? _dataRepository;
  
  User? _currentUser;
  
  /// Constructor for admin mode (uses local UsersRepository)
  AuthRepository(this._usersRepository) : _dataRepository = null;
  
  /// Constructor for client mode (uses DataRepository via gRPC)
  AuthRepository.withDataRepository(this._dataRepository) : _usersRepository = null;
  
  /// Check if user is logged in
  bool get isAuthenticated => _currentUser != null;
  
  /// Get current user
  User? get currentUser => _currentUser;
  
  /// Check if current user is admin
  bool get isAdmin => _currentUser?.id == 'admin';
  
  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    try {
      User? user;
      
      if (_dataRepository != null) {
        // CLIENT MODE: Use gRPC via DataRepository
        print('🔐 Login via gRPC (client mode)...');
        final dbUser = await _dataRepository!.getUserByUsername(username);
        if (dbUser != null) {
          user = User(
            id: dbUser.id.toString(),
            name: dbUser.fullName,
            role: dbUser.role,
            password: dbUser.passwordHash,  // Will compare hash
          );
        }
      } else if (_usersRepository != null) {
        // ADMIN MODE: Use local database
        print('🔐 Login via local DB (admin mode)...');
        user = await _usersRepository!.getUserByName(username);
      }
      
      if (user == null) {
        return AuthResult.failure('Nom d\'utilisateur ou mot de passe incorrect');
      }
      
      // Check password
      if (user.password != password) {
        return AuthResult.failure('Nom d\'utilisateur ou mot de passe incorrect');
      }
      
      _currentUser = user;
      return AuthResult.success(user);
    } catch (e) {
      print('❌ Login error: $e');
      return AuthResult.failure('Erreur de connexion: $e');
    }
  }
  
  /// Logout current user
  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _currentUser = null;
  }
}

/// Authentication result
class AuthResult {
  final bool success;
  final User? user;
  final String? errorMessage;
  
  AuthResult.success(this.user)
      : success = true,
        errorMessage = null;
        
  AuthResult.failure(this.errorMessage)
      : success = false,
        user = null;
}
