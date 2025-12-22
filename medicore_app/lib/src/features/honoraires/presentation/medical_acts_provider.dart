import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/types/proto_types.dart';

/// Medical acts repository provider
final medicalActsRepositoryProvider = Provider<MedicalActsRepository>((ref) {
  return MedicalActsRepository();
});

/// All medical acts stream provider
final medicalActsListProvider = StreamProvider<List<MedicalAct>>((ref) {
  final repository = ref.watch(medicalActsRepositoryProvider);
  return repository.watchAllMedicalActs();
});
