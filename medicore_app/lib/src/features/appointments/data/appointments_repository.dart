import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';

/// Repository for appointments - works on both admin and client modes
class AppointmentsRepository {
  final AppDatabase _db;
  
  AppointmentsRepository([AppDatabase? db]) : _db = db ?? AppDatabase.instance;
  
  /// Get appointments for a specific date
  Future<List<Appointment>> getAppointmentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAppointmentsForDate(date);
        return _mapAppointmentsFromJson(response['appointments'] as List<dynamic>? ?? []);
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote fetch failed: $e');
        return [];
      }
    }
    
    return await (_db.select(_db.appointments)
      ..where((t) => t.appointmentDate.isBetweenValues(startOfDay, endOfDay))
      ..orderBy([(t) => OrderingTerm.asc(t.lastName)])
    ).get();
  }
  
  /// Get all appointments
  Future<List<Appointment>> getAllAppointments() async {
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllAppointments();
        return _mapAppointmentsFromJson(response['appointments'] as List<dynamic>? ?? []);
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote fetch failed: $e');
        return [];
      }
    }
    
    return await (_db.select(_db.appointments)
      ..orderBy([(t) => OrderingTerm.asc(t.appointmentDate)])
    ).get();
  }
  
  /// Add new appointment
  Future<int> addAppointment({
    required DateTime appointmentDate,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? phoneNumber,
    String? address,
    String? notes,
    int? existingPatientCode,
    String? createdBy,
  }) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.createAppointment({
          'appointment_date': appointmentDate.toIso8601String(),
          'first_name': firstName,
          'last_name': lastName,
          'age': age,
          'date_of_birth': dateOfBirth?.toIso8601String(),
          'phone_number': phoneNumber,
          'address': address,
          'notes': notes,
          'existing_patient_code': existingPatientCode,
          'created_by': createdBy,
        });
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote create failed: $e');
        return -1;
      }
    }
    
    return await _db.into(_db.appointments).insert(
      AppointmentsCompanion.insert(
        appointmentDate: appointmentDate,
        firstName: firstName,
        lastName: lastName,
        age: Value(age),
        dateOfBirth: Value(dateOfBirth),
        phoneNumber: Value(phoneNumber),
        address: Value(address),
        notes: Value(notes),
        existingPatientCode: Value(existingPatientCode),
        createdBy: Value(createdBy),
      ),
    );
  }
  
  /// Update appointment date (move to another day)
  Future<bool> updateAppointmentDate(int id, DateTime newDate) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.updateAppointmentDate(id, newDate);
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote update failed: $e');
        return false;
      }
    }
    
    final count = await (_db.update(_db.appointments)
      ..where((t) => t.id.equals(id))
    ).write(AppointmentsCompanion(
      appointmentDate: Value(newDate),
    ));
    return count > 0;
  }
  
  /// Mark appointment as added to patients
  Future<bool> markAsAdded(int id) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.markAppointmentAsAdded(id);
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote markAsAdded failed: $e');
        return false;
      }
    }
    
    final count = await (_db.update(_db.appointments)
      ..where((t) => t.id.equals(id))
    ).write(const AppointmentsCompanion(
      wasAdded: Value(true),
    ));
    return count > 0;
  }
  
  /// Delete appointment
  Future<bool> deleteAppointment(int id) async {
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.deleteAppointment(id);
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote delete failed: $e');
        return false;
      }
    }
    
    final count = await (_db.delete(_db.appointments)
      ..where((t) => t.id.equals(id))
    ).go();
    return count > 0;
  }
  
  /// Delete all past appointments that were not added
  Future<int> cleanupPastAppointments() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    
    if (!GrpcClientConfig.isServer) {
      try {
        return await MediCoreClient.instance.cleanupPastAppointments();
      } catch (e) {
        print('❌ [AppointmentsRepository] Remote cleanup failed: $e');
        return 0;
      }
    }
    
    return await (_db.delete(_db.appointments)
      ..where((t) => t.appointmentDate.isSmallerThanValue(startOfToday))
      ..where((t) => t.wasAdded.equals(false))
    ).go();
  }
  
  /// Map JSON to Appointment objects
  List<Appointment> _mapAppointmentsFromJson(List<dynamic> jsonList) {
    return jsonList.map((json) {
      final m = json as Map<String, dynamic>;
      return Appointment(
        id: (m['id'] as num).toInt(),
        appointmentDate: DateTime.parse(m['appointment_date'] as String),
        firstName: m['first_name'] as String? ?? '',
        lastName: m['last_name'] as String? ?? '',
        age: (m['age'] as num?)?.toInt(),
        dateOfBirth: m['date_of_birth'] != null ? DateTime.tryParse(m['date_of_birth'] as String) : null,
        phoneNumber: m['phone_number'] as String?,
        address: m['address'] as String?,
        notes: m['notes'] as String?,
        existingPatientCode: (m['existing_patient_code'] as num?)?.toInt(),
        wasAdded: m['was_added'] as bool? ?? false,
        createdAt: m['created_at'] != null ? DateTime.parse(m['created_at'] as String) : DateTime.now(),
        createdBy: m['created_by'] as String?,
      );
    }).toList();
  }
}

/// Provider for appointments repository
final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository();
});

/// Provider for appointments for a specific date
final appointmentsForDateProvider = FutureProvider.family<List<Appointment>, DateTime>((ref, date) async {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return repo.getAppointmentsForDate(date);
});

/// Provider for today's appointments
final todayAppointmentsProvider = FutureProvider<List<Appointment>>((ref) async {
  final repo = ref.watch(appointmentsRepositoryProvider);
  return repo.getAppointmentsForDate(DateTime.now());
});
