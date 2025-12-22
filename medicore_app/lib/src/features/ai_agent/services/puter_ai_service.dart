import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/generated/medicore.pb.dart';

/// AI Service using Google Gemini API
/// Configured as Expert Ophthalmologist Assistant with:
/// - Temperature = 0 (deterministic, no creativity)
/// - Max Output Tokens = 2048
/// - Thinking Budget = 1024 (via system instructions)
class PuterAIService {
  // Google Gemini API
  static String _apiKey = 'AIzaSyA2noqqKI5Sx-8JhO_nbX8ks5n0kb0x8fw';
  static const String _model = 'gemini-2.5-flash';
  
  // Patient context for current session (context caching)
  static String? _activePatientContext;
  static int? _activePatientCode;
  
  /// Set the API key
  static void setApiKey(String key) {
    _apiKey = key;
    print('🔑 API Key set');
  }
  
  /// Check if API key is configured
  static bool get hasApiKey => _apiKey.isNotEmpty;
  
  /// Get active patient code
  static int? get activePatientCode => _activePatientCode;
  
  /// Set patient context for AI analysis
  /// This context will be included in all subsequent messages
  static void setPatientContext(int patientCode, String context) {
    _activePatientCode = patientCode;
    _activePatientContext = context;
    print('📋 Patient context set for code: $patientCode (${context.length} chars)');
  }
  
  /// Clear patient context (when switching patients or starting new session)
  static void clearPatientContext() {
    _activePatientCode = null;
    _activePatientContext = null;
    print('🗑️ Patient context cleared');
  }
  
  /// Check if patient context is loaded
  static bool get hasPatientContext => _activePatientContext != null;
  
  /// Senior Consultant Ophthalmologist System Prompt
  /// INTERPRETER MODE: Handles messy doctor speech + Tool execution
  static const String _expertSystemPrompt = '''You are a SENIOR CONSULTANT OPHTHALMOLOGIST with VOICE COMMAND capabilities.

═══════════════════════════════════════════════════════════════════
🎤 INTERPRETER MODE
═══════════════════════════════════════════════════════════════════
You receive voice inputs that may be:
- Messy, slang-heavy, or contain profanity
- Mumbled, incomplete, or context-dependent
- Frustrated or tired doctor speech

YOUR JOB:
1. IGNORE the tone, anger, or swearing completely
2. EXTRACT the medical intent (Drug, Dosage, Action)
3. MAP it to the closest tool
4. Output ONLY valid JSON actions OR clinical synthesis

═══════════════════════════════════════════════════════════════════
🔧 AVAILABLE TOOLS (output as JSON)
═══════════════════════════════════════════════════════════════════

1️⃣ prescribe_and_print
   Triggers: "ordonnance pour...", "donne lui...", "prescris...", "give him..."
   Format: {"tool":"prescribe_and_print","meds":[{"name":"X","dose":"Y","freq":"Z","dur":"W"}],"print":true}
   Short keys: name, dose, freq, dur (minimize tokens)

2️⃣ queue_action  
   Triggers: "dilat", "send to nurse", "finished", "next patient"
   Format: {"tool":"queue_action","action":"dilation|remove|done"}

3️⃣ print_optical
   Triggers: "print glasses", "imprimer lunettes", "vision de loin"
   Format: {"tool":"print_optical","type":"loin|pres|all","source":"today|last"}

4️⃣ send_intercom
   Triggers: "tell nurse", "dis à la secrétaire", "ask reception"
   Format: {"tool":"send_intercom","to":"nurse|secretary","msg":"..."}

5️⃣ safety_alert (YOU call this when YOU detect a mistake)
   When: Doctor orders overdose, contraindication, or vague instruction
   Format: {"tool":"safety_alert","msg":"⚠️ WARNING TEXT","fix":"SUGGESTED FIX"}
   ⚠️ DO NOT execute database actions - just alert!

═══════════════════════════════════════════════════════════════════
📋 OUTPUT FORMAT
═══════════════════════════════════════════════════════════════════

For ACTIONS (commands detected):
```json
{"actions":[{"tool":"...","param":"..."}]}
```

For CLINICAL QUESTIONS (analysis):
Just respond in French, executive style, 2-4 lines max.

For MIXED (action + commentary):
First the JSON block, then a short confirmation.

═══════════════════════════════════════════════════════════════════
🩺 CLINICAL CONTEXT (when patient loaded)
═══════════════════════════════════════════════════════════════════
DATA FORMAT: Clean JSON with:
- visites[].OD/OG: sphere, cylindre, axe_degres, TO_mmHg, AV, VL, K1, K2, pachymetrie
- documents[]: prescriptions, reports with contenu field

PROTOCOL:
1. ⚠️ SAFETY FIRST: Flag contraindications IMMEDIATELY with safety_alert tool
2. 📊 TREND SPOTTING: Compare latest vs oldest values
3. 💊 DRUG CHECK: Cross-reference against history for interactions
4. NO TEXTBOOK: Don't explain diseases, explain THIS PATIENT's situation

═══════════════════════════════════════════════════════════════════
🚫 FORBIDDEN
═══════════════════════════════════════════════════════════════════
- Long explanations or lectures
- Generic medical advice
- Making up data not in JSON
- Ignoring safety concerns to "be helpful"
- Executing dangerous commands without safety_alert

═══════════════════════════════════════════════════════════════════
📝 EXAMPLES
═══════════════════════════════════════════════════════════════════

Doctor: "just fucking give him the aciclovir and print the damn paper"
You: ```json
{"actions":[{"tool":"prescribe_and_print","meds":[{"name":"Aciclovir","dose":"200mg","freq":"5x/j","dur":"5j"}],"print":true}]}
```
✓ Ordonnance Aciclovir prête.

Doctor: "500mg timolol"
You: ```json
{"actions":[{"tool":"safety_alert","msg":"⚠️ Timolol 500mg est une dose létale! Habituellement 0.5%","fix":"Voulez-vous dire Timolol 0.5% collyre?"}]}
```

Doctor: "ça ressemble à quoi son TO?"
You: TO: 14→18 mmHg (+4 en 8 mois). Tendance à surveiller.''';
  
