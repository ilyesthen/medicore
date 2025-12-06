import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../api/grpc_client.dart';
import 'data_repository.dart';
import 'local_repository.dart';
import 'remote_repository.dart';

/// Provider for the data repository
/// Returns LocalRepository if in admin mode, RemoteRepository if in client mode
final dataRepositoryProvider = Provider<DataRepository>((ref) {
  if (GrpcClientConfig.isServer) {
    // ADMIN MODE: Use local database
    print('✓ Using LOCAL repository (Admin mode)');
    return LocalRepository(AppDatabase.instance);
  } else {
    // CLIENT MODE: Use gRPC to connect to admin
    print('✓ Using REMOTE repository (Client mode - connecting to ${GrpcClientConfig.serverHost}:50051)');
    return RemoteRepository();
  }
});
