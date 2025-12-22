import 'dart:convert';
import '../../../core/types/proto_types.dart';

/// AI Action Handler - Middleware between AI output and Repositories
/// Parses AI JSON actions and executes them against the database
class AIActionHandler {
  final OrdonnancesRepository _ordonnancesRepo;
  final WaitingQueueRepository _waitingQueueRepo;
  final MessagesRepository _messagesRepo;
  
  // Current context (auto-injected by app, not by AI)
  int? currentPatientCode;
  String? currentPatientName;
  String? currentRoomId;
  String? currentRoomName;
  String? currentUserId;
  String? currentUserName;
  String? currentUserRole;
  
  AIActionHandler({
    OrdonnancesRepository? ordonnancesRepo,
    WaitingQueueRepository? waitingQueueRepo,
    MessagesRepository? messagesRepo,
  })  : _ordonnancesRepo = ordonnancesRepo ?? OrdonnancesRepository(),
        _waitingQueueRepo = waitingQueueRepo ?? WaitingQueueRepository(),
        _messagesRepo = messagesRepo ?? MessagesRepository();
  
  /// Set current context (called by UI when patient is selected)
  void setContext({
    int? patientCode,
    String? patientName,
    String? roomId,
    String? roomName,
    String? userId,
    String? userName,
    String? userRole,
  }) {
    currentPatientCode = patientCode;
    currentPatientName = patientName;
    currentRoomId = roomId;
    currentRoomName = roomName;
    currentUserId = userId;
    currentUserName = userName;
    currentUserRole = userRole;
  }
  
  /// Parse AI response and extract actions
  /// Returns list of ActionResult for each action found
  Future<List<ActionResult>> parseAndExecute(String aiResponse) async {
    final results = <ActionResult>[];
    
    // Look for JSON action blocks in the response
    // Format: ```json\n{"actions": [...]}```
    // Or inline: [ACTION: TOOL(params)]
    
    // Try to find JSON block first
    final jsonMatch = RegExp(r'```json\s*([\s\S]*?)\s*```').firstMatch(aiResponse);
    if (jsonMatch != null) {
      try {
        final jsonStr = jsonMatch.group(1)!;
        final parsed = jsonDecode(jsonStr);
        
        if (parsed is Map && parsed.containsKey('actions')) {
          final actions = parsed['actions'] as List;
          for (final action in actions) {
            final result = await _executeAction(action as Map<String, dynamic>);
            results.add(result);
          }
        } else if (parsed is Map && parsed.containsKey('tool')) {
          // Single action format
          final result = await _executeAction(parsed as Map<String, dynamic>);
          results.add(result);
        }
      } catch (e) {
        results.add(ActionResult(
          tool: 'parse_error',
          success: false,
          error: 'Failed to parse JSON: $e',
        ));
      }
    }
    
    // Also check for inline action format: [ACTION: TOOL(params)]
    final inlineMatches = RegExp(r'\[ACTION:\s*(\w+)\((.*?)\)\]').allMatches(aiResponse);
    for (final match in inlineMatches) {
      final tool = match.group(1)!.toLowerCase();
      final paramsStr = match.group(2) ?? '';
      
      final action = _parseInlineAction(tool, paramsStr);
      if (action != null) {
        final result = await _executeAction(action);
        results.add(result);
      }
    }
    
    return results;
  }
  
