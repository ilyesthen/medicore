import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../services/puter_ai_service.dart';
import '../services/patient_context_service.dart';
import '../services/patient_chat_history_service.dart';

/// Message model for chat
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;

  ChatMessage({
    required this.content,
    required this.isUser,
    DateTime? timestamp,
    this.isLoading = false,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Compact AI Chat Widget for Patient Pages
/// Auto-loads patient context and maintains per-patient chat history
class PatientAIChatWidget extends StatefulWidget {
  final Patient patient;
  
  const PatientAIChatWidget({super.key, required this.patient});

  @override
  State<PatientAIChatWidget> createState() => _PatientAIChatWidgetState();
}

class _PatientAIChatWidgetState extends State<PatientAIChatWidget> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  
  final PatientContextService _patientContextService = PatientContextService();
  bool _isLoading = false;
  bool _contextLoaded = false;
  int _visitCount = 0;
  int _documentCount = 0;
  
  @override
  void initState() {
    super.initState();
    _loadPatientContext();
    _loadChatHistory();
    _textController.addListener(() => setState(() {}));
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  /// Load patient context and set it in AI service
  Future<void> _loadPatientContext() async {
    setState(() => _isLoading = true);
    
    try {
      final result = await _patientContextService.buildPatientContext(widget.patient.code);
      
      if (result.success && result.context != null) {
        // Set patient context in AI service
        PuterAIService.setPatientContext(widget.patient.code, result.context!);
        
        setState(() {
          _contextLoaded = true;
          _visitCount = result.visitCount;
          _documentCount = result.documentCount;
        });
        
        print('✅ Patient context loaded: ${result.visitCount} visits, ${result.documentCount} documents');
      } else {
        _showError('Erreur de chargement du dossier patient: ${result.error}');
      }
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  /// Load chat history for this specific patient
  Future<void> _loadChatHistory() async {
    final history = await PatientChatHistoryService.getHistory(widget.patient.code);
    
    setState(() {
      _messages.clear();
      for (final msg in history) {
        _messages.add(ChatMessage(
          content: msg['content'] as String,
          isUser: msg['isUser'] as bool,
          timestamp: DateTime.parse(msg['timestamp'] as String),
        ));
      }
    });
    
    // Add welcome if no history
    if (_messages.isEmpty) {
      _addWelcomeMessage();
    }
    
    _scrollToBottom();
  }
  
  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        content: '''🤖 **Assistant IA Ophtalmologique**

Patient chargé: **${widget.patient.firstName} ${widget.patient.lastName}** (Code: ${widget.patient.code})

Je suis prêt à analyser ce dossier patient. Posez-moi des questions sur:
- **Historique médical** et évolution
- **Prescriptions** et traitements
- **Analyses** et comparaisons
- **Recommandations** cliniques

*Toutes vos conversations sont sauvegardées pour ce patient.*''',
        isUser: false,
      ));
    });
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    
    if (!_contextLoaded) {
      _showError('Veuillez attendre le chargement du dossier patient');
      return;
    }
    
    if (!PuterAIService.hasApiKey) {
      _showError('Clé API non configurée');
      return;
    }
    
    // Add user message
    final userMessage = ChatMessage(content: text, isUser: true);
    setState(() {
      _messages.add(userMessage);
      _messages.add(ChatMessage(content: '', isUser: false, isLoading: true));
    });
    
    // Save user message to history
    await PatientChatHistoryService.saveMessage(
      patientCode: widget.patient.code,
      content: text,
      isUser: true,
    );
    
    _textController.clear();
    _scrollToBottom();
    
    // Get conversation history for context
    final conversationHistory = await PatientChatHistoryService.getConversationHistoryForAI(widget.patient.code);
    
    // Send to AI
    setState(() => _isLoading = true);
    try {
      final response = await PuterAIService.sendMessage(
        text,
        conversationHistory: conversationHistory,
        includePatientContext: true,
      );
      
      // Remove loading message and add response
      setState(() {
        _messages.removeLast(); // Remove loading
        _messages.add(ChatMessage(content: response, isUser: false));
      });
      
      // Save AI response to history
      await PatientChatHistoryService.saveMessage(
        patientCode: widget.patient.code,
        content: response,
        isUser: false,
      );
      
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.removeLast(); // Remove loading
        _messages.add(ChatMessage(
          content: '❌ **Erreur**: $e',
          isUser: false,
        ));
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Effacer l\'historique'),
        content: Text('Voulez-vous effacer toute la conversation pour ${widget.patient.firstName} ${widget.patient.lastName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('EFFACER'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await PatientChatHistoryService.clearHistory(widget.patient.code);
      setState(() {
        _messages.clear();
        _addWelcomeMessage();
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        border: Border.all(color: MediCoreColors.steelOutline, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: MediCoreColors.deepNavy,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.psychology, color: Colors.amber, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assistant IA - ${widget.patient.firstName} ${widget.patient.lastName}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_contextLoaded)
                        Text(
                          '$_visitCount visites • $_documentCount documents',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.white70),
                  onPressed: _clearHistory,
                  tooltip: 'Effacer l\'historique',
                ),
              ],
            ),
          ),
          
          // Messages
          Expanded(
            child: _isLoading && _messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      return _buildMessage(message);
                    },
                  ),
          ),
          
          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText: 'Posez une question sur ce patient...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(color: MediCoreColors.steelOutline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      filled: true,
                      fillColor: const Color(0xFFF8F8F8),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: _textController.text.trim().isEmpty
                        ? Colors.grey
                        : MediCoreColors.professionalBlue,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _textController.text.trim().isEmpty ? null : _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessage(ChatMessage message) {
    if (message.isLoading) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: MediCoreColors.professionalBlue,
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: MediCoreColors.steelOutline),
              ),
              child: const Text('🤔 Analyse en cours...'),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            CircleAvatar(
              backgroundColor: MediCoreColors.professionalBlue,
              child: const Icon(Icons.psychology, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? MediCoreColors.professionalBlue
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: message.isUser
                          ? MediCoreColors.professionalBlue
                          : MediCoreColors.steelOutline,
                    ),
                  ),
                  child: message.isUser
                      ? Text(
                          message.content,
                          style: const TextStyle(color: Colors.white),
                        )
                      : MarkdownBody(
                          data: message.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(color: Colors.black87),
                            strong: const TextStyle(fontWeight: FontWeight.bold),
                            code: TextStyle(
                              backgroundColor: const Color(0xFFF0F0F0),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('HH:mm').format(message.timestamp),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ),
          if (message.isUser) ...[
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: MediCoreColors.professionalBlue,
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

/// Floating AI Button to show chat dialog
class FloatingAIButton extends StatelessWidget {
  final Patient patient;
  
  const FloatingAIButton({super.key, required this.patient});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showAIChat(context),
      backgroundColor: Colors.amber,
      icon: const Icon(Icons.psychology, color: Colors.black),
      label: const Text(
        'Assistant IA',
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
  
  void _showAIChat(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 800,
          height: 700,
          child: PatientAIChatWidget(patient: patient),
        ),
      ),
    );
  }
}
