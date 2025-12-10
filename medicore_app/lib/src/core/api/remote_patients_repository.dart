import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import 'realtime_sync_service.dart';
import '../database/app_database.dart' show Patient;

/// Remote Patients Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only - now with SSE-powered instant updates!
class RemotePatientsRepository {
  final MediCoreClient _client;
  
  // Cache for reactive streams
  final _patientsController = StreamController<List<Patient>>.broadcast();
  List<Patient> _cachedPatients = [];
  DateTime? _lastFetch;
  
  // SSE callback for instant refresh
  void Function()? _sseRefreshCallback;
  
  RemotePatientsRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance {
    // Register for SSE patient events for instant updates
    _sseRefreshCallback = () => _refreshPatients();
    RealtimeSyncService.instance.onPatientRefresh(_sseRefreshCallback!);
  }

  /// Watch all patients (with caching for performance)
  Stream<List<Patient>> watchAllPatients() async* {
    // Initial fetch
    await _refreshPatients();
    yield _cachedPatients;
    
    // Fallback poll every 10 seconds (SSE handles real-time updates)
    await for (final _ in Stream.periodic(const Duration(seconds: 10))) {
      await _refreshPatients();
      yield _cachedPatients;
    }
  }
  
  Future<void> _refreshPatients() async {
    try {
      final response = await _client.getAllPatients();
      _cachedPatients = response.patients.map(_grpcPatientToLocal).toList();
      _lastFetch = DateTime.now();
      // Notify stream listeners
      _patientsController.add(_cachedPatients);
    } catch (e) {
      print('❌ [RemotePatients] Failed to refresh: $e');
    }
  }

  /// Get patient by code
  Future<Patient?> getPatientByCode(int code) async {
    try {
      final grpcPatient = await _client.getPatientByCode(code);
      return grpcPatient != null ? _grpcPatientToLocal(grpcPatient) : null;
    } catch (e) {
      print('❌ [RemotePatients] getPatientByCode failed: $e');
      return null;
    }
  }

  /// Search patients
  Stream<List<Patient>> searchPatients(String query) async* {
    if (query.isEmpty) {
      yield* watchAllPatients();
      return;
    }
    
    try {
      final response = await _client.searchPatients(query);
      yield response.patients.map(_grpcPatientToLocal).toList();
    } catch (e) {
      print('❌ [RemotePatients] search failed: $e');
      yield [];
    }
  }

  /// Create new patient - INSTANT UI update (optimistic)
  Future<Patient> createPatient({
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    // Create temp patient with placeholder code for INSTANT UI
    final tempCode = DateTime.now().millisecondsSinceEpoch;
    final tempPatient = Patient(
      code: tempCode,
      barcode: '',
      createdAt: DateTime.now(),
      firstName: firstName,
      lastName: lastName,
      age: age,
      dateOfBirth: dateOfBirth,
      address: address,
      phoneNumber: phoneNumber,
      otherInfo: otherInfo,
      updatedAt: DateTime.now(),
      needsSync: true,
    );
    
    // Add to cache IMMEDIATELY (before network call)
    _cachedPatients.insert(0, tempPatient); // Insert at TOP
    _patientsController.add(_cachedPatients);
    
    try {
      final request = CreatePatientRequest(
        code: 0, // Server will assign
        firstName: firstName,
        lastName: lastName,
        age: age,
        dateOfBirth: dateOfBirth?.toIso8601String(),
        address: address,
        phone: phoneNumber,
      );
      
      final realCode = await _client.createPatient(request);
      
      // Update temp patient with real code
      final idx = _cachedPatients.indexWhere((p) => p.code == tempCode);
      if (idx >= 0) {
        _cachedPatients[idx] = Patient(
          code: realCode,
          barcode: '',
          createdAt: DateTime.now(),
          firstName: firstName,
          lastName: lastName,
          age: age,
          dateOfBirth: dateOfBirth,
          address: address,
          phoneNumber: phoneNumber,
          otherInfo: otherInfo,
          updatedAt: DateTime.now(),
          needsSync: false,
        );
        _patientsController.add(_cachedPatients);
      }
      
      return _cachedPatients[idx >= 0 ? idx : 0];
    } catch (e) {
      // Remove temp patient on error
      _cachedPatients.removeWhere((p) => p.code == tempCode);
      _patientsController.add(_cachedPatients);
      print('❌ [RemotePatients] createPatient failed: $e');
      rethrow;
    }
  }

  /// Update patient - INSTANT (optimistic update)
  Future<void> updatePatient({
    required int code,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    // Update cache IMMEDIATELY (before network call)
    Patient? oldPatient;
    final idx = _cachedPatients.indexWhere((p) => p.code == code);
    if (idx >= 0) {
      oldPatient = _cachedPatients[idx];
      _cachedPatients[idx] = Patient(
        code: code,
        barcode: oldPatient.barcode,
        createdAt: oldPatient.createdAt,
        firstName: firstName,
        lastName: lastName,
        age: age,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        otherInfo: otherInfo,
        updatedAt: DateTime.now(),
        needsSync: true,
      );
      _patientsController.add(_cachedPatients);
    }
    
    // Network call in background
    try {
      final patient = GrpcPatient(
        code: code,
        firstName: firstName,
        lastName: lastName,
        age: age,
        dateOfBirth: dateOfBirth?.toIso8601String(),
        address: address,
        phone: phoneNumber,
      );
      await _client.updatePatient(patient);
    } catch (e) {
      // Revert on error
      if (oldPatient != null && idx >= 0) {
        _cachedPatients[idx] = oldPatient;
        _patientsController.add(_cachedPatients);
      }
      print('❌ [RemotePatients] updatePatient failed: $e');
      rethrow;
    }
  }

  /// Delete patient - INSTANT (optimistic delete)
  Future<void> deletePatient(int code) async {
    // Remove from cache IMMEDIATELY (before network call)
    Patient? deletedPatient;
    final idx = _cachedPatients.indexWhere((p) => p.code == code);
    if (idx >= 0) {
      deletedPatient = _cachedPatients.removeAt(idx);
      _patientsController.add(_cachedPatients);
    }
    
    // Network call in background
    try {
      await _client.deletePatient(code);
    } catch (e) {
      // Revert on error
      if (deletedPatient != null) {
        _cachedPatients.insert(idx, deletedPatient);
        _patientsController.add(_cachedPatients);
      }
      print('❌ [RemotePatients] deletePatient failed: $e');
      rethrow;
    }
  }

  /// Get patient count
  Future<int> getPatientCount() async {
    if (_cachedPatients.isEmpty) {
      await _refreshPatients();
    }
    return _cachedPatients.length;
  }

  /// Convert GrpcPatient to local Patient model
  Patient _grpcPatientToLocal(GrpcPatient grpc) {
    return Patient(
      code: grpc.code,
      barcode: grpc.barcode ?? '',
      createdAt: DateTime.now(),
      firstName: grpc.firstName,
      lastName: grpc.lastName,
      age: grpc.age,
      dateOfBirth: grpc.dateOfBirth != null ? DateTime.tryParse(grpc.dateOfBirth!) : null,
      address: grpc.address,
      phoneNumber: grpc.phone,
      otherInfo: grpc.notes,
      updatedAt: DateTime.now(),
      needsSync: false,
    );
  }
  
  void dispose() {
    // Unregister SSE callback
    if (_sseRefreshCallback != null) {
      RealtimeSyncService.instance.removePatientRefresh(_sseRefreshCallback!);
    }
    _patientsController.close();
  }
}
