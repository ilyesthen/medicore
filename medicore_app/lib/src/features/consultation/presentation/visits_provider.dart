import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/types/proto_types.dart';

/// Visits repository provider (stub - not yet implemented)
final visitsRepositoryProvider = Provider((ref) {
  throw UnimplementedError('VisitsRepository not yet implemented in gRPC mode');
});

/// Patient visits provider (stub - returns empty list)
final patientVisitsProvider = StreamProvider.family<List<Visit>, int>((ref, patientCode) {
  return Stream.value([]);
});

/// Patient visit count provider (stub - returns 0)
final patientVisitCountProvider = StreamProvider.family<int, int>((ref, patientCode) {
  return Stream.value(0);
});
