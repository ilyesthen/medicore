import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to manage per-patient chat history
/// Each patient has their own conversation history that persists across sessions
class PatientChatHistoryService {
  static const String _keyPrefix = 'patient_chat_';
  static const int _maxMessagesPerPatient = 50; // Keep last 50 messages max
  
  /// Save a message to patient's chat history
  static Future<void> saveMessage({
    required int patientCode,
    required String content,
    required bool isUser,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$patientCode';
    
    // Load existing history
    final history = await getHistory(patientCode);
    
    // Add new message
    history.add({
      'content': content,
      'isUser': isUser,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    // Keep only last N messages
    if (history.length > _maxMessagesPerPatient) {
      history.removeRange(0, history.length - _maxMessagesPerPatient);
    }
    
    // Save back
    await prefs.setString(key, jsonEncode(history));
  }
  
  /// Get chat history for a patient
  static Future<List<Map<String, dynamic>>> getHistory(int patientCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$patientCode';
    final jsonString = prefs.getString(key);
    
    if (jsonString == null) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error loading chat history for patient $patientCode: $e');
      return [];
    }
  }
  
  /// Clear chat history for a specific patient
  static Future<void> clearHistory(int patientCode) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_keyPrefix$patientCode';
    await prefs.remove(key);
  }
  
  /// Clear all chat histories
  static Future<void> clearAllHistories() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    for (final key in keys) {
      if (key.startsWith(_keyPrefix)) {
        await prefs.remove(key);
      }
    }
  }
  
  /// Get conversation history in format needed for AI API
  static Future<List<Map<String, String>>> getConversationHistoryForAI(int patientCode) async {
    final history = await getHistory(patientCode);
    return history.map((msg) => {
      'role': msg['isUser'] == true ? 'user' : 'assistant',
      'content': msg['content'] as String,
    }).toList();
  }
}
