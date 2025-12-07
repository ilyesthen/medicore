import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// LAN Discovery Protocol Constants
class LANDiscovery {
  static const int broadcastPort = 45678;
  static const int discoveryPort = 45677;
  static const int grpcPort = 50051;
  static const String discoverRequest = 'MEDICORE_DISCOVER';
  static const String discoverResponse = 'MEDICORE_SERVER';
}

/// Service that broadcasts admin presence AND responds to discovery requests
/// Based on enterprise LAN discovery pattern:
/// - Admin broadcasts presence periodically (so clients can passively discover)
/// - Admin listens for discovery requests and responds (so clients can actively discover)
class AdminBroadcastService {
  static AdminBroadcastService? _instance;
  static AdminBroadcastService get instance => _instance ??= AdminBroadcastService._();
  
  AdminBroadcastService._();
  
  RawDatagramSocket? _broadcastSocket;
  RawDatagramSocket? _discoveryResponderSocket;
  Timer? _broadcastTimer;
  String? _currentIP;
  String? _computerName;
  bool _isRunning = false;
  
  /// Start admin services: broadcasting + discovery responder
  Future<void> start(String ip) async {
    if (_isRunning && _currentIP == ip) {
      print('✓ Admin services already running for $ip');
      return;
    }
    
    await stop();
    
    _currentIP = ip;
    _computerName = Platform.localHostname;
    
    try {
      // 1. Start the discovery responder (listens for client requests)
      await _startDiscoveryResponder();
      
      // 2. Start periodic broadcasting (passive discovery)
      await _startBroadcasting();
      
      _isRunning = true;
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('✅ ADMIN LAN SERVICES STARTED');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📡 Broadcasting on port ${LANDiscovery.broadcastPort}');
      print('🔍 Discovery responder on port ${LANDiscovery.discoveryPort}');
      print('🌐 gRPC server on port ${LANDiscovery.grpcPort}');
      print('💻 Computer: $_computerName');
      print('🔗 IP Address: $ip');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ Failed to start admin services: $e');
      await stop();
    }
  }
  
  /// Start listening for discovery requests and respond
  Future<void> _startDiscoveryResponder() async {
    _discoveryResponderSocket = await RawDatagramSocket.bind(
      InternetAddress.anyIPv4,
      LANDiscovery.discoveryPort,
      reuseAddress: true,
    );
    
    _discoveryResponderSocket!.listen((event) {
      if (event == RawSocketEvent.read) {
        final datagram = _discoveryResponderSocket!.receive();
        if (datagram != null) {
          _handleDiscoveryRequest(datagram);
        }
      }
    });
    
    print('🔍 Discovery responder listening on port ${LANDiscovery.discoveryPort}');
  }
  
  /// Handle incoming discovery request from a client
  void _handleDiscoveryRequest(Datagram datagram) {
    try {
      final message = utf8.decode(datagram.data);
      
      if (message == LANDiscovery.discoverRequest) {
        print('📡 Discovery request from ${datagram.address.address}');
        
        // Build response with server info
        final response = jsonEncode({
          'type': LANDiscovery.discoverResponse,
          'name': 'MediCore Admin',
          'computerName': _computerName,
          'ip': _currentIP,
          'port': LANDiscovery.grpcPort,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        });
        
        // Send response back to the requesting client
        _discoveryResponderSocket!.send(
          utf8.encode(response),
          datagram.address,
          datagram.port,
        );
        
        print('✅ Sent discovery response to ${datagram.address.address}');
      }
    } catch (e) {
      print('⚠️ Error handling discovery request: $e');
    }
  }
  
  /// Start periodic broadcasting for passive discovery
  Future<void> _startBroadcasting() async {
    _broadcastSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _broadcastSocket!.broadcastEnabled = true;
    
    // Broadcast message
    final message = jsonEncode({
      'type': 'medicore',
      'name': 'MediCore Admin',
      'computerName': _computerName,
      'ip': _currentIP,
      'port': LANDiscovery.grpcPort,
    });
    final bytes = utf8.encode(message);
    
    // Send immediately
    _broadcastSocket!.send(
      bytes,
      InternetAddress('255.255.255.255'),
      LANDiscovery.broadcastPort,
    );
    
    // Then broadcast every 2 seconds
    _broadcastTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      try {
        _broadcastSocket?.send(
          bytes,
          InternetAddress('255.255.255.255'),
          LANDiscovery.broadcastPort,
        );
      } catch (e) {
        // Ignore broadcast errors
      }
    });
    
    print('📢 Broadcasting presence every 2 seconds');
  }
  
  /// Stop all admin services
  Future<void> stop() async {
    _broadcastTimer?.cancel();
    _broadcastTimer = null;
    
    _broadcastSocket?.close();
    _broadcastSocket = null;
    
    _discoveryResponderSocket?.close();
    _discoveryResponderSocket = null;
    
    _currentIP = null;
    _computerName = null;
    _isRunning = false;
    
    print('✓ Admin services stopped');
  }
  
  /// Check if running
  bool get isRunning => _isRunning;
  
  /// Get current IP
  String? get currentIP => _currentIP;
  
  /// Get computer name
  String? get computerName => _computerName;
}
