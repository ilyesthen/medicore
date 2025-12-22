import '../core/types/proto_types.dart';
/// User model
class User {
  final String id;
  final String name;
  final String role;
  final String password;
  final double? percentage; // Only for template-created users
  final bool isTemplateUser; // True if created from template
  final DateTime createdAt;
  
  User({
    required this.id,
    required this.name,
    required this.role,
    required this.password,
    this.percentage,
    this.isTemplateUser = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
  
  /// Copy with method for editing
  User copyWith({
    String? id,
    String? name,
    String? role,
    String? password,
    double? percentage,
    bool? isTemplateUser,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      password: password ?? this.password,
      percentage: percentage ?? this.percentage,
      isTemplateUser: isTemplateUser ?? this.isTemplateUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  
  /// Convert to map for storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'password': password,
      'percentage': percentage,
      'isTemplateUser': isTemplateUser,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  
  /// Create from map
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      password: map['password'] as String,
      percentage: map['percentage'] as double?,
      isTemplateUser: map['isTemplateUser'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
