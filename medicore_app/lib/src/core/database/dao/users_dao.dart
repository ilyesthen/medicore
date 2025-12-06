import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/users_table.dart';

part 'users_dao.g.dart';

/// Data Access Object for Users
/// Handles all database operations for users
@DriftAccessor(tables: [Users])
class UsersDao extends DatabaseAccessor<AppDatabase> with _$UsersDaoMixin {
  UsersDao(AppDatabase db) : super(db);

  /// Get all users (excluding soft-deleted)
  Future<List<UserEntity>> getAllUsers() {
    return (select(users)..where((u) => u.deletedAt.isNull())).get();
  }

  /// Get user by ID
  Future<UserEntity?> getUserById(String id) {
    return (select(users)..where((u) => u.id.equals(id) & u.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get user by name (for login)
  Future<UserEntity?> getUserByName(String name) {
    return (select(users)..where((u) => u.name.equals(name) & u.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get users created from templates
  Future<List<UserEntity>> getTemplateUsers() {
    return (select(users)
          ..where((u) => u.isTemplateUser.equals(true) & u.deletedAt.isNull()))
        .get();
  }

  /// Get permanent users (not from templates)
  Future<List<UserEntity>> getPermanentUsers() {
    return (select(users)
          ..where((u) => u.isTemplateUser.equals(false) & u.deletedAt.isNull()))
        .get();
  }

  /// Insert new user
  Future<int> insertUser(UsersCompanion user) {
    return into(users).insert(user);
  }

  /// Update existing user
  Future<bool> updateUser(UserEntity user) {
    return update(users).replace(user);
  }

  /// Soft delete user
  Future<int> deleteUser(String id) {
    return (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ),
    );
  }

  /// Hard delete user (for admin only)
  Future<int> hardDeleteUser(String id) {
    return (delete(users)..where((u) => u.id.equals(id))).go();
  }

  /// Get users that need syncing
  Future<List<UserEntity>> getUsersNeedingSync() {
    return (select(users)..where((u) => u.needsSync.equals(true))).get();
  }

  /// Mark user as synced
  Future<int> markAsSynced(String id, DateTime syncTime) {
    return (update(users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        lastSyncedAt: Value(syncTime),
        needsSync: const Value(false),
      ),
    );
  }

  /// Watch all users (for real-time UI updates)
  Stream<List<UserEntity>> watchAllUsers() {
    return (select(users)..where((u) => u.deletedAt.isNull())).watch();
  }
}
