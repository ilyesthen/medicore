import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';

/// Repository for message template operations
class MessageTemplatesRepository {
  final AppDatabase _db;

  MessageTemplatesRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Get all templates
  Stream<List<MessageTemplate>> watchAllTemplates() {
    return (_db.select(_db.messageTemplates)
          ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
        .watch();
  }

  /// Get a specific template
  Future<MessageTemplate?> getTemplate(int id) async {
    return await (_db.select(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new template
  Future<MessageTemplate> createTemplate({
    required String content,
    required String createdBy,
  }) async {
    // Get max display order
    final query = _db.selectOnly(_db.messageTemplates)
      ..addColumns([_db.messageTemplates.displayOrder.max()]);
    final result = await query.getSingleOrNull();
    final maxOrder = result?.read(_db.messageTemplates.displayOrder.max()) ?? 0;

    final companion = MessageTemplatesCompanion.insert(
      content: content,
      displayOrder: maxOrder + 1,
      createdAt: DateTime.now(),
      createdBy: Value(createdBy),
    );

    final id = await _db.into(_db.messageTemplates).insert(companion);
    return (await getTemplate(id))!;
  }

  /// Update a template
  Future<void> updateTemplate({
    required int id,
    required String content,
  }) async {
    await (_db.update(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .write(MessageTemplatesCompanion(
      content: Value(content),
    ));
  }

  /// Delete a template
  Future<void> deleteTemplate(int id) async {
    await (_db.delete(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Reorder templates
  Future<void> reorderTemplates(List<int> orderedIds) async {
    for (int i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.messageTemplates)
            ..where((t) => t.id.equals(orderedIds[i])))
          .write(MessageTemplatesCompanion(
        displayOrder: Value(i + 1),
      ));
    }
  }
}
