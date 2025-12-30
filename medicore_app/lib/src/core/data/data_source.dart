import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/grpc_client.dart';
import '../api/medicore_client.dart';
import '../api/realtime_sync_service.dart';

/// PRO ARCHITECTURE: All operations go through the Go REST API server
/// All instances use the remote API - no direct database access

/// Central data source manager
/// ALL data operations go through the Go REST API server
class DataSourceManager {
  static DataSourceManager? _instance;
  static DataSourceManager get instance => _instance ??= DataSourceManager._();
  
  DataSourceManager._();
  
  bool _initialized = false;
  
  /// Always use remote API in pro architecture
  bool get isLocal => false;
  
  /// Always use remote API
  bool get isRemote => true;
  
  /// Check if initialized
  bool get isInitialized => _initialized;
  
  /// Initialize data source - always connects to Go REST API
  Future<void> initialize() async {
    if (_initialized) return;
    
    final host = GrpcClientConfig.serverHost;
    
    debugPrint('📊 [DataSource] PRO Mode: Using REST API server at $host:50052');
    
    // Initialize MediCoreClient
    await MediCoreClient.instance.initialize(host: host);
    
    // Initialize real-time sync via SSE for instant updates
    await RealtimeSyncService.instance.initialize();
    
    _initialized = true;
  }
  
  /// Get remote client (always available in pro architecture)
  MediCoreClient get client => MediCoreClient.instance;
}
