import '../../users/data/users_repository.dart';
import '../../users/data/models/user_model.dart';

/// Authentication Repository
/// Handles login/logout with user system
class AuthRepository {
  final UsersRepository _usersRepository;
  
  User? _currentUser;
  
  AuthRepository(this._usersRepository);
  
  /// Check if user is logged in
  bool get isAuthenticated => _currentUser != null;
  
  /// Get current user
  User? get currentUser => _currentUser;
  
  /// Check if current user is admin
  bool get isAdmin => _currentUser?.id == 'admin';
  
  /// Login with username and password
  Future<AuthResult> login(String username, String password) async {
    // Try to find user by name
    final user = await _usersRepository.getUserByName(username);
    
    if (user == null) {
      return AuthResult.failure('Nom d\'utilisateur ou mot de passe incorrect');
    }
    
    // Check password
    if (user.password != password) {
      return AuthResult.failure('Nom d\'utilisateur ou mot de passe incorrect');
    }
    
    _currentUser = user;
    return AuthResult.success(user);
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
