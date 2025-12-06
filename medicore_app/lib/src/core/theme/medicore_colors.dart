import 'package:flutter/material.dart';

/// MediCore Colors - "The Cockpit" Design System
/// Steel & Navy Palette for Professional, Authoritative Look
class MediCoreColors {
  MediCoreColors._(); // Private constructor
  
  // === PRIMARY PALETTE: Steel & Navy ===
  
  /// Deep Navy - Almost black-blue
  /// Used for: Sidebar, Top Header, anchors the screen
  static const Color deepNavy = Color(0xFF1B263B);
  
  /// Professional Blue - Muted steel blue
  /// Used for: Active buttons, highlights (not neon)
  static const Color professionalBlue = Color(0xFF415A77);
  
  /// Canvas Grey - Darker stone-grey
  /// Used for: Main background (reduces eye glare, not white)
  static const Color canvasGrey = Color(0xFFE0E1DD);
  
  /// Paper White - Pure white
  /// Used for: Data input areas ONLY
  static const Color paperWhite = Color(0xFFFFFFFF);
  
  /// Steel Outline - Key element
  /// Used for: Borders on every pane (1px solid)
  static const Color steelOutline = Color(0xFF778DA9);
  
  // === UI COMPONENT COLORS ===
  
  /// Pane Title Bar Background
  static const Color paneTitleBar = Color(0xFFD3D6DB);
  
  /// Input Field Background (Inset look)
  static const Color inputBackground = Color(0xFFF8F9FA);
  
  /// Input Border
  static const Color inputBorder = Color(0xFFA0AAB4);
  
  /// Data Grid Lines
  static const Color gridLines = Color(0xFFCFD8DC);
  
  /// Zebra Row Alternate (light grey)
  static const Color zebraRowAlt = Color(0xFFF1F3F5);
  
  // === STATUS COLORS (Universal) ===
  
  /// Critical/Unpaid/Error
  static const Color criticalRed = Color(0xFFD32F2F);
  
  /// Warning/Pending
  static const Color warningOrange = Color(0xFFED6C02);
  
  /// Healthy/Paid/Success
  static const Color healthyGreen = Color(0xFF2E7D32);
  
  /// Inactive/Archived
  static const Color inactiveGrey = Color(0xFF9E9E9E);
  
  // === BUTTON GRADIENTS (Semi-Skeuomorphic) ===
  
  /// Button gradient - subtle vertical gradient
  static LinearGradient get buttonGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      professionalBlue,
      professionalBlue.withBlue((professionalBlue.blue * 0.85).toInt()),
    ],
  );
  
  /// Button shadow - 1px bottom shadow for "thickness"
  static List<BoxShadow> get buttonShadow => [
    const BoxShadow(
      color: Color(0x40000000),
      offset: Offset(0, 1),
      blurRadius: 0,
    ),
  ];
}
