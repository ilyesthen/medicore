import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../generated/medicore.pb.dart';
import 'grpc_client.dart';

/// MediCore gRPC/HTTP Client
/// Connects to admin server for all data operations in CLIENT mode
/// Uses HTTP/JSON as transport (compatible with Go server)
class MediCoreClient {
  static MediCoreClient? _instance;
  static MediCoreClient get instance => _instance ??= MediCoreClient._();
  
  MediCoreClient._();
  
  HttpClient? _httpClient;
  String? _serverHost;
  int _serverPort = 50052; // REST API port (gRPC is 50051)
  bool _isConnected = false;
  
  /// Connection status stream
  final _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;
  
  /// Check if connected
  bool get isConnected => _isConnected;
  
  /// Get server URL
  String get serverUrl => 'http://$_serverHost:$_serverPort';
  
  /// Initialize client with server host
  Future<void> initialize({String? host, int? port}) async {
    _serverHost = host ?? GrpcClientConfig.serverHost;
    _serverPort = port ?? 50052; // REST API port (gRPC is 50051)
    _httpClient = HttpClient();
    _httpClient!.connectionTimeout = const Duration(seconds: 10);
    
    debugPrint('🔌 [MediCoreClient] Initializing connection to $_serverHost:$_serverPort');
    
    // Test connection
    _isConnected = await testConnection();
    _connectionController.add(_isConnected);
    
    if (_isConnected) {
      debugPrint('✅ [MediCoreClient] Connected to server');
    } else {
      debugPrint('❌ [MediCoreClient] Failed to connect to server');
    }
  }
  
  /// Test connection to server
  Future<bool> testConnection() async {
    try {
      final socket = await Socket.connect(
        _serverHost ?? 'localhost',
        _serverPort,
        timeout: const Duration(seconds: 5),
      );
      socket.destroy();
      return true;
    } catch (e) {
      debugPrint('❌ [MediCoreClient] Connection test failed: $e');
      return false;
    }
  }
  
  /// Make HTTP request to server (gRPC-Web style)
  Future<Map<String, dynamic>> _request(String method, Map<String, dynamic> body) async {
    // Auto-initialize if not already
    if (_httpClient == null || _serverHost == null) {
      debugPrint('⚠️ [MediCoreClient] Client not initialized, initializing now...');
      await initialize(host: GrpcClientConfig.serverHost);
    }
    
    if (_httpClient == null || _serverHost == null) {
      throw Exception('Client not initialized - check server configuration');
    }
    
    try {
      debugPrint('📡 [MediCoreClient] $method -> $serverUrl/api/$method');
      final request = await _httpClient!.postUrl(
        Uri.parse('$serverUrl/api/$method'),
      );
      
      // Encode JSON as UTF-8 bytes to properly handle special characters (newlines, accents, etc.)
      final jsonString = jsonEncode(body);
      final jsonBytes = utf8.encode(jsonString);
      
      request.headers.set('Content-Type', 'application/json; charset=utf-8');
      request.headers.set('Content-Length', jsonBytes.length.toString());
      request.add(jsonBytes);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        _isConnected = true;
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        debugPrint('❌ [MediCoreClient] Server error ${response.statusCode}: $responseBody');
        throw Exception('Server error ${response.statusCode}: $responseBody');
      }
    } catch (e) {
      debugPrint('❌ [MediCoreClient] Request $method failed: $e');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }
  
  // ==================== USER OPERATIONS ====================
  
  /// Get all users
  Future<UserList> getAllUsers() async {
    final response = await _request('GetAllUsers', {});
    return UserList.fromJson(response);
  }
  
  /// Get user by ID
  Future<GrpcUser?> getUserById(int id) async {
    final response = await _request('GetUserById', {'id': id});
    if (response.isEmpty) return null;
    return GrpcUser.fromJson(response);
  }
  
  /// Get user by username (for login)
  Future<GrpcUser?> getUserByUsername(String username) async {
    final response = await _request('GetUserByUsername', {'username': username});
    if (response.isEmpty) return null;
    return GrpcUser.fromJson(response);
  }
  
  /// Create user
  Future<int> createUser(CreateUserRequest request) async {
    final response = await _request('CreateUser', request.toJson());
    return (response['id'] as num).toInt();
  }
  
  /// Update user
  Future<void> updateUser(GrpcUser user) async {
    await _request('UpdateUser', user.toJson());
  }
  
