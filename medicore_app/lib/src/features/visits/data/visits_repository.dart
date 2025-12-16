import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Provider for the database instance (visits module)
final _databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase();
});

/// Repository for managing patient visits
class VisitsRepository {
  final AppDatabase _db;

  VisitsRepository(this._db);

  /// Get all visits for a specific patient
  Future<List<Visit>> getVisitsForPatient(int patientCode) async {
    // Client mode: use REST API
    if (!GrpcClientConfig.isServer) {
      try {
        print('📤 [VisitsRepository] Fetching visits for patient: $patientCode');
        final response = await MediCoreClient.instance.getVisitsForPatient(patientCode);
        final visits = (response['visits'] as List<dynamic>?) ?? [];
        print('📥 [VisitsRepository] Received ${visits.length} visits');
        return visits.map((v) => _mapToVisit(v as Map<String, dynamic>)).toList();
      } catch (e, stackTrace) {
        print('❌ [VisitsRepository] Remote fetch failed: $e');
        print('📍 Stack trace: $stackTrace');
        return [];
      }
    }
    
    // Admin mode: use local database
    return await (_db.select(_db.visits)
          ..where((v) => v.patientCode.equals(patientCode))
          ..where((v) => v.isActive.equals(true))
          ..orderBy([(v) => OrderingTerm.desc(v.visitDate)]))
        .get();
  }
  
