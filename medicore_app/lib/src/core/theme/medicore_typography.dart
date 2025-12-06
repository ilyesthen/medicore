import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// MediCore Typography - "The Editorial Hybrid"
/// Merriweather (Serif) for headings + Roboto (Sans-Serif) for data/UI
/// Creates "Old Class" professional feel like medical journals
class MediCoreTypography {
  MediCoreTypography._();
  
  // Tabular figures for number alignment in data
  static const List<FontFeature> _tabularFigures = [
    FontFeature.tabularFigures(),
  ];
  
  // === HEADINGS (Serif - Merriweather) ===
  // Classic, book-like, commands respect
  
  /// Page Title: Merriweather 28px Bold
  static TextStyle pageTitle = GoogleFonts.merriweather(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  /// Section Header: Merriweather 20px Bold
  static TextStyle sectionHeader = GoogleFonts.merriweather(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  
  /// Subsection Header: Merriweather 16px Semi-Bold
  static TextStyle subsectionHeader = GoogleFonts.merriweather(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  // === DATA/UI (Sans-Serif - Roboto) ===
  // Clean, mechanical, legible at small sizes
  
  /// Data Grid Header: Roboto 11px Bold ALL CAPS
  static TextStyle gridHeader = GoogleFonts.roboto(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.5,
    fontFeatures: _tabularFigures,
  );
  
  /// Data Grid Cell: Roboto 13px Regular
  static final TextStyle gridCell = GoogleFonts.roboto(
    fontSize: 13,
    fontWeight: FontWeight.normal,
    fontFeatures: _tabularFigures,
  );
  
  /// Data cell text (alias for gridCell)
  static final TextStyle dataCell = gridCell;
  
  /// Button Text: Roboto 13px Medium
  static TextStyle button = GoogleFonts.roboto(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );
  
  /// Input Field: Roboto 14px Regular
  static TextStyle inputField = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    fontFeatures: _tabularFigures,
  );
  
  /// Body Text: Roboto 14px Regular
  static TextStyle body = GoogleFonts.roboto(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );
  
  /// Small Label: Roboto 12px Regular
  static TextStyle label = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: const Color(0xFF666666),
  );
  
  /// Pane Title Bar: Roboto 12px Medium
  static TextStyle paneTitleBar = GoogleFonts.roboto(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.2,
  );
}