  /// Delete user
  Future<void> deleteUser(int id) async {
    await _request('DeleteUser', {'id': id});
  }
  
  /// Get template users
  Future<UserList> getTemplateUsers() async {
    final response = await _request('GetTemplateUsers', {});
    return UserList.fromJson(response);
  }
  
  /// Get permanent users
  Future<UserList> getPermanentUsers() async {
    final response = await _request('GetPermanentUsers', {});
    return UserList.fromJson(response);
  }
  
  // ==================== USER TEMPLATE OPERATIONS ====================
  
  /// Get all user templates
  Future<Map<String, dynamic>> getAllUserTemplates() async {
    return await _request('GetAllUserTemplates', {});
  }
  
  /// Create user template
  Future<String> createUserTemplate({
    required String id,
    required String role,
    required String passwordHash,
    required double percentage,
  }) async {
    final response = await _request('CreateUserTemplate', {
      'id': id,
      'role': role,
      'password_hash': passwordHash,
      'percentage': percentage,
    });
    return response['id'] as String;
  }
  
  /// Update user template
  Future<void> updateUserTemplate({
    required String id,
    required String role,
    required String passwordHash,
    required double percentage,
  }) async {
    await _request('UpdateUserTemplate', {
      'id': id,
      'role': role,
      'password_hash': passwordHash,
      'percentage': percentage,
    });
  }
  
  /// Delete user template
  Future<void> deleteUserTemplate(String id) async {
    await _request('DeleteUserTemplate', {'id': id});
  }

  /// Get user template by ID
  Future<Map<String, dynamic>> getUserTemplateById(String id) async {
    return await _request('GetUserTemplateById', {'id': id});
  }

  /// Create user from template
  Future<Map<String, dynamic>> createUserFromTemplate({
    required String templateId,
    required String userName,
    required String userId,
  }) async {
    return await _request('CreateUserFromTemplate', {
      'template_id': templateId,
      'user_name': userName,
      'user_id': userId,
    });
  }
  
  // ==================== ROOM OPERATIONS ====================
  
  /// Get all rooms
  Future<RoomList> getAllRooms() async {
    final response = await _request('GetAllRooms', {});
    return RoomList.fromJson(response);
  }
  
  /// Get room by ID
  Future<GrpcRoom?> getRoomById(int id) async {
    final response = await _request('GetRoomById', {'id': id});
    if (response.isEmpty) return null;
    return GrpcRoom.fromJson(response);
  }
  
  /// Create room
  Future<int> createRoom(CreateRoomRequest request) async {
    final response = await _request('CreateRoom', request.toJson());
    return (response['id'] as num).toInt();
  }
  
  /// Update room
  Future<void> updateRoom(GrpcRoom room) async {
    await _request('UpdateRoom', room.toJson());
  }
  
  /// Delete room
  Future<void> deleteRoom(int id) async {
    await _request('DeleteRoom', {'id': id});
  }
  
  // ==================== PATIENT OPERATIONS ====================
  
  /// Get all patients
  Future<PatientList> getAllPatients() async {
    final response = await _request('GetAllPatients', {});
    return PatientList.fromJson(response);
  }
  
  /// Get patient by code
  Future<GrpcPatient?> getPatientByCode(int code) async {
    final response = await _request('GetPatientByCode', {'patient_code': code});
    if (response.isEmpty) return null;
    return GrpcPatient.fromJson(response);
  }
  
  /// Search patients
  Future<PatientList> searchPatients(String query) async {
    final response = await _request('SearchPatients', {'query': query});
    return PatientList.fromJson(response);
  }
  
  /// Create patient
  Future<int> createPatient(CreatePatientRequest request) async {
    final response = await _request('CreatePatient', request.toJson());
    return (response['id'] as num?)?.toInt() ?? (response['code'] as num).toInt();
  }
  
  /// Update patient
  Future<void> updatePatient(GrpcPatient patient) async {
    await _request('UpdatePatient', patient.toJson());
  }
  
  /// Delete patient
  Future<void> deletePatient(int code) async {
    await _request('DeletePatient', {'patient_code': code});
  }
  
  // ==================== MESSAGE OPERATIONS ====================
  
  /// Get messages by room
  Future<MessageList> getMessagesByRoom(String roomId) async {
    final response = await _request('GetMessagesByRoom', {'room_id': roomId});
    return MessageList.fromJson(response);
  }
  
  /// Create message
  Future<int> createMessage(CreateMessageRequest request) async {
    final response = await _request('CreateMessage', request.toJson());
    return (response['id'] as num).toInt();
  }
  