  /// Map JSON to Visit object (includes ALL fields)
  Visit _mapToVisit(Map<String, dynamic> json) {
    return Visit(
      id: (json['id'] as num).toInt(),
      patientCode: (json['patient_code'] as num).toInt(),
      visitSequence: (json['visit_sequence'] as num?)?.toInt() ?? 1,
      visitDate: DateTime.tryParse(json['visit_date'] as String? ?? '') ?? DateTime.now(),
      doctorName: json['doctor_name'] as String? ?? '',
      motif: json['motif'] as String?,
      diagnosis: json['diagnosis'] as String?,
      conduct: json['conduct'] as String?,
      // Right Eye (OD)
      odSv: json['od_sv'] as String?,
      odAv: json['od_av'] as String?,
      odSphere: json['od_sphere'] as String?,
      odCylinder: json['od_cylinder'] as String?,
      odAxis: json['od_axis'] as String?,
      odVl: json['od_vl'] as String?,
      odK1: json['od_k1'] as String?,
      odK2: json['od_k2'] as String?,
      odR1: json['od_r1'] as String?,
      odR2: json['od_r2'] as String?,
      odR0: json['od_r0'] as String?,
      odPachy: json['od_pachy'] as String?,
      odToc: json['od_toc'] as String?,
      odNotes: json['od_notes'] as String?,
      odGonio: json['od_gonio'] as String?,
      odTo: json['od_to'] as String?,
      odLaf: json['od_laf'] as String?,
      odFo: json['od_fo'] as String?,
      // Left Eye (OG)
      ogSv: json['og_sv'] as String?,
      ogAv: json['og_av'] as String?,
      ogSphere: json['og_sphere'] as String?,
      ogCylinder: json['og_cylinder'] as String?,
      ogAxis: json['og_axis'] as String?,
      ogVl: json['og_vl'] as String?,
      ogK1: json['og_k1'] as String?,
      ogK2: json['og_k2'] as String?,
      ogR1: json['og_r1'] as String?,
      ogR2: json['og_r2'] as String?,
      ogR0: json['og_r0'] as String?,
      ogPachy: json['og_pachy'] as String?,
      ogToc: json['og_toc'] as String?,
      ogNotes: json['og_notes'] as String?,
      ogGonio: json['og_gonio'] as String?,
      ogTo: json['og_to'] as String?,
      ogLaf: json['og_laf'] as String?,
      ogFo: json['og_fo'] as String?,
      // Shared
      addition: json['addition'] as String?,
      dip: json['dip'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      needsSync: false,
    );
  }

  /// Get visit count for a patient
  Future<int> getVisitCountForPatient(int patientCode) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      final visits = await getVisitsForPatient(patientCode);
      return visits.length;
    }
    final count = await (_db.select(_db.visits)
          ..where((v) => v.patientCode.equals(patientCode))
          ..where((v) => v.isActive.equals(true)))
        .get();
    return count.length;
  }

  /// Get a single visit by ID
  Future<Visit?> getVisitById(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getVisitById(id);
        if (response.isEmpty) return null;
        return _mapToVisit(response);
      } catch (e) {
        print('❌ [VisitsRepository] Remote getVisitById failed: $e');
        return null;
      }
    }
    
    return await (_db.select(_db.visits)
          ..where((v) => v.id.equals(id)))
        .getSingleOrNull();
  }

  /// Insert a new visit
  Future<int> insertVisit(VisitsCompanion visit) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final json = _visitCompanionToJson(visit);
        print('📤 [VisitsRepository] Creating visit: patient_code=${json['patient_code']}, date=${json['visit_date']}');
        final result = await MediCoreClient.instance.createVisit(json);
        print('✅ [VisitsRepository] Visit created with ID: $result');
        return result;
      } catch (e, stackTrace) {
        print('❌ [VisitsRepository] Remote insert failed: $e');
        print('📍 Stack trace: $stackTrace');
        return -1;
      }
    }
    return await _db.into(_db.visits).insert(visit);
  }
  
  /// Convert VisitsCompanion to JSON with all fields
  /// Uses helper to safely extract values from Value<T> (handles absent values)
  Map<String, dynamic> _visitCompanionToJson(VisitsCompanion visit) {
    T? _val<T>(Value<T> v) => v.present ? v.value : null;
    
    return {
      'patient_code': _val(visit.patientCode),
      'visit_sequence': _val(visit.visitSequence) ?? 1, // Default to 1 if not set
      'visit_date': _val(visit.visitDate)?.toIso8601String(),
      'doctor_name': _val(visit.doctorName),
      'motif': _val(visit.motif),
      'diagnosis': _val(visit.diagnosis),
      'conduct': _val(visit.conduct),
      // Right Eye (OD)
      'od_sv': _val(visit.odSv),
      'od_av': _val(visit.odAv),
      'od_sphere': _val(visit.odSphere),
      'od_cylinder': _val(visit.odCylinder),
      'od_axis': _val(visit.odAxis),
      'od_vl': _val(visit.odVl),
      'od_k1': _val(visit.odK1),
      'od_k2': _val(visit.odK2),
      'od_r1': _val(visit.odR1),
      'od_r2': _val(visit.odR2),
      'od_r0': _val(visit.odR0),
      'od_pachy': _val(visit.odPachy),
      'od_toc': _val(visit.odToc),
      'od_notes': _val(visit.odNotes),
      'od_gonio': _val(visit.odGonio),
      'od_to': _val(visit.odTo),
      'od_laf': _val(visit.odLaf),
      'od_fo': _val(visit.odFo),
      // Left Eye (OG)
      'og_sv': _val(visit.ogSv),
      'og_av': _val(visit.ogAv),
      'og_sphere': _val(visit.ogSphere),
      'og_cylinder': _val(visit.ogCylinder),
      'og_axis': _val(visit.ogAxis),
      'og_vl': _val(visit.ogVl),
      'og_k1': _val(visit.ogK1),
      'og_k2': _val(visit.ogK2),
      'og_r1': _val(visit.ogR1),
      'og_r2': _val(visit.ogR2),
      'og_r0': _val(visit.ogR0),
      'og_pachy': _val(visit.ogPachy),
      'og_toc': _val(visit.ogToc),
      'og_notes': _val(visit.ogNotes),
      'og_gonio': _val(visit.ogGonio),
      'og_to': _val(visit.ogTo),
      'og_laf': _val(visit.ogLaf),
      'og_fo': _val(visit.ogFo),
      // Shared
      'addition': _val(visit.addition),
      'dip': _val(visit.dip),
    };
  }

  /// Insert multiple visits (batch import)
  Future<void> insertVisits(List<VisitsCompanion> visits) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final visitsData = visits.map((v) => _visitCompanionToJson(v)).toList();
        await MediCoreClient.instance.insertVisits(visitsData);
        return;
      } catch (e) {
        print('❌ [VisitsRepository] Remote insertVisits failed: $e');
        return;
      }
    }
    await _db.batch((batch) {
      batch.insertAll(_db.visits, visits);
    });
  }

  /// Update an existing visit
  Future<bool> updateVisit(int id, VisitsCompanion visit) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final data = _visitCompanionToJson(visit);
        data['id'] = id;
        print('📤 [VisitsRepository] Updating visit ID: $id');
        await MediCoreClient.instance.updateVisit(data);
        print('✅ [VisitsRepository] Visit updated successfully');
        return true;
      } catch (e, stackTrace) {
        print('❌ [VisitsRepository] Remote update failed: $e');
        print('📍 Stack trace: $stackTrace');
        return false;
      }
    }
    return await (_db.update(_db.visits)..where((v) => v.id.equals(id)))
            .write(visit) >
        0;
  }

  /// Soft delete a visit
  Future<bool> deleteVisit(int id) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deleteVisit(id);
        return true;
      } catch (e) {
        print('❌ [VisitsRepository] Remote delete failed: $e');
        return false;
      }
    }
    return await (_db.update(_db.visits)..where((v) => v.id.equals(id)))
            .write(const VisitsCompanion(isActive: Value(false))) >
        0;
  }

  /// Check if visits exist for a patient
  Future<bool> hasVisitsForPatient(int patientCode) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      final visits = await getVisitsForPatient(patientCode);
      return visits.isNotEmpty;
    }
    final result = await (_db.select(_db.visits)
          ..where((v) => v.patientCode.equals(patientCode))
          ..where((v) => v.isActive.equals(true))
          ..limit(1))
        .get();
    return result.isNotEmpty;
  }

  /// Get total visit count in database
  Future<int> getTotalVisitCount() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.getTotalVisitCount();
      } catch (e) {
        print('❌ [VisitsRepository] Remote getTotalVisitCount failed: $e');
        return 0;
      }
    }
    final count = await (_db.select(_db.visits)
          ..where((v) => v.isActive.equals(true)))
        .get();
    return count.length;
  }

  /// Clear all visits (for reimport)
  Future<int> clearAllVisits() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.clearAllVisits();
      } catch (e) {
        print('❌ [VisitsRepository] Remote clearAllVisits failed: $e');
        return 0;
      }
    }
    return await _db.delete(_db.visits).go();
  }
}

/// Provider for visits repository
final visitsRepositoryProvider = Provider<VisitsRepository>((ref) {
  final db = ref.watch(_databaseProvider);
  return VisitsRepository(db);
});

/// Provider for visits of a specific patient
final patientVisitsProvider = FutureProvider.family<List<Visit>, int>((ref, patientCode) async {
  final repository = ref.watch(visitsRepositoryProvider);
  return repository.getVisitsForPatient(patientCode);
});

/// Provider for visit count of a specific patient
final patientVisitCountProvider = FutureProvider.family<int, int>((ref, patientCode) async {
  final repository = ref.watch(visitsRepositoryProvider);
  return repository.getVisitCountForPatient(patientCode);
});
