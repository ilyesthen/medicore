import 'user_model.dart';
import '../core/types/proto_types.dart';

/// Template model - used for quick user creation
/// Template = Role + Password + Percentage (no name)
class UserTemplate {
  final String id;
  final String role;
  final String password;
  final double percentage;
  final DateTime createdAt;
  
  UserTemplate({
    required this.id,
    required this.role,
    required this.password,
    required this.percentage,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Copy with method for editing
  UserTemplate copyWith({
    String? id,
    String? role,
    String? password,
    double? percentage,
    DateTime? createdAt,
  }) {
    return UserTemplate(
      id: id ?? this.id,
      role: role ?? this.role,
      password: password ?? this.password,
      percentage: percentage ?? this.percentage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'role': role,
      'password': password,
      'percentage': percentage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Create from map
  factory UserTemplate.fromMap(Map<String, dynamic> map) {
    return UserTemplate(
      id: map['id'] as String,
      role: map['role'] as String,
      password: map['password'] as String,
      percentage: (map['percentage'] as num).toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
  
  /// Create user from this template with provided name
  User createUser(String name) {
    return User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      role: role,
      password: password,
      percentage: percentage,
      isTemplateUser: true,
    );
  }
}