  /// Delete message
  Future<void> deleteMessage(int id) async {
    await _request('DeleteMessage', {'id': id});
  }
  
  /// Mark message as read
  Future<void> markMessageAsRead(int id) async {
    await _request('MarkMessageAsRead', {'id': id});
  }
  
  /// Mark all messages as read for a room and direction
  Future<void> markAllMessagesAsRead(String roomId, String direction) async {
    await _request('MarkAllMessagesAsRead', {'room_id': roomId, 'direction': direction});
  }
  
  // ==================== MESSAGE TEMPLATE OPERATIONS ====================
  
  /// Get all message templates
  Future<Map<String, dynamic>> getAllMessageTemplates() async {
    return await _request('GetAllMessageTemplates', {});
  }
  
  /// Create message template
  Future<int> createMessageTemplate({required String content, String? createdBy}) async {
    final response = await _request('CreateMessageTemplate', {
      'content': content,
      if (createdBy != null) 'created_by': createdBy,
    });
    return (response['id'] as num).toInt();
  }
  
  /// Update message template
  Future<void> updateMessageTemplate({required int id, required String content}) async {
    await _request('UpdateMessageTemplate', {'id': id, 'content': content});
  }
  
  /// Delete message template
  Future<void> deleteMessageTemplate(int id) async {
    await _request('DeleteMessageTemplate', {'id': id});
  }

  /// Get message template by ID
  Future<Map<String, dynamic>> getMessageTemplateById(int id) async {
    return await _request('GetMessageTemplateById', {'id': id});
  }

  /// Reorder message templates
  Future<void> reorderMessageTemplates(List<int> orderedIds) async {
    await _request('ReorderMessageTemplates', {'ordered_ids': orderedIds});
  }

  // ==================== VISIT OPERATIONS ====================
  
  /// Get visits for patient
  Future<Map<String, dynamic>> getVisitsForPatient(int patientCode) async {
    return await _request('GetVisitsForPatient', {'patient_code': patientCode});
  }
  
  /// Get visit by ID
  Future<Map<String, dynamic>> getVisitById(int id) async {
    return await _request('GetVisitById', {'id': id});
  }
  
  /// Create visit
  Future<int> createVisit(Map<String, dynamic> visit) async {
    final response = await _request('CreateVisit', visit);
    return (response['id'] as num).toInt();
  }
  
  /// Update visit
  Future<void> updateVisit(Map<String, dynamic> visit) async {
    await _request('UpdateVisit', visit);
  }
  
  /// Delete visit
  Future<void> deleteVisit(int id) async {
    await _request('DeleteVisit', {'id': id});
  }
  
  // ==================== ORDONNANCE OPERATIONS ====================
  
  /// Get ordonnances for patient
  Future<Map<String, dynamic>> getOrdonnancesForPatient(int patientCode) async {
    return await _request('GetOrdonnancesForPatient', {'patient_code': patientCode});
  }
  
  /// Create ordonnance
  Future<int> createOrdonnance(Map<String, dynamic> ordonnance) async {
    final response = await _request('CreateOrdonnance', ordonnance);
    return (response['id'] as num).toInt();
  }
  
  /// Update ordonnance
  Future<void> updateOrdonnance(Map<String, dynamic> ordonnance) async {
    await _request('UpdateOrdonnance', ordonnance);
  }
  
  /// Delete ordonnance
  Future<void> deleteOrdonnance(int id) async {
    await _request('DeleteOrdonnance', {'id': id});
  }
  
  // ==================== PAYMENT OPERATIONS ====================
  
  /// Get payments for patient
  Future<Map<String, dynamic>> getPaymentsForPatient(int patientCode) async {
    return await _request('GetPaymentsForPatient', {'patient_code': patientCode});
  }
  
  /// Get payments for visit
  Future<Map<String, dynamic>> getPaymentsForVisit(int visitId) async {
    return await _request('GetPaymentsForVisit', {'visit_id': visitId});
  }
  
  /// Get payments by user and date (for comptabilité)
  Future<Map<String, dynamic>> getPaymentsByUserAndDate(String userName, String dateStr) async {
    return await _request('GetPaymentsByUserAndDate', {'user_name': userName, 'date': dateStr});
  }
  
  /// Create payment
  Future<int> createPayment(Map<String, dynamic> payment) async {
    final response = await _request('CreatePayment', payment);
    return (response['id'] as num).toInt();
  }
  
