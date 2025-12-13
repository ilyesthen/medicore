import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/remote_patients_repository.dart';
import '../data/patients_repository.dart';

/// Global refresh trigger for instant CRUD updates
final _patientsRefreshController = StreamController<void>.broadcast();

/// Call this to trigger an instant refresh of the patients list
void refreshPatientsList() {
  _patientsRefreshController.add(null);
  print('🔄 Patients list refresh triggered');
}

/// Abstract interface for patient operations
/// Allows switching between local (admin) and remote (client) implementations
abstract class IPatientsRepository {
  Stream<List<Patient>> watchAllPatients();
  Future<Patient?> getPatientByCode(int code);
  Stream<List<Patient>> searchPatients(String query);
  Future<Patient> createPatient({
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  });
  Future<void> updatePatient({
    required int code,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  });
  Future<void> deletePatient(int code);
  Future<int> getPatientCount();
}

/// Local patients adapter
class LocalPatientsAdapter implements IPatientsRepository {
  final PatientsRepository _local;
  LocalPatientsAdapter(this._local);
  
  @override
  Stream<List<Patient>> watchAllPatients() => _local.watchAllPatients();
  
  @override
  Future<Patient?> getPatientByCode(int code) => _local.getPatientByCode(code);
  
  @override
  Stream<List<Patient>> searchPatients(String query) => _local.searchPatients(query);
  
