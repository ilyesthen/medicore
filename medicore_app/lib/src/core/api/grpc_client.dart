import 'package:grpc/grpc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// gRPC client provider
final grpcClientProvider = Provider<ClientChannel>((ref) {
  return GrpcClientConfig.getChannel();
});

/// gRPC Client Configuration
/// Connects to Go backend server for syncing data
class GrpcClientConfig {
  GrpcClientConfig._();
  
  // Server Configuration
  static const String defaultHost = 'localhost';
  static const int defaultPort = 50051;
  
  static String? _serverHost;
  static bool _isServer = true;
  static ClientChannel? _channel;
  
  /// Initialize from saved preferences
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isServer = prefs.getBool('is_server') ?? true;
    _serverHost = prefs.getString('server_ip');
    
    // DEBUG: Log the configuration to help diagnose issues
    print('🔧 [GrpcClientConfig] Initialized: isServer=$_isServer, serverHost=$_serverHost');
    
    // SAFETY CHECK: If server_ip is null or localhost, this MUST be server mode
    if (_serverHost == null || _serverHost == 'localhost' || _serverHost == '127.0.0.1') {
      if (!_isServer) {
        print('⚠️ [GrpcClientConfig] FIXING MISCONFIGURATION: No server IP but is_server=false. Forcing server mode.');
        _isServer = true;
        await prefs.setBool('is_server', true);
      }
    }
  }
  
  /// Check if this instance is the server
  static bool get isServer => _isServer;
  
  /// Get server host
  static String get serverHost => _serverHost ?? defaultHost;
  
  /// Set server host dynamically
  static void setServerHost(String host) {
    _serverHost = host;
    _channel?.shutdown();
    _channel = null;
  }
  
  /// Set server mode
  static void setServerMode(bool isServer) {
    _isServer = isServer;
  }
  
  /// Get or create the shared channel
  static ClientChannel getChannel() {
    _channel ??= createChannel(host: serverHost);
    return _channel!;
  }
  
  /// Creates a gRPC client channel
  static ClientChannel createChannel({
    String? host,
    int? port,
    bool useSSL = false,
  }) {
    return ClientChannel(
      host ?? serverHost,
      port: port ?? defaultPort,
      options: ChannelOptions(
        credentials: useSSL 
            ? const ChannelCredentials.secure()
            : const ChannelCredentials.insecure(),
        connectionTimeout: const Duration(seconds: 5),
      ),
    );
  }
  
  /// Test connection to server
  static Future<bool> testConnection([String? host]) async {
    try {
      final channel = createChannel(host: host);
      await channel.getConnection();
      await channel.shutdown();
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Shutdown the channel
  static Future<void> shutdown() async {
    await _channel?.shutdown();
    _channel = null;
  }
}
