import 'dart:async';
import 'package:flutter/foundation.dart';
import '../api/grpc_client.dart';
import '../api/medicore_client.dart';
import '../api/realtime_sync_service.dart';
import '../database/app_database.dart';

/// Data source mode - determines where data comes from
enum DataSourceMode {
  local,  // Admin mode - uses local SQLite database
  remote, // Client mode - uses REST API to admin server
}

/// Central data source manager
/// Handles switching between local (admin) and remote (client) data sources
/// ALL data operations go through this class
class DataSourceManager {
  static DataSourceManager? _instance;
  static DataSourceManager get instance => _instance ??= DataSourceManager._();
  
  DataSourceManager._();
  
  DataSourceMode _mode = DataSourceMode.local;
  bool _initialized = false;
  
  /// Current mode
  DataSourceMode get mode => _mode;
  
  /// Check if using local database
  bool get isLocal => _mode == DataSourceMode.local;
  
  /// Check if using remote API
  bool get isRemote => _mode == DataSourceMode.remote;
  
  /// Check if initialized
  bool get isInitialized => _initialized;
  
  /// Initialize data source based on configuration
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Determine mode from GrpcClientConfig
    if (GrpcClientConfig.isServer) {
      _mode = DataSourceMode.local;
      debugPrint('📊 [DataSource] Mode: LOCAL (Admin)');
    } else {
      _mode = DataSourceMode.remote;
      debugPrint('📊 [DataSource] Mode: REMOTE (Client)');
      
      // Initialize MediCoreClient
      await MediCoreClient.instance.initialize(
        host: GrpcClientConfig.serverHost,
      );
      
      // Initialize real-time sync via SSE for instant updates
      await RealtimeSyncService.instance.initialize();
    }
    
    _initialized = true;
  }
  
  /// Get local database (only in local mode)
  AppDatabase get database {
    if (_mode == DataSourceMode.remote) {
      debugPrint('⚠️ [DataSource] Warning: Accessing local database in remote mode');
    }
    return AppDatabase.instance;
  }
  
  /// Get remote client (only in remote mode)
  MediCoreClient get client {
    if (_mode == DataSourceMode.local) {
      debugPrint('⚠️ [DataSource] Warning: Accessing remote client in local mode');
    }
    return MediCoreClient.instance;
  }
  
  /// Force mode (for testing)
  @visibleForTesting
  void setMode(DataSourceMode mode) {
    _mode = mode;
  }
}
