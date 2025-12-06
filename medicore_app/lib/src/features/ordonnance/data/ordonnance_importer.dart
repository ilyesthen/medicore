import 'dart:io';
import 'package:drift/drift.dart';
import 'package:xml/xml.dart';
import '../../../core/database/app_database.dart';

/// Imports ordonnances from XML file preserving exact formatting
class OrdonnanceImporter {
  final AppDatabase _db;
  
  OrdonnanceImporter([AppDatabase? db]) : _db = db ?? AppDatabase();
  
  /// Import from XML file
  /// Returns (successCount, errorCount, totalRecords)
  Future<ImportResult> importFromXml(
    String xmlPath, {
    void Function(int current, int total)? onProgress,
  }) async {
    final file = File(xmlPath);
    if (!await file.exists()) {
      throw Exception('File not found: $xmlPath');
    }
    
    final xmlContent = await file.readAsString();
    final document = XmlDocument.parse(xmlContent);
    final records = document.findAllElements('Table_Contenu').toList();
    
    int success = 0;
    int errors = 0;
    final total = records.length;
    
    // Process in batches for better performance
    const batchSize = 100;
    
    for (int i = 0; i < records.length; i += batchSize) {
      final batch = records.skip(i).take(batchSize);
      
      await _db.transaction(() async {
        for (final record in batch) {
          try {
            await _insertRecord(record);
            success++;
          } catch (e) {
            errors++;
          }
        }
      });
      
      onProgress?.call(i + batchSize.clamp(0, records.length - i), total);
    }
    
    return ImportResult(
      successCount: success,
      errorCount: errors,
      totalRecords: total,
    );
  }
  
  Future<void> _insertRecord(XmlElement record) async {
    final originalId = _getInt(record, 'N__Enr.');
    final patientCode = _getInt(record, 'CDEP');
    
    if (patientCode == null) return;
    
    final dateOrd = _getText(record, 'DATEORD');
    final age = _getInt(record, 'AG2');
    final seq = _getInt(record, 'SEQ') ?? 1;
    final seqPat = _getText(record, 'SEQPAT');
    final doctorName = _getText(record, 'MEDCIN');
    final amount = _getDouble(record, 'SMONT') ?? 0;
    
    // Content fields - preserve exact formatting
    final content1 = _getTextPreserveFormat(record, 'STRAIT');
    final type1 = _getText(record, 'ACTEX') ?? 'ORDONNANCE';
    final content2 = _getTextPreserveFormat(record, 'strait1');
    final type2 = _getText(record, 'ACTEX1');
    final content3 = _getTextPreserveFormat(record, 'strait2');
    final type3 = _getText(record, 'ACTEX2');
    final additionalNotes = _getTextPreserveFormat(record, 'strait3');
    final reportTitle = _getText(record, 'titre_cr');
    final referredBy = _getText(record, 'ADressé_par');
    
    final rdvFlag = _getInt(record, 'rdvle') ?? 0;
    final rdvDate = _getText(record, 'datele');
    final rdvDay = _getText(record, 'jourle');
    
    // Parse date
    DateTime? documentDate;
    if (dateOrd != null && dateOrd.isNotEmpty) {
      documentDate = _parseDate(dateOrd);
    }
    
    await _db.into(_db.ordonnances).insert(OrdonnancesCompanion(
      originalId: Value(originalId),
      patientCode: Value(patientCode),
      documentDate: Value(documentDate),
      patientAge: Value(age),
      sequence: Value(seq),
      seqPat: Value(seqPat),
      doctorName: Value(doctorName),
      amount: Value(amount),
      content1: Value(content1),
      type1: Value(type1),
      content2: Value(content2),
      type2: Value(type2),
      content3: Value(content3),
      type3: Value(type3),
      additionalNotes: Value(additionalNotes),
      reportTitle: Value(reportTitle),
      referredBy: Value(referredBy),
      rdvFlag: Value(rdvFlag),
      rdvDate: Value(rdvDate),
      rdvDay: Value(rdvDay),
    ));
  }
  
  /// Get text content from element
  String? _getText(XmlElement parent, String name) {
    final elements = parent.findElements(name);
    if (elements.isEmpty) return null;
    final text = elements.first.innerText.trim();
    return text.isEmpty ? null : text;
  }
  
  /// Get text content preserving exact formatting
  String? _getTextPreserveFormat(XmlElement parent, String name) {
    final elements = parent.findElements(name);
    if (elements.isEmpty) return null;
    
    String text = elements.first.innerText;
    // Normalize line endings
    text = text.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    // Trim only leading/trailing but preserve internal formatting
    text = text.trim();
    
    return text.isEmpty ? null : text;
  }
  
  /// Get integer value
  int? _getInt(XmlElement parent, String name) {
    final text = _getText(parent, name);
    if (text == null) return null;
    return int.tryParse(text);
  }
  
  /// Get double value
  double? _getDouble(XmlElement parent, String name) {
    final text = _getText(parent, name);
    if (text == null) return null;
    return double.tryParse(text);
  }
  
  /// Parse date from DD/MM/YYYY format
  DateTime? _parseDate(String dateStr) {
    try {
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;
      final day = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final year = int.parse(parts[2]);
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }
  
  /// Check if ordonnances have been imported
  Future<bool> hasImportedData() async {
    final count = await _db.ordonnances.count().getSingle();
    return count > 0;
  }
  
  /// Get import count
  Future<int> getImportedCount() async {
    return await _db.ordonnances.count().getSingle();
  }
  
  /// Clear all imported ordonnances
  Future<int> clearAll() async {
    return await _db.delete(_db.ordonnances).go();
  }
}

/// Import result
class ImportResult {
  final int successCount;
  final int errorCount;
  final int totalRecords;
  
  ImportResult({
    required this.successCount,
    required this.errorCount,
    required this.totalRecords,
  });
  
  double get successRate => totalRecords > 0 ? successCount / totalRecords * 100 : 0;
}
