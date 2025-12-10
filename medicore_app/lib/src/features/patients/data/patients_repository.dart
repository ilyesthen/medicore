import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';
import '../../../core/api/realtime_sync_service.dart';
import '../presentation/patients_provider.dart' show refreshPatientsList;

/// Trigger INSTANT UI update - emits to reactive stream AND calls external refresh
void _triggerInstantUpdate() {
  PatientsRepository._emitCache();
  refreshPatientsList();
}

/// Repository for patient data operations
/// Optimized with in-memory cache for instant CRUD operations
class PatientsRepository {
  final AppDatabase _db;
  
  // In-memory cache for instant access
  static List<Patient>? _cachedPatients;
  static DateTime? _cacheTime;
  static const _cacheMaxAge = Duration(minutes: 5);
  static bool _isFetching = false;
  
  // REACTIVE STREAM - emits whenever cache changes
  static final _patientsController = StreamController<List<Patient>>.broadcast();
  
  /// Emit current cache to all listeners (for INSTANT UI updates)
  static void _emitCache() {
    if (_cachedPatients != null && !_patientsController.isClosed) {
      _patientsController.add(_cachedPatients!);
      print('📤 [PatientsRepository] Emitted ${_cachedPatients!.length} patients to UI');
    }
  }

  PatientsRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();
  
  /// Clear cache (call after create/update/delete)
  void _invalidateCache() {
    _cachedPatients = null;
    _cacheTime = null;
  }
  
  /// Check if cache is valid
  bool get _isCacheValid {
    if (_cachedPatients == null || _cacheTime == null) return false;
    return DateTime.now().difference(_cacheTime!) < _cacheMaxAge;
  }
  
  /// Get patients from cache or fetch fresh
  Future<List<Patient>> _getCachedPatients() async {
    if (_isCacheValid) return _cachedPatients!;
    
    // Prevent multiple simultaneous fetches
    if (_isFetching) {
      // Wait for existing fetch to complete
      while (_isFetching) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      if (_cachedPatients != null) return _cachedPatients!;
    }
    
    _isFetching = true;
    try {
      if (GrpcClientConfig.isServer) {
        // Admin mode: fetch from local DB
        _cachedPatients = await _db.select(_db.patients).get();
      } else {
        // Client mode: fetch from server
        final response = await MediCoreClient.instance.getAllPatients();
        _cachedPatients = response.patients.map(_grpcPatientToLocal).toList();
      }
      _cacheTime = DateTime.now();
      return _cachedPatients!;
    } finally {
      _isFetching = false;
    }
  }

  /// Generate unique 8-character barcode
  Future<String> _generateUniqueBarcode() async {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789+';
    final random = Random();
    
    while (true) {
      final barcode = List.generate(
        8,
        (index) => chars[random.nextInt(chars.length)],
      ).join();
      
      // Check if barcode already exists
      final existing = await (_db.select(_db.patients)
            ..where((p) => p.barcode.equals(barcode)))
          .getSingleOrNull();
      
      if (existing == null) {
        return barcode;
      }
    }
  }

  /// Get next patient code (sequential) - NEVER reuses codes even after deletion
  Future<int> _getNextPatientCode() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Get the highest code ever used (stored persistently)
    final highestEverUsed = prefs.getInt('highest_patient_code_ever') ?? 0;
    
    // Also check current max in database
    final query = _db.selectOnly(_db.patients)
      ..addColumns([_db.patients.code.max()]);
    final result = await query.getSingleOrNull();
    final currentMax = result?.read(_db.patients.code.max()) ?? 0;
    
    // Use the higher of the two + 1
    final nextCode = (highestEverUsed > currentMax ? highestEverUsed : currentMax) + 1;
    
    // Save this as the new highest ever
    await prefs.setInt('highest_patient_code_ever', nextCode);
    
