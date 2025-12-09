import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/remote_waiting_queue_repository.dart';
import '../data/waiting_queue_repository.dart';

/// Abstract interface for waiting queue operations
abstract class IWaitingQueueRepository {
  Future<int> addToQueue({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String motif,
    required String sentByUserId,
    required String sentByUserName,
    bool isUrgent,
  });
  Future<int> addToDilatation({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String dilatationType,
    required String sentByUserId,
    required String sentByUserName,
  });
  Stream<List<WaitingPatient>> watchWaitingPatientsForRoom(String roomId);
  Stream<List<WaitingPatient>> watchUrgentPatientsForRoom(String roomId);
  Stream<List<WaitingPatient>> watchDilatationPatientsForRoom(String roomId);
  Stream<List<WaitingPatient>> watchDilatationPatientsForRooms(List<String> roomIds);
  Stream<int> watchWaitingCountForRoom(String roomId);
  Stream<int> watchUrgentCountForRoom(String roomId);
  Stream<int> watchDilatationCountForRoom(String roomId);
  Stream<int> watchTotalDilatationCount(List<String> roomIds);
  Future<void> toggleChecked(int id);
  Future<void> removeFromQueue(int id);
  Future<void> removeByPatientCode(int patientCode);
  Future<void> markDilatationsAsNotified(List<String> roomIds);
}

/// Local waiting queue adapter
class LocalWaitingQueueAdapter implements IWaitingQueueRepository {
  final WaitingQueueRepository _local;
  LocalWaitingQueueAdapter(this._local);
  
  @override
  Future<int> addToQueue({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String motif,
    required String sentByUserId,
    required String sentByUserName,
    bool isUrgent = false,
  }) => _local.addToQueue(
    patientCode: patientCode,
    patientFirstName: patientFirstName,
    patientLastName: patientLastName,
    patientBirthDate: patientBirthDate,
    patientAge: patientAge,
    roomId: roomId,
    roomName: roomName,
    motif: motif,
    sentByUserId: sentByUserId,
    sentByUserName: sentByUserName,
    isUrgent: isUrgent,
  );
  
  @override
  Future<int> addToDilatation({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String dilatationType,
    required String sentByUserId,
    required String sentByUserName,
  }) => _local.addToDilatation(
    patientCode: patientCode,
    patientFirstName: patientFirstName,
    patientLastName: patientLastName,
    patientBirthDate: patientBirthDate,
    patientAge: patientAge,
    roomId: roomId,
    roomName: roomName,
    dilatationType: dilatationType,
    sentByUserId: sentByUserId,
    sentByUserName: sentByUserName,
  );
  
  @override
  Stream<List<WaitingPatient>> watchWaitingPatientsForRoom(String roomId) => 
    _local.watchWaitingPatientsForRoom(roomId);
  
  @override
  Stream<List<WaitingPatient>> watchUrgentPatientsForRoom(String roomId) => 
    _local.watchUrgentPatientsForRoom(roomId);
  
  @override
  Stream<List<WaitingPatient>> watchDilatationPatientsForRoom(String roomId) => 
    _local.watchDilatationPatientsForRoom(roomId);
  
  @override
  Stream<List<WaitingPatient>> watchDilatationPatientsForRooms(List<String> roomIds) => 
    _local.watchDilatationPatientsForRooms(roomIds);
  
  @override
  Stream<int> watchWaitingCountForRoom(String roomId) => 
    _local.watchWaitingCountForRoom(roomId);
  
  @override
  Stream<int> watchUrgentCountForRoom(String roomId) => 
    _local.watchUrgentCountForRoom(roomId);
  
  @override
  Stream<int> watchDilatationCountForRoom(String roomId) => 
    _local.watchDilatationCountForRoom(roomId);
  
  @override
  Stream<int> watchTotalDilatationCount(List<String> roomIds) => 
    _local.watchTotalDilatationCount(roomIds);
  
  @override
  Future<void> toggleChecked(int id) => _local.toggleChecked(id);
  
  @override
  Future<void> removeFromQueue(int id) => _local.removeFromQueue(id);
  
  @override
  Future<void> removeByPatientCode(int patientCode) => 
    _local.removeByPatientCode(patientCode);
  
  @override
  Future<void> markDilatationsAsNotified(List<String> roomIds) => 
    _local.markDilatationsAsNotified(roomIds);
}

/// Remote waiting queue adapter
class RemoteWaitingQueueAdapter implements IWaitingQueueRepository {
  final RemoteWaitingQueueRepository _remote;
  RemoteWaitingQueueAdapter(this._remote);
  