  /// Update payment
  Future<void> updatePayment(Map<String, dynamic> payment) async {
    await _request('UpdatePayment', payment);
  }
  
  /// Delete payment
  Future<void> deletePayment(int id) async {
    await _request('DeletePayment', {'id': id});
  }
  
  /// Get payment by ID
  Future<Map<String, dynamic>> getPaymentById(int id) async {
    return await _request('GetPaymentById', {'id': id});
  }
  
  /// Get all payments by user
  Future<Map<String, dynamic>> getAllPaymentsByUser(String userName) async {
    return await _request('GetAllPaymentsByUser', {'user_name': userName});
  }
  
  /// Delete payments by patient and date
  Future<int> deletePaymentsByPatientAndDate(int patientCode, String date) async {
    final response = await _request('DeletePaymentsByPatientAndDate', {'patient_code': patientCode, 'date': date});
    return (response['deleted'] as num).toInt();
  }
  
  /// Count payments by patient and date
  Future<int> countPaymentsByPatientAndDate(int patientCode, String date) async {
    final response = await _request('CountPaymentsByPatientAndDate', {'patient_code': patientCode, 'date': date});
    return (response['count'] as num).toInt();
  }
  
  /// Get max payment ID
  Future<int> getMaxPaymentId() async {
    final response = await _request('GetMaxPaymentId', {});
    return (response['max_id'] as num).toInt();
  }
  
  /// Get all payments for a patient (history)
  Future<Map<String, dynamic>> getPaymentsByPatient(int patientCode) async {
    return await _request('GetPaymentsByPatient', {'patient_code': patientCode});
  }
  
  // ==================== MEDICATION OPERATIONS ====================
  
  /// Get all medications
  Future<Map<String, dynamic>> getAllMedications() async {
    return await _request('GetAllMedications', {});
  }
  
  /// Search medications
  Future<Map<String, dynamic>> searchMedications(String query) async {
    return await _request('SearchMedications', {'query': query});
  }
  
  /// Get medication by ID
  Future<Map<String, dynamic>> getMedicationById(int id) async {
    return await _request('GetMedicationById', {'id': id});
  }
  
  /// Get medication count
  Future<int> getMedicationCount() async {
    final response = await _request('GetMedicationCount', {});
    return (response['count'] as num).toInt();
  }
  
  /// Increment medication usage
  Future<void> incrementMedicationUsage(int id) async {
    await _request('IncrementMedicationUsage', {'id': id});
  }
  
  /// Set medication usage count
  Future<void> setMedicationUsageCount(int id, int count) async {
    await _request('SetMedicationUsageCount', {'id': id, 'count': count});
  }
  
  /// Add new medication
  Future<int> addMedication({required String code, required String prescription}) async {
    final response = await _request('AddMedication', {
      'code': code,
      'prescription': prescription,
    });
    return (response['id'] as num).toInt();
  }
  
  /// Update medication
  Future<bool> updateMedication({required int id, required String code, required String prescription}) async {
    final response = await _request('UpdateMedication', {
      'id': id,
      'code': code,
      'prescription': prescription,
    });
    return response['success'] == true;
  }
  
  /// Delete medication
  Future<bool> deleteMedication(int id) async {
    final response = await _request('DeleteMedication', {'id': id});
    return response['success'] == true;
  }
  
  // ==================== ADDITIONAL VISIT OPERATIONS ====================
  
  /// Get total visit count
  Future<int> getTotalVisitCount() async {
    final response = await _request('GetTotalVisitCount', {});
    return (response['count'] as num).toInt();
  }
  
  /// Clear all visits
  Future<int> clearAllVisits() async {
    final response = await _request('ClearAllVisits', {});
    return (response['deleted'] as num).toInt();
  }
  
  /// Insert visits (batch)
  Future<int> insertVisits(List<Map<String, dynamic>> visits) async {
    final response = await _request('InsertVisits', {'visits': visits});
    return (response['inserted'] as num).toInt();
  }
  
  // ==================== ADDITIONAL MESSAGE OPERATIONS ====================
  
  /// Get message by ID
  Future<Map<String, dynamic>> getMessageById(int id) async {
    return await _request('GetMessageById', {'id': id});
  }
  
  // ==================== ADDITIONAL PATIENT OPERATIONS ====================
  
  /// Import patient
  Future<int> importPatient(Map<String, dynamic> patient) async {
    final response = await _request('ImportPatient', patient);
    return (response['code'] as num).toInt();
  }
  
