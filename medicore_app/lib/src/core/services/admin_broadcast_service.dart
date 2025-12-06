import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Service that continuously broadcasts admin server presence on LAN
class AdminBroadcastService {
  static AdminBroadcastService? _instance;
  static AdminBroadcastService get instance => _instance ??= AdminBroadcastService._();
  
  AdminBroadcastService._();
  
  RawDatagramSocket? _socket;
  Timer? _timer;
  String? _currentIP;
  bool _isRunning = false;
  
  /// Start broadcasting admin server presence
  Future<void> start(String ip) async {
    if (_isRunning && _currentIP == ip) {
      print('✓ Broadcast already running for $ip');
      return;
    }
    
    await stop(); // Stop any existing broadcast
    
    try {
      _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket!.broadcastEnabled = true;
      _currentIP = ip;
      
      final message = jsonEncode({
        'type': 'medicore',
        'name': 'MediCore Admin',
        'ip': ip,
      });
      
      final bytes = utf8.encode(message);
      final broadcastAddr = InternetAddress('255.255.255.255');
      const port = 45678;
      
      // Send immediately
      _socket!.send(bytes, broadcastAddr, port);
      print('✓ Started broadcasting MediCore Admin at $ip');
      
      // Then broadcast every second
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        try {
          _socket?.send(bytes, broadcastAddr, port);
        } catch (e) {
          print('Broadcast error: $e');
        }
      });
      
      _isRunning = true;
    } catch (e) {
      print('Failed to start broadcast: $e');
      await stop();
    }
  }
  
  /// Stop broadcasting
  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    
    _socket?.close();
    _socket = null;
    
    _currentIP = null;
    _isRunning = false;
    
    print('✓ Broadcast stopped');
  }
  
  /// Check if broadcasting
  bool get isRunning => _isRunning;
  
  /// Get current broadcast IP
  String? get currentIP => _currentIP;
}
