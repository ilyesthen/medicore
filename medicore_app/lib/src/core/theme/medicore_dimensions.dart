/// MediCore Dimensions - "The Cockpit" Design
/// Dense, compact layout for maximum information density
class MediCoreDimensions {
  MediCoreDimensions._();
  
  // === MASTER CANVAS ===
  /// Design reference size (all UI designed for this)
  static const double designWidth = 1440.0;
  static const double designHeight = 900.0;
  
  // === BORDERS (Key Visual Element) ===
  static const double paneBorderWidth = 1.0; // All panes have visible 1px borders
  static const double gridLineWidth = 1.0;
  static const double buttonBorderWidth = 1.0;
  
  // === PANE SYSTEM ===
  static const double paneTitleBarHeight = 35.0;
  static const double paneTitleBarBottomBorder = 1.0;
  
  // === DATA GRID (Compact & Dense) ===
  static const double gridHeaderHeight = 35.0; // Compact header
  static const double gridRowHeight = 35.0; // Dense rows (NOT touch-friendly, desktop optimized)
  
  // === SPACING (Tighter than mobile apps) ===
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingS = 6.0;
  static const double spacingM = 8.0;
  static const double spacingL = 12.0;
  static const double spacingXl = 16.0;
  
  // === BORDER RADIUS (Minimal) ===
  static const double radiusNone = 0.0; // Panes are sharp rectangles
  static const double radiusSmall = 4.0; // Buttons only
  
  // === BUTTONS (Weighty & Tactile) ===
  static const double buttonHeight = 32.0;
  static const double buttonPaddingH = 16.0;
  static const double buttonPaddingV = 8.0;
  
  // === INPUTS (Inset Look) ===
  static const double inputHeight = 32.0;
  static const double inputBorderWidth = 1.0;
  static const double inputFocusBorderWidth = 2.0;
  static const double inputPaddingH = 12.0;
  
  // === WINDOW MINIMUM SIZE ===
  static const double minWindowWidth = 1024.0;
  static const double minWindowHeight = 600.0;
}
