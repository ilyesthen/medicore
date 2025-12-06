import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../data/waiting_queue_repository.dart';

/// Provider for waiting queue repository
final waitingQueueRepositoryProvider = Provider<WaitingQueueRepository>((ref) {
  return WaitingQueueRepository(AppDatabase());
});

/// Provider for waiting count for a specific room (non-urgent)
final waitingCountProvider = StreamProvider.family<int, String>((ref, roomId) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchWaitingCountForRoom(roomId);
});

/// Provider for urgent count for a specific room
final urgentCountProvider = StreamProvider.family<int, String>((ref, roomId) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchUrgentCountForRoom(roomId);
});

/// Provider for waiting patients list for a specific room (non-urgent)
final waitingPatientsProvider = StreamProvider.family<List<WaitingPatient>, String>((ref, roomId) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchWaitingPatientsForRoom(roomId);
});

/// Provider for urgent patients list for a specific room
final urgentPatientsProvider = StreamProvider.family<List<WaitingPatient>, String>((ref, roomId) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchUrgentPatientsForRoom(roomId);
});

/// Provider for dilatation count for a specific room
final dilatationCountProvider = StreamProvider.family<int, String>((ref, roomId) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchDilatationCountForRoom(roomId);
});

/// Provider for dilatation patients list for a specific room
final dilatationPatientsProvider = StreamProvider.family<List<WaitingPatient>, String>((ref, roomId) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchDilatationPatientsForRoom(roomId);
});

/// Provider for total dilatation count across multiple rooms (for nurse)
final totalDilatationCountProvider = StreamProvider.family<int, List<String>>((ref, roomIds) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchTotalDilatationCount(roomIds);
});

/// Provider for dilatation patients across multiple rooms (for nurse)
final allDilatationPatientsProvider = StreamProvider.family<List<WaitingPatient>, List<String>>((ref, roomIds) {
  final repository = ref.watch(waitingQueueRepositoryProvider);
  return repository.watchDilatationPatientsForRooms(roomIds);
});
