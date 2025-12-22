import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../core/types/proto_types.dart';

/// Service to build comprehensive patient context for AI analysis
/// Collects ALL patient data: demographics, visits, documents
/// Sorts chronologically (oldest → newest) for treatment progression understanding
class PatientContextService {
  // Stub - repositories not yet implemented with gRPC
  
  // Cache for follow-up questions (context caching)
  static int? _cachedPatientCode;
  static String? _cachedContext;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);
  
  PatientContextService();
  
  /// Check if we have valid cached context for this patient
  bool hasCachedContext(int patientCode) {
    if (_cachedPatientCode != patientCode) return false;
    if (_cachedContext == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheDuration;
  }
  
  /// Get cached context (for follow-up questions)
  String? getCachedContext(int patientCode) {
    if (hasCachedContext(patientCode)) return _cachedContext;
    return null;
  }
  
  /// Clear cache (call when switching patients)
  void clearCache() {
    _cachedPatientCode = null;
    _cachedContext = null;
    _cacheTime = null;
  }
  
  /// Build complete patient context for AI
  /// Returns a massive text block with ALL patient data sorted chronologically
  Future<PatientContextResult> buildPatientContext(int patientCode) async {
    // Check cache first
    if (hasCachedContext(patientCode)) {
      return PatientContextResult(
        success: true,
        context: _cachedContext!,
        patientCode: patientCode,
        fromCache: true,
      );
    }
    
    // TODO: Implement patient context in gRPC mode
    // Repositories not yet implemented with gRPC
    return PatientContextResult(
      success: false,
      error: 'Patient context service not yet implemented in gRPC mode',
      patientCode: patientCode,
    );
    
    // Dead code - will be re-implemented with gRPC
    // final patient = await _patientsRepo.getPatientByCode(patientCode);
    // final visits = await _visitsRepo.getVisitsForPatient(patientCode);
    // final documents = await _ordonnancesRepo.getDocumentsForPatient(patientCode);
    
    // Build the comprehensive context
    // final context = _buildContextText(patient, visits, documents);
    final context = 'Patient context not available in gRPC mode';
    
    // Cache it
    // _cachedPatientCode = patientCode;
    // _cachedContext = context;
    // _cacheTime = DateTime.now();
    
    return PatientContextResult(
      success: true,
      context: context,
      patientCode: patientCode,
      visitCount: 0,
      documentCount: 0,
      fromCache: false,
    );
  }
  
  /// Build CLEAN JSON for AI consumption - no messy text that LLM can misread
  String _buildContextText(Patient patient, List<Visit> visits, List<OrdonnanceDocument> documents) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Build structured JSON object
    final patientData = <String, dynamic>{
      'patient_code': patient.code,
      'barcode': patient.barcode ?? '',
      'created_at': patient.createdAt ?? '',
      'age': patient.age,
      'dateNaissance': patient.dateOfBirth != null ? dateFormat.format(patient.dateOfBirth!) : null,
      'notes': patient.notes,
    };
    
    // Build visits as clean JSON array
    final visitsJson = <Map<String, dynamic>>[];
    for (final visit in visits) {
      visitsJson.add(_visitToJson(visit, dateFormat));
    }
    
    // Sort visits by date (oldest first)
    visitsJson.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    
    // Build documents as clean JSON array
    final docsJson = <Map<String, dynamic>>[];
    for (final doc in documents) {
      if (doc.documentDate != null) {
        docsJson.add(_documentToJson(doc, dateFormat));
      }
    }
    
    // Sort documents by date (oldest first)
    docsJson.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
    
    // Create the final structured object
    final fullContext = {
      'patient': patientData,
      'nombreVisites': visits.length,
      'nombreDocuments': documents.length,
      'visites': visitsJson,
      'documents': docsJson,
    };
    
    // Convert to pretty JSON for readability
    final encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(fullContext);
  }
  
  /// Convert a Visit to clean JSON with explicit field names
  Map<String, dynamic> _visitToJson(Visit visit, DateFormat dateFormat) {
    final json = <String, dynamic>{
      'date': dateFormat.format(visit.visitDate),
      'medecin': visit.doctorName,
    };
    
    // Add optional fields only if they have values
    if (visit.motif?.isNotEmpty ?? false) json['motif'] = visit.motif;
    if (visit.diagnosis?.isNotEmpty ?? false) json['diagnostic'] = visit.diagnosis;
    if (visit.conduct?.isNotEmpty ?? false) json['conduite'] = visit.conduct;
    
    // Right Eye (OD) - explicit object with clear field names
    final od = <String, dynamic>{};
    if (visit.odSv?.isNotEmpty ?? false) od['SV'] = visit.odSv;
    if (visit.odAv?.isNotEmpty ?? false) od['AV'] = visit.odAv;
    if (visit.odSphere?.isNotEmpty ?? false) od['sphere'] = visit.odSphere;
    if (visit.odCylinder?.isNotEmpty ?? false) od['cylindre'] = visit.odCylinder;
    if (visit.odAxis?.isNotEmpty ?? false) od['axe_degres'] = visit.odAxis; // EXPLICIT: degrees
    if (visit.odVl?.isNotEmpty ?? false) od['VL'] = visit.odVl;
    if (visit.odK1?.isNotEmpty ?? false) od['K1'] = visit.odK1;
    if (visit.odK2?.isNotEmpty ?? false) od['K2'] = visit.odK2;
    if (visit.odR1?.isNotEmpty ?? false) od['R1'] = visit.odR1;
    if (visit.odR2?.isNotEmpty ?? false) od['R2'] = visit.odR2;
    if (visit.odR0?.isNotEmpty ?? false) od['R0'] = visit.odR0;
    if (visit.odPachy?.isNotEmpty ?? false) od['pachymetrie'] = visit.odPachy;
    if (visit.odToc?.isNotEmpty ?? false) od['TOC'] = visit.odToc;
    if (visit.odTo?.isNotEmpty ?? false) od['TO_mmHg'] = visit.odTo; // EXPLICIT: mmHg
    if (visit.odGonio?.isNotEmpty ?? false) od['gonio'] = visit.odGonio;
    if (visit.odLaf?.isNotEmpty ?? false) od['LAF'] = visit.odLaf;
    if (visit.odFo?.isNotEmpty ?? false) od['FO'] = visit.odFo;
    if (visit.odNotes?.isNotEmpty ?? false) od['notes'] = visit.odNotes;
    if (od.isNotEmpty) json['OD'] = od;
    
    // Left Eye (OG) - explicit object with clear field names
    final og = <String, dynamic>{};
    if (visit.ogSv?.isNotEmpty ?? false) og['SV'] = visit.ogSv;
    if (visit.ogAv?.isNotEmpty ?? false) og['AV'] = visit.ogAv;
    if (visit.ogSphere?.isNotEmpty ?? false) og['sphere'] = visit.ogSphere;
    if (visit.ogCylinder?.isNotEmpty ?? false) og['cylindre'] = visit.ogCylinder;
    if (visit.ogAxis?.isNotEmpty ?? false) og['axe_degres'] = visit.ogAxis; // EXPLICIT: degrees
    if (visit.ogVl?.isNotEmpty ?? false) og['VL'] = visit.ogVl;
    if (visit.ogK1?.isNotEmpty ?? false) og['K1'] = visit.ogK1;
    if (visit.ogK2?.isNotEmpty ?? false) og['K2'] = visit.ogK2;
    if (visit.ogR1?.isNotEmpty ?? false) og['R1'] = visit.ogR1;
    if (visit.ogR2?.isNotEmpty ?? false) og['R2'] = visit.ogR2;
    if (visit.ogR0?.isNotEmpty ?? false) og['R0'] = visit.ogR0;
    if (visit.ogPachy?.isNotEmpty ?? false) og['pachymetrie'] = visit.ogPachy;
    if (visit.ogToc?.isNotEmpty ?? false) og['TOC'] = visit.ogToc;
    if (visit.ogTo?.isNotEmpty ?? false) og['TO_mmHg'] = visit.ogTo; // EXPLICIT: mmHg
    if (visit.ogGonio?.isNotEmpty ?? false) og['gonio'] = visit.ogGonio;
    if (visit.ogLaf?.isNotEmpty ?? false) og['LAF'] = visit.ogLaf;
    if (visit.ogFo?.isNotEmpty ?? false) og['FO'] = visit.ogFo;
    if (visit.ogNotes?.isNotEmpty ?? false) og['notes'] = visit.ogNotes;
    if (og.isNotEmpty) json['OG'] = og;
    
    // Shared fields
    if (visit.addition?.isNotEmpty ?? false) json['addition'] = visit.addition;
    if (visit.dip?.isNotEmpty ?? false) json['DIP'] = visit.dip;
    
    return json;
  }
  
  /// Convert a Document to clean JSON
  Map<String, dynamic> _documentToJson(OrdonnanceDocument doc, DateFormat dateFormat) {
    final json = <String, dynamic>{
      'date': dateFormat.format(doc.documentDate!),
      'type': doc.type,
    };
    
    if (doc.doctorName?.isNotEmpty ?? false) {
      json['medecin'] = doc.doctorName;
    }
    if (doc.reportTitle?.isNotEmpty ?? false) {
      json['titre'] = doc.reportTitle;
    }
    if (doc.referredBy?.isNotEmpty ?? false) {
      json['adressePar'] = doc.referredBy;
    }
    if (doc.content.isNotEmpty) {
      json['contenu'] = doc.content;
    }
    
    return json;
  }
  
  /// Check if a string value is non-null and non-empty
  bool _hasValue(String? value) {
    return value != null && value.trim().isNotEmpty;
  }
}

/// Result of building patient context
class PatientContextResult {
  final bool success;
  final String? context;
  final String? error;
  final int patientCode;
  final int visitCount;
  final int documentCount;
  final bool fromCache;
  
  PatientContextResult({
    required this.success,
    this.context,
    this.error,
    required this.patientCode,
    this.visitCount = 0,
    this.documentCount = 0,
    this.fromCache = false,
  });
}
