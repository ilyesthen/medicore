import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/patients_repository.dart';

/// Patients repository provider
final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository();
});

/// All patients stream provider
final patientsListProvider = StreamProvider<List<Patient>>((ref) {
  final repository = ref.watch(patientsRepositoryProvider);
  return repository.watchAllPatients();
});

/// Search patients provider
final patientSearchProvider = StateProvider<String>((ref) => '');

/// Pagination: Page size (patients per page)
final pageSizeProvider = StateProvider<int>((ref) => 100);

/// Pagination: Current page (0-indexed)
final currentPageProvider = StateProvider<int>((ref) => 0);

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

  return allPatients.when(
    data: (patients) {
      // Calculate pagination
      final startIndex = currentPage * pageSize;
      final endIndex = (startIndex + pageSize).clamp(0, patients.length);
      
      if (startIndex >= patients.length) {
        return AsyncValue.data([]);
      }
      
      final paginatedPatients = patients.sublist(startIndex, endIndex);
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
