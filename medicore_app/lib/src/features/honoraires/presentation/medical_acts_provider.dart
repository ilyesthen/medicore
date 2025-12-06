import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/medical_acts_repository.dart';

/// Medical acts repository provider
final medicalActsRepositoryProvider = Provider<MedicalActsRepository>((ref) {
  return MedicalActsRepository();
});

/// All medical acts stream provider
final medicalActsListProvider = StreamProvider<List<MedicalAct>>((ref) {
  final repository = ref.watch(medicalActsRepositoryProvider);
  return repository.watchAllMedicalActs();
});
