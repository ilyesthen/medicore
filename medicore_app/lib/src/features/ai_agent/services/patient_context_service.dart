import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../patients/data/patients_repository.dart';
import '../../visits/data/visits_repository.dart';
import '../../ordonnance/data/ordonnances_repository.dart';

/// Service to build comprehensive patient context for AI analysis
/// Collects ALL patient data: demographics, visits, documents
/// Sorts chronologically (oldest → newest) for treatment progression understanding
class PatientContextService {
  final PatientsRepository _patientsRepo;
  final VisitsRepository _visitsRepo;
  final OrdonnancesRepository _ordonnancesRepo;
  
  // Cache for follow-up questions (context caching)
  static int? _cachedPatientCode;
  static String? _cachedContext;
  static DateTime? _cacheTime;
  static const _cacheDuration = Duration(minutes: 30);
  
  PatientContextService({
    PatientsRepository? patientsRepo,
    VisitsRepository? visitsRepo,
    OrdonnancesRepository? ordonnancesRepo,
  })  : _patientsRepo = patientsRepo ?? PatientsRepository(),
        _visitsRepo = visitsRepo ?? VisitsRepository(AppDatabase()),
        _ordonnancesRepo = ordonnancesRepo ?? OrdonnancesRepository();
  
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
    
    // Fetch patient basic info
    final patient = await _patientsRepo.getPatientByCode(patientCode);
    if (patient == null) {
      return PatientContextResult(
        success: false,
        error: 'Patient avec code $patientCode non trouvé',
        patientCode: patientCode,
      );
    }
    
    // Fetch all visits
    final visits = await _visitsRepo.getVisitsForPatient(patientCode);
    
    // Fetch all documents
    final documents = await _ordonnancesRepo.getDocumentsForPatient(patientCode);
    
    // Build the comprehensive context
    final context = _buildContextText(patient, visits, documents);
    
    // Cache it
    _cachedPatientCode = patientCode;
    _cachedContext = context;
    _cacheTime = DateTime.now();
    
    return PatientContextResult(
      success: true,
      context: context,
      patientCode: patientCode,
      visitCount: visits.length,
      documentCount: documents.length,
      fromCache: false,
    );
  }
  
  /// Build CLEAN JSON for AI consumption - no messy text that LLM can misread
  String _buildContextText(Patient patient, List<Visit> visits, List<OrdonnanceDocument> documents) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // Build structured JSON object
    final patientData = <String, dynamic>{
      'code': patient.code,
      'age': patient.age,
      'dateNaissance': patient.dateOfBirth != null ? dateFormat.format(patient.dateOfBirth!) : null,
      'notes': patient.otherInfo,
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
    if (_hasValue(visit.motif)) json['motif'] = visit.motif;
    if (_hasValue(visit.diagnosis)) json['diagnostic'] = visit.diagnosis;
    if (_hasValue(visit.conduct)) json['conduite'] = visit.conduct;
    
    // Right Eye (OD) - explicit object with clear field names
    final od = <String, dynamic>{};
    if (_hasValue(visit.odSv)) od['SV'] = visit.odSv;
    if (_hasValue(visit.odAv)) od['AV'] = visit.odAv;
    if (_hasValue(visit.odSphere)) od['sphere'] = visit.odSphere;
    if (_hasValue(visit.odCylinder)) od['cylindre'] = visit.odCylinder;
    if (_hasValue(visit.odAxis)) od['axe_degres'] = visit.odAxis; // EXPLICIT: degrees
    if (_hasValue(visit.odVl)) od['VL'] = visit.odVl;
    if (_hasValue(visit.odK1)) od['K1'] = visit.odK1;
    if (_hasValue(visit.odK2)) od['K2'] = visit.odK2;
    if (_hasValue(visit.odR1)) od['R1'] = visit.odR1;
    if (_hasValue(visit.odR2)) od['R2'] = visit.odR2;
    if (_hasValue(visit.odR0)) od['R0'] = visit.odR0;
    if (_hasValue(visit.odPachy)) od['pachymetrie'] = visit.odPachy;
    if (_hasValue(visit.odToc)) od['TOC'] = visit.odToc;
    if (_hasValue(visit.odTo)) od['TO_mmHg'] = visit.odTo; // EXPLICIT: mmHg
    if (_hasValue(visit.odGonio)) od['gonio'] = visit.odGonio;
    if (_hasValue(visit.odLaf)) od['LAF'] = visit.odLaf;
    if (_hasValue(visit.odFo)) od['FO'] = visit.odFo;
    if (_hasValue(visit.odNotes)) od['notes'] = visit.odNotes;
    if (od.isNotEmpty) json['OD'] = od;
    
    // Left Eye (OG) - explicit object with clear field names
    final og = <String, dynamic>{};
    if (_hasValue(visit.ogSv)) og['SV'] = visit.ogSv;
    if (_hasValue(visit.ogAv)) og['AV'] = visit.ogAv;
    if (_hasValue(visit.ogSphere)) og['sphere'] = visit.ogSphere;
    if (_hasValue(visit.ogCylinder)) og['cylindre'] = visit.ogCylinder;
    if (_hasValue(visit.ogAxis)) og['axe_degres'] = visit.ogAxis; // EXPLICIT: degrees
    if (_hasValue(visit.ogVl)) og['VL'] = visit.ogVl;
    if (_hasValue(visit.ogK1)) og['K1'] = visit.ogK1;
    if (_hasValue(visit.ogK2)) og['K2'] = visit.ogK2;
    if (_hasValue(visit.ogR1)) og['R1'] = visit.ogR1;
    if (_hasValue(visit.ogR2)) og['R2'] = visit.ogR2;
    if (_hasValue(visit.ogR0)) og['R0'] = visit.ogR0;
    if (_hasValue(visit.ogPachy)) og['pachymetrie'] = visit.ogPachy;
    if (_hasValue(visit.ogToc)) og['TOC'] = visit.ogToc;
    if (_hasValue(visit.ogTo)) og['TO_mmHg'] = visit.ogTo; // EXPLICIT: mmHg
    if (_hasValue(visit.ogGonio)) og['gonio'] = visit.ogGonio;
    if (_hasValue(visit.ogLaf)) og['LAF'] = visit.ogLaf;
    if (_hasValue(visit.ogFo)) og['FO'] = visit.ogFo;
    if (_hasValue(visit.ogNotes)) og['notes'] = visit.ogNotes;
    if (og.isNotEmpty) json['OG'] = og;
    
    // Shared fields
    if (_hasValue(visit.addition)) json['addition'] = visit.addition;
    if (_hasValue(visit.dip)) json['DIP'] = visit.dip;
    
    return json;
  }
  
  /// Convert a Document to clean JSON
  Map<String, dynamic> _documentToJson(OrdonnanceDocument doc, DateFormat dateFormat) {
    final json = <String, dynamic>{
      'date': dateFormat.format(doc.documentDate!),
      'type': doc.type,
    };
    
    if (doc.doctorName != null && doc.doctorName!.isNotEmpty) {
      json['medecin'] = doc.doctorName;
    }
    if (doc.reportTitle != null && doc.reportTitle!.isNotEmpty) {
      json['titre'] = doc.reportTitle;
    }
    if (doc.referredBy != null && doc.referredBy!.isNotEmpty) {
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
