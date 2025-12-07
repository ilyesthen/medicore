import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../api/grpc_client.dart';
import 'data_repository.dart';
import 'local_repository.dart';
// import 'remote_repository.dart'; // TODO: Enable when proto generation is fixed

/// Provider for the data repository
/// TODO: When gRPC proto is properly generated, use RemoteRepository for client mode
/// For now, both modes use LocalRepository (database will be synced separately)
final dataRepositoryProvider = Provider<DataRepository>((ref) {
  // Both admin and client use local database for now
  // gRPC sync will be implemented when proto generation is fixed
  print('✓ Using LOCAL repository');
  return LocalRepository(AppDatabase.instance);
});
