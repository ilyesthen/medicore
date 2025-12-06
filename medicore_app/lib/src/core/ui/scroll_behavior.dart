import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Desktop Scroll Behavior - No bounce, instant stop
/// Makes the app feel like a native Windows/Mac app, not a phone
class DesktopScrollBehavior extends MaterialScrollBehavior {
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // ClampingScrollPhysics: Stops instantly at bounds (no bounce)
    return const ClampingScrollPhysics();
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}
