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
        final response = await MediCoreClient.instance.getVisitsForPatient(patientCode);
        final visits = (response['visits'] as List<dynamic>?) ?? [];
        return visits.map((v) => _mapToVisit(v as Map<String, dynamic>)).toList();
      } catch (e) {
        print('❌ [VisitsRepository] Remote fetch failed: $e');
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
  
  /// Map JSON to Visit object
  Visit _mapToVisit(Map<String, dynamic> json) {
    return Visit(
      id: json['id'] as int,
      patientCode: json['patient_code'] as int,
      visitSequence: json['visit_sequence'] as int? ?? 1,
      visitDate: DateTime.tryParse(json['visit_date'] as String? ?? '') ?? DateTime.now(),
      doctorName: json['doctor_name'] as String? ?? '',
      motif: json['motif'] as String?,
      diagnosis: json['diagnosis'] as String?,
      conduct: json['conduct'] as String?,
      odSv: json['od_sv'] as String?,
      odAv: json['od_av'] as String?,
      odSphere: json['od_sphere'] as String?,
      odCylinder: json['od_cylinder'] as String?,
      odAxis: json['od_axis'] as String?,
      odToc: json['od_toc'] as String?,
      ogSv: json['og_sv'] as String?,
      ogAv: json['og_av'] as String?,
      ogSphere: json['og_sphere'] as String?,
      ogCylinder: json['og_cylinder'] as String?,
      ogAxis: json['og_axis'] as String?,
      ogToc: json['og_toc'] as String?,
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
        return await MediCoreClient.instance.createVisit({
          'patient_code': visit.patientCode.value,
          'visit_date': visit.visitDate.value?.toIso8601String(),
          'doctor_name': visit.doctorName.value,
          'motif': visit.motif.value,
          'diagnosis': visit.diagnosis.value,
          'conduct': visit.conduct.value,
        });
      } catch (e) {
        print('❌ [VisitsRepository] Remote insert failed: $e');
        return -1;
      }
    }
    return await _db.into(_db.visits).insert(visit);
  }

  /// Insert multiple visits (batch import)
  Future<void> insertVisits(List<VisitsCompanion> visits) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final visitsData = visits.map((v) => {
          'patient_code': v.patientCode.value,
          'visit_sequence': v.visitSequence.value,
          'visit_date': v.visitDate.value?.toIso8601String(),
          'doctor_name': v.doctorName.value,
          'motif': v.motif.value,
          'diagnosis': v.diagnosis.value,
          'conduct': v.conduct.value,
        }).toList();
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
        await MediCoreClient.instance.updateVisit({
          'id': id,
          'motif': visit.motif.value,
          'diagnosis': visit.diagnosis.value,
          'conduct': visit.conduct.value,
        });
        return true;
      } catch (e) {
        print('❌ [VisitsRepository] Remote update failed: $e');
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
