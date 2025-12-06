import 'package:uuid/uuid.dart';

/// Room model - Medical/operational room in the facility
class Room {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool needsSync;

  Room({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.needsSync = true,
  });

  /// Create a new room with generated ID
  factory Room.create({
    required String name,
  }) {
    final now = DateTime.now();
    return Room(
      id: const Uuid().v4(),
      name: name,
      createdAt: now,
      updatedAt: now,
      needsSync: true,
    );
  }

  /// Copy with modified fields
  Room copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? needsSync,
  }) {
    return Room(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      needsSync: needsSync ?? this.needsSync,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'needsSync': needsSync,
    };
  }

  /// Create from JSON
  factory Room.fromJson(Map<String, dynamic> json) {
    return Room(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      needsSync: json['needsSync'] as bool? ?? true,
    );
  }

  @override
  String toString() => 'Room(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
