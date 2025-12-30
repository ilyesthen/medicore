import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'grpc_client.dart';
import 'medicore_client.dart';
import 'sse_client.dart';
import 'realtime_sync_service.dart';

/// Connection status enum
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// Connection state immutable class
class ServerConnectionState {
  final ConnectionStatus status;
  final String? serverIP;
  final String? serverName;
  final DateTime? lastConnected;
  final int reconnectAttempts;
  final String? error;

  const ServerConnectionState({
    this.status = ConnectionStatus.disconnected,
    this.serverIP,
    this.serverName,
    this.lastConnected,
    this.reconnectAttempts = 0,
    this.error,
  });

  ServerConnectionState copyWith({
    ConnectionStatus? status,
    String? serverIP,
    String? serverName,
    DateTime? lastConnected,
    int? reconnectAttempts,
    String? error,
  }) {
    return ServerConnectionState(
      status: status ?? this.status,
      serverIP: serverIP ?? this.serverIP,
      serverName: serverName ?? this.serverName,
      lastConnected: lastConnected ?? this.lastConnected,
      reconnectAttempts: reconnectAttempts ?? this.reconnectAttempts,
      error: error,
    );
  }

  bool get isConnected => status == ConnectionStatus.connected;
  bool get isConnecting => status == ConnectionStatus.connecting || status == ConnectionStatus.reconnecting;
}

/// Enterprise-grade Connection Manager
/// Handles server discovery, connection, health monitoring, and auto-reconnection
class ConnectionManager {
  static ConnectionManager? _instance;
  static ConnectionManager get instance => _instance ??= ConnectionManager._();

  ConnectionManager._();

  // State
  ServerConnectionState _state = const ServerConnectionState();
  ServerConnectionState get state => _state;

  // Stream controller for state changes
  final _stateController = StreamController<ServerConnectionState>.broadcast();
  Stream<ServerConnectionState> get stateStream => _stateController.stream;

  // Health check timer
  Timer? _healthCheckTimer;
  static const _healthCheckInterval = Duration(seconds: 10);

  // Reconnect settings
  Timer? _reconnectTimer;
  static const _minReconnectDelay = Duration(seconds: 1);
  static const _maxReconnectDelay = Duration(seconds: 30);

  // Callbacks for UI
  final List<VoidCallback> _onConnectedCallbacks = [];
  final List<VoidCallback> _onDisconnectedCallbacks = [];

  /// Add callback for when connected
  void onConnected(VoidCallback callback) => _onConnectedCallbacks.add(callback);

  /// Add callback for when disconnected
  void onDisconnected(VoidCallback callback) => _onDisconnectedCallbacks.add(callback);

  /// Initialize connection manager with saved server config
  Future<bool> initialize() async {
    debugPrint('🔌 [ConnectionManager] Initializing...');

    // Load saved config
    final config = await _loadConfig();
    if (config == null || config['serverIp'] == null) {
      debugPrint('⚠️ [ConnectionManager] No saved config found');
      return false;
    }

    final serverIP = config['serverIp'] as String;
    final serverName = config['serverName'] as String? ?? 'MediCore Server';

    debugPrint('🔌 [ConnectionManager] Connecting to saved server: $serverIP');

    // Connect
    return await connect(serverIP, serverName);
  }

  /// Connect to server with auto-reconnect
  Future<bool> connect(String serverIP, String serverName) async {
    _updateState(_state.copyWith(
      status: ConnectionStatus.connecting,
      serverIP: serverIP,
      serverName: serverName,
      reconnectAttempts: 0,
      error: null,
    ));

    try {
      // Step 1: Test TCP connection
      debugPrint('🔌 [ConnectionManager] Testing connection to $serverIP:50052');
      final canConnect = await _testConnection(serverIP);

      if (!canConnect) {
        _updateState(_state.copyWith(
          status: ConnectionStatus.disconnected,
          error: 'Cannot connect to server at $serverIP',
        ));
        _scheduleReconnect();
        return false;
      }

      // Step 2: Configure GrpcClientConfig
      GrpcClientConfig.setServerHost(serverIP);

      // Step 3: Initialize MediCoreClient
      await MediCoreClient.instance.initialize(host: serverIP);

      // Step 4: Verify with health check
      final isHealthy = await _performHealthCheck();

      if (!isHealthy) {
        _updateState(_state.copyWith(
          status: ConnectionStatus.disconnected,
          error: 'Server not responding',
        ));
        _scheduleReconnect();
        return false;
      }

      // Step 5: Initialize SSE for real-time updates
      await SSEClient.instance.connect(host: serverIP);

      // Step 6: Initialize real-time sync service
      await RealtimeSyncService.instance.initialize();

      // Step 7: Save config
      await _saveConfig(serverIP, serverName);

      // Connected!
      _updateState(_state.copyWith(
        status: ConnectionStatus.connected,
        lastConnected: DateTime.now(),
        reconnectAttempts: 0,
        error: null,
      ));

      // Start health monitoring
      _startHealthMonitor();

      // Notify callbacks
      for (final callback in _onConnectedCallbacks) {
        callback();
      }

      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('✅ [ConnectionManager] CONNECTED TO SERVER');
      debugPrint('📡 Server: $serverName');
      debugPrint('🔗 IP: $serverIP:50052');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return true;
    } catch (e) {
      debugPrint('❌ [ConnectionManager] Connection error: $e');
      _updateState(_state.copyWith(
        status: ConnectionStatus.disconnected,
        error: e.toString(),
      ));
      _scheduleReconnect();
      return false;
    }
  }

