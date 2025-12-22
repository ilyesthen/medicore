import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/appointments_repository_stub.dart';

final appointmentsRepositoryProvider = Provider<AppointmentsRepository>((ref) {
  return AppointmentsRepository();
});
