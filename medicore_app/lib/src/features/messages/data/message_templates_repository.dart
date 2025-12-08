import 'dart:async';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Repository for message template operations
class MessageTemplatesRepository {
  final AppDatabase _db;

  MessageTemplatesRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

  /// Get all templates
  Stream<List<MessageTemplate>> watchAllTemplates() {
    // Client mode: poll remote
    if (!GrpcClientConfig.isServer) {
      return _watchTemplatesRemote();
    }
    return (_db.select(_db.messageTemplates)
          ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
        .watch();
  }
  
  Stream<List<MessageTemplate>> _watchTemplatesRemote() async* {
    yield await _fetchTemplatesRemote();
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      yield await _fetchTemplatesRemote();
    }
  }
  
  Future<List<MessageTemplate>> _fetchTemplatesRemote() async {
    try {
      final response = await MediCoreClient.instance.getAllMessageTemplates();
      final templates = (response['templates'] as List<dynamic>?) ?? [];
      return templates.map((t) {
        final json = t as Map<String, dynamic>;
        return MessageTemplate(
          id: json['id'] as int,
          content: json['content'] as String,
          displayOrder: json['display_order'] as int? ?? 0,
          createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
          createdBy: json['created_by'] as String?,
        );
      }).toList();
    } catch (e) {
      print('❌ [MessageTemplatesRepository] Remote fetch failed: $e');
      return [];
    }
  }

  /// Get a specific template
  Future<MessageTemplate?> getTemplate(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getMessageTemplateById(id);
        if (response.isEmpty) return null;
        return MessageTemplate(
          id: response['id'] as int,
          content: response['content'] as String,
          displayOrder: response['display_order'] as int? ?? 0,
          createdAt: DateTime.tryParse(response['created_at'] as String? ?? '') ?? DateTime.now(),
          createdBy: response['created_by'] as String?,
        );
      } catch (e) {
        print('❌ [MessageTemplatesRepository] Remote getTemplate failed: $e');
        return null;
      }
    }
    
    return await (_db.select(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Create a new template
  Future<MessageTemplate> createTemplate({
    required String content,
    required String createdBy,
  }) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final id = await MediCoreClient.instance.createMessageTemplate(content: content, createdBy: createdBy);
        return MessageTemplate(
          id: id,
          content: content,
          displayOrder: 0,
          createdAt: DateTime.now(),
          createdBy: createdBy,
        );
      } catch (e) {
        print('❌ [MessageTemplatesRepository] Remote create failed: $e');
        rethrow;
      }
    }
    
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.updateMessageTemplate(id: id, content: content);
        return;
      } catch (e) {
        print('❌ [MessageTemplatesRepository] Remote update failed: $e');
        rethrow;
      }
    }
    
    await (_db.update(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .write(MessageTemplatesCompanion(
      content: Value(content),
    ));
  }

  /// Delete a template
  Future<void> deleteTemplate(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deleteMessageTemplate(id);
        return;
      } catch (e) {
        print('❌ [MessageTemplatesRepository] Remote delete failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.messageTemplates)
          ..where((t) => t.id.equals(id)))
        .go();
  }

  /// Reorder templates
  Future<void> reorderTemplates(List<int> orderedIds) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.reorderMessageTemplates(orderedIds);
        return;
      } catch (e) {
        print('❌ [MessageTemplatesRepository] Remote reorderTemplates failed: $e');
        rethrow;
      }
    }
    
    for (int i = 0; i < orderedIds.length; i++) {
      await (_db.update(_db.messageTemplates)
            ..where((t) => t.id.equals(orderedIds[i])))
          .write(MessageTemplatesCompanion(
        displayOrder: Value(i + 1),
      ));
    }
  }
}