  /// Test TCP connection to server
  Future<bool> _testConnection(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        50052,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Perform health check (HTTP ping)
  Future<bool> _performHealthCheck() async {
    if (_state.serverIP == null) return false;

    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 5);

      final request = await client.getUrl(
        Uri.parse('http://${_state.serverIP}:50052/health'),
      );
      final response = await request.close();
      client.close();

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('⚠️ [ConnectionManager] Health check failed: $e');
      return false;
    }
  }

  /// Start health monitoring loop
  void _startHealthMonitor() {
    _stopHealthMonitor();

    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (_) async {
      if (_state.status != ConnectionStatus.connected) return;

      final isHealthy = await _performHealthCheck();

      if (!isHealthy) {
        debugPrint('❌ [ConnectionManager] Health check failed - server down');
        _handleServerDown();
      }
    });

    debugPrint('💓 [ConnectionManager] Health monitor started (${_healthCheckInterval.inSeconds}s interval)');
  }

  /// Stop health monitoring
  void _stopHealthMonitor() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
  }

  /// Handle server going down
  void _handleServerDown() {
    if (_state.status == ConnectionStatus.reconnecting) return;

    _stopHealthMonitor();

    _updateState(_state.copyWith(
      status: ConnectionStatus.reconnecting,
      error: 'Connection lost',
    ));

    // Notify callbacks
    for (final callback in _onDisconnectedCallbacks) {
      callback();
    }

    _scheduleReconnect();
  }

  /// Schedule reconnect with exponential backoff
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();

    if (_state.serverIP == null) {
      debugPrint('⚠️ [ConnectionManager] Cannot reconnect - no server IP');
      return;
    }

    // Calculate delay with exponential backoff
    final attempt = _state.reconnectAttempts;
    final delaySeconds = (_minReconnectDelay.inSeconds * (1 << attempt))
        .clamp(_minReconnectDelay.inSeconds, _maxReconnectDelay.inSeconds);
    final delay = Duration(seconds: delaySeconds);

    debugPrint('🔄 [ConnectionManager] Reconnecting in ${delay.inSeconds}s (attempt ${attempt + 1})');

    _reconnectTimer = Timer(delay, () async {
      _updateState(_state.copyWith(
        status: ConnectionStatus.reconnecting,
        reconnectAttempts: attempt + 1,
      ));

      final success = await connect(_state.serverIP!, _state.serverName ?? 'MediCore Server');

      if (!success) {
        // connect() will schedule another reconnect
      }
    });
  }

  /// Cancel reconnect attempts
  void cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  /// Disconnect from server
  void disconnect() {
    debugPrint('🔌 [ConnectionManager] Disconnecting...');

    _stopHealthMonitor();
    cancelReconnect();

    SSEClient.instance.disconnect();

    _updateState(const ServerConnectionState(status: ConnectionStatus.disconnected));
  }

  /// Update state and notify listeners
  void _updateState(ServerConnectionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  /// Load saved config
  Future<Map<String, dynamic>?> _loadConfig() async {
    try {
      final appDir = await getApplicationSupportDirectory();
      final configFile = File(p.join(appDir.path, 'medicore_config.txt'));

      if (!configFile.existsSync()) return null;

      return jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('⚠️ [ConnectionManager] Error loading config: $e');
      return null;
    }
  }

  /// Save config
  Future<void> _saveConfig(String serverIP, String serverName) async {
    try {
      final appDir = await getApplicationSupportDirectory();
      if (!await appDir.exists()) await appDir.create(recursive: true);

      final config = {
        'version': '5.1.0',
        'serverIp': serverIP,
        'serverName': serverName,
        'connectedAt': DateTime.now().toIso8601String(),
      };

      final configFile = File(p.join(appDir.path, 'medicore_config.txt'));
      await configFile.writeAsString(jsonEncode(config));
    } catch (e) {
      debugPrint('⚠️ [ConnectionManager] Error saving config: $e');
    }
  }

  /// Dispose
  void dispose() {
    disconnect();
    _stateController.close();
  }

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // FAST SERVER DISCOVERY
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  /// Discover servers on network - fast parallel scan
  Future<List<ServerInfo>> discoverServers({
    Duration timeout = const Duration(seconds: 8),
    void Function(ServerInfo)? onFound,
  }) async {
    final servers = <ServerInfo>[];
    final seen = <String>{};

    void addServer(String ip, String name) {
      if (!seen.contains(ip)) {
        seen.add(ip);
        final server = ServerInfo(ip: ip, name: name);
        servers.add(server);
        onFound?.call(server);
      }
    }

    try {
      debugPrint('🔍 [ConnectionManager] Scanning for servers...');

      final localIP = await _getLocalIP();

      if (localIP == '127.0.0.1') {
        debugPrint('⚠️ [ConnectionManager] No network interface found');
        return servers;
      }

      final subnet = localIP.substring(0, localIP.lastIndexOf('.'));
      debugPrint('🔍 [ConnectionManager] Scanning subnet: $subnet.0/24');

      // Priority IPs (common server addresses)
      final priorityIPs = <String>[
        '$subnet.1', '$subnet.2', '$subnet.3', '$subnet.4', '$subnet.5',
        '$subnet.10', '$subnet.11', '$subnet.20', '$subnet.50',
        '$subnet.100', '$subnet.101', '$subnet.200', '$subnet.254',
      ];

      // First: fast scan priority IPs
      final priorityFutures = priorityIPs.where((ip) => ip != localIP).map((ip) {
        return _quickProbe(ip).then((success) {
          if (success) addServer(ip, 'MediCore Server');
        });
      });

      await Future.wait(priorityFutures);

      // If found, return early
      if (servers.isNotEmpty) {
        debugPrint('✅ [ConnectionManager] Found ${servers.length} server(s) in priority scan');
        return servers;
      }

      // Full subnet scan
      debugPrint('🔍 [ConnectionManager] Priority scan empty, doing full scan...');

      final fullFutures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (ip == localIP || seen.contains(ip)) continue;

        fullFutures.add(
          _quickProbe(ip).then((success) {
            if (success) addServer(ip, 'MediCore Server');
          }),
        );
      }

      await Future.wait(fullFutures).timeout(timeout, onTimeout: () => []);

      debugPrint('✅ [ConnectionManager] Scan complete: ${servers.length} server(s) found');
      return servers;
    } catch (e) {
      debugPrint('❌ [ConnectionManager] Discovery error: $e');
      return servers;
    }
  }

  /// Quick TCP probe with short timeout
  Future<bool> _quickProbe(String ip) async {
    try {
      final socket = await Socket.connect(
        ip,
        50052,
        timeout: const Duration(milliseconds: 200),
      );
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Get local IP address
  Future<String> _getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.isLoopback &&
              (addr.address.startsWith('192.168') ||
                  addr.address.startsWith('10.') ||
                  addr.address.startsWith('172.'))) {
            return addr.address;
          }
        }
      }
    } catch (_) {}
    return '127.0.0.1';
  }
}

/// Server info for discovery
class ServerInfo {
  final String ip;
  final String name;

  const ServerInfo({required this.ip, required this.name});
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RIVERPOD PROVIDERS
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Connection state provider
final connectionStateProvider = StreamProvider<ServerConnectionState>((ref) {
  return ConnectionManager.instance.stateStream;
});

/// Current connection status provider
final connectionStatusProvider = Provider<ConnectionStatus>((ref) {
  final asyncState = ref.watch(connectionStateProvider);
  return asyncState.valueOrNull?.status ?? ConnectionManager.instance.state.status;
});

/// Is connected provider
final isConnectedProvider = Provider<bool>((ref) {
  final status = ref.watch(connectionStatusProvider);
  return status == ConnectionStatus.connected;
});