  @override
  Future<int> addToQueue({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String motif,
    required String sentByUserId,
    required String sentByUserName,
    bool isUrgent = false,
  }) => _remote.addToQueue(
    patientCode: patientCode,
    patientFirstName: patientFirstName,
    patientLastName: patientLastName,
    patientBirthDate: patientBirthDate,
    patientAge: patientAge,
    roomId: roomId,
    roomName: roomName,
    motif: motif,
    sentByUserId: sentByUserId,
    sentByUserName: sentByUserName,
    isUrgent: isUrgent,
  );
  
  @override
  Future<int> addToDilatation({
    required int patientCode,
    required String patientFirstName,
    required String patientLastName,
    DateTime? patientBirthDate,
    int? patientAge,
    required String roomId,
    required String roomName,
    required String dilatationType,
    required String sentByUserId,
    required String sentByUserName,
  }) => _remote.addToDilatation(
    patientCode: patientCode,
    patientFirstName: patientFirstName,
    patientLastName: patientLastName,
    patientBirthDate: patientBirthDate,
    patientAge: patientAge,
    roomId: roomId,
    roomName: roomName,
    dilatationType: dilatationType,
    sentByUserId: sentByUserId,
    sentByUserName: sentByUserName,
  );
  
  @override
  Stream<List<WaitingPatient>> watchWaitingPatientsForRoom(String roomId) => 
    _remote.watchWaitingPatientsForRoom(roomId);
  
  @override
  Stream<List<WaitingPatient>> watchUrgentPatientsForRoom(String roomId) => 
    _remote.watchUrgentPatientsForRoom(roomId);
  
  @override
  Stream<List<WaitingPatient>> watchDilatationPatientsForRoom(String roomId) => 
    _remote.watchDilatationPatientsForRoom(roomId);
  
  @override
  Stream<List<WaitingPatient>> watchDilatationPatientsForRooms(List<String> roomIds) => 
    _remote.watchDilatationPatientsForRooms(roomIds);
  
  @override
  Stream<int> watchWaitingCountForRoom(String roomId) => 
    _remote.watchWaitingCountForRoom(roomId);
  
  @override
  Stream<int> watchUrgentCountForRoom(String roomId) => 
    _remote.watchUrgentCountForRoom(roomId);
  
  @override
  Stream<int> watchDilatationCountForRoom(String roomId) => 
    _remote.watchDilatationCountForRoom(roomId);
  
  @override
  Stream<int> watchTotalDilatationCount(List<String> roomIds) => 
    _remote.watchTotalDilatationCount(roomIds);
  
  @override
  Future<void> toggleChecked(int id) => _remote.toggleChecked(id);
  
  @override
  Future<void> removeFromQueue(int id) => _remote.removeFromQueue(id);
  
  @override
  Future<void> removeByPatientCode(int patientCode) => 
    _remote.removeByPatientCode(patientCode);
  
  @override
  Future<void> markDilatationsAsNotified(List<String> roomIds) => 
    _remote.markDilatationsAsNotified(roomIds);
}

// Singleton instances to prevent multiple SSE registrations
RemoteWaitingQueueRepository? _remoteWaitingQueueRepo;
WaitingQueueRepository? _localWaitingQueueRepo;

/// Waiting queue repository provider - switches between local and remote
final waitingQueueRepositoryProvider = Provider<IWaitingQueueRepository>((ref) {
  if (GrpcClientConfig.isServer) {
    print('✓ [WaitingQueueRepository] Using LOCAL database (Admin mode)');
    _localWaitingQueueRepo ??= WaitingQueueRepository(AppDatabase.instance);
    return LocalWaitingQueueAdapter(_localWaitingQueueRepo!);
  } else {
    print('✓ [WaitingQueueRepository] Using REMOTE API (Client mode)');
    _remoteWaitingQueueRepo ??= RemoteWaitingQueueRepository();
    return RemoteWaitingQueueAdapter(_remoteWaitingQueueRepo!);
  }
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

/// Provider for total waiting count across multiple rooms (for nurse)
final totalWaitingCountProvider = StreamProvider.family<int, List<String>>((ref, roomIds) {
  if (roomIds.isEmpty) return Stream.value(0);
  
  // Watch all individual room counts and sum them
  final streams = roomIds.map((roomId) {
    final countAsync = ref.watch(waitingCountProvider(roomId));
    return countAsync.valueOrNull ?? 0;
  });
  
  return Stream.value(streams.fold(0, (sum, count) => sum + count));
});