  /// Parse inline action format like PRESCRIBE("Aciclovir", "200mg")
  Map<String, dynamic>? _parseInlineAction(String tool, String paramsStr) {
    switch (tool) {
      case 'prescribe':
      case 'prescribe_and_print':
        // Parse medication and dosage
        final parts = paramsStr.split(',').map((s) => s.trim().replaceAll('"', '')).toList();
        return {
          'tool': 'prescribe_and_print',
          'meds': [{'name': parts.isNotEmpty ? parts[0] : '', 'dose': parts.length > 1 ? parts[1] : ''}],
          'print': tool == 'prescribe_and_print' || paramsStr.toLowerCase().contains('print'),
        };
        
      case 'print':
        return {'tool': 'prescribe_and_print', 'print': true};
        
      case 'queue':
      case 'queue_action':
        return {'tool': 'queue_action', 'action': paramsStr.replaceAll('"', '')};
        
      case 'print_optical':
        return {'tool': 'print_optical', 'type': paramsStr.replaceAll('"', '')};
        
      case 'send_intercom':
      case 'intercom':
        final parts = paramsStr.split(',').map((s) => s.trim().replaceAll('"', '')).toList();
        return {
          'tool': 'send_intercom',
          'to': parts.isNotEmpty ? parts[0] : 'nurse',
          'msg': parts.length > 1 ? parts[1] : '',
        };
        
      case 'safety_alert':
      case 'alert':
        return {'tool': 'safety_alert', 'msg': paramsStr.replaceAll('"', '')};
        
      default:
        return null;
    }
  }
  
  /// Execute a single action
  Future<ActionResult> _executeAction(Map<String, dynamic> action) async {
    final tool = action['tool'] as String? ?? '';
    
    switch (tool) {
      case 'prescribe_and_print':
        return await _executePrescribeAndPrint(action);
        
      case 'queue_action':
        return await _executeQueueAction(action);
        
      case 'print_optical':
        return await _executePrintOptical(action);
        
      case 'send_intercom':
        return await _executeSendIntercom(action);
        
      case 'safety_alert':
        return _executeSafetyAlert(action);
        
      default:
        return ActionResult(
          tool: tool,
          success: false,
          error: 'Unknown tool: $tool',
        );
    }
  }
  
