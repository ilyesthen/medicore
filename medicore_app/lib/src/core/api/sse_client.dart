import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'grpc_client.dart';
import '../../core/types/proto_types.dart';

/// Event types from the server (must match Go server sse_handler.go)
enum SSEEventType {
  connected,
  ping,
  // Patient events
  patientCreated,
  patientUpdated,
  patientDeleted,
  // Message events
  messageCreated,
  messageRead,
  messagesCleared,
  // Waiting queue events
  waitingAdded,
  waitingUpdated,
  waitingRemoved,
  dilatationAdded,
  // Payment events
  paymentCreated,
  paymentUpdated,
  paymentDeleted,
  // User events
  userCreated,
  userUpdated,
  userDeleted,
  // User template events
  templateCreated,
  templateUpdated,
  templateDeleted,
  // Room events
  roomCreated,
  roomUpdated,
  roomDeleted,
  // Visit events
  visitCreated,
  visitUpdated,
  visitDeleted,
  // Ordonnance events
  ordonnanceCreated,
  ordonnanceUpdated,
  ordonnanceDeleted,
  // Medical act events
  medicalActCreated,
  medicalActUpdated,
  medicalActDeleted,
  medicalActReorder,
  // Message template events
  msgTemplateCreated,
  msgTemplateUpdated,
  msgTemplateDeleted,
  msgTemplateReorder,
  // Medication events
  medicationUpdated,
  // Nurse preference events
  nursePrefsUpdated,
  nurseActive,
  nurseInactive,
  unknown,
}

/// Parse event type from string
SSEEventType parseEventType(String type) {
  switch (type) {
    case 'connected': return SSEEventType.connected;
    case 'ping': return SSEEventType.ping;
    case 'patient_created': return SSEEventType.patientCreated;
    case 'patient_updated': return SSEEventType.patientUpdated;
    case 'patient_deleted': return SSEEventType.patientDeleted;
    case 'message_created': return SSEEventType.messageCreated;
    case 'message_read': return SSEEventType.messageRead;
    case 'messages_cleared': return SSEEventType.messagesCleared;
    case 'waiting_added': return SSEEventType.waitingAdded;
    case 'waiting_updated': return SSEEventType.waitingUpdated;
    case 'waiting_removed': return SSEEventType.waitingRemoved;
    case 'dilatation_added': return SSEEventType.dilatationAdded;
    case 'payment_created': return SSEEventType.paymentCreated;
    case 'payment_updated': return SSEEventType.paymentUpdated;
    case 'payment_deleted': return SSEEventType.paymentDeleted;
    case 'user_created': return SSEEventType.userCreated;
    case 'user_updated': return SSEEventType.userUpdated;
    case 'user_deleted': return SSEEventType.userDeleted;
    case 'room_created': return SSEEventType.roomCreated;
    case 'room_updated': return SSEEventType.roomUpdated;
    case 'room_deleted': return SSEEventType.roomDeleted;
    case 'visit_created': return SSEEventType.visitCreated;
    case 'visit_updated': return SSEEventType.visitUpdated;
    case 'visit_deleted': return SSEEventType.visitDeleted;
    case 'ordonnance_created': return SSEEventType.ordonnanceCreated;
    case 'ordonnance_updated': return SSEEventType.ordonnanceUpdated;
    case 'ordonnance_deleted': return SSEEventType.ordonnanceDeleted;
    case 'medical_act_created': return SSEEventType.medicalActCreated;
    case 'medical_act_updated': return SSEEventType.medicalActUpdated;
    case 'medical_act_deleted': return SSEEventType.medicalActDeleted;
    case 'medical_act_reorder': return SSEEventType.medicalActReorder;
    case 'msg_template_created': return SSEEventType.msgTemplateCreated;
    case 'msg_template_updated': return SSEEventType.msgTemplateUpdated;
    case 'msg_template_deleted': return SSEEventType.msgTemplateDeleted;
    case 'msg_template_reorder': return SSEEventType.msgTemplateReorder;
    case 'medication_updated': return SSEEventType.medicationUpdated;
    case 'template_created': return SSEEventType.templateCreated;
    case 'template_updated': return SSEEventType.templateUpdated;
    case 'template_deleted': return SSEEventType.templateDeleted;
    case 'nurse_prefs_updated': return SSEEventType.nursePrefsUpdated;
    case 'nurse_active': return SSEEventType.nurseActive;
    case 'nurse_inactive': return SSEEventType.nurseInactive;
    default: return SSEEventType.unknown;
  }
}

/// SSE Event from server
class SSEEvent {
  final SSEEventType type;
  final String? roomId;
  final Map<String, dynamic> data;
  final int timestamp;

  SSEEvent({
    required this.type,
    this.roomId,
    required this.data,
    required this.timestamp,
  });

