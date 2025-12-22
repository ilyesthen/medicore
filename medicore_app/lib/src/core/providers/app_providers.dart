import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../types/proto_types.dart';

/// Stub providers for missing functionality
/// These are temporary stubs to allow compilation until features are implemented

/// AppDatabase provider (stub - database functionality handled by drift)
class AppDatabase {
  AppDatabase() {
    throw UnimplementedError('AppDatabase direct access not available - use repository providers instead');
  }
}

/// Nurse preferences repository provider (stub - not yet implemented)
class NursePreferencesRepository {
  NursePreferencesRepository() {
    throw UnimplementedError('NursePreferencesRepository not yet implemented');
  }
  
  Future<void> markNurseActive(String nurseId) async {
    throw UnimplementedError('NursePreferencesRepository not yet implemented');
  }
  
  Future<void> markNurseInactive(String nurseId) async {
    throw UnimplementedError('NursePreferencesRepository not yet implemented');
  }
  
  Future<List<String>?> getPreferredRoomIds(String nurseId) async {
    throw UnimplementedError('NursePreferencesRepository not yet implemented');
  }
}

/// Visits repository provider (stub - not yet implemented)
final visitsRepositoryProvider = Provider((ref) {
  throw UnimplementedError('VisitsRepository not yet implemented');
});

/// Patient visits provider (stub - not yet implemented)
final patientVisitsProvider = FutureProvider.family<List<Visit>, int>((ref, patientCode) async {
  return [];
});

/// Patient visit count provider (stub - not yet implemented)  
final patientVisitCountProvider = FutureProvider.family<int, int>((ref, patientCode) async {
  return 0;
});

/// Ordonnances repository provider (stub - not yet implemented)
final ordonnancesRepositoryProvider = Provider((ref) {
  throw UnimplementedError('OrdonnancesRepository not yet implemented');
});

/// Medications repository provider (stub - not yet implemented)
final medicationsRepositoryProvider = Provider((ref) {
  throw UnimplementedError('MedicationsRepository not yet implemented');
});

/// Appointments repository provider (stub - not yet implemented)
final appointmentsRepositoryProvider = Provider((ref) {
  throw UnimplementedError('AppointmentsRepository not yet implemented');
});

/// Surgery plans repository provider (stub - not yet implemented)
final surgeryPlansRepositoryProvider = Provider((ref) {
  throw UnimplementedError('SurgeryPlansRepository not yet implemented');
});

/// Medical acts repository provider (stub - not yet implemented)
final medicalActsRepositoryProvider = Provider((ref) {
  throw UnimplementedError('MedicalActsRepository not yet implemented');
});

/// Database path class (stub)
class DatabasePath {
  static String? _path;
  
  static String get path {
    if (_path == null) {
      throw UnimplementedError('DatabasePath not initialized');
    }
    return _path!;
  }
  
  static void setPath(String path) {
    _path = path;
  }
}
