import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/types/proto_types.dart';

/// All medical acts stream provider (stub - not yet implemented)
final medicalActsListProvider = StreamProvider<List<MedicalAct>>((ref) {
  // Return empty stream for now - medical acts feature not yet implemented
  return Stream.value([]);
});
