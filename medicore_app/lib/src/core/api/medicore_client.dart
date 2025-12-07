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
    if (_httpClient == null || _serverHost == null) {
      throw Exception('Client not initialized');
    }
    
    try {
      final request = await _httpClient!.postUrl(
        Uri.parse('$serverUrl/api/$method'),
      );
      
      request.headers.set('Content-Type', 'application/json');
      request.write(jsonEncode(body));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        return jsonDecode(responseBody) as Map<String, dynamic>;
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ [MediCoreClient] Request failed: $e');
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
    return response['id'] as int;
  }
  
  /// Update user
  Future<void> updateUser(GrpcUser user) async {
    await _request('UpdateUser', user.toJson());
  }
  
  /// Delete user
  Future<void> deleteUser(int id) async {
    await _request('DeleteUser', {'id': id});
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
    return response['id'] as int;
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
    return response['id'] as int? ?? response['code'] as int;
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
    return response['id'] as int;
  }
  
  /// Delete message
  Future<void> deleteMessage(int id) async {
    await _request('DeleteMessage', {'id': id});
  }
  
  // ==================== WAITING PATIENT OPERATIONS ====================
  
  /// Get waiting patients for room
  Future<WaitingPatientList> getWaitingPatientsByRoom(String roomId) async {
    final response = await _request('GetWaitingPatientsByRoom', {'room_id': roomId});
    return WaitingPatientList.fromJson(response);
  }
  
  /// Add waiting patient
  Future<int> addWaitingPatient(CreateWaitingPatientRequest request) async {
    final response = await _request('AddWaitingPatient', request.toJson());
    return response['id'] as int;
  }
  
  /// Update waiting patient
  Future<void> updateWaitingPatient(GrpcWaitingPatient patient) async {
    await _request('UpdateWaitingPatient', patient.toJson());
  }
  
  /// Remove waiting patient
  Future<void> removeWaitingPatient(int id) async {
    await _request('RemoveWaitingPatient', {'id': id});
  }
  
  // ==================== MEDICAL ACT OPERATIONS ====================
  
  /// Get all medical acts
  Future<MedicalActList> getAllMedicalActs() async {
    final response = await _request('GetAllMedicalActs', {});
    return MedicalActList.fromJson(response);
  }
  
  /// Get medical act by ID
  Future<GrpcMedicalAct?> getMedicalActById(int id) async {
    final response = await _request('GetMedicalActById', {'id': id});
    if (response.isEmpty) return null;
    return GrpcMedicalAct.fromJson(response);
  }
  
  /// Dispose client
  void dispose() {
    _httpClient?.close();
    _httpClient = null;
    _connectionController.close();
    _instance = null;
  }
}
