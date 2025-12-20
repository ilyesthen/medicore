import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../services/puter_ai_service.dart';
import '../services/patient_context_service.dart';
import '../services/ai_action_handler.dart';
import '../services/ai_safety_validator.dart';

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

/// Premium AI Agent Chat Screen
class AIAgentScreen extends StatefulWidget {
  const AIAgentScreen({super.key});

  @override
  State<AIAgentScreen> createState() => _AIAgentScreenState();
}

class _AIAgentScreenState extends State<AIAgentScreen> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _patientCodeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final FocusNode _patientCodeFocusNode = FocusNode();
  final List<ChatMessage> _messages = [];
  final List<Map<String, String>> _conversationHistory = [];
  
  // Patient context
  final PatientContextService _patientContextService = PatientContextService();
  final AIActionHandler _actionHandler = AIActionHandler();
  final AISafetyValidator _safetyValidator = AISafetyValidator();
  bool _isLoadingPatient = false;
  int? _loadedPatientCode;
  int _patientVisitCount = 0;
  int _patientDocumentCount = 0;
  
  // Last executed actions (for UI feedback)
  List<ActionResult> _lastActionResults = [];
  
  // Speech to text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _lastWords = '';
  
  // Audio for beep sound
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  // Loading state
  bool _isLoading = false;
  
  // Animation controllers
  late AnimationController _micPulseController;
  late AnimationController _dotsController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // Mic pulse animation
    _micPulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    
    // Dots loading animation
    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
    
    // Listen to text changes for send button state
    _textController.addListener(() {
      setState(() {});
    });
    
    // Load saved API key
    _loadApiKey();
    
    // Add welcome message
    _addWelcomeMessage();
    
    // Check if there's already a loaded patient context
    if (PuterAIService.hasPatientContext) {
      _loadedPatientCode = PuterAIService.activePatientCode;
      _patientCodeController.text = _loadedPatientCode.toString();
    }
  }
  
  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final savedKey = prefs.getString('gemini_api_key');
    if (savedKey != null && savedKey.isNotEmpty) {
      PuterAIService.setApiKey(savedKey);
      setState(() {});
    }
  }
  
  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key);
    PuterAIService.setApiKey(key);
    setState(() {});
  }
  
  void _showApiKeyDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.key, color: MediCoreColors.professionalBlue),
            const SizedBox(width: 8),
            const Text('Clé API Gemini'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Obtenez une clé gratuite sur:',
              style: MediCoreTypography.body,
            ),
            const SizedBox(height: 4),
            SelectableText(
              'https://makersuite.google.com/app/apikey',
              style: MediCoreTypography.body.copyWith(
                color: MediCoreColors.professionalBlue,
                decoration: TextDecoration.underline,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: 'Clé API',
                hintText: 'AIza...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
              ),
              obscureText: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _saveApiKey(controller.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ Clé API configurée!'),
                    backgroundColor: MediCoreColors.healthyGreen,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: MediCoreColors.professionalBlue,
            ),
            child: const Text('Enregistrer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage(
        content: '''# Consultant Senior IA 🔬

**Mode:** Synthèse clinique executive • Pas de blabla

### Utilisation:
1. Entrez le **code patient** → Cliquez **Charger**
2. Posez vos questions

### Ce que je fais:
- ⚠️ **Alertes sécurité** (stéroïdes sur ulcères, interactions)
- 📊 **Tendances** (TO, AV: valeur actuelle vs plus ancienne)
- 🔍 **Gaps** (examens manquants >1 an)
- 💊 **Vérification Rx** vs allergies/traitements en cours

*Réponses courtes et actionnables. Pas de cours de médecine.*''',
        isUser: false,
      ));
    });
  }
  
  /// Load patient context from database
  Future<void> _loadPatientContext() async {
    final codeText = _patientCodeController.text.trim();
    if (codeText.isEmpty) {
      _showError('Veuillez entrer un code patient');
      return;
    }
    
    final code = int.tryParse(codeText);
    if (code == null) {
      _showError('Code patient invalide');
      return;
    }
    
    setState(() => _isLoadingPatient = true);
    
    try {
      final result = await _patientContextService.buildPatientContext(code);
      
      if (result.success) {
        // Set context in AI service
        PuterAIService.setPatientContext(code, result.context!);
        
        // Set context in action handler for tool execution
        _actionHandler.setContext(
          patientCode: code,
          patientName: 'Patient $code', // TODO: get actual name
        );
        
        setState(() {
          _loadedPatientCode = code;
          _patientVisitCount = result.visitCount;
          _patientDocumentCount = result.documentCount;
          _isLoadingPatient = false;
        });
        
        // Clear previous conversation and add patient loaded message
        _messages.clear();
        _conversationHistory.clear();
        _messages.add(ChatMessage(
          content: '''# ✅ Patient $code | ${result.visitCount} visites | ${result.documentCount} docs

**Mode Commande Vocale activé.** Parlez naturellement:
- "Donne lui Aciclovir 200mg"
- "Imprime les lunettes"
- "Dis à l'infirmière de préparer la dilatation"

Ou posez des questions cliniques:
- "Évolution TO?"
- "Risques avec cette Rx?"''',
          isUser: false,
        ));
        _scrollToBottom();
      } else {
        setState(() => _isLoadingPatient = false);
        _showError(result.error ?? 'Erreur inconnue');
      }
    } catch (e) {
      setState(() => _isLoadingPatient = false);
      _showError('Erreur: $e');
    }
  }
  
  /// Clear loaded patient
  void _clearPatient() {
    PuterAIService.clearPatientContext();
    _patientContextService.clearCache();
    _actionHandler.setContext(); // Clear action handler context
    setState(() {
      _loadedPatientCode = null;
      _patientVisitCount = 0;
      _patientDocumentCount = 0;
      _patientCodeController.clear();
    });
    _messages.clear();
    _conversationHistory.clear();
    _addWelcomeMessage();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
      onError: (error) {
        setState(() => _isListening = false);
        _showError('Erreur de reconnaissance vocale: ${error.errorMsg}');
      },
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechAvailable) {
      _showError('La reconnaissance vocale n\'est pas disponible sur cet appareil');
      return;
    }
    
    // Play beep sound
    await _audioPlayer.play(AssetSource('sounds/notification.m4a'));
    
    setState(() {
      _isListening = true;
      _lastWords = _textController.text;
    });
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          // Append new words to existing text
          if (result.recognizedWords.isNotEmpty) {
            if (_lastWords.isNotEmpty && !_lastWords.endsWith(' ')) {
              _textController.text = '$_lastWords ${result.recognizedWords}';
            } else {
              _textController.text = _lastWords + result.recognizedWords;
            }
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'fr_FR', // French locale
      cancelOnError: true,
      partialResults: true,
      listenMode: stt.ListenMode.dictation,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _lastWords = _textController.text;
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _isLoading) return;
    
    // Add user message
    setState(() {
      _messages.add(ChatMessage(content: text, isUser: true));
      _isLoading = true;
    });
    
    // Clear input
    _textController.clear();
    _lastWords = '';
    
    // Add to conversation history
    _conversationHistory.add({'role': 'user', 'content': text});
    
    // Scroll to bottom
    _scrollToBottom();
    
    // Add loading message
    setState(() {
      _messages.add(ChatMessage(content: '', isUser: false, isLoading: true));
    });
    
    try {
      // Get AI response
      final response = await PuterAIService.sendMessage(
        text, 
        conversationHistory: _conversationHistory.length > 10 
            ? _conversationHistory.sublist(_conversationHistory.length - 10)
            : _conversationHistory,
      );
      
      // Parse and execute any actions in the response
      final actionResults = await _actionHandler.parseAndExecute(response);
      _lastActionResults = actionResults;
      
      // Build response text with action results
      String displayResponse = response;
      if (actionResults.isNotEmpty) {
        final actionSummary = actionResults.map((r) => r.toString()).join('\n');
        displayResponse = '$response\n\n---\n**Actions exécutées:**\n$actionSummary';
        
        // Show safety alerts prominently
        for (final result in actionResults) {
          if (result.isSafetyAlert) {
            _showSafetyAlert(result.data?['warning'] ?? '', result.data?['suggested_fix'] ?? '');
          }
        }
      }
      
      // Remove loading message and add real response
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(content: displayResponse, isUser: false));
        _isLoading = false;
      });
      
      // Add to history
      _conversationHistory.add({'role': 'assistant', 'content': response});
      
    } catch (e) {
      setState(() {
        _messages.removeLast();
        _messages.add(ChatMessage(
          content: '❌ Erreur: Impossible de contacter l\'IA. Veuillez réessayer.',
          isUser: false,
        ));
        _isLoading = false;
      });
    }
    
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: MediCoreColors.criticalRed,
      ),
    );
  }
  
  /// Show safety alert dialog - RED warning that blocks execution
  void _showSafetyAlert(String warning, String suggestedFix) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red.shade50,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade700, width: 3),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ ALERTE SÉCURITÉ',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                warning,
                style: TextStyle(
                  color: Colors.red.shade900,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (suggestedFix.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '💡 Suggestion:',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                suggestedFix,
                style: TextStyle(
                  color: Colors.grey.shade800,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'COMPRIS',
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _patientCodeController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _patientCodeFocusNode.dispose();
    _speech.cancel();
    _audioPlayer.dispose();
    _micPulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: MediCoreColors.canvasGrey,
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Chat messages
          Expanded(
            child: _buildChatArea(),
          ),
          
          // Input bar
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: MediCoreColors.paneTitleBar,
        border: Border(
          bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Title and status
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      MediCoreColors.professionalBlue,
                      MediCoreColors.deepNavy,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.psychology, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                'ASSISTANT IA EXPERT',
                style: MediCoreTypography.paneTitleBar.copyWith(
                  fontWeight: FontWeight.w600,
                  color: MediCoreColors.deepNavy,
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              // API Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: PuterAIService.hasApiKey 
                      ? MediCoreColors.healthyGreen.withOpacity(0.1)
                      : MediCoreColors.warningOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: PuterAIService.hasApiKey 
                        ? MediCoreColors.healthyGreen 
                        : MediCoreColors.warningOrange,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: PuterAIService.hasApiKey 
                            ? MediCoreColors.healthyGreen 
                            : MediCoreColors.warningOrange,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      PuterAIService.hasApiKey ? 'Gemini' : 'Non configuré',
                      style: MediCoreTypography.label.copyWith(
                        color: PuterAIService.hasApiKey 
                            ? MediCoreColors.healthyGreen 
                            : MediCoreColors.warningOrange,
                        fontWeight: FontWeight.w500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.settings, size: 18),
                tooltip: 'Configurer la clé API',
                color: MediCoreColors.professionalBlue,
                onPressed: _showApiKeyDialog,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bottom row: Patient code input
          _buildPatientCodeBar(),
        ],
      ),
    );
  }
  
  /// Build the patient code input bar
  Widget _buildPatientCodeBar() {
    return Row(
      children: [
        // Patient code input
        Expanded(
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              color: MediCoreColors.paperWhite,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _loadedPatientCode != null 
                    ? MediCoreColors.healthyGreen 
                    : MediCoreColors.steelOutline,
                width: _loadedPatientCode != null ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Icon(
                  _loadedPatientCode != null ? Icons.person_pin : Icons.person_search,
                  size: 18,
                  color: _loadedPatientCode != null 
                      ? MediCoreColors.healthyGreen 
                      : MediCoreColors.steelOutline,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _patientCodeController,
                    focusNode: _patientCodeFocusNode,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: MediCoreTypography.inputField.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Code patient (ex: 1234)',
                      hintStyle: MediCoreTypography.inputField.copyWith(
                        color: MediCoreColors.steelOutline,
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    onSubmitted: (_) => _loadPatientContext(),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Load button
        SizedBox(
          height: 36,
          child: ElevatedButton.icon(
            onPressed: _isLoadingPatient ? null : _loadPatientContext,
            icon: _isLoadingPatient 
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download, size: 16),
            label: Text(_isLoadingPatient ? 'Chargement...' : 'Charger'),
            style: ElevatedButton.styleFrom(
              backgroundColor: MediCoreColors.professionalBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Clear button (only show if patient loaded)
        if (_loadedPatientCode != null) ...[
          const SizedBox(width: 4),
          SizedBox(
            height: 36,
            width: 36,
            child: IconButton(
              onPressed: _clearPatient,
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Effacer patient',
              color: MediCoreColors.criticalRed,
              padding: EdgeInsets.zero,
            ),
          ),
        ],
        const SizedBox(width: 8),
        // Patient status badge
        if (_loadedPatientCode != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: MediCoreColors.healthyGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: MediCoreColors.healthyGreen),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, size: 14, color: MediCoreColors.healthyGreen),
                const SizedBox(width: 6),
                Text(
                  'Patient $_loadedPatientCode',
                  style: MediCoreTypography.label.copyWith(
                    color: MediCoreColors.healthyGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_patientVisitCount visites • $_patientDocumentCount docs',
                  style: MediCoreTypography.label.copyWith(
                    color: MediCoreColors.healthyGreen,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatArea() {
    return Container(
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border.all(color: MediCoreColors.steelOutline),
      ),
      margin: const EdgeInsets.all(12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: _messages.length,
          itemBuilder: (context, index) {
            final message = _messages[index];
            return _MessageBubble(
              message: message,
              dotsController: _dotsController,
              animationDelay: index * 50,
            );
          },
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: const BoxDecoration(
        color: MediCoreColors.paneTitleBar,
        border: Border(
          top: BorderSide(color: MediCoreColors.steelOutline, width: 1),
        ),
      ),
      child: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Mic button with pulse animation
            AnimatedBuilder(
              animation: _micPulseController,
              builder: (context, child) {
                return Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: _isListening
                        ? [
                            BoxShadow(
                              color: MediCoreColors.criticalRed.withOpacity(
                                0.3 + (_micPulseController.value * 0.3),
                              ),
                              blurRadius: 8 + (_micPulseController.value * 8),
                              spreadRadius: _micPulseController.value * 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: _isListening
                        ? MediCoreColors.criticalRed
                        : MediCoreColors.professionalBlue,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _speechAvailable ? _toggleListening : null,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Icon(
                          _isListening ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(width: 12),
            
            // Text field
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: MediCoreColors.paperWhite,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _isListening 
                        ? MediCoreColors.criticalRed 
                        : MediCoreColors.steelOutline,
                    width: _isListening ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        style: MediCoreTypography.inputField,
                        decoration: InputDecoration(
                          hintText: _isListening 
                              ? 'Parlez maintenant...' 
                              : 'Tapez votre message ou utilisez le micro...',
                          hintStyle: MediCoreTypography.inputField.copyWith(
                            color: _isListening 
                                ? MediCoreColors.criticalRed.withOpacity(0.7)
                                : MediCoreColors.steelOutline,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    if (_isListening)
                      Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: _buildRecordingIndicator(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Send button
            Material(
              color: _textController.text.trim().isNotEmpty && !_isLoading
                  ? MediCoreColors.healthyGreen
                  : MediCoreColors.steelOutline,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: _textController.text.trim().isNotEmpty && !_isLoading
                    ? _sendMessage
                    : null,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return AnimatedBuilder(
      animation: _micPulseController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: MediCoreColors.criticalRed.withOpacity(
                  0.5 + (_micPulseController.value * 0.5),
                ),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'REC',
              style: MediCoreTypography.label.copyWith(
                color: MediCoreColors.criticalRed,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Message bubble widget with animations
class _MessageBubble extends StatefulWidget {
  final ChatMessage message;
  final AnimationController dotsController;
  final int animationDelay;

  const _MessageBubble({
    required this.message,
    required this.dotsController,
    required this.animationDelay,
  });

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    // Start animation with delay
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.message.isUser) _buildAvatar(),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: widget.message.isUser
                        ? MediCoreColors.professionalBlue
                        : MediCoreColors.paperWhite,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(widget.message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(widget.message.isUser ? 4 : 16),
                    ),
                    border: widget.message.isUser
                        ? null
                        : Border.all(color: MediCoreColors.steelOutline.withOpacity(0.5)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: widget.message.isLoading
                      ? _buildLoadingDots()
                      : widget.message.isUser
                          ? Text(
                              widget.message.content,
                              style: MediCoreTypography.body.copyWith(
                                color: Colors.white,
                              ),
                            )
                          : _buildMarkdownContent(),
                ),
              ),
              const SizedBox(width: 8),
              if (widget.message.isUser) _buildUserAvatar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            MediCoreColors.professionalBlue,
            MediCoreColors.deepNavy,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.psychology, color: Colors.white, size: 20),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: MediCoreColors.steelOutline.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: MediCoreColors.steelOutline),
      ),
      child: const Icon(Icons.person, color: MediCoreColors.deepNavy, size: 20),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: widget.dotsController,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (widget.dotsController.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (2 * progress - 1).abs()));
            final opacity = 0.3 + (0.7 * scale);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: MediCoreColors.professionalBlue.withOpacity(opacity),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildMarkdownContent() {
    return MarkdownBody(
      data: widget.message.content,
      selectable: true,
      styleSheet: MarkdownStyleSheet(
        h1: MediCoreTypography.sectionHeader.copyWith(
          fontSize: 18,
          color: MediCoreColors.deepNavy,
        ),
        h2: MediCoreTypography.subsectionHeader.copyWith(
          fontSize: 16,
          color: MediCoreColors.deepNavy,
        ),
        h3: MediCoreTypography.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: MediCoreColors.deepNavy,
        ),
        p: MediCoreTypography.body.copyWith(
          color: Colors.black87,
        ),
        strong: MediCoreTypography.body.copyWith(
          fontWeight: FontWeight.bold,
          color: MediCoreColors.deepNavy,
        ),
        em: MediCoreTypography.body.copyWith(
          fontStyle: FontStyle.italic,
          color: Colors.black54,
        ),
        listBullet: MediCoreTypography.body.copyWith(
          color: MediCoreColors.professionalBlue,
        ),
        tableHead: MediCoreTypography.gridHeader.copyWith(
          color: Colors.white,
        ),
        tableBody: MediCoreTypography.gridCell,
        tableBorder: TableBorder.all(
          color: MediCoreColors.steelOutline,
          width: 1,
        ),
        tableHeadAlign: TextAlign.center,
        tableCellsPadding: const EdgeInsets.all(8),
        blockquotePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: MediCoreColors.professionalBlue,
              width: 3,
            ),
          ),
          color: MediCoreColors.professionalBlue.withOpacity(0.05),
        ),
        codeblockDecoration: BoxDecoration(
          color: MediCoreColors.deepNavy.withOpacity(0.05),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: MediCoreColors.steelOutline.withOpacity(0.3)),
        ),
        code: MediCoreTypography.gridCell.copyWith(
          backgroundColor: MediCoreColors.deepNavy.withOpacity(0.05),
          color: MediCoreColors.deepNavy,
        ),
      ),
      styleSheetTheme: MarkdownStyleSheetBaseTheme.material,
    );
  }
}
