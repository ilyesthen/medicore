import 'dart:io';
import 'package:flutter/foundation.dart';

/// Connection configuration for Server/Client modes
/// Reads from environment file to determine how to connect
class ConnectionConfig {
  static ConnectionConfig? _instance;
  
  final bool isServerMode;
  final String serverIP;
  final int serverPort;
  final String databasePath;
  final bool allowLAN;
  
  ConnectionConfig._({
    required this.isServerMode,
    required this.serverIP,
    required this.serverPort,
    required this.databasePath,
    required this.allowLAN,
  });
  
  static ConnectionConfig get instance {
    _instance ??= ConnectionConfig._(
      isServerMode: true,
      serverIP: 'localhost',
      serverPort: 8080,
      databasePath: 'medicore.db',
      allowLAN: false,
    );
    return _instance!;
  }
  
  /// Initialize configuration from environment files
  static Future<void> initialize() async {
    try {
      // Check for server mode config
      final serverEnvFile = File('server/server.env');
      final clientEnvFile = File('client.env');
      
      if (await serverEnvFile.exists()) {
        // Server mode
        final config = await _parseEnvFile(serverEnvFile);
        _instance = ConnectionConfig._(
          isServerMode: true,
          serverIP: '0.0.0.0',
          serverPort: int.tryParse(config['SERVER_PORT'] ?? '8080') ?? 8080,
          databasePath: config['DATABASE_PATH'] ?? './data/medicore.db',
          allowLAN: config['ALLOW_LAN']?.toLowerCase() == 'true',
        );
        debugPrint('MediCore: Running in SERVER mode');
      } else if (await clientEnvFile.exists()) {
        // Client mode
        final config = await _parseEnvFile(clientEnvFile);
        _instance = ConnectionConfig._(
          isServerMode: false,
          serverIP: config['SERVER_IP'] ?? '192.168.1.100',
          serverPort: int.tryParse(config['SERVER_PORT'] ?? '8080') ?? 8080,
          databasePath: '', // Client doesn't have local database
          allowLAN: false,
        );
        debugPrint('MediCore: Running in CLIENT mode, connecting to ${_instance!.serverIP}:${_instance!.serverPort}');
      } else {
        // Default: standalone mode with local database
        _instance = ConnectionConfig._(
          isServerMode: true,
          serverIP: 'localhost',
          serverPort: 8080,
          databasePath: 'medicore.db',
          allowLAN: false,
        );
        debugPrint('MediCore: Running in STANDALONE mode');
      }
    } catch (e) {
      debugPrint('MediCore: Error loading config: $e');
      // Fallback to standalone
      _instance = ConnectionConfig._(
        isServerMode: true,
        serverIP: 'localhost',
        serverPort: 8080,
        databasePath: 'medicore.db',
        allowLAN: false,
      );
    }
  }
  
  static Future<Map<String, String>> _parseEnvFile(File file) async {
    final Map<String, String> env = {};
    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        final trimmed = line.trim();
        if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
        
        final parts = trimmed.split('=');
        if (parts.length >= 2) {
          final key = parts[0].trim();
          final value = parts.sublist(1).join('=').trim();
          env[key] = value;
        }
      }
    } catch (e) {
      debugPrint('Error parsing env file: $e');
    }
    return env;
  }
  
  /// Get the base URL for API calls (used in client mode)
  String get apiBaseUrl => 'http://$serverIP:$serverPort/api';
  
  /// Get the gRPC endpoint
  String get grpcEndpoint => '$serverIP:$serverPort';
  
  /// Check if we should use remote database
  bool get useRemoteDatabase => !isServerMode;
  
  @override
  String toString() => 'ConnectionConfig(isServer: $isServerMode, ip: $serverIP, port: $serverPort)';
}
