import 'package:shared_preferences/shared_preferences.dart';

/// Server Configuration
/// All instances connect to the Go backend server REST API
/// No more local database or gRPC - everything goes through HTTP REST API
class GrpcClientConfig {
  GrpcClientConfig._();
  
  // Server Configuration
  static const String defaultHost = 'localhost';
  static const int restPort = 50052;
  
  static String? _serverHost;
  
  /// Initialize from saved preferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _serverHost = prefs.getString('server_ip');
    print('🔌 ServerConfig: Server host = ${_serverHost ?? defaultHost}');
  }
  
  /// Get server host
  static String get serverHost => _serverHost ?? defaultHost;
  
  /// Get REST API port
  static int get serverPort => restPort;
  
  /// Set server host dynamically
  static void setServerHost(String host) async {
    _serverHost = host;
    // Save to preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', host);
    print('🔌 ServerConfig: Server host set to $host');
  }
  
  /// Get full server URL
  static String get serverUrl => 'http://$serverHost:$restPort';
}
