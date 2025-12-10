import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';
import '../../../core/api/realtime_sync_service.dart';

/// Repository for patient data operations
/// Optimized with in-memory cache for instant CRUD operations
class PatientsRepository {
  final AppDatabase _db;
  
  // In-memory cache for instant access
  static List<Patient>? _cachedPatients;
  static DateTime? _cacheTime;
  static const _cacheMaxAge = Duration(minutes: 5);
  static bool _isFetching = false;

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

  /// Get next patient code (sequential)
  Future<int> _getNextPatientCode() async {
    final query = _db.selectOnly(_db.patients)
      ..addColumns([_db.patients.code.max()]);
    final result = await query.getSingleOrNull();
    final maxCode = result?.read(_db.patients.code.max());
    return (maxCode ?? 0) + 1;
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

  /// Get all patients with smart ordering:
  /// - Today's patients first (newest code first for easy access)
  /// - Then all other patients (oldest code first)
  /// OPTIMIZED: Uses cache for instant loading
  Stream<List<Patient>> watchAllPatients() async* {
    // First, yield cached data immediately if available
    if (_isCacheValid) {
      yield _applySmartOrdering(_cachedPatients!);
    }
    
    // Then fetch fresh data
    try {
      final patients = await _getCachedPatients();
      yield _applySmartOrdering(patients);
    } catch (e) {
      print('❌ [PatientsRepository] watchAllPatients failed: $e');
      if (_cachedPatients != null) {
        yield _applySmartOrdering(_cachedPatients!);
      } else {
        yield [];
      }
    }
  }
  
  /// Apply smart ordering: today's patients first (newest first), then others (oldest first)
  List<Patient> _applySmartOrdering(List<Patient> patients) {
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    
    final todayPatients = <Patient>[];
    final otherPatients = <Patient>[];
    
    for (final p in patients) {
      if (p.createdAt.isAfter(todayStart) || p.createdAt.isAtSameMomentAs(todayStart)) {
        todayPatients.add(p);
      } else {
        otherPatients.add(p);
      }
    }
    
    // Today's: newest code first
    todayPatients.sort((a, b) => b.code.compareTo(a.code));
    // Others: oldest code first
    otherPatients.sort((a, b) => a.code.compareTo(b.code));
    
    return [...todayPatients, ...otherPatients];
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
      
      // Today's patients: newest code first (descending)
      todayPatients.sort((a, b) => b.code.compareTo(a.code));
      
      // Other patients: oldest code first (ascending)
      otherPatients.sort((a, b) => a.code.compareTo(b.code));
      
      // Combine: today's first, then others
      return [...todayPatients, ...otherPatients];
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
    
    // Apply smart ordering
    final todayPatients = <Patient>[];
    final otherPatients = <Patient>[];
    
    for (final p in filtered) {
      if (p.createdAt.isAfter(todayStart) || p.createdAt.isAtSameMomentAs(todayStart)) {
        todayPatients.add(p);
      } else {
        otherPatients.add(p);
      }
    }
    
    // Today's patients: newest code first
    todayPatients.sort((a, b) => b.code.compareTo(a.code));
    // Other patients: oldest code first
    otherPatients.sort((a, b) => a.code.compareTo(b.code));
    
    return [...todayPatients, ...otherPatients];
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
        final code = await MediCoreClient.instance.createPatient(request);
        _invalidateCache(); // Clear cache after create
        final newPatient = Patient(
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
        );
        // Add to cache immediately for instant visibility
        if (_cachedPatients != null) {
          _cachedPatients!.insert(0, newPatient);
        }
        return newPatient;
      } catch (e) {
        print('❌ [PatientsRepository] Remote createPatient failed: $e');
        rethrow;
      }
    }
    
    final code = await _getNextPatientCode();
    final barcode = await _generateUniqueBarcode();
    final now = DateTime.now();

    // Calculate age from date of birth if provided
    final finalAge = dateOfBirth != null ? _calculateAge(dateOfBirth) : age;

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
    _invalidateCache(); // Clear cache after create
    final newPatient = (await getPatientByCode(code))!;
    // Add to cache immediately
    if (_cachedPatients != null) {
      _cachedPatients!.insert(0, newPatient);
    }
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
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
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
        _invalidateCache(); // Clear cache after update
        return;
      } catch (e) {
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
    _invalidateCache(); // Clear cache after update
  }

  /// Delete patient
  Future<void> deletePatient(int code) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deletePatient(code);
        _invalidateCache(); // Clear cache after delete
        // Remove from cache immediately
        _cachedPatients?.removeWhere((p) => p.code == code);
        return;
      } catch (e) {
        print('❌ [PatientsRepository] Remote deletePatient failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.patients)
          ..where((p) => p.code.equals(code)))
        .go();
    _invalidateCache(); // Clear cache after delete
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
