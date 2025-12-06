/// Application constants
class AppConstants {
  /// Predefined user roles
  static const List<String> userRoles = [
    'Médecin',
    'Infirmier',
    'Assistant 1',
    'Assistant 2',
  ];
  
  /// Roles that can have templates and percentages
  static const List<String> assistantRoles = [
    'Assistant 1',
    'Assistant 2',
  ];
  
  /// Admin user ID
  static const String adminUserId = 'admin';
  
  /// Minimum name words required
  static const int minNameWords = 2;
  
  /// Minimum password length
  static const int minPasswordLength = 4;
  
  /// Percentage range
  static const double minPercentage = 0;
  static const double maxPercentage = 100;
}