  @override
  Future<Patient> createPatient({
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) => _local.createPatient(
    firstName: firstName,
    lastName: lastName,
    age: age,
    dateOfBirth: dateOfBirth,
    address: address,
    phoneNumber: phoneNumber,
    otherInfo: otherInfo,
  );
  
  @override
  Future<void> updatePatient({
    required int code,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) => _local.updatePatient(
    code: code,
    firstName: firstName,
    lastName: lastName,
    age: age,
    dateOfBirth: dateOfBirth,
    address: address,
    phoneNumber: phoneNumber,
    otherInfo: otherInfo,
  );
  
  @override
  Future<void> deletePatient(int code) => _local.deletePatient(code);
  
  @override
  Future<int> getPatientCount() => _local.getPatientCount();
}

/// Remote patients adapter
class RemotePatientsAdapter implements IPatientsRepository {
  final RemotePatientsRepository _remote;
  RemotePatientsAdapter(this._remote);
  
  @override
  Stream<List<Patient>> watchAllPatients() => _remote.watchAllPatients();
  
  @override
  Future<Patient?> getPatientByCode(int code) => _remote.getPatientByCode(code);
  
  @override
  Stream<List<Patient>> searchPatients(String query) => _remote.searchPatients(query);
  
  @override
  Future<Patient> createPatient({
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) => _remote.createPatient(
    firstName: firstName,
    lastName: lastName,
    age: age,
    dateOfBirth: dateOfBirth,
    address: address,
    phoneNumber: phoneNumber,
    otherInfo: otherInfo,
  );
  
  @override
  Future<void> updatePatient({
    required int code,
    required String firstName,
    required String lastName,
    int? age,
    DateTime? dateOfBirth,
    String? address,
    String? phoneNumber,
    String? otherInfo,
  }) => _remote.updatePatient(
    code: code,
    firstName: firstName,
    lastName: lastName,
    age: age,
    dateOfBirth: dateOfBirth,
    address: address,
    phoneNumber: phoneNumber,
    otherInfo: otherInfo,
  );
  
  @override
  Future<void> deletePatient(int code) => _remote.deletePatient(code);
  
  @override
  Future<int> getPatientCount() => _remote.getPatientCount();
}

// Singleton instances to prevent multiple SSE registrations
RemotePatientsRepository? _remotePatientsRepo;
PatientsRepository? _localPatientsRepo;

/// Patients repository provider - switches between local and remote
final patientsRepositoryProvider = Provider<IPatientsRepository>((ref) {
  if (GrpcClientConfig.isServer) {
    print('✓ [PatientsRepository] Using LOCAL database (Admin mode)');
    _localPatientsRepo ??= PatientsRepository();
    return LocalPatientsAdapter(_localPatientsRepo!);
  } else {
    print('✓ [PatientsRepository] Using REMOTE API (Client mode)');
    _remotePatientsRepo ??= RemotePatientsRepository();
    return RemotePatientsAdapter(_remotePatientsRepo!);
  }
});

/// All patients stream provider with instant refresh support
final patientsListProvider = StreamProvider<List<Patient>>((ref) {
  final repository = ref.watch(patientsRepositoryProvider);
  
  // Create a merged stream that responds to both data changes and manual refresh
  final controller = StreamController<List<Patient>>.broadcast();
  StreamSubscription<List<Patient>>? dataSub;
  StreamSubscription<void>? refreshSub;
  
  void fetchAndEmit() async {
    await for (final patients in repository.watchAllPatients()) {
      if (!controller.isClosed) {
        controller.add(patients);
      }
      break; // Just get the first emission
    }
  }
  
  // Listen for data changes
  dataSub = repository.watchAllPatients().listen(
    (patients) {
      if (!controller.isClosed) controller.add(patients);
    },
    onError: (e) {
      if (!controller.isClosed) controller.addError(e);
    },
  );
  
  // Listen for manual refresh triggers
  refreshSub = _patientsRefreshController.stream.listen((_) {
    fetchAndEmit();
  });
  
  ref.onDispose(() {
    dataSub?.cancel();
    refreshSub?.cancel();
    controller.close();
  });
  
  return controller.stream;
});

/// Search patients provider
final patientSearchProvider = StateProvider<String>((ref) => '');

/// Pagination: Page size (patients per page)
final pageSizeProvider = StateProvider<int>((ref) => 100);

/// Pagination: Current page (0-indexed)
final currentPageProvider = StateProvider<int>((ref) => 0);

/// Sort order: true = oldest first (by code ASC), false = newest first (by code DESC)
final patientSortOldestFirstProvider = StateProvider<bool>((ref) => false);

/// Filtered patients based on search query (without pagination)
final allFilteredPatientsProvider = StreamProvider<List<Patient>>((ref) {
  final repository = ref.watch(patientsRepositoryProvider);
  final searchQuery = ref.watch(patientSearchProvider);
  return repository.searchPatients(searchQuery);
});

/// Paginated patients based on search query and current page
final filteredPatientsProvider = Provider<AsyncValue<List<Patient>>>((ref) {
  final allPatients = ref.watch(allFilteredPatientsProvider);
  final currentPage = ref.watch(currentPageProvider);
  final pageSize = ref.watch(pageSizeProvider);
  final oldestFirst = ref.watch(patientSortOldestFirstProvider);

  return allPatients.when(
    data: (patients) {
      // Apply sorting
      final sortedPatients = patients.toList();
      sortedPatients.sort((a, b) => oldestFirst 
          ? a.code.compareTo(b.code)  // Oldest first (lower code = older patient)
          : b.code.compareTo(a.code)  // Newest first (higher code = newer patient)
      );
      
      // Calculate pagination
      final startIndex = currentPage * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, sortedPatients.length);
      
      if (startIndex >= sortedPatients.length) {
        return AsyncValue.data([]);
      }
      
      final paginatedPatients = sortedPatients.sublist(startIndex, endIndex);
      return AsyncValue.data(paginatedPatients);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stack) => AsyncValue.error(error, stack),
  );
});

/// Total pages count
final totalPagesProvider = Provider<int>((ref) {
  final allPatients = ref.watch(allFilteredPatientsProvider);
  final pageSize = ref.watch(pageSizeProvider);
  
  return allPatients.when(
    data: (patients) => (patients.length / pageSize).ceil(),
    loading: () => 1,
    error: (_, __) => 1,
  );
});

/// Total patients count
final totalPatientsProvider = Provider<int>((ref) {
  final allPatients = ref.watch(allFilteredPatientsProvider);
  
  return allPatients.when(
    data: (patients) => patients.length,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Selected patient provider (for edit/delete operations)
final selectedPatientProvider = StateProvider<Patient?>((ref) => null);
