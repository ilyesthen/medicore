import 'dart:async';
import '../generated/medicore.pb.dart';
import 'medicore_client.dart';
import '../database/app_database.dart' show Patient;

/// Remote Patients Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only
class RemotePatientsRepository {
  final MediCoreClient _client;
  
  // Cache for reactive streams
  final _patientsController = StreamController<List<Patient>>.broadcast();
  List<Patient> _cachedPatients = [];
  DateTime? _lastFetch;
  
  RemotePatientsRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance;

  /// Watch all patients (with caching for performance)
  Stream<List<Patient>> watchAllPatients() async* {
    // Initial fetch
    await _refreshPatients();
    yield _cachedPatients;
    
    // Periodic refresh every 5 seconds for real-time updates
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      await _refreshPatients();
      yield _cachedPatients;
    }
  }
  
  Future<void> _refreshPatients() async {
    try {
      final response = await _client.getAllPatients();
      _cachedPatients = response.patients.map(_grpcPatientToLocal).toList();
      _lastFetch = DateTime.now();
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

  /// Create new patient
  Future<Patient> createPatient({
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    final request = CreatePatientRequest(
      code: 0, // Server will assign
      firstName: firstName,
      lastName: lastName,
      age: age,
      dateOfBirth: dateOfBirth?.toIso8601String(),
      address: address,
      phone: phoneNumber,
    );
    
    final code = await _client.createPatient(request);
    
    // Refresh cache
    await _refreshPatients();
    
    // Return from cache or create placeholder
    return _cachedPatients.firstWhere(
      (p) => p.code == code,
      orElse: () => Patient(
        code: code,
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
      ),
    );
  }

  /// Update patient
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
    await _refreshPatients();
  }

  /// Delete patient
  Future<void> deletePatient(int code) async {
    await _client.deletePatient(code);
    await _refreshPatients();
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
    _patientsController.close();
  }
}
