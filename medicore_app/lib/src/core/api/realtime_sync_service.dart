import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sse_client.dart';
import 'grpc_client.dart';
import '../../features/messages/services/notification_service.dart';

/// Real-time sync service that connects SSE events to data refreshes
/// This is the central hub for instant updates across all clients
class RealtimeSyncService {
  static RealtimeSyncService? _instance;
  static RealtimeSyncService get instance => _instance ??= RealtimeSyncService._();

  RealtimeSyncService._();

  final SSEClient _sseClient = SSEClient.instance;
  final NotificationService _notificationService = NotificationService();

  bool _isInitialized = false;
  StreamSubscription? _eventSubscription;

  /// Callbacks for different event types - repositories register these
  final List<void Function()> _patientRefreshCallbacks = [];
  final List<void Function(String? roomId)> _messageRefreshCallbacks = [];
  final List<void Function(String? roomId)> _waitingRefreshCallbacks = [];
  final List<void Function()> _paymentRefreshCallbacks = [];
  final List<void Function()> _userRefreshCallbacks = [];
  final List<void Function()> _roomRefreshCallbacks = [];
  final List<void Function(int? patientCode)> _visitRefreshCallbacks = [];
  final List<void Function(int? patientCode)> _ordonnanceRefreshCallbacks = [];
  final List<void Function()> _medicalActRefreshCallbacks = [];
  final List<void Function()> _msgTemplateRefreshCallbacks = [];
  final List<void Function()> _medicationRefreshCallbacks = [];
  final List<void Function()> _templateRefreshCallbacks = [];  // User templates
  final List<void Function()> _nursePrefsRefreshCallbacks = [];

  /// Notification callbacks - dashboards register these
  final List<void Function(SSEEvent event)> _notificationCallbacks = [];

  /// Room IDs this client is interested in (for filtering notifications)
  final Set<String> _activeRoomIds = {};

  /// Current user role (for filtering notification sounds)
  String? _currentUserRole;

  /// Initialize the real-time sync service
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Only initialize in client mode
    if (GrpcClientConfig.isServer) {
      debugPrint('📡 [RealtimeSync] Skipping SSE in server mode (uses local DB)');
      return;
    }

    debugPrint('📡 [RealtimeSync] Initializing real-time sync service');

    await _notificationService.initialize();

    // Connect to SSE
    await _sseClient.connect();

    // Listen to events
    _eventSubscription = _sseClient.events.listen(_handleEvent);