  factory SSEEvent.fromJson(Map<String, dynamic> json) {
    return SSEEvent(
      type: parseEventType(json['type'] as String? ?? 'unknown'),
      roomId: json['room_id'] as String?,
      data: (json['data'] as Map<String, dynamic>?) ?? {},
      timestamp: (json['timestamp'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  String toString() => 'SSEEvent(type: $type, roomId: $roomId, data: $data)';
}

/// SSE Client for real-time updates from server
/// Enterprise-grade with exponential backoff reconnection
class SSEClient {
  static SSEClient? _instance;
  static SSEClient get instance => _instance ??= SSEClient._();

  SSEClient._();

  HttpClient? _httpClient;
  String? _serverHost;
  int _serverPort = 50052;
  bool _isConnected = false;
  bool _shouldReconnect = true;
  Timer? _reconnectTimer;
  StreamSubscription? _eventSubscription;
  
  // Reconnection with exponential backoff
  int _reconnectAttempts = 0;
  static const _minReconnectDelay = Duration(seconds: 1);
  static const _maxReconnectDelay = Duration(seconds: 30);

  /// Event stream controller
  final _eventController = StreamController<SSEEvent>.broadcast();

  /// Stream of all SSE events
  Stream<SSEEvent> get events => _eventController.stream;

  /// Connection status
  bool get isConnected => _isConnected;

  /// Stream of connection status changes
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  /// Initialize and connect to SSE endpoint
  Future<void> connect({String? host, int? port}) async {
    _serverHost = host ?? GrpcClientConfig.serverHost;
    _serverPort = port ?? 50052;
    _shouldReconnect = true;
    _reconnectAttempts = 0;

    debugPrint('📡 [SSE] Connecting to $_serverHost:$_serverPort/api/events');

    await _connectInternal();
  }

  Future<void> _connectInternal() async {
    if (_httpClient != null) {
      _httpClient!.close();
    }

    _httpClient = HttpClient();
    _httpClient!.connectionTimeout = const Duration(seconds: 30);

    try {
      final request = await _httpClient!.getUrl(
        Uri.parse('http://$_serverHost:$_serverPort/api/events'),
      );
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');

      final response = await request.close();

      if (response.statusCode == 200) {
        _isConnected = true;
        _reconnectAttempts = 0; // Reset on successful connection
        _connectionController.add(true);
        debugPrint('✅ [SSE] Connected to server');

        // Listen to event stream
        _eventSubscription = response
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          _handleLine,
          onError: (error) {
            debugPrint('❌ [SSE] Stream error: $error');
            _handleDisconnect();
          },
          onDone: () {
            debugPrint('📡 [SSE] Stream closed');
            _handleDisconnect();
          },
          cancelOnError: false,
        );
      } else {
        debugPrint('❌ [SSE] Connection failed: ${response.statusCode}');
        _handleDisconnect();
      }
    } catch (e) {
      debugPrint('❌ [SSE] Connection error: $e');
      _handleDisconnect();
    }
  }

  String _dataBuffer = '';

  void _handleLine(String line) {
    if (line.startsWith('data: ')) {
      _dataBuffer = line.substring(6);
    } else if (line.isEmpty && _dataBuffer.isNotEmpty) {
      // Empty line = end of event, parse the data
      try {
        final json = jsonDecode(_dataBuffer) as Map<String, dynamic>;
        final event = SSEEvent.fromJson(json);
        
        if (event.type != SSEEventType.ping) {
          debugPrint('📨 [SSE] Event: ${event.type} roomId: ${event.roomId}');
        }
        
        _eventController.add(event);
      } catch (e) {
        debugPrint('⚠️ [SSE] Parse error: $e, data: $_dataBuffer');
      }
      _dataBuffer = '';
    }
  }

  void _handleDisconnect() {
    _isConnected = false;
    _connectionController.add(false);
    _eventSubscription?.cancel();

    if (_shouldReconnect) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    
    // Exponential backoff: 1s, 2s, 4s, 8s, 16s, 30s (max)
    final delaySeconds = (_minReconnectDelay.inSeconds * (1 << _reconnectAttempts))
        .clamp(_minReconnectDelay.inSeconds, _maxReconnectDelay.inSeconds);
    final delay = Duration(seconds: delaySeconds);
    
    debugPrint('🔄 [SSE] Reconnecting in ${delay.inSeconds}s (attempt ${_reconnectAttempts + 1})');
    
    _reconnectTimer = Timer(delay, () {
      if (_shouldReconnect) {
        _reconnectAttempts++;
        _connectInternal();
      }
    });
  }

  /// Disconnect from SSE endpoint
  void disconnect() {
    debugPrint('📡 [SSE] Disconnecting');
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _eventSubscription?.cancel();
    _httpClient?.close();
    _httpClient = null;
    _isConnected = false;
    _reconnectAttempts = 0;
    _connectionController.add(false);
  }

  /// Force reconnect now
  void reconnectNow() {
    if (!_isConnected && _shouldReconnect) {
      _reconnectTimer?.cancel();
      _reconnectAttempts = 0;
      _connectInternal();
    }
  }

  /// Dispose resources
  void dispose() {
    disconnect();
    _eventController.close();
    _connectionController.close();
    _instance = null;
  }

  /// Filter events by type
  Stream<SSEEvent> whereType(SSEEventType type) {
    return events.where((e) => e.type == type);
  }

  /// Filter events by room
  Stream<SSEEvent> whereRoom(String roomId) {
    return events.where((e) => e.roomId == roomId || e.roomId == null);
  }

  /// Get patient-related events
  Stream<SSEEvent> get patientEvents => events.where((e) =>
      e.type == SSEEventType.patientCreated ||
      e.type == SSEEventType.patientUpdated ||
      e.type == SSEEventType.patientDeleted);

  /// Get message-related events
  Stream<SSEEvent> get messageEvents => events.where((e) =>
      e.type == SSEEventType.messageCreated ||
      e.type == SSEEventType.messageRead ||
      e.type == SSEEventType.messagesCleared);

  /// Get waiting queue events
  Stream<SSEEvent> get waitingEvents => events.where((e) =>
      e.type == SSEEventType.waitingAdded ||
      e.type == SSEEventType.waitingUpdated ||
      e.type == SSEEventType.waitingRemoved ||
      e.type == SSEEventType.dilatationAdded);

  /// Get payment events
  Stream<SSEEvent> get paymentEvents => events.where((e) =>
      e.type == SSEEventType.paymentCreated ||
      e.type == SSEEventType.paymentUpdated ||
      e.type == SSEEventType.paymentDeleted);
}
