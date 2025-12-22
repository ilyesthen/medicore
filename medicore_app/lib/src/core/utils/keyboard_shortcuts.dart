import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/types/proto_types.dart';

/// Enterprise-grade keyboard shortcut handler
/// F1: New Patient, F2: Receive Messages, F3: Send Message, F5: Comptabilité
/// Arrow Up/Down: Navigate patient list
class KeyboardShortcutHandler extends StatefulWidget {
  final Widget child;
  final VoidCallback? onF1Pressed; // New Patient
  final VoidCallback? onF2Pressed; // Receive Messages
  final VoidCallback? onF3Pressed; // Send Message
  final VoidCallback? onF5Pressed; // Comptabilité
  final VoidCallback? onArrowUpPressed; // Navigate up in patient list
  final VoidCallback? onArrowDownPressed; // Navigate down in patient list

  const KeyboardShortcutHandler({
    super.key,
    required this.child,
    this.onF1Pressed,
    this.onF2Pressed,
    this.onF3Pressed,
    this.onF5Pressed,
    this.onArrowUpPressed,
    this.onArrowDownPressed,
  });

  @override
  State<KeyboardShortcutHandler> createState() => _KeyboardShortcutHandlerState();
}

class _KeyboardShortcutHandlerState extends State<KeyboardShortcutHandler> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // Request focus when widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // F1 - New Patient
          if (event.logicalKey == LogicalKeyboardKey.f1) {
            widget.onF1Pressed?.call();
            return KeyEventResult.handled;
          }
          
          // F2 - Receive Messages
          if (event.logicalKey == LogicalKeyboardKey.f2) {
            widget.onF2Pressed?.call();
            return KeyEventResult.handled;
          }
          
          // F3 - Send Message
          if (event.logicalKey == LogicalKeyboardKey.f3) {
            widget.onF3Pressed?.call();
            return KeyEventResult.handled;
          }
          
          // F5 - Comptabilité
          if (event.logicalKey == LogicalKeyboardKey.f5) {
            widget.onF5Pressed?.call();
            return KeyEventResult.handled;
          }
          
          // Arrow Up - Navigate up in patient list
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (widget.onArrowUpPressed != null) {
              widget.onArrowUpPressed!();
              return KeyEventResult.handled;
            }
          }
          
          // Arrow Down - Navigate down in patient list
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            if (widget.onArrowDownPressed != null) {
              widget.onArrowDownPressed!();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: widget.child,
    );
  }
}
