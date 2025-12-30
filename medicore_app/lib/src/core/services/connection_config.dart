import 'package:flutter/foundation.dart';
import '../api/grpc_client.dart';

/// Server Connection Configuration
/// PRO ARCHITECTURE: All instances connect to the Go backend server REST API
/// No local database, no server mode - everyone is a client
class ConnectionConfig {
  static ConnectionConfig? _instance;
  
  final String serverIP;
  final int serverPort;
  
  ConnectionConfig._({
    required this.serverIP,
    required this.serverPort,
  });
  
  static ConnectionConfig get instance {
    _instance ??= ConnectionConfig._(
      serverIP: GrpcClientConfig.serverHost,
      serverPort: GrpcClientConfig.serverPort,
    );
    return _instance!;
  }
  
  /// Initialize configuration
  static Future<void> initialize() async {
    await GrpcClientConfig.initialize();
    _instance = ConnectionConfig._(
      serverIP: GrpcClientConfig.serverHost,
      serverPort: GrpcClientConfig.serverPort,
    );
    debugPrint('📡 ConnectionConfig: Server at ${_instance!.serverIP}:${_instance!.serverPort}');
  }
  
  /// Update server connection
  static void setServerIP(String ip) {
    GrpcClientConfig.setServerHost(ip);
    _instance = ConnectionConfig._(
      serverIP: ip,
      serverPort: GrpcClientConfig.serverPort,
    );
  }
  
  /// Get the base URL for API calls
  String get apiBaseUrl => 'http://$serverIP:$serverPort/api';
  
  /// Get REST endpoint
  String get restEndpoint => '$serverIP:$serverPort';
  
  @override
  String toString() => 'ConnectionConfig(server: $serverIP:$serverPort)';
}
