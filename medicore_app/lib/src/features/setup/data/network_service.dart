import 'dart:io';
import 'dart:async';
import 'dart:convert';

/// Network service for LAN server discovery and communication
class NetworkService {
  static const int broadcastPort = 45678;
  static const int serverPort = 50051; // gRPC port
  static RawDatagramSocket? _broadcastSocket;
  static Timer? _broadcastTimer;

  /// Get local IP address
  static Future<String> getLocalIP() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLinkLocal: false,
      );
      
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback && addr.address.startsWith('192.168') || 
              addr.address.startsWith('10.') || 
              addr.address.startsWith('172.')) {
            return addr.address;
          }
        }
      }
      
      // Fallback: try to get any non-loopback address
      for (final interface in interfaces) {
        for (final addr in interface.addresses) {
          if (!addr.isLoopback) {
            return addr.address;
          }
        }
      }
      
      return '127.0.0.1';
    } catch (e) {
      return '127.0.0.1';
    }
  }

  /// Start broadcasting server presence on LAN
  static Future<void> startServerBroadcast(String serverName) async {
    try {
      final ip = await getLocalIP();
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _broadcastSocket = socket;
      socket.broadcastEnabled = true;

      final message = jsonEncode({
        'type': 'medicore_server',
        'name': serverName,
        'ip': ip,
        'port': serverPort,
        'version': '1.0.0',
      });

      // Broadcast every 2 seconds
      _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
        try {
          socket.send(
            utf8.encode(message),
            InternetAddress('255.255.255.255'),
            broadcastPort,
          );
        } catch (e) {
          // Ignore broadcast errors
        }
      });

      // Also send immediately
      socket.send(
        utf8.encode(message),
        InternetAddress('255.255.255.255'),
        broadcastPort,
      );
    } catch (e) {
      print('Failed to start broadcast: $e');
    }
  }

  /// Stop server broadcast
  static void stopServerBroadcast() {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    _broadcastSocket?.close();
    _broadcastSocket = null;
  }

  /// Discover servers on LAN
  static Future<List<ServerInfo>> discoverServers() async {
    final servers = <ServerInfo>[];
    final seen = <String>{};

    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, broadcastPort, reuseAddress: true);
      socket.broadcastEnabled = true;

      // Listen for responses for 3 seconds
      final completer = Completer<List<ServerInfo>>();
      
      socket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = socket.receive();
          if (datagram != null) {
            try {
              final message = utf8.decode(datagram.data);
              final data = jsonDecode(message) as Map<String, dynamic>;
              
              if (data['type'] == 'medicore_server') {
                final ip = data['ip'] as String;
                if (!seen.contains(ip)) {
                  seen.add(ip);
                  servers.add(ServerInfo(
                    name: data['name'] as String,
                    ip: ip,
                    port: data['port'] as int,
                    version: data['version'] as String? ?? '1.0.0',
                  ));
                }
              }
            } catch (e) {
              // Ignore malformed messages
            }
          }
        }
      });

      // Also try to discover by scanning common IPs
      _scanLocalNetwork(servers, seen);

      // Wait for responses
      await Future.delayed(const Duration(seconds: 3));
      socket.close();
      
      return servers;
    } catch (e) {
      print('Discovery error: $e');
      return servers;
    }
  }

  /// Scan local network for servers
  static Future<void> _scanLocalNetwork(List<ServerInfo> servers, Set<String> seen) async {
    try {
      final localIP = await getLocalIP();
      final parts = localIP.split('.');
      if (parts.length != 4) return;

      final subnet = '${parts[0]}.${parts[1]}.${parts[2]}';
      
      // Scan common IPs in parallel (limited to avoid overwhelming)
      final futures = <Future>[];
      for (int i = 1; i <= 254; i++) {
        final ip = '$subnet.$i';
        if (seen.contains(ip)) continue;
        
        futures.add(_checkServer(ip).then((info) {
          if (info != null && !seen.contains(info.ip)) {
            seen.add(info.ip);
            servers.add(info);
          }
        }).catchError((_) {}));
        
        // Limit concurrent connections
        if (futures.length >= 50) {
          await Future.wait(futures);
          futures.clear();
        }
      }
      
      if (futures.isNotEmpty) {
        await Future.wait(futures).timeout(const Duration(seconds: 2), onTimeout: () => []);
      }
    } catch (e) {
      // Ignore scan errors
    }
  }

  /// Check if a specific IP has a MediCore server
  static Future<ServerInfo?> _checkServer(String ip) async {
    try {
      final socket = await Socket.connect(ip, serverPort, timeout: const Duration(milliseconds: 500));
      socket.destroy();
      
      // If connection succeeded, it's likely our server
      return ServerInfo(
        name: 'MediCore Server',
        ip: ip,
        port: serverPort,
        version: '1.0.0',
      );
    } catch (e) {
      return null;
    }
  }

  /// Test connection to a server
  static Future<bool> testConnection(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(seconds: 2));
      socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}

/// Server information
class ServerInfo {
  final String name;
  final String ip;
  final int port;
  final String version;

  ServerInfo({
    required this.name,
    required this.ip,
    required this.port,
    required this.version,
  });

  @override
  String toString() => '$name ($ip:$port)';
}
