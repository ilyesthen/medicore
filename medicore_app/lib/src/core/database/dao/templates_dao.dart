import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/templates_table.dart';

part 'templates_dao.g.dart';

/// Data Access Object for Templates
/// Handles all database operations for user templates
@DriftAccessor(tables: [Templates])
class TemplatesDao extends DatabaseAccessor<AppDatabase> with _$TemplatesDaoMixin {
  TemplatesDao(AppDatabase db) : super(db);

  /// Get all templates (excluding soft-deleted)
  Future<List<TemplateEntity>> getAllTemplates() {
    return (select(templates)..where((t) => t.deletedAt.isNull())).get();
  }

  /// Get template by ID
  Future<TemplateEntity?> getTemplateById(String id) {
    return (select(templates)..where((t) => t.id.equals(id) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Get template by role
  Future<TemplateEntity?> getTemplateByRole(String role) {
    return (select(templates)..where((t) => t.role.equals(role) & t.deletedAt.isNull()))
        .getSingleOrNull();
  }

  /// Insert new template
  Future<int> insertTemplate(TemplatesCompanion template) {
    return into(templates).insert(template);
  }

  /// Update existing template
  Future<bool> updateTemplate(TemplateEntity template) {
    return update(templates).replace(template);
  }

  /// Soft delete template
  Future<int> deleteTemplate(String id) {
    return (update(templates)..where((t) => t.id.equals(id))).write(
      TemplatesCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
        needsSync: const Value(true),
      ),
    );
  }

  /// Hard delete template (for admin only)
  Future<int> hardDeleteTemplate(String id) {
    return (delete(templates)..where((t) => t.id.equals(id))).go();
  }

  /// Get templates that need syncing
  Future<List<TemplateEntity>> getTemplatesNeedingSync() {
    return (select(templates)..where((t) => t.needsSync.equals(true))).get();
  }

  /// Mark template as synced
  Future<int> markAsSynced(String id, DateTime syncTime) {
    return (update(templates)..where((t) => t.id.equals(id))).write(
      TemplatesCompanion(
        lastSyncedAt: Value(syncTime),
        needsSync: const Value(false),
      ),
    );
  }

  /// Watch all templates (for real-time UI updates)
  Stream<List<TemplateEntity>> watchAllTemplates() {
    return (select(templates)..where((t) => t.deletedAt.isNull())).watch();
  }
}