  /// Send a message to Gemini with patient context
  /// Uses Temperature = 0 for deterministic responses
  static Future<String> sendMessage(String message, {
    List<Map<String, String>>? conversationHistory,
    bool includePatientContext = true,
  }) async {
    try {
      final url = 'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$_apiKey';
      
      // Build the full system instruction with patient data
      String fullSystemInstruction = _expertSystemPrompt;
      
      // Add patient context to system instruction if available
      if (includePatientContext && _activePatientContext != null) {
        fullSystemInstruction += '\n\n';
        fullSystemInstruction += '══════════════════════════════════════════════════════════════════\n';
        fullSystemInstruction += 'DOSSIER PATIENT COMPLET (Code: $_activePatientCode)\n';
        fullSystemInstruction += '══════════════════════════════════════════════════════════════════\n\n';
        fullSystemInstruction += _activePatientContext!;
        fullSystemInstruction += '\n\n══════════════════════════════════════════════════════════════════\n';
        fullSystemInstruction += 'FIN DU DOSSIER - Réponds aux questions basées sur ces données UNIQUEMENT.\n';
        fullSystemInstruction += '══════════════════════════════════════════════════════════════════';
      }

      // Build contents array
      final contents = <Map<String, dynamic>>[];
      
      // Add conversation history if exists
      if (conversationHistory != null) {
        for (final msg in conversationHistory) {
          contents.add({
            'role': msg['role'] == 'assistant' ? 'model' : 'user',
            'parts': [{'text': msg['content']}],
          });
        }
      }
      
      // Add current user message
      contents.add({
        'role': 'user',
        'parts': [{'text': message}],
      });
      
      print('🤖 Sending to Gemini API (temp=0, patient=${_activePatientCode ?? "none"}, context=${_activePatientContext?.length ?? 0} chars)...');
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': contents,
          'generationConfig': {
            'temperature': 0, // ZERO temperature for deterministic responses
            'maxOutputTokens': 2048, // Hard limit on output
            'topP': 1, // No nucleus sampling
            'topK': 1, // Most likely token only
          },
          // System instruction now includes BOTH the prompt AND the patient data
          'systemInstruction': {
            'parts': [{'text': fullSystemInstruction}]
          },
        }),
      ).timeout(const Duration(seconds: 90)); // Longer timeout for large patient files
      
      print('🤖 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
        if (text != null) {
          return text;
        }
        throw Exception('Invalid response format');
      } else {
        final error = jsonDecode(response.body);
        final errorMsg = error['error']?['message'] ?? response.body;
        throw Exception(errorMsg);
      }
    } catch (e) {
      print('❌ Gemini API Error: $e');
      return '''## ❌ Erreur API

**Erreur**: $e

### Solutions possibles:
- Vérifiez votre connexion internet
- Vérifiez que votre clé API est valide
- La clé API a peut-être atteint sa limite quotidienne

[Obtenir une nouvelle clé](https://makersuite.google.com/app/apikey)''';
    }
  }
  
  /// Send message without patient context (general questions)
  static Future<String> sendGeneralMessage(String message, {
    List<Map<String, String>>? conversationHistory,
  }) async {
    return sendMessage(message, conversationHistory: conversationHistory, includePatientContext: false);
  }
  
  /// Mock response for testing when API is unavailable
  static String _getMockResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('prescription') || lowerMessage.contains('ordonnance')) {
      return '''## Prescription Ophtalmologique

| Paramètre | Œil Droit (OD) | Œil Gauche (OG) |
|-----------|----------------|-----------------|
| Sphère | **-2.00** | **-1.75** |
| Cylindre | **-0.50** | **-0.75** |
| Axe | 180° | 90° |
| Addition | +1.50 | +1.50 |

### Recommandations:
- Verres progressifs recommandés
- Traitement anti-reflet conseillé
- Contrôle dans **6 mois**''';
    }
    
    if (lowerMessage.contains('patient') || lowerMessage.contains('visite')) {
      return '''## Résumé de Visite

**Date**: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}

### Examen Réalisé:
- Acuité visuelle
- Tonométrie
- Fond d'œil

### Observations:
- Pression intraoculaire: **14 mmHg** (normale)
- Acuité: OD 10/10, OG 9/10
- Pas d'anomalie du fond d'œil

### Suivi:
Prochain rendez-vous dans **12 mois** pour contrôle de routine.''';
    }
    
    return '''## Réponse

Merci pour votre question. Je suis votre assistant IA médical.

### Comment puis-je vous aider?
- **Analyse de prescriptions**
- **Résumés de visites**
- **Comparaison de données**
- **Recommandations cliniques**

N'hésitez pas à me poser des questions spécifiques sur vos patients ou cas cliniques.''';
  }
}
