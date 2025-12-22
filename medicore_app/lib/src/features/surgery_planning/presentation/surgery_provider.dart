import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/surgery_repository_stub.dart';

final surgeryPlansRepositoryProvider = Provider<SurgeryPlansRepository>((ref) {
  return SurgeryPlansRepository();
});