  // ==================== NURSE PREFERENCES OPERATIONS ====================
  
  /// Get nurse room preferences
  Future<List<String?>> getNurseRoomPreferences(String nurseId) async {
    final response = await _request('GetNurseRoomPreferences', {'nurse_id': nurseId});
    final rooms = (response['rooms'] as List<dynamic>?) ?? [null, null, null];
    return rooms.map((r) => r as String?).toList();
  }
  
  /// Save nurse room preferences
  Future<void> saveNurseRoomPreferences(String nurseId, List<String?> rooms) async {
    await _request('SaveNurseRoomPreferences', {'nurse_id': nurseId, 'rooms': rooms});
  }
  
  /// Clear nurse room preferences
  Future<void> clearNurseRoomPreferences(String nurseId) async {
    await _request('ClearNurseRoomPreferences', {'nurse_id': nurseId});
  }
  
  /// Get active nurses
  Future<List<String>> getActiveNurses() async {
    final response = await _request('GetActiveNurses', {});
    final nurses = (response['nurses'] as List<dynamic>?) ?? [];
    return nurses.map((n) => n as String).toList();
  }
  
  /// Mark nurse active
  Future<void> markNurseActive(String nurseId) async {
    await _request('MarkNurseActive', {'nurse_id': nurseId});
  }
  
  /// Mark nurse inactive
  Future<void> markNurseInactive(String nurseId) async {
    await _request('MarkNurseInactive', {'nurse_id': nurseId});
  }
  
  // ==================== TEMPLATES CR OPERATIONS ====================
  
  /// Get all templates CR (Compte Rendu templates)
  Future<List<Map<String, dynamic>>> getAllTemplatesCR() async {
    final response = await _request('GetAllTemplatesCR', {});
    final templates = (response['templates'] as List<dynamic>?) ?? [];
    return templates.map((t) => t as Map<String, dynamic>).toList();
  }
  
  /// Increment template CR usage count
  Future<void> incrementTemplateCRUsage(int id) async {
    await _request('IncrementTemplateCRUsage', {'id': id});
  }
  
  // ==================== ADDITIONAL PAYMENT OPERATIONS ====================
  
  /// Import payment
  Future<void> importPayment(Map<String, dynamic> payment) async {
    await _request('ImportPayment', payment);
  }
  
  /// Batch import payments
  Future<void> batchImportPayments(List<Map<String, dynamic>> payments) async {
    await _request('BatchImportPayments', {'payments': payments});
  }
  
  // ==================== WAITING QUEUE OPERATIONS ====================
  
  /// Add waiting patient (accepts protobuf CreateWaitingPatientRequest)
  Future<int> addWaitingPatient(CreateWaitingPatientRequest request) async {
    final response = await _request('AddWaitingPatient', {
      'patient_code': request.patientCode,
      'patient_first_name': request.patientFirstName,
      'patient_last_name': request.patientLastName,
      'room_id': request.roomId,
      'room_name': request.roomName,
      'motif': request.motif,
      'sent_by_user_id': request.sentByUserId,
      'sent_by_user_name': request.sentByUserName,
      'patient_age': request.patientAge,
      'is_urgent': request.isUrgent,
      'is_dilatation': request.isDilatation,
      'dilatation_type': request.dilatationType,
    });
    return (response['id'] as num).toInt();
  }
  
  /// Get waiting patients by room - returns object with patients list
  Future<WaitingPatientList> getWaitingPatientsByRoom(String roomId) async {
    final response = await _request('GetWaitingPatientsByRoom', {'room_id': roomId});
    return WaitingPatientList.fromJson(response);
  }
  
  /// Get waiting patient by ID
  Future<Map<String, dynamic>> getWaitingPatientById(int id) async {
    return await _request('GetWaitingPatientById', {'id': id});
  }
  
  /// Update waiting patient (accepts protobuf GrpcWaitingPatient)
  Future<void> updateWaitingPatient(GrpcWaitingPatient patient) async {
    await _request('UpdateWaitingPatient', {
      'id': patient.id,
      'is_checked': patient.isChecked,
      'is_active': patient.isActive,
    });
  }
  
  /// Remove waiting patient
  Future<void> removeWaitingPatient(int id) async {
    await _request('RemoveWaitingPatient', {'id': id});
  }
  
  /// Remove waiting patient by code
  Future<void> removeWaitingPatientByCode(int patientCode) async {
    await _request('RemoveWaitingPatientByCode', {'patient_code': patientCode});
  }
  