    _isInitialized = true;
    debugPrint('✅ [RealtimeSync] Initialized');
  }

  /// Set current user role for notification filtering
  void setUserRole(String? role) {
    _currentUserRole = role;
    debugPrint('📡 [RealtimeSync] User role set to: $role');
  }

  /// Add active room ID for notification filtering
  void addActiveRoom(String roomId) {
    _activeRoomIds.add(roomId);
    debugPrint('📡 [RealtimeSync] Active room added: $roomId');
  }

  /// Remove active room ID
  void removeActiveRoom(String roomId) {
    _activeRoomIds.remove(roomId);
  }

  /// Clear active rooms
  void clearActiveRooms() {
    _activeRoomIds.clear();
  }

  /// Set active rooms
  void setActiveRooms(List<String> roomIds) {
    _activeRoomIds.clear();
    _activeRoomIds.addAll(roomIds);
    debugPrint('📡 [RealtimeSync] Active rooms set: $roomIds');
  }

  /// Register callbacks for data refresh
  void onPatientRefresh(void Function() callback) {
    _patientRefreshCallbacks.add(callback);
  }

  void onMessageRefresh(void Function(String? roomId) callback) {
    _messageRefreshCallbacks.add(callback);
  }

  void onWaitingRefresh(void Function(String? roomId) callback) {
    _waitingRefreshCallbacks.add(callback);
  }

  void onPaymentRefresh(void Function() callback) {
    _paymentRefreshCallbacks.add(callback);
  }

  void onUserRefresh(void Function() callback) {
    _userRefreshCallbacks.add(callback);
  }

  void onRoomRefresh(void Function() callback) {
    _roomRefreshCallbacks.add(callback);
  }

  void onVisitRefresh(void Function(int? patientCode) callback) {
    _visitRefreshCallbacks.add(callback);
  }

  void onOrdonnanceRefresh(void Function(int? patientCode) callback) {
    _ordonnanceRefreshCallbacks.add(callback);
  }

  void onMedicalActRefresh(void Function() callback) {
    _medicalActRefreshCallbacks.add(callback);
  }

  void onMsgTemplateRefresh(void Function() callback) {
    _msgTemplateRefreshCallbacks.add(callback);
  }

  void onMedicationRefresh(void Function() callback) {
    _medicationRefreshCallbacks.add(callback);
  }

  void onTemplateRefresh(void Function() callback) {
    _templateRefreshCallbacks.add(callback);
  }

  void onNursePrefsRefresh(void Function() callback) {
    _nursePrefsRefreshCallbacks.add(callback);
  }

  /// Register callback for notification events (dashboards use this for sounds)
  void onNotification(void Function(SSEEvent event) callback) {
    _notificationCallbacks.add(callback);
  }

  /// Remove callbacks
  void removePatientRefresh(void Function() callback) {
    _patientRefreshCallbacks.remove(callback);
  }

  void removeMessageRefresh(void Function(String? roomId) callback) {
    _messageRefreshCallbacks.remove(callback);
  }

  void removeWaitingRefresh(void Function(String? roomId) callback) {
    _waitingRefreshCallbacks.remove(callback);
  }

  void removePaymentRefresh(void Function() callback) {
    _paymentRefreshCallbacks.remove(callback);
  }

  void removeNotification(void Function(SSEEvent event) callback) {
    _notificationCallbacks.remove(callback);
  }

  void removeVisitRefresh(void Function(int? patientCode) callback) {
    _visitRefreshCallbacks.remove(callback);
  }

  void removeOrdonnanceRefresh(void Function(int? patientCode) callback) {
    _ordonnanceRefreshCallbacks.remove(callback);
  }

  void removeMedicalActRefresh(void Function() callback) {
    _medicalActRefreshCallbacks.remove(callback);
  }

  void removeMsgTemplateRefresh(void Function() callback) {
    _msgTemplateRefreshCallbacks.remove(callback);
  }

  void removeMedicationRefresh(void Function() callback) {
    _medicationRefreshCallbacks.remove(callback);
  }

  void removeTemplateRefresh(void Function() callback) {
    _templateRefreshCallbacks.remove(callback);
  }

  void removeNursePrefsRefresh(void Function() callback) {
    _nursePrefsRefreshCallbacks.remove(callback);
  }

  /// Handle incoming SSE event
  void _handleEvent(SSEEvent event) {
    debugPrint('🔔 [RealtimeSync] Event: ${event.type} roomId: ${event.roomId}');

    switch (event.type) {
      case SSEEventType.connected:
      case SSEEventType.ping:
        // No action needed
        break;

      // Patient events
      case SSEEventType.patientCreated:
      case SSEEventType.patientUpdated:
      case SSEEventType.patientDeleted:
        _triggerPatientRefresh();
        break;

      // Message events - trigger notification sound for nurses/doctors
      case SSEEventType.messageCreated:
        _triggerMessageRefresh(event.roomId);
        _handleMessageNotification(event);
        break;

      case SSEEventType.messageRead:
      case SSEEventType.messagesCleared:
        _triggerMessageRefresh(event.roomId);
        break;

      // Waiting queue events - trigger notification sound for nurses
      case SSEEventType.waitingAdded:
      case SSEEventType.dilatationAdded:
        _triggerWaitingRefresh(event.roomId);
        _handleWaitingNotification(event);
        break;

      case SSEEventType.waitingUpdated:
      case SSEEventType.waitingRemoved:
        _triggerWaitingRefresh(event.roomId);
        break;

      // Payment events
      case SSEEventType.paymentCreated:
      case SSEEventType.paymentUpdated:
      case SSEEventType.paymentDeleted:
        _triggerPaymentRefresh();
        break;

      // User events
      case SSEEventType.userCreated:
      case SSEEventType.userUpdated:
      case SSEEventType.userDeleted:
        _triggerUserRefresh();
        break;

      // Room events
      case SSEEventType.roomCreated:
      case SSEEventType.roomUpdated:
      case SSEEventType.roomDeleted:
        _triggerRoomRefresh();
        break;

      // Visit events
      case SSEEventType.visitCreated:
      case SSEEventType.visitUpdated:
      case SSEEventType.visitDeleted:
        _triggerVisitRefresh(event.data['patient_code'] as int?);
        break;

      // Ordonnance events
      case SSEEventType.ordonnanceCreated:
      case SSEEventType.ordonnanceUpdated:
      case SSEEventType.ordonnanceDeleted:
        _triggerOrdonnanceRefresh(event.data['patient_code'] as int?);
        break;

      // Medical act events
      case SSEEventType.medicalActCreated:
      case SSEEventType.medicalActUpdated:
      case SSEEventType.medicalActDeleted:
      case SSEEventType.medicalActReorder:
        _triggerMedicalActRefresh();
        break;

      // Message template events
      case SSEEventType.msgTemplateCreated:
      case SSEEventType.msgTemplateUpdated:
      case SSEEventType.msgTemplateDeleted:
      case SSEEventType.msgTemplateReorder:
        _triggerMsgTemplateRefresh();
        break;

      // Medication events
      case SSEEventType.medicationUpdated:
        _triggerMedicationRefresh();
        break;

      // User template events
      case SSEEventType.templateCreated:
      case SSEEventType.templateUpdated:
      case SSEEventType.templateDeleted:
        _triggerTemplateRefresh();
        break;

      // Nurse preference events
      case SSEEventType.nursePrefsUpdated:
      case SSEEventType.nurseActive:
      case SSEEventType.nurseInactive:
        _triggerNursePrefsRefresh();
        break;

      case SSEEventType.unknown:
        debugPrint('⚠️ [RealtimeSync] Unknown event type');
        break;
    }

    // Notify all registered notification listeners
    for (final callback in _notificationCallbacks) {
      callback(event);
    }
  }

  void _triggerPatientRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering patient refresh');
    for (final callback in _patientRefreshCallbacks) {
      callback();
    }
  }

  void _triggerMessageRefresh(String? roomId) {
    debugPrint('🔄 [RealtimeSync] Triggering message refresh for room: $roomId');
    for (final callback in _messageRefreshCallbacks) {
      callback(roomId);
    }
  }

  void _triggerWaitingRefresh(String? roomId) {
    debugPrint('🔄 [RealtimeSync] Triggering waiting queue refresh for room: $roomId');
    for (final callback in _waitingRefreshCallbacks) {
      callback(roomId);
    }
  }

  void _triggerPaymentRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering payment refresh');
    for (final callback in _paymentRefreshCallbacks) {
      callback();
    }
  }

  void _triggerUserRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering user refresh');
    for (final callback in _userRefreshCallbacks) {
      callback();
    }
  }

  void _triggerRoomRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering room refresh');
    for (final callback in _roomRefreshCallbacks) {
      callback();
    }
  }

  void _triggerVisitRefresh(int? patientCode) {
    debugPrint('🔄 [RealtimeSync] Triggering visit refresh for patient: $patientCode');
    for (final callback in _visitRefreshCallbacks) {
      callback(patientCode);
    }
  }

  void _triggerOrdonnanceRefresh(int? patientCode) {
    debugPrint('🔄 [RealtimeSync] Triggering ordonnance refresh for patient: $patientCode');
    for (final callback in _ordonnanceRefreshCallbacks) {
      callback(patientCode);
    }
  }

  void _triggerMedicalActRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering medical act refresh');
    for (final callback in _medicalActRefreshCallbacks) {
      callback();
    }
  }

  void _triggerMsgTemplateRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering message template refresh');
    for (final callback in _msgTemplateRefreshCallbacks) {
      callback();
    }
  }

  void _triggerMedicationRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering medication refresh');
    for (final callback in _medicationRefreshCallbacks) {
      callback();
    }
  }

  void _triggerTemplateRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering user template refresh');
    for (final callback in _templateRefreshCallbacks) {
      callback();
    }
  }

  void _triggerNursePrefsRefresh() {
    debugPrint('🔄 [RealtimeSync] Triggering nurse prefs refresh');
    for (final callback in _nursePrefsRefreshCallbacks) {
      callback();
    }
  }

  /// Handle message notification - play sound for relevant users
  void _handleMessageNotification(SSEEvent event) {
    final roomId = event.roomId;
    final direction = event.data['direction'] as String?;

    // Check if this message is relevant to current user
    bool shouldNotify = false;

    if (_currentUserRole == 'nurse' && direction == 'to_nurse') {
      // Nurse receives message from doctor
      if (roomId == null || _activeRoomIds.contains(roomId)) {
        shouldNotify = true;
      }
    } else if (_currentUserRole == 'doctor' && direction == 'to_doctor') {
      // Doctor receives message from nurse
      if (roomId == null || _activeRoomIds.contains(roomId)) {
        shouldNotify = true;
      }
    }

    if (shouldNotify) {
      debugPrint('🔊 [RealtimeSync] Playing message notification sound');
      _notificationService.playNotificationSound();
    }
  }

  /// Handle waiting queue notification - play sound for nurses
  void _handleWaitingNotification(SSEEvent event) {
    final roomId = event.roomId;

    // Only nurses care about waiting queue updates
    if (_currentUserRole != 'nurse') return;

    // Check if this is for one of our active rooms
    if (roomId == null || _activeRoomIds.contains(roomId)) {
      debugPrint('🔊 [RealtimeSync] Playing waiting patient notification sound');
      _notificationService.playNotificationSound();
    }
  }

  /// Check if connected
  bool get isConnected => _sseClient.isConnected;

  /// Connection stream
  Stream<bool> get connectionStream => _sseClient.connectionStream;

  /// Dispose resources
  void dispose() {
    _eventSubscription?.cancel();
    _patientRefreshCallbacks.clear();
    _messageRefreshCallbacks.clear();
    _waitingRefreshCallbacks.clear();
    _paymentRefreshCallbacks.clear();
    _userRefreshCallbacks.clear();
    _roomRefreshCallbacks.clear();
    _visitRefreshCallbacks.clear();
    _ordonnanceRefreshCallbacks.clear();
    _medicalActRefreshCallbacks.clear();
    _msgTemplateRefreshCallbacks.clear();
    _medicationRefreshCallbacks.clear();
    _templateRefreshCallbacks.clear();
    _nursePrefsRefreshCallbacks.clear();
    _notificationCallbacks.clear();
    _sseClient.disconnect();
    _isInitialized = false;
    _instance = null;
  }
}

/// Riverpod provider for RealtimeSyncService
final realtimeSyncServiceProvider = Provider<RealtimeSyncService>((ref) {
  return RealtimeSyncService.instance;
});