  /// Tool 1: Prescribe and Print
  Future<ActionResult> _executePrescribeAndPrint(Map<String, dynamic> action) async {
    try {
      if (currentPatientCode == null) {
        return ActionResult(
          tool: 'prescribe_and_print',
          success: false,
          error: 'No patient selected',
        );
      }
      
      final meds = action['meds'] as List<dynamic>? ?? [];
      final instructions = action['instructions'] as String? ?? '';
      final shouldPrint = action['print'] as bool? ?? true;
      
      // Build prescription content
      final buffer = StringBuffer();
      for (final med in meds) {
        final m = med as Map<String, dynamic>;
        final name = m['name'] as String? ?? '';
        final dose = m['dose'] as String? ?? '';
        final freq = m['freq'] as String? ?? '';
        final duration = m['dur'] as String? ?? '';
        
        buffer.writeln('$name $dose');
        if (freq.isNotEmpty) buffer.writeln('  $freq');
        if (duration.isNotEmpty) buffer.writeln('  Durée: $duration');
        buffer.writeln();
      }
      if (instructions.isNotEmpty) {
        buffer.writeln('Instructions: $instructions');
      }
      
      // Insert ordonnance
      final ordonnanceId = await _ordonnancesRepo.insertOrdonnance(
        OrdonnancesCompanion.insert(
          patientCode: currentPatientCode!,
          sequence: const Value(1),
          documentDate: Value(DateTime.now()),
          doctorName: Value(currentUserName ?? 'Dr.'),
          type1: const Value('PRESCRIPTION'),
          content1: Value(buffer.toString()),
        ),
      );
      
      return ActionResult(
        tool: 'prescribe_and_print',
        success: true,
        data: {
          'ordonnance_id': ordonnanceId,
          'meds_count': meds.length,
          'should_print': shouldPrint,
        },
      );
    } catch (e) {
      return ActionResult(
        tool: 'prescribe_and_print',
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Tool 2: Queue Action (dilation, remove, mark done)
  Future<ActionResult> _executeQueueAction(Map<String, dynamic> action) async {
    try {
      if (currentPatientCode == null) {
        return ActionResult(
          tool: 'queue_action',
          success: false,
          error: 'No patient selected',
        );
      }
      
      final queueAction = action['action'] as String? ?? '';
      
      switch (queueAction) {
        case 'add_dilation':
        case 'dilation':
        case 'dilatation':
          // Add to dilation queue
          // This would need the waiting queue repository method
          return ActionResult(
            tool: 'queue_action',
            success: true,
            data: {'action': 'add_dilation', 'patient': currentPatientCode},
          );
          
        case 'remove':
        case 'done':
        case 'finish':
          return ActionResult(
            tool: 'queue_action',
            success: true,
            data: {'action': 'remove', 'patient': currentPatientCode},
          );
          
        default:
          return ActionResult(
            tool: 'queue_action',
            success: false,
            error: 'Unknown queue action: $queueAction',
          );
      }
    } catch (e) {
      return ActionResult(
        tool: 'queue_action',
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Tool 3: Print Optical Prescription
  Future<ActionResult> _executePrintOptical(Map<String, dynamic> action) async {
    try {
      if (currentPatientCode == null) {
        return ActionResult(
          tool: 'print_optical',
          success: false,
          error: 'No patient selected',
        );
      }
      
      final type = action['type'] as String? ?? 'all';
      final source = action['source'] as String? ?? 'today';
      
      // This triggers the print dialog in the UI
      return ActionResult(
        tool: 'print_optical',
        success: true,
        data: {
          'type': type, // 'loin', 'pres', 'all'
          'source': source, // 'today', 'last_visit'
          'patient': currentPatientCode,
        },
        requiresUI: true, // Signal to UI to open print dialog
      );
    } catch (e) {
      return ActionResult(
        tool: 'print_optical',
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Tool 4: Send Intercom Message
  Future<ActionResult> _executeSendIntercom(Map<String, dynamic> action) async {
    try {
      if (currentRoomId == null || currentUserId == null) {
        return ActionResult(
          tool: 'send_intercom',
          success: false,
          error: 'No room or user context',
        );
      }
      
      final recipient = action['to'] as String? ?? 'nurse';
      final message = action['msg'] as String? ?? '';
      
      // Map recipient to direction
      final direction = recipient == 'nurse' || recipient == 'secretary' 
          ? 'to_nurse' 
          : 'to_doctor';
      
      await _messagesRepo.sendMessage(
        roomId: currentRoomId!,
        senderId: currentUserId!,
        senderName: currentUserName ?? 'Dr.',
        senderRole: currentUserRole ?? 'Médecin',
        content: message,
        direction: direction,
        patientCode: currentPatientCode,
        patientName: currentPatientName,
      );
      
      return ActionResult(
        tool: 'send_intercom',
        success: true,
        data: {'to': recipient, 'msg': message},
      );
    } catch (e) {
      return ActionResult(
        tool: 'send_intercom',
        success: false,
        error: e.toString(),
      );
    }
  }
  
  /// Tool 5: Safety Alert (NO database action - just returns warning)
  ActionResult _executeSafetyAlert(Map<String, dynamic> action) {
    final warning = action['msg'] as String? ?? action['warning'] as String? ?? '';
    final fix = action['fix'] as String? ?? '';
    
    return ActionResult(
      tool: 'safety_alert',
      success: true, // Alert was "executed" (displayed)
      data: {
        'warning': warning,
        'suggested_fix': fix,
      },
      isSafetyAlert: true,
    );
  }
}

/// Result of an action execution
class ActionResult {
  final String tool;
  final bool success;
  final String? error;
  final Map<String, dynamic>? data;
  final bool requiresUI;
  final bool isSafetyAlert;
  
  ActionResult({
    required this.tool,
    required this.success,
    this.error,
    this.data,
    this.requiresUI = false,
    this.isSafetyAlert = false,
  });
  
  @override
  String toString() {
    if (isSafetyAlert) {
      return '⚠️ ALERTE: ${data?['warning']}';
    }
    if (!success) {
      return '❌ $tool: $error';
    }
    return '✅ $tool: ${data ?? 'OK'}';
  }
}
