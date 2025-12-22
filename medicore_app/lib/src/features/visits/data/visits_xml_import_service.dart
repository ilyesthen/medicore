import 'dart:io';
import 'package:xml/xml.dart';
import 'visits_repository.dart';

/// Result of XML import operation
class VisitsImportResult {
  final int successCount;
  final int errorCount;
  final List<String> errors;

  VisitsImportResult({
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });

  bool get isSuccess => errorCount == 0;
}

/// Service for importing visits from XML files
class VisitsXmlImportService {
  final VisitsRepository _repository;

  VisitsXmlImportService(this._repository);

  /// Import visits from XML file
  Future<VisitsImportResult> importFromXml(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return VisitsImportResult(
        successCount: 0,
        errorCount: 1,
        errors: ['File not found: $filePath'],
      );
    }

    final xmlString = await file.readAsString();
    final document = XmlDocument.parse(xmlString);

    final visits = <VisitsCompanion>[];
    final errors = <String>[];
    int successCount = 0;
    int errorCount = 0;

    final elements = document.findAllElements('Table_Contenu');

    for (final element in elements) {
      try {
        final visit = _parseVisitElement(element);
        if (visit != null) {
          visits.add(visit);
          successCount++;
        }
      } catch (e) {
        errorCount++;
        final id = _getElementText(element, 'N__Enr.');
        errors.add('Error parsing visit $id: $e');
      }
    }

    // Batch insert all visits
    if (visits.isNotEmpty) {
      try {
        await _repository.insertVisits(visits);
      } catch (e) {
        errors.add('Database insert error: $e');
        errorCount += visits.length;
        successCount = 0;
      }
    }

    // Delete XML file after successful import
    if (errorCount == 0 && successCount > 0) {
      try {
        await file.delete();
      } catch (e) {
        errors.add('Warning: Could not delete XML file: $e');
      }
    }

    return VisitsImportResult(
      successCount: successCount,
      errorCount: errorCount,
      errors: errors,
    );
  }

  /// Parse a single visit element from XML
  VisitsCompanion? _parseVisitElement(XmlElement element) {
    // Get patient code (CDEP) - required
    final patientCodeStr = _getElementText(element, 'CDEP');
    if (patientCodeStr.isEmpty) return null;
    
    final patientCode = int.tryParse(patientCodeStr);
    if (patientCode == null || patientCode == 0) return null;

    // Get visit date (DATECLI) - required
    final dateStr = _getElementText(element, 'DATECLI');
    final visitDate = _parseDate(dateStr);
    if (visitDate == null) return null;

    // Get doctor name (MEDCIN) - required
    final doctorName = _getElementText(element, 'MEDCIN');
    if (doctorName.isEmpty) return null;

    final now = DateTime.now();

    return VisitsCompanion(
      originalId: Value(int.tryParse(_getElementText(element, 'N__Enr.'))),
      patientCode: Value(patientCode),
      visitSequence: Value(int.tryParse(_getElementText(element, 'SEQC')) ?? 1),
      visitDate: Value(visitDate),
      doctorName: Value(doctorName),
      motif: Value(_getElementTextNullable(element, 'MOTIF')),
      diagnosis: Value(_getElementTextNullable(element, 'DIIAG')),
      conduct: Value(_getElementTextNullable(element, 'CAT')),
      
      // Right Eye (OD)
      odSv: Value(_getElementTextNullable(element, 'SCOD')),
      odAv: Value(_getElementTextNullable(element, 'AVOD')),
      odSphere: Value(_getElementTextNullable(element, 'p1')),
      odCylinder: Value(_getElementTextNullable(element, 'p2')),
      odAxis: Value(_getElementTextNullable(element, 'AXD')),
      odVl: Value(_getElementTextNullable(element, 'VPOD')),
      odK1: Value(_getElementTextNullable(element, 'K1_D')),
      odK2: Value(_getElementTextNullable(element, 'K2_D')),
      odR1: Value(_getElementTextNullable(element, 'R1_d')),
      odR2: Value(_getElementTextNullable(element, 'R2_d')),
      odR0: Value(_getElementTextNullable(element, 'RAYOND')),
      odPachy: Value(_getElementTextNullable(element, 'pachy1_D')),
      odToc: Value(_getElementTextNullable(element, 'TOOD')),
      odNotes: Value(_getElementTextNullable(element, 'comentaire_D')),
      odGonio: Value(_getElementTextNullable(element, 'VAD')),
      odTo: Value(_getElementTextNullable(element, 'TOOD')),
      odLaf: Value(_getElementTextNullable(element, 'LAF')),
      odFo: Value(_getElementTextNullable(element, 'FO')),
      
      // Left Eye (OG)
      ogSv: Value(_getElementTextNullable(element, 'SCOG')),
      ogAv: Value(_getElementTextNullable(element, 'AVOG')),
      ogSphere: Value(_getElementTextNullable(element, 'p3')),
      ogCylinder: Value(_getElementTextNullable(element, 'p5')),
      ogAxis: Value(_getElementTextNullable(element, 'AXG')),
      ogVl: Value(_getElementTextNullable(element, 'VPOG')),
      ogK1: Value(_getElementTextNullable(element, 'K1_G')),
      ogK2: Value(_getElementTextNullable(element, 'K2_G')),
      ogR1: Value(_getElementTextNullable(element, 'R1_G')),
      ogR2: Value(_getElementTextNullable(element, 'R2_G')),
      ogR0: Value(_getElementTextNullable(element, 'RAYONG')),
      ogPachy: Value(_getElementTextNullable(element, 'pachy1_g')),
      ogToc: Value(_getElementTextNullable(element, 'TOOG')),
      ogNotes: Value(_getElementTextNullable(element, 'commentaire_G')),
      ogGonio: Value(_getElementTextNullable(element, 'VAG')),
      ogTo: Value(_getElementTextNullable(element, 'TOOG')),
      ogLaf: Value(_getElementTextNullable(element, 'LAF_G')),
      ogFo: Value(_getElementTextNullable(element, 'FO_G')),
      
      // Shared fields
      addition: Value(_getElementTextNullable(element, 'EP')),
      dip: Value(_getElementTextNullable(element, 'EP')),
      
      // Metadata
      createdAt: Value(now),
      updatedAt: Value(now),
      needsSync: const Value(true),
      isActive: const Value(true),
    );
  }

  /// Get text content of an XML element by tag name
  String _getElementText(XmlElement parent, String tagName) {
    final element = parent.findElements(tagName).firstOrNull;
    return element?.innerText.trim() ?? '';
  }

  /// Get text content or null if empty
  String? _getElementTextNullable(XmlElement parent, String tagName) {
    final text = _getElementText(parent, tagName);
    return text.isEmpty ? null : text;
  }

  /// Parse date from DD/MM/YYYY format
  DateTime? _parseDate(String dateStr) {
    if (dateStr.isEmpty) return null;
    
    try {
      final parts = dateStr.split('/');
      if (parts.length == 3) {
        final day = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final year = int.parse(parts[2]);
        return DateTime(year, month, day);
      }
    } catch (e) {
      // Invalid date format
    }
    return null;
  }
}
