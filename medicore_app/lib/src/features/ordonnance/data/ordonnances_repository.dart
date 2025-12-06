import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';

/// Repository for ordonnances/documents
class OrdonnancesRepository {
  final AppDatabase _db;
  
  OrdonnancesRepository([AppDatabase? db]) : _db = db ?? AppDatabase();
  
  /// Get all documents for a patient (all types combined)
  /// Returns list sorted by date descending
  Future<List<OrdonnanceDocument>> getDocumentsForPatient(int patientCode) async {
    final rows = await (_db.select(_db.ordonnances)
      ..where((t) => t.patientCode.equals(patientCode))
      ..orderBy([(t) => OrderingTerm.desc(t.documentDate), (t) => OrderingTerm.desc(t.id)])
    ).get();
    
    // Flatten: each row can have up to 3 documents
    final documents = <OrdonnanceDocument>[];
    
    for (final row in rows) {
      // Primary document (STRAIT / ACTEX)
      if (row.content1 != null && row.content1!.isNotEmpty) {
        documents.add(OrdonnanceDocument(
          id: row.id,
          patientCode: row.patientCode,
          documentDate: row.documentDate,
          sequence: row.sequence,
          doctorName: row.doctorName,
          content: row.content1!,
          type: row.type1,
          reportTitle: row.reportTitle,
          referredBy: row.referredBy,
          slot: 1,
        ));
      }
      
      // Secondary document (strait1 / ACTEX1)
      if (row.content2 != null && row.content2!.isNotEmpty) {
        documents.add(OrdonnanceDocument(
          id: row.id,
          patientCode: row.patientCode,
          documentDate: row.documentDate,
          sequence: row.sequence,
          doctorName: row.doctorName,
          content: row.content2!,
          type: row.type2 ?? 'DOCUMENT',
          reportTitle: row.reportTitle,
          referredBy: row.referredBy,
          slot: 2,
        ));
      }
      
      // Third document (strait2 / ACTEX2)
      if (row.content3 != null && row.content3!.isNotEmpty) {
        documents.add(OrdonnanceDocument(
          id: row.id,
          patientCode: row.patientCode,
          documentDate: row.documentDate,
          sequence: row.sequence,
          doctorName: row.doctorName,
          content: row.content3!,
          type: row.type3 ?? 'DOCUMENT',
          reportTitle: row.reportTitle,
          referredBy: row.referredBy,
          slot: 3,
        ));
      }
    }
    
    return documents;
  }
  
  /// Get documents filtered by type category
  Future<List<OrdonnanceDocument>> getDocumentsByCategory(int patientCode, DocumentCategory category) async {
    final all = await getDocumentsForPatient(patientCode);
    return all.where((d) => d.category == category).toList();
  }
  
  /// Get document count for patient
  Future<int> getDocumentCount(int patientCode) async {
    final docs = await getDocumentsForPatient(patientCode);
    return docs.length;
  }
  
  /// Insert new ordonnance
  Future<int> insertOrdonnance(OrdonnancesCompanion ordonnance) async {
    return await _db.into(_db.ordonnances).insert(ordonnance);
  }
  
  /// Update existing ordonnance
  Future<bool> updateOrdonnance(int id, OrdonnancesCompanion ordonnance) async {
    return await (_db.update(_db.ordonnances)
      ..where((t) => t.id.equals(id))
    ).write(ordonnance) > 0;
  }
  
  /// Delete ordonnance
  Future<int> deleteOrdonnance(int id) async {
    return await (_db.delete(_db.ordonnances)
      ..where((t) => t.id.equals(id))
    ).go();
  }
}

/// Flattened document representation
class OrdonnanceDocument {
  final int id;
  final int patientCode;
  final DateTime? documentDate;
  final int sequence;
  final String? doctorName;
  final String content;
  final String type;
  final String? reportTitle;
  final String? referredBy;
  final int slot; // 1, 2, or 3
  
  OrdonnanceDocument({
    required this.id,
    required this.patientCode,
    this.documentDate,
    required this.sequence,
    this.doctorName,
    required this.content,
    required this.type,
    this.reportTitle,
    this.referredBy,
    required this.slot,
  });
  
  /// Get display title for the document
  String get displayTitle {
    if (reportTitle != null && reportTitle!.isNotEmpty) {
      return reportTitle!;
    }
    return type;
  }
  
  /// Get document category for tab filtering
  DocumentCategory get category {
    final upperType = type.toUpperCase();
    
    // Tab 1: Prescriptions
    if (upperType == 'ORDONNANCE' || 
        upperType == 'CORRECTION OPTIQUE' ||
        upperType == 'LENTILLES DE CONTACT') {
      return DocumentCategory.prescriptions;
    }
    
    // Tab 2: Bilan (certificates, requests)
    if (upperType.contains('CERTIFICAT') ||
        upperType.contains('DEMANDE') ||
        upperType == 'ORIENTATION' ||
        upperType == 'FACTURE') {
      return DocumentCategory.bilan;
    }
    
    // Tab 3: Comptes Rendus (reports, responses)
    if (upperType.contains('COMPTE RENDU') ||
        upperType == 'REPONSE' ||
        upperType.contains('PROTOCOLE')) {
      return DocumentCategory.comptesRendus;
    }
    
    // Default to bilan
    return DocumentCategory.bilan;
  }
  
  /// Format date for display
  String get formattedDate {
    if (documentDate == null) return '';
    final d = documentDate!;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

/// Document categories for tabs
enum DocumentCategory {
  prescriptions,  // Tab 1
  bilan,          // Tab 2
  comptesRendus,  // Tab 3
}

/// Provider
final ordonnancesRepositoryProvider = Provider<OrdonnancesRepository>((ref) {
  return OrdonnancesRepository();
});

/// Provider for patient documents
final patientDocumentsProvider = FutureProvider.family<List<OrdonnanceDocument>, int>((ref, patientCode) async {
  final repo = ref.watch(ordonnancesRepositoryProvider);
  return repo.getDocumentsForPatient(patientCode);
});

/// Provider for document count
final patientDocumentCountProvider = FutureProvider.family<int, int>((ref, patientCode) async {
  final repo = ref.watch(ordonnancesRepositoryProvider);
  return repo.getDocumentCount(patientCode);
});
