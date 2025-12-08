import 'dart:async';
import 'dart:math';
import 'package:drift/drift.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/generated/medicore.pb.dart';

/// Repository for patient data operations
class PatientsRepository {
  final AppDatabase _db;

  PatientsRepository([AppDatabase? database]) 
      : _db = database ?? AppDatabase();

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
  Stream<List<Patient>> watchAllPatients() async* {
    // Client mode: use remote with polling
    if (!GrpcClientConfig.isServer) {
      yield* _watchPatientsRemote();
      return;
    }
    
    await for (final _ in _db.select(_db.patients).watch()) {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      // Get today's patients (newest first)
      final todayPatients = await (_db.select(_db.patients)
            ..where((p) => 
                p.createdAt.isBiggerOrEqualValue(todayStart) &
                p.createdAt.isSmallerThanValue(todayEnd))
            ..orderBy([(p) => OrderingTerm.desc(p.code)]))
          .get();

      // Get all other patients (oldest first)
      final otherPatients = await (_db.select(_db.patients)
            ..where((p) => p.createdAt.isSmallerThanValue(todayStart))
            ..orderBy([(p) => OrderingTerm.asc(p.code)]))
          .get();

      // Combine: today's patients first, then others
      yield [...todayPatients, ...otherPatients];
    }
  }
  
  /// Remote polling stream for patients
  Stream<List<Patient>> _watchPatientsRemote() async* {
    // Initial fetch
    yield await _fetchPatientsRemote();
    
    // Poll every 5 seconds
    await for (final _ in Stream.periodic(const Duration(seconds: 1))) {
      yield await _fetchPatientsRemote();
    }
  }
  
  /// Fetch patients from remote server (server returns in code ASC order)
  Future<List<Patient>> _fetchPatientsRemote() async {
    try {
      final response = await MediCoreClient.instance.getAllPatients();
      // Server already returns patients ordered by code ASC (oldest first)
      return response.patients.map(_grpcPatientToLocal).toList();
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
  /// Also respects smart ordering (today's patients first)
  Stream<List<Patient>> searchPatients(String query) async* {
    if (query.isEmpty) {
      yield* watchAllPatients();
      return;
    }
    
    // Client mode: fetch all and filter locally for reliable search
    if (!GrpcClientConfig.isServer) {
      try {
        final allPatients = await _fetchPatientsRemote();
        final lowerQuery = query.toLowerCase().trim();
        
        List<Patient> filtered;
        
        // Check if query is a valid patient code (exact number match)
        final queryAsCode = int.tryParse(query.trim());
        if (queryAsCode != null) {
          // Exact code match only
          filtered = allPatients.where((p) => p.code == queryAsCode).toList();
        } else if (lowerQuery.contains(' ')) {
          // Search with space: match both first and last name
          final parts = lowerQuery.split(' ');
          final part1 = parts[0];
          final part2 = parts.sublist(1).join(' ');
          
          filtered = allPatients.where((p) {
            final firstName = p.firstName.toLowerCase();
            final lastName = p.lastName.toLowerCase();
            return (firstName.contains(part1) && lastName.contains(part2)) ||
                   (firstName.contains(part2) && lastName.contains(part1));
          }).toList();
        } else {
          // Single word: search in first or last name
          filtered = allPatients.where((p) {
            return p.firstName.toLowerCase().contains(lowerQuery) ||
                   p.lastName.toLowerCase().contains(lowerQuery);
          }).toList();
        }
        
        yield filtered;
      } catch (e) {
        print('❌ [PatientsRepository] Remote searchPatients failed: $e');
        yield [];
      }
      return;
    }

    final lowerQuery = query.toLowerCase().trim();
    
    await for (final _ in _db.select(_db.patients).watch()) {
      // Get today's date range
      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      List<Patient> todayResults = [];
      List<Patient> otherResults = [];

      // Check if query contains space (searching both names)
      if (lowerQuery.contains(' ')) {
        final parts = lowerQuery.split(' ');
        final part1 = parts[0];
        final part2 = parts.sublist(1).join(' ');
        
        // Today's patients matching search
        todayResults = await (_db.select(_db.patients)
              ..where((p) =>
                  (p.createdAt.isBiggerOrEqualValue(todayStart) &
                   p.createdAt.isSmallerThanValue(todayEnd)) &
                  ((p.firstName.lower().like('%$part1%') & p.lastName.lower().like('%$part2%')) |
                   (p.firstName.lower().like('%$part2%') & p.lastName.lower().like('%$part1%'))))
              ..orderBy([(p) => OrderingTerm.desc(p.code)]))
            .get();

        // Other patients matching search
        otherResults = await (_db.select(_db.patients)
              ..where((p) =>
                  p.createdAt.isSmallerThanValue(todayStart) &
                  ((p.firstName.lower().like('%$part1%') & p.lastName.lower().like('%$part2%')) |
                   (p.firstName.lower().like('%$part2%') & p.lastName.lower().like('%$part1%'))))
              ..orderBy([(p) => OrderingTerm.asc(p.code)]))
            .get();
      } else {
        // Check if query is a valid patient code (number)
        final queryAsCode = int.tryParse(query);
        
        // Single word search - today's patients
        if (queryAsCode != null) {
          // Search by code only
          todayResults = await (_db.select(_db.patients)
                ..where((p) =>
                    (p.createdAt.isBiggerOrEqualValue(todayStart) &
                     p.createdAt.isSmallerThanValue(todayEnd)) &
                    p.code.equals(queryAsCode))
                ..orderBy([(p) => OrderingTerm.desc(p.code)]))
              .get();
          
          otherResults = await (_db.select(_db.patients)
                ..where((p) =>
                    p.createdAt.isSmallerThanValue(todayStart) &
                    p.code.equals(queryAsCode))
                ..orderBy([(p) => OrderingTerm.asc(p.code)]))
              .get();
        } else {
          // Search by name only
          todayResults = await (_db.select(_db.patients)
                ..where((p) =>
                    (p.createdAt.isBiggerOrEqualValue(todayStart) &
                     p.createdAt.isSmallerThanValue(todayEnd)) &
                    (p.firstName.lower().like('%$lowerQuery%') |
                     p.lastName.lower().like('%$lowerQuery%')))
                ..orderBy([(p) => OrderingTerm.desc(p.code)]))
              .get();

          otherResults = await (_db.select(_db.patients)
                ..where((p) =>
                    p.createdAt.isSmallerThanValue(todayStart) &
                    (p.firstName.lower().like('%$lowerQuery%') |
                     p.lastName.lower().like('%$lowerQuery%')))
                ..orderBy([(p) => OrderingTerm.asc(p.code)]))
              .get();
        }
      }

      // Combine: today's matches first, then others
      yield [...todayResults, ...otherResults];
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
        return Patient(
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
    return (await getPatientByCode(code))!;
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
  }

  /// Delete patient
  Future<void> deletePatient(int code) async {
    // Client mode: use remote
    if (!GrpcClientConfig.isServer) {
      try {
        await MediCoreClient.instance.deletePatient(code);
        return;
      } catch (e) {
        print('❌ [PatientsRepository] Remote deletePatient failed: $e');
        rethrow;
      }
    }
    
    await (_db.delete(_db.patients)
          ..where((p) => p.code.equals(code)))
        .go();
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
