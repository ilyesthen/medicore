import 'package:flutter/material.dart';
import 'package:bitsdojo_window/bitsdojo_window.dart';
import '../theme/medicore_colors.dart';
import '../theme/medicore_dimensions.dart';

/// Window initialization for desktop platforms
/// Customizes window chrome to match Cockpit design
void initializeWindow() {
  doWhenWindowReady(() {
    appWindow
      ..title = 'Thaziri - Gestion Médicale'
      ..minSize = const Size(
        MediCoreDimensions.minWindowWidth,
        MediCoreDimensions.minWindowHeight,
      );
    
    // Start in fullscreen/maximized mode
    appWindow.maximize();
    
    appWindow.show();
  });
}

/// Custom window title bar that matches Cockpit theme
class CockpitWindowTitleBar extends StatelessWidget {
  final String title;
  
  const CockpitWindowTitleBar({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return WindowTitleBarBox(
      child: Container(
        color: MediCoreColors.deepNavy,
        child: Row(
          children: [
            Expanded(
              child: MoveWindow(
                child: Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
            // Window control buttons
            WindowButtons(),
          ],
        ),
      ),
    );
  }
}

/// Window control buttons (Minimize, Maximize, Close)
class WindowButtons extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MinimizeWindowButton(
          colors: _buttonColors,
        ),
        MaximizeWindowButton(
          colors: _buttonColors,
        ),
        CloseWindowButton(
          colors: _closeButtonColors,
        ),
      ],
    );
  }
  
  static final _buttonColors = WindowButtonColors(
    iconNormal: Colors.white,
    iconMouseOver: Colors.white,
    iconMouseDown: Colors.white70,
    mouseOver: MediCoreColors.professionalBlue,
    mouseDown: MediCoreColors.professionalBlue.withOpacity(0.8),
  );
  
  static final _closeButtonColors = WindowButtonColors(
    iconNormal: Colors.white,
    iconMouseOver: Colors.white,
    iconMouseDown: Colors.white,
    mouseOver: MediCoreColors.criticalRed,
    mouseDown: MediCoreColors.criticalRed.withOpacity(0.8),
  );
}