  /// Mark dilatations as notified (accepts room IDs as strings)
  Future<void> markDilatationsAsNotified(List<String> roomIds) async {
    await _request('MarkDilatationsAsNotified', {'room_ids': roomIds});
  }
  
  // ==================== MEDICAL ACT OPERATIONS ====================
  
  /// Get all medical acts
  Future<Map<String, dynamic>> getAllMedicalActs() async {
    return await _request('GetAllMedicalActs', {});
  }
  
  /// Get medical act by ID
  Future<Map<String, dynamic>> getMedicalActById(int id) async {
    return await _request('GetMedicalActById', {'id': id});
  }
  
  /// Create medical act
  Future<int> createMedicalAct({required String name, required int feeAmount}) async {
    final response = await _request('CreateMedicalAct', {'name': name, 'fee_amount': feeAmount});
    return (response['id'] as num).toInt();
  }
  
  /// Update medical act
  Future<void> updateMedicalAct({required int id, required String name, required int feeAmount}) async {
    await _request('UpdateMedicalAct', {'id': id, 'name': name, 'fee_amount': feeAmount});
  }
  
  /// Delete medical act
  Future<void> deleteMedicalAct(int id) async {
    await _request('DeleteMedicalAct', {'id': id});
  }
  
  /// Reorder medical acts
  Future<void> reorderMedicalActs(List<int> ids) async {
    await _request('ReorderMedicalActs', {'ids': ids});
  }
  
  // ==================== APPOINTMENT OPERATIONS ====================
  
  /// Get appointments for a specific date
  Future<Map<String, dynamic>> getAppointmentsForDate(DateTime date) async {
    return await _request('GetAppointmentsForDate', {'date': date.toIso8601String()});
  }
  
  /// Get all appointments
  Future<Map<String, dynamic>> getAllAppointments() async {
    return await _request('GetAllAppointments', {});
  }
  
  /// Create appointment
  Future<int> createAppointment(Map<String, dynamic> data) async {
    final response = await _request('CreateAppointment', data);
    return (response['id'] as num).toInt();
  }
  
  /// Update appointment date
  Future<bool> updateAppointmentDate(int id, DateTime newDate) async {
    final response = await _request('UpdateAppointmentDate', {
      'id': id,
      'new_date': newDate.toIso8601String(),
    });
    return response['success'] == true;
  }
  
  /// Mark appointment as added to patients
  Future<bool> markAppointmentAsAdded(int id) async {
    final response = await _request('MarkAppointmentAsAdded', {'id': id});
    return response['success'] == true;
  }
  
  /// Delete appointment
  Future<bool> deleteAppointment(int id) async {
    final response = await _request('DeleteAppointment', {'id': id});
    return response['success'] == true;
  }
  
  /// Cleanup past appointments that were not added
  Future<int> cleanupPastAppointments() async {
    final response = await _request('CleanupPastAppointments', {});
    return (response['deleted'] as num).toInt();
  }
  
  // ==================== SURGERY PLAN OPERATIONS ====================
  
  /// Get surgery plans for a specific date
  Future<Map<String, dynamic>> getSurgeryPlansForDate(DateTime date) async {
    return await _request('GetSurgeryPlansForDate', {'date': date.toIso8601String()});
  }
  
  /// Get all surgery plans
  Future<Map<String, dynamic>> getAllSurgeryPlans() async {
    return await _request('GetAllSurgeryPlans', {});
  }
  
  /// Create surgery plan
  Future<int> createSurgeryPlan(Map<String, dynamic> data) async {
    final response = await _request('CreateSurgeryPlan', data);
    return (response['id'] as num).toInt();
  }
  
  /// Update surgery plan
  Future<bool> updateSurgeryPlan(int id, Map<String, dynamic> data) async {
    final response = await _request('UpdateSurgeryPlan', {'id': id, ...data});
    return response['success'] == true;
  }
  
  /// Reschedule surgery
  Future<bool> rescheduleSurgery(int id, Map<String, dynamic> data) async {
    final response = await _request('RescheduleSurgery', {'id': id, ...data});
    return response['success'] == true;
  }
  
  /// Delete surgery plan
  Future<bool> deleteSurgeryPlan(int id) async {
    final response = await _request('DeleteSurgeryPlan', {'id': id});
    return response['success'] == true;
  }
  
  /// Dispose client
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    _connectionController.close();
    _instance = null;
  }
}
