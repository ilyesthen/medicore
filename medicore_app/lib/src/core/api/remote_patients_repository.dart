import 'dart:async';
import '../generated/medicore.pb.dart' as pb;
import 'medicore_client.dart';
import 'realtime_sync_service.dart';

/// Remote Patients Repository - Uses REST API to communicate with admin server
/// Used in CLIENT mode only - now with SSE-powered instant updates!
class RemotePatientsRepository {
  final MediCoreClient _client;
  
  // Cache for reactive streams
  final _patientsController = StreamController<List<pb.GrpcPatient>>.broadcast();
  List<pb.GrpcPatient> _cachedPatients = [];
  DateTime? _lastFetch;
  
  // SSE callback for instant refresh
  void Function()? _sseRefreshCallback;
  
  RemotePatientsRepository([MediCoreClient? client])
      : _client = client ?? MediCoreClient.instance {
    // Register for SSE patient events for instant updates
    _sseRefreshCallback = () => _refreshPatients();
    RealtimeSyncService.instance.onPatientRefresh(_sseRefreshCallback!);
  }

  /// Watch all patients with INSTANT reactive updates
  Stream<List<pb.GrpcPatient>> watchAllPatients() async* {
    // Emit cached data immediately if available
    if (_cachedPatients.isNotEmpty) {
      yield _cachedPatients;
    }
    
    // Fetch fresh data in background
    _refreshPatients();
    
    // Listen to reactive stream for INSTANT updates
    await for (final patients in _patientsController.stream) {
      yield patients;
    }
  }
  
  Future<void> _refreshPatients() async {
    try {
      final response = await _client.getAllPatients();
      _cachedPatients = _applySmartOrdering(response.patients.map(_grpcToLocal).toList());
      _lastFetch = DateTime.now();
      // Notify stream listeners
      _patientsController.add(_cachedPatients);
    } catch (e) {
      print('❌ [RemotePatients] Failed to refresh: $e');
    }
  }
  
  /// Apply smart ordering:
  /// 1. Today's patients at TOP (newest today first - so newly created is #1)
  /// 2. Then older patients sorted by code ASC (oldest first: 3, 4, 5...)
  List<pb.GrpcPatient> _applySmartOrdering(List<pb.GrpcPatient> patients) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Split into today's patients and older patients
    final todayPatients = <pb.GrpcPatient>[];
    final olderPatients = <pb.GrpcPatient>[];
    
    for (final p in patients) {
      final createdAt = p.createdAt != null ? DateTime.tryParse(p.createdAt!) : null;
      if (createdAt != null && (createdAt.isAfter(todayStart) || createdAt.isAtSameMomentAs(todayStart))) {
        todayPatients.add(p);
      } else {
        olderPatients.add(p);
      }
    }
    
    // Today's patients: newest first (highest code = most recent)
    todayPatients.sort((a, b) => b.code.compareTo(a.code));
    
    // Older patients: oldest first (lowest code = oldest)
    olderPatients.sort((a, b) => a.code.compareTo(b.code));
    
    // Combine: today's first, then older
    return [...todayPatients, ...olderPatients];
  }

  /// Get patient by code
  Future<pb.GrpcPatient?> getPatientByCode(int code) async {
    try {
      final grpcPatient = await _client.getPatientByCode(code);
      return grpcPatient != null ? _grpcToLocal(grpcPatient) : null;
    } catch (e) {
      print('❌ [RemotePatients] getPatientByCode failed: $e');
      return null;
    }
  }

  /// Search patients
  Stream<List<pb.GrpcPatient>> searchPatients(String query) async* {
    if (query.isEmpty) {
      yield* watchAllPatients();
      return;
    }
    
    try {
      final response = await _client.searchPatients(query);
      yield response.patients.map(_grpcToLocal).toList();
    } catch (e) {
      print('❌ [RemotePatients] search failed: $e');
      yield [];
    }
  }

  /// Create new patient - INSTANT UI update (optimistic)
  Future<pb.GrpcPatient> createPatient({
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
    final tempPatient = pb.GrpcPatient(
      code: tempCode,
      barcode: '',
      createdAt: DateTime.now().toIso8601String(),
      firstName: firstName,
      lastName: lastName,
      age: age,
      dateOfBirth: dateOfBirth?.toIso8601String(),
      address: address,
      phone: phoneNumber,
      notes: otherInfo,
    );
    
    // Add to cache IMMEDIATELY (before network call)
    _cachedPatients.insert(0, tempPatient); // Insert at TOP
    _cachedPatients = _applySmartOrdering(_cachedPatients);
    _patientsController.add(_cachedPatients);
    
    try {
      final request = pb.CreatePatientRequest(
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
        _cachedPatients[idx] = pb.GrpcPatient(
          code: realCode,
          barcode: '',
          createdAt: DateTime.now().toIso8601String(),
          firstName: firstName,
          lastName: lastName,
          age: age,
          dateOfBirth: dateOfBirth?.toIso8601String(),
          address: address,
          phone: phoneNumber,
          notes: otherInfo,
        );
        _cachedPatients = _applySmartOrdering(_cachedPatients);
        _patientsController.add(_cachedPatients);
      }
      
      return _cachedPatients[idx >= 0 ? idx : 0];
    } catch (e) {
      // Remove temp patient on error
      _cachedPatients.removeWhere((p) => p.code == tempCode);
      _cachedPatients = _applySmartOrdering(_cachedPatients);
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
    pb.GrpcPatient? oldPatient;
    final idx = _cachedPatients.indexWhere((p) => p.code == code);
    if (idx >= 0) {
      oldPatient = _cachedPatients[idx];
      _cachedPatients[idx] = pb.GrpcPatient(
        code: code,
        barcode: oldPatient.barcode,
        createdAt: oldPatient.createdAt,
        firstName: firstName,
        lastName: lastName,
        age: age,
        dateOfBirth: dateOfBirth?.toIso8601String(),
        address: address,
        phone: phoneNumber,
        notes: otherInfo,
      );
      _cachedPatients = _applySmartOrdering(_cachedPatients);
      _patientsController.add(_cachedPatients);
    }
    
    // Network call in background
    try {
      final patient = pb.GrpcPatient(
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
        _cachedPatients = _applySmartOrdering(_cachedPatients);
        _patientsController.add(_cachedPatients);
      }
      print('❌ [RemotePatients] updatePatient failed: $e');
      rethrow;
    }
  }

  /// Delete patient - INSTANT (optimistic delete)
  Future<void> deletePatient(int code) async {
    // Remove from cache IMMEDIATELY (before network call)
    pb.GrpcPatient? deletedPatient;
    final idx = _cachedPatients.indexWhere((p) => p.code == code);
    if (idx >= 0) {
      deletedPatient = _cachedPatients.removeAt(idx);
      _cachedPatients = _applySmartOrdering(_cachedPatients);
      _patientsController.add(_cachedPatients);
    }
    
    // Network call in background
    try {
      await _client.deletePatient(code);
    } catch (e) {
      // Revert on error
      if (deletedPatient != null) {
        _cachedPatients.insert(idx, deletedPatient);
        _cachedPatients = _applySmartOrdering(_cachedPatients);
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
  pb.GrpcPatient _grpcToLocal(pb.GrpcPatient grpc) {
    // Just return the grpc object as-is
    return grpc;
  }
  
  void dispose() {
    // Unregister SSE callback
    if (_sseRefreshCallback != null) {
      RealtimeSyncService.instance.removePatientRefresh(_sseRefreshCallback!);
    }
    _patientsController.close();
  }
}