    return nextCode;
  }

  /// Calculate age from date of birth
  int? _calculateAge(DateTime? dateOfBirth) {
    if (dateOfBirth == null) return null;
    final today = DateTime.now();
    int age = today.year - dateOfBirth.year;
    if (today.month < dateOfBirth.month ||
        (today.month == dateOfBirth.month && today.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  /// Get all patients with INSTANT reactive updates
  /// Uses broadcast stream - updates immediately when cache changes
  Stream<List<Patient>> watchAllPatients() async* {
    // First, yield cached data immediately if available
    if (_cachedPatients != null) {
      yield _applySmartOrdering(_cachedPatients!);
    }
    
    // Fetch fresh data in background if cache is stale
    if (!_isCacheValid) {
      try {
        final patients = await _getCachedPatients();
        _cachedPatients = patients;
        _cacheTime = DateTime.now();
        yield _applySmartOrdering(patients);
      } catch (e) {
        print('❌ [PatientsRepository] watchAllPatients failed: $e');
      }
    }
    
    // Listen to the reactive stream for instant updates
    await for (final patients in _patientsController.stream) {
      yield _applySmartOrdering(patients);
    }
  }
  
  /// Apply smart ordering:
  /// 1. Today's patients at TOP (newest today first - so newly created is #1)
  /// 2. Then older patients sorted by code ASC (oldest first: 3, 4, 5...)
  List<Patient> _applySmartOrdering(List<Patient> patients) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    // Split into today's patients and older patients
    final todayPatients = <Patient>[];
    final olderPatients = <Patient>[];
    
    for (final p in patients) {
      if (p.createdAt.isAfter(todayStart) || p.createdAt.isAtSameMomentAs(todayStart)) {
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
  
  /// Remote stream for patients with SSE support
  Stream<List<Patient>> _watchPatientsRemote() {
    final controller = StreamController<List<Patient>>.broadcast();
    Timer? pollTimer;
    void Function()? sseCallback;
    
    Future<void> fetch() async {
      final patients = await _fetchPatientsRemote();
      if (!controller.isClosed) {
        controller.add(patients);
      }
    }
    
    // Register SSE callback for instant refresh
    sseCallback = () => fetch();
    RealtimeSyncService.instance.onPatientRefresh(sseCallback!);
    
    // Initial fetch
    fetch();
    
    // Fallback poll every 30 seconds (SSE handles real-time)
    pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => fetch());
    
    controller.onCancel = () {
      pollTimer?.cancel();
      if (sseCallback != null) {
        RealtimeSyncService.instance.removePatientRefresh(sseCallback!);
      }
    };
    
    return controller.stream;
  }
  
  /// Fetch patients from remote server with smart ordering
  /// Same as admin: today's patients first (newest code first), then others (oldest first)
  Future<List<Patient>> _fetchPatientsRemote() async {
    try {
      final response = await MediCoreClient.instance.getAllPatients();
      final allPatients = response.patients.map(_grpcPatientToLocal).toList();
      
      // Apply same smart ordering as admin mode
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      
      // Split into today's patients and others
      final todayPatients = <Patient>[];
      final otherPatients = <Patient>[];
      
      for (final p in allPatients) {
        if (p.createdAt.isAfter(todayStart) || p.createdAt.isAtSameMomentAs(todayStart)) {
          todayPatients.add(p);
        } else {
          otherPatients.add(p);
        }
      }
      
      // Sort all patients: newest first (descending order by code)
      allPatients.sort((a, b) => b.code.compareTo(a.code));
      return allPatients;
    } catch (e) {
      print('❌ [PatientsRepository] Remote fetch failed: $e');
      return [];
    }
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

  /// Get patient by code
  Future<Patient?> getPatientByCode(int code) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final grpcPatient = await MediCoreClient.instance.getPatientByCode(code);
        return grpcPatient != null ? _grpcPatientToLocal(grpcPatient) : null;
      } catch (e) {
        print('❌ [PatientsRepository] Remote getPatientByCode failed: $e');
        return null;
      }
    }
    
    return await (_db.select(_db.patients)
          ..where((p) => p.code.equals(code)))
        .getSingleOrNull();
  }

  /// Search patients by name (first, last, or both with space)
  /// OPTIMIZED: Uses in-memory cache for instant search
  Stream<List<Patient>> searchPatients(String query) async* {
    if (query.isEmpty) {
      yield* watchAllPatients();
      return;
    }
    
    // Use cached patients for instant search
    try {
      final allPatients = await _getCachedPatients();
      final results = _filterPatients(allPatients, query);
      yield results;
    } catch (e) {
      print('❌ [PatientsRepository] searchPatients failed: $e');
      yield [];
    }
  }
  
  /// Filter patients by query - pure in-memory operation (instant)
  List<Patient> _filterPatients(List<Patient> patients, String query) {
    final lowerQuery = query.toLowerCase().trim();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    List<Patient> filtered;
    
    // Check if query is a valid patient code (exact number match)
    final queryAsCode = int.tryParse(query.trim());
    if (queryAsCode != null) {
      // Exact code match only
      filtered = patients.where((p) => p.code == queryAsCode).toList();
    } else if (lowerQuery.contains(' ')) {
      // Search with space: match both first and last name
      final parts = lowerQuery.split(' ');
      final part1 = parts[0];
      final part2 = parts.sublist(1).join(' ');
      
      filtered = patients.where((p) {
        final firstName = p.firstName.toLowerCase();
        final lastName = p.lastName.toLowerCase();
        return (firstName.contains(part1) && lastName.contains(part2)) ||
               (firstName.contains(part2) && lastName.contains(part1));
      }).toList();
    } else {
      // Single word: search in first or last name
      filtered = patients.where((p) {
        return p.firstName.toLowerCase().contains(lowerQuery) ||
               p.lastName.toLowerCase().contains(lowerQuery);
      }).toList();
    }
    
    // Sort: newest first (descending order by code)
    filtered.sort((a, b) => b.code.compareTo(a.code));
    return filtered;
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      // Create temporary patient with placeholder code for INSTANT UI update
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
      if (_cachedPatients != null) {
        _cachedPatients!.insert(0, tempPatient); // Insert at TOP
      } else {
        _cachedPatients = [tempPatient];
        _cacheTime = DateTime.now();
      }
      // Trigger INSTANT UI refresh
      _triggerInstantUpdate();
      
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
        final realCode = await MediCoreClient.instance.createPatient(request);
        
        // Update temp patient with real code
        if (_cachedPatients != null) {
          final idx = _cachedPatients!.indexWhere((p) => p.code == tempCode);
          if (idx >= 0) {
            _cachedPatients![idx] = Patient(
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
          }
        }
        
        return Patient(
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
      } catch (e) {
        // Remove temp patient on error
        _cachedPatients?.removeWhere((p) => p.code == tempCode);
        _triggerInstantUpdate();
        print('❌ [PatientsRepository] Remote createPatient failed: $e');
        rethrow;
      }
    }
    
    // Admin mode: INSTANT UI update with optimistic cache
    final code = await _getNextPatientCode();
    final barcode = await _generateUniqueBarcode();
    final now = DateTime.now();

    // Calculate age from date of birth if provided
    final finalAge = dateOfBirth != null ? _calculateAge(dateOfBirth) : age;

    // Create patient object for INSTANT UI update
    final newPatient = Patient(
      code: code,
      barcode: barcode,
      createdAt: now,
      firstName: firstName,
      lastName: lastName,
      age: finalAge,
      dateOfBirth: dateOfBirth,
      address: address,
      phoneNumber: phoneNumber,
      otherInfo: otherInfo,
      updatedAt: now,
      needsSync: true,
    );
    
    // Add to cache IMMEDIATELY (before DB insert)
    if (_cachedPatients != null) {
      _cachedPatients!.insert(0, newPatient); // Insert at TOP
    } else {
      _cachedPatients = [newPatient];
      _cacheTime = DateTime.now();
    }
    // Trigger INSTANT UI refresh
    _triggerInstantUpdate();

    // Insert to DB in background
    final companion = PatientsCompanion.insert(
      code: Value(code),
      barcode: barcode,
      createdAt: now,
      firstName: firstName,
      lastName: lastName,
      age: Value(finalAge),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      phoneNumber: Value(phoneNumber),
      otherInfo: Value(otherInfo),
      updatedAt: now,
      needsSync: const Value(true),
    );

    await _db.into(_db.patients).insert(companion);
    return newPatient;
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
    // Client mode: use remote - INSTANT UI update
    if (!GrpcClientConfig.isServer) {
      // Update cache IMMEDIATELY (before network call)
      Patient? oldPatient;
      if (_cachedPatients != null) {
        final idx = _cachedPatients!.indexWhere((p) => p.code == code);
        if (idx >= 0) {
          oldPatient = _cachedPatients![idx];
          _cachedPatients![idx] = Patient(
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
        }
      }
      // Trigger INSTANT UI refresh
      _triggerInstantUpdate();
      
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
        await MediCoreClient.instance.updatePatient(patient);
        return;
      } catch (e) {
        // Revert on error
        if (oldPatient != null && _cachedPatients != null) {
          final idx = _cachedPatients!.indexWhere((p) => p.code == code);
          if (idx >= 0) _cachedPatients![idx] = oldPatient;
          _triggerInstantUpdate();
        }
        print('❌ [PatientsRepository] Remote updatePatient failed: $e');
        rethrow;
      }
    }
    
    // Calculate age from date of birth if provided
    final finalAge = dateOfBirth != null ? _calculateAge(dateOfBirth) : age;

    final companion = PatientsCompanion(
      code: Value(code),
      firstName: Value(firstName),
      lastName: Value(lastName),
      age: Value(finalAge),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      phoneNumber: Value(phoneNumber),
      otherInfo: Value(otherInfo),
      updatedAt: Value(DateTime.now()),
      needsSync: const Value(true),
    );

    await (_db.update(_db.patients)
          ..where((p) => p.code.equals(code)))
        .write(companion);
    // Update cache immediately
    if (_cachedPatients != null) {
      final idx = _cachedPatients!.indexWhere((p) => p.code == code);
      if (idx >= 0) {
        final updated = await getPatientByCode(code);
        if (updated != null) {
          _cachedPatients![idx] = updated;
        }
      }
    }
    // Trigger instant UI refresh
    _triggerInstantUpdate();
  }

  /// Delete patient - INSTANT (optimistic delete)
  Future<void> deletePatient(int code) async {
    // Save for rollback on error
    Patient? deletedPatient;
    int? deletedIndex;
    
    // Remove from cache IMMEDIATELY (before any network/DB call)
    if (_cachedPatients != null) {
      deletedIndex = _cachedPatients!.indexWhere((p) => p.code == code);
      if (deletedIndex >= 0) {
        deletedPatient = _cachedPatients![deletedIndex];
        _cachedPatients!.removeAt(deletedIndex);
      }
    }
    // Trigger INSTANT UI refresh
    _triggerInstantUpdate();
    
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deletePatient(code);
        return;
      } catch (e) {
        // Revert on error
        if (deletedPatient != null && deletedIndex != null && _cachedPatients != null) {
          _cachedPatients!.insert(deletedIndex, deletedPatient);
          _triggerInstantUpdate();
        }
        print('❌ [PatientsRepository] Remote deletePatient failed: $e');
        rethrow;
      }
    }
    
    // Admin mode: delete from DB + ALL related data
    try {
      // Delete all related data first (cascade delete)
      await (_db.delete(_db.visits)..where((v) => v.patientCode.equals(code))).go();
      await (_db.delete(_db.payments)..where((p) => p.patientCode.equals(code))).go();
      await (_db.delete(_db.ordonnances)..where((o) => o.patientCode.equals(code))).go();
      await (_db.delete(_db.messages)..where((m) => m.patientCode.equals(code))).go();
      await (_db.delete(_db.waitingPatients)..where((w) => w.patientCode.equals(code))).go();
      
      // Finally delete the patient
      await (_db.delete(_db.patients)
            ..where((p) => p.code.equals(code)))
          .go();
      
      print('✓ Patient $code and all related data deleted');
    } catch (e) {
      // Revert on error
      if (deletedPatient != null && deletedIndex != null && _cachedPatients != null) {
        _cachedPatients!.insert(deletedIndex, deletedPatient);
        _triggerInstantUpdate();
      }
      rethrow;
    }
  }

  /// Import patient from XML data (used for migration)
  Future<Patient> importPatient({
    required int code,
    required String barcode,
    required DateTime createdAt,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.importPatient({
          'code': code,
          'first_name': firstName,
          'last_name': lastName,
          'age': age,
          'date_of_birth': dateOfBirth?.toIso8601String(),
          'address': address,
          'phone': phoneNumber,
          'other_info': otherInfo,
        });
        return Patient(
          code: code,
          barcode: barcode,
          createdAt: createdAt,
          firstName: firstName,
          lastName: lastName,
          age: age,
          dateOfBirth: dateOfBirth,
          address: address,
          phoneNumber: phoneNumber,
          otherInfo: otherInfo,
          updatedAt: createdAt,
          needsSync: false,
        );
      } catch (e) {
        print('❌ [PatientsRepository] Remote importPatient failed: $e');
        rethrow;
      }
    }
    
    // Check if patient with this code already exists
    final existing = await getPatientByCode(code);
    if (existing != null) {
      // Update existing patient
      await updatePatient(
        code: code,
        firstName: firstName,
        lastName: lastName,
        age: age,
        dateOfBirth: dateOfBirth,
        address: address,
        phoneNumber: phoneNumber,
        otherInfo: otherInfo,
      );
      return (await getPatientByCode(code))!;
    }

    // Insert new patient with specified data
    final companion = PatientsCompanion.insert(
      code: Value(code),
      barcode: barcode,
      createdAt: createdAt,
      firstName: firstName,
      lastName: lastName,
      age: Value(age),
      dateOfBirth: Value(dateOfBirth),
      address: Value(address),
      phoneNumber: Value(phoneNumber),
      otherInfo: Value(otherInfo),
      updatedAt: createdAt,
      needsSync: const Value(false), // Imported data doesn't need sync
    );

    await _db.into(_db.patients).insert(companion);
    return (await getPatientByCode(code))!;
  }

  /// Get total patient count
  Future<int> getPatientCount() async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        final response = await MediCoreClient.instance.getAllPatients();
        return response.patients.length;
      } catch (e) {
        print('❌ [PatientsRepository] Remote getPatientCount failed: $e');
        return 0;
      }
    }
    
    final count = await _db.patients.count().getSingleOrNull();
    return count ?? 0;
  }
}
