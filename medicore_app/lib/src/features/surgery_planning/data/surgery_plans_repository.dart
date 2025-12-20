import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Repository for surgery plans - works on both admin and client modes
class SurgeryPlansRepository {
  final AppDatabase _db;
  
  SurgeryPlansRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  
  /// Predefined surgery types
  static const List<String> surgeryTypes = [
    'Cataracte - phacoemulsification',
    'Cataracte - EEC',
    'ICL',
    'DCR',
    'Sondage sous AG',
    'Entropion',
    'ECTROPION',
    'PTOSIS - Résection RPS',
  ];
  
  /// Eye options
  static const List<String> eyeOptions = ['OD', 'OG', 'ODG'];
  
  /// Payment statuses
  static const List<String> paymentStatuses = ['pending', 'partial', 'paid'];
  
  /// Surgery statuses
  static const List<String> surgeryStatuses = ['scheduled', 'done', 'cancelled'];
  
  /// Get surgery plans for a specific date
  Future<List<SurgeryPlan>> getSurgeryPlansForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getSurgeryPlansForDate(date);
        return _mapSurgeryPlansFromJson(response['surgery_plans'] as List<dynamic>? ?? []);
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote fetch failed: $e');
        return [];
      }
    }
    
    return await (_db.select(_db.surgeryPlans)
      ..where((t) => t.surgeryDate.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(t) => OrderingTerm.asc(t.surgeryHour)])
    ).get();
  }
  
  /// Get all surgery plans
  Future<List<SurgeryPlan>> getAllSurgeryPlans() async {
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllSurgeryPlans();
        return _mapSurgeryPlansFromJson(response['surgery_plans'] as List<dynamic>? ?? []);
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote fetch failed: $e');
        return [];
      }
    }
    
    return await (_db.select(_db.surgeryPlans)
      ..orderBy([(t) => OrderingTerm.asc(t.surgeryDate), (t) => OrderingTerm.asc(t.surgeryHour)])
    ).get();
  }
  
  /// Add new surgery plan
  Future<int> addSurgeryPlan({
    required DateTime surgeryDate,
    required String surgeryHour,
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    int? patientAge,
    String? patientPhone,
    required String surgeryType,
    required String eyeToOperate,
    String? implantPower,
    int? tarif,
    String? notes,
    String? createdBy,
  }) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.createSurgeryPlan({
          'surgery_date': surgeryDate.toIso8601String(),
          'surgery_hour': surgeryHour,
          'patient_code': patientCode,
          'patient_first_name': patientFirstName,
          'patient_last_name': patientLastName,
          'patient_age': patientAge,
          'patient_phone': patientPhone,
          'surgery_type': surgeryType,
          'eye_to_operate': eyeToOperate,
          'implant_power': implantPower,
          'tarif': tarif,
          'notes': notes,
          'created_by': createdBy,
        });
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote create failed: $e');
        return -1;
      }
    }
    
    return await _db.into(_db.surgeryPlans).insert(
      SurgeryPlansCompanion.insert(
        surgeryDate: surgeryDate,
        surgeryHour: surgeryHour,
        patientCode: patientCode,
        patientFirstName: patientFirstName,
        patientLastName: patientLastName,
        patientAge: Value(patientAge),
        patientPhone: Value(patientPhone),
        surgeryType: surgeryType,
        eyeToOperate: eyeToOperate,
        implantPower: Value(implantPower),
        tarif: Value(tarif),
        notes: Value(notes),
        createdBy: Value(createdBy),
      ),
    );
  }
  
  /// Update surgery plan
  Future<bool> updateSurgeryPlan(int id, {
    String? surgeryHour,
    String? surgeryType,
    String? eyeToOperate,
    String? implantPower,
    int? tarif,
    String? paymentStatus,
    int? amountRemaining,
    String? surgeryStatus,
    bool? patientCame,
    String? notes,
  }) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.updateSurgeryPlan(id, {
          if (surgeryHour != null) 'surgery_hour': surgeryHour,
          if (surgeryType != null) 'surgery_type': surgeryType,
          if (eyeToOperate != null) 'eye_to_operate': eyeToOperate,
          if (implantPower != null) 'implant_power': implantPower,
          if (tarif != null) 'tarif': tarif,
          if (paymentStatus != null) 'payment_status': paymentStatus,
          if (amountRemaining != null) 'amount_remaining': amountRemaining,
          if (surgeryStatus != null) 'surgery_status': surgeryStatus,
          if (patientCame != null) 'patient_came': patientCame,
          if (notes != null) 'notes': notes,
        });
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote update failed: $e');
        return false;
      }
    }
    
    final companion = SurgeryPlansCompanion(
      surgeryHour: surgeryHour != null ? Value(surgeryHour) : const Value.absent(),
      surgeryType: surgeryType != null ? Value(surgeryType) : const Value.absent(),
      eyeToOperate: eyeToOperate != null ? Value(eyeToOperate) : const Value.absent(),
      implantPower: implantPower != null ? Value(implantPower) : const Value.absent(),
      tarif: tarif != null ? Value(tarif) : const Value.absent(),
      paymentStatus: paymentStatus != null ? Value(paymentStatus) : const Value.absent(),
      amountRemaining: amountRemaining != null ? Value(amountRemaining) : const Value.absent(),
      surgeryStatus: surgeryStatus != null ? Value(surgeryStatus) : const Value.absent(),
      patientCame: patientCame != null ? Value(patientCame) : const Value.absent(),
      notes: notes != null ? Value(notes) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    );
    
    final count = await (_db.update(_db.surgeryPlans)
      ..where((t) => t.id.equals(id))
    ).write(companion);
    return count > 0;
  }
  
  /// Move surgery to another date
  Future<bool> rescheduleSurgery(int id, DateTime newDate, {
    String? surgeryHour,
    String? surgeryType,
    String? eyeToOperate,
    String? implantPower,
    int? tarif,
  }) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.rescheduleSurgery(id, {
          'surgery_date': newDate.toIso8601String(),
          if (surgeryHour != null) 'surgery_hour': surgeryHour,
          if (surgeryType != null) 'surgery_type': surgeryType,
          if (eyeToOperate != null) 'eye_to_operate': eyeToOperate,
          if (implantPower != null) 'implant_power': implantPower,
          if (tarif != null) 'tarif': tarif,
        });
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote reschedule failed: $e');
        return false;
      }
    }
    
    final companion = SurgeryPlansCompanion(
      surgeryDate: Value(newDate),
      surgeryHour: surgeryHour != null ? Value(surgeryHour) : const Value.absent(),
      surgeryType: surgeryType != null ? Value(surgeryType) : const Value.absent(),
      eyeToOperate: eyeToOperate != null ? Value(eyeToOperate) : const Value.absent(),
      implantPower: implantPower != null ? Value(implantPower) : const Value.absent(),
      tarif: tarif != null ? Value(tarif) : const Value.absent(),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    );
    
    final count = await (_db.update(_db.surgeryPlans)
      ..where((t) => t.id.equals(id))
    ).write(companion);
    return count > 0;
  }
  
  /// Mark surgery as done
  Future<bool> markAsDone(int id) async {
    return updateSurgeryPlan(id, surgeryStatus: 'done', patientCame: true);
  }
  
  /// Mark surgery as cancelled (will delete from table)
  Future<bool> cancelSurgery(int id) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.deleteSurgeryPlan(id);
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote delete failed: $e');
        return false;
      }
    }
    
    final count = await (_db.delete(_db.surgeryPlans)
      ..where((t) => t.id.equals(id))
    ).go();
    return count > 0;
  }
  
  /// Delete surgery plan
  Future<bool> deleteSurgeryPlan(int id) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.deleteSurgeryPlan(id);
      } catch (e) {
        print('❌ [SurgeryPlansRepository] Remote delete failed: $e');
        return false;
      }
    }
    
    final count = await (_db.delete(_db.surgeryPlans)
      ..where((t) => t.id.equals(id))
    ).go();
    return count > 0;
  }
  
  /// Map JSON to SurgeryPlan objects
  List<SurgeryPlan> _mapSurgeryPlansFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) {
      final m = json as Map<String, dynamic>;
      return SurgeryPlan(
        id: (m['id'] as num).toInt(),
        surgeryDate: DateTime.parse(m['surgery_date'] as String),
        surgeryHour: m['surgery_hour'] as String? ?? '',
        patientCode: (m['patient_code'] as num).toInt(),
        patientFirstName: m['patient_first_name'] as String? ?? '',
        patientLastName: m['patient_last_name'] as String? ?? '',
        patientAge: (m['patient_age'] as num?)?.toInt(),
        patientPhone: m['patient_phone'] as String?,
        surgeryType: m['surgery_type'] as String? ?? '',
        eyeToOperate: m['eye_to_operate'] as String? ?? '',
        implantPower: m['implant_power'] as String?,
        tarif: (m['tarif'] as num?)?.toInt(),
        paymentStatus: m['payment_status'] as String? ?? 'pending',
        amountRemaining: (m['amount_remaining'] as num?)?.toInt(),
        surgeryStatus: m['surgery_status'] as String? ?? 'scheduled',
        patientCame: m['patient_came'] as bool? ?? false,
        notes: m['notes'] as String?,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
        createdBy: m['created_by'] as String?,
        updatedAt: m['updated_at'] != null ? DateTime.parse(m['updated_at'] as String) : DateTime.now(),
        needsSync: m['needs_sync'] as bool? ?? false,
      );
    }).toList();
  }
}

/// Provider for surgery plans repository
final surgeryPlansRepositoryProvider = Provider<SurgeryPlansRepository>((ref) {
  return SurgeryPlansRepository();
});

/// Provider for surgery plans for a specific date
final surgeryPlansForDateProvider = FutureProvider.family<List<SurgeryPlan>, DateTime>((ref, date) async {
  final repo = ref.watch(surgeryPlansRepositoryProvider);
  return repo.getSurgeryPlansForDate(date);
});

/// Provider for today's surgery plans
final todaySurgeryPlansProvider = FutureProvider<List<SurgeryPlan>>((ref) async {
  final repo = ref.watch(surgeryPlansRepositoryProvider);
  return repo.getSurgeryPlansForDate(DateTime.now());
});
