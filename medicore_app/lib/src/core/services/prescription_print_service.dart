import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import '../core/types/proto_types.dart';

/// Enterprise-grade prescription PDF service with background template, patient info, and barcode
class PrescriptionPrintService {
  static const String _assetBackgroundPath = 'assets/images/prescription_bg.jpg';
  static Uint8List? _cachedBackground;
  
  /// Title color for all printed documents (black, bold)
  static const PdfColor _titleColor = PdfColors.black;
  
  /// A5 page format: Extended width to prevent early text wrapping
  /// Physical A5 = 420pt wide, but we add ~40pt to compensate for printer clipping
  /// This makes text wrap later since PDF thinks there's more space on the right
  static const PdfPageFormat a5Format = PdfPageFormat(460, 595);  // 420 + 40pt extra
  
  /// A4 page format: Extended width similarly
  static const PdfPageFormat a4Format = PdfPageFormat(635, 842);  // 595 + 40pt extra
  
  /// Sanitize text for printing - replaces special characters that printers can't handle
  static String _sanitizeForPrint(String text) {
    return text
        .replaceAll('Œ', 'OE')
        .replaceAll('œ', 'oe')
        .replaceAll('Æ', 'AE')
        .replaceAll('æ', 'ae');
  }
  
  /// Build content lines preserving exact formatting (line breaks and empty lines)
  static List<pw.Widget> _buildContentLines(String content, double fontSize) {
    final lines = content.split('\n');
    final widgets = <pw.Widget>[];
    
    for (final line in lines) {
      if (line.trim().isEmpty) {
        // Empty line - add spacing
        widgets.add(pw.SizedBox(height: fontSize * 0.8));
      } else {
        // Text line - preserve leading spaces for indentation
        widgets.add(pw.Text(
          line,
          style: pw.TextStyle(fontSize: fontSize),
        ));
      }
    }
    
    return widgets;
  }
  
  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIQUE - PRINT METHODS
  // ═══════════════════════════════════════════════════════════════════════════
  
  /// Print Prescription Optique - Vision de Loin (direct to printer)
  /// Returns true if print succeeded, false if no printer found
  static Future<bool> printOptiqueLoin({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    String? glassType,
    String? age,
  }) async {
    final pdf = await generateOptiqueLoinPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      sphereOD: sphereOD, cylindreOD: cylindreOD, axeOD: axeOD,
      sphereOG: sphereOG, cylindreOG: cylindreOG, axeOG: axeOG, glassType: glassType, age: age,
    );
    return await _printDirect(pdf);
  }

  /// Print Prescription Optique - Vision de Près (direct to printer)
  static Future<bool> printOptiquePres({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    required String addition,
    String? glassType,
    String? age,
  }) async {
    final pdf = await generateOptiquePresPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      sphereOD: sphereOD, cylindreOD: cylindreOD, axeOD: axeOD,
      sphereOG: sphereOG, cylindreOG: cylindreOG, axeOG: axeOG,
      addition: addition, glassType: glassType, age: age,
    );
    return await _printDirect(pdf);
  }

  /// Print Prescription Optique - All (direct to printer)
  static Future<bool> printOptiqueAll({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    required String addition,
    String? glassType,
    String? age,
  }) async {
    final pdf = await generateOptiqueAllPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      sphereOD: sphereOD, cylindreOD: cylindreOD, axeOD: axeOD,
      sphereOG: sphereOG, cylindreOG: cylindreOG, axeOG: axeOG,
      addition: addition, glassType: glassType, age: age,
    );
    return await _printDirect(pdf);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // OPTIQUE - DOWNLOAD/GENERATE METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Generate and download PDF for Vision de Loin
  static Future<Uint8List> generateOptiqueLoinPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    String? glassType,
    String? age,
  }) async {
    return _createOptiquePdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      title: 'Vision de Loin',
      sphereOD: sphereOD, cylindreOD: cylindreOD, axeOD: axeOD,
      sphereOG: sphereOG, cylindreOG: cylindreOG, axeOG: axeOG,
      glassType: glassType, age: age,
    );
  }

  /// Generate and download PDF for Vision de Près
  static Future<Uint8List> generateOptiquePresPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    required String addition,
    String? glassType,
    String? age,
  }) async {
    return _createOptiquePdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      title: 'Vision de Près',
      sphereOD: sphereOD, cylindreOD: cylindreOD, axeOD: axeOD,
      sphereOG: sphereOG, cylindreOG: cylindreOG, axeOG: axeOG,
      addition: addition, glassType: glassType, isNearVision: true, age: age,
    );
  }

  /// Generate and download PDF for All (Loin + Près)
  static Future<Uint8List> generateOptiqueAllPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    required String addition,
    String? glassType,
    String? age,
  }) async {
    return _createOptiqueAllPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      sphereOD: sphereOD, cylindreOD: cylindreOD, axeOD: axeOD,
      sphereOG: sphereOG, cylindreOG: cylindreOG, axeOG: axeOG,
      addition: addition, glassType: glassType, age: age,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LENTILLES - PRINT & DOWNLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Print Prescription Lentilles (direct to printer)
  /// Returns true if print succeeded, false if no printer found
  static Future<bool> printLentilles({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String puissanceOD,
    required String diametreOD,
    required String rayonOD,
    required String puissanceOG,
    required String diametreOG,
    required String rayonOG,
    required String marque,
    required String type,
    required bool isToric,
    String? age,
  }) async {
    final pdf = await generateLentillesPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      puissanceOD: puissanceOD, diametreOD: diametreOD, rayonOD: rayonOD,
      puissanceOG: puissanceOG, diametreOG: diametreOG, rayonOG: rayonOG,
      marque: marque, type: type, isToric: isToric, age: age,
    );
    return await _printDirect(pdf);
  }

  /// Generate Lentilles PDF
  static Future<Uint8List> generateLentillesPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String puissanceOD,
    required String diametreOD,
    required String rayonOD,
    required String puissanceOG,
    required String diametreOG,
    required String rayonOG,
    required String marque,
    required String type,
    required bool isToric,
    String? age,
  }) async {
    return _createLentillesPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      puissanceOD: puissanceOD, diametreOD: diametreOD, rayonOD: rayonOD,
      puissanceOG: puissanceOG, diametreOG: diametreOG, rayonOG: rayonOG,
      marque: marque, type: type, isToric: isToric, age: age,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ORDONNANCE - PRINT & DOWNLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Print Ordonnance (direct to printer)
  /// If printName/printPrenom/printAge are provided, they override patient info for printing only
  /// useA4: if true, prints on A4 paper (same design, just bigger paper)
  static Future<bool> printOrdonnance({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String content,
    required String documentType,
    String? printName,
    String? printPrenom,
    String? printAge,
    String? age,
    bool useA4 = false,
  }) async {
    final pdf = await generateOrdonnancePdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      content: content, documentType: documentType,
      printName: printName, printPrenom: printPrenom, printAge: printAge, age: age,
      useA4: useA4,
    );
    return await _printDirect(pdf);
  }

  /// Generate Ordonnance PDF
  /// useA4: if true, generates on A4 paper (same design, just bigger paper)
  static Future<Uint8List> generateOrdonnancePdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String content,
    required String documentType,
    String? printName,
    String? printPrenom,
    String? printAge,
    String? age,
    bool useA4 = false,
  }) async {
    return _createOrdonnancePdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      content: content, documentType: documentType,
      printName: printName, printPrenom: printPrenom, printAge: printAge, age: age,
      useA4: useA4,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COMPTE RENDU (A4) - PRINT & DOWNLOAD
  // ═══════════════════════════════════════════════════════════════════════════

  /// Print Compte Rendu on A4
  static Future<bool> printCompteRendu({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String content,
    required String documentType,
    String? printName,
    String? printPrenom,
    String? printAge,
    String? age,
  }) async {
    final pdf = await generateCompteRenduPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      content: content, documentType: documentType,
      printName: printName, printPrenom: printPrenom, printAge: printAge, age: age,
    );
    return await _printDirect(pdf);
  }

  /// Generate Compte Rendu PDF (A4)
  static Future<Uint8List> generateCompteRenduPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String content,
    required String documentType,
    String? printName,
    String? printPrenom,
    String? printAge,
    String? age,
  }) async {
    return _createCompteRenduPdf(
      patientName: patientName, patientCode: patientCode, barcode: barcode, date: date,
      content: content, documentType: documentType,
      printName: printName, printPrenom: printPrenom, printAge: printAge, age: age,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD TO FILE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Save PDF - shows file picker dialog so user chooses location
  static Future<String> downloadPdf(Uint8List pdfData, String filename) async {
    // Clean filename
    final cleanName = filename.replaceAll(RegExp(r'[/\\:*?"<>|]'), '_');
    
    // Show save dialog
    final result = await FilePicker.platform.saveFile(
      dialogTitle: 'Enregistrer la prescription',
      fileName: cleanName,
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    
    if (result != null) {
      final file = File(result);
      await file.writeAsBytes(pdfData);
      return file.path;
    }
    
    // If user cancelled, save to Downloads as fallback
    try {
      final downloadsDir = Directory('${Platform.environment['HOME']}/Downloads');
      if (await downloadsDir.exists()) {
        final file = File('${downloadsDir.path}/$cleanName');
        await file.writeAsBytes(pdfData);
        return file.path;
      }
    } catch (_) {}
    
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/$cleanName');
    await file.writeAsBytes(pdfData);
    return file.path;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INTERNAL HELPERS
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<bool> _printDirect(Uint8List pdf) async {
    try {
      // Check for printers with timeout
      final printers = await Printing.listPrinters().timeout(
        const Duration(seconds: 3),
        onTimeout: () => <Printer>[],
      );
      
      if (printers.isEmpty) {
        return false; // No printer found
      }
      
      final printer = printers.firstWhere((p) => p.isDefault, orElse: () => printers.first);
      final result = await Printing.directPrintPdf(
        printer: printer,
        onLayout: (format) async => pdf,
        format: a5Format,
        name: 'Prescription MediCore',
      );
      
      return result;
    } catch (_) {
      return false;
    }
  }

  static Future<Uint8List?> _loadBackgroundImage() async {
    // Return cached version if available
    if (_cachedBackground != null) return _cachedBackground;
    
    try {
      // Load from bundled assets
      print('📄 Loading background image from: $_assetBackgroundPath');
      final data = await rootBundle.load(_assetBackgroundPath);
      _cachedBackground = data.buffer.asUint8List();
      print('✅ Background image loaded: ${_cachedBackground!.length} bytes');
      return _cachedBackground;
    } catch (e) {
      print('⚠️ Failed to load from bundle: $e');
      // Fallback: try loading from file system (dev mode)
      try {
        final file = File('assets/images/prescription_bg.jpg');
        if (await file.exists()) {
          _cachedBackground = await file.readAsBytes();
          print('✅ Background image loaded from file: ${_cachedBackground!.length} bytes');
          return _cachedBackground;
        }
      } catch (e2) {
        print('⚠️ Failed to load from file: $e2');
      }
    }
    print('❌ Background image not found');
    return null;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION - OPTIQUE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _createOptiquePdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String title,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    String? addition,
    String? glassType,
    String? age,
    bool isNearVision = false,
  }) async {
    final doc = pw.Document(
      title: 'Prescription Optique - $patientName',
      author: 'MediCore Ophthalmology',
      creator: 'MediCore v1.0',
    );
    
    // Background image disabled for now
    // final bgImage = await _loadBackgroundImage();
    const pageFormat = a5Format;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Background image disabled
              // if (bgImage != null)
              //   pw.Positioned.fill(child: pw.Image(pw.MemoryImage(bgImage), fit: pw.BoxFit.cover)),
              
              // Content - more right (200pt) and moved UP (155pt)
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 200, right: 0, top: 155, bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfoBox(patientName, patientCode, barcode, date, age: age),
                    pw.SizedBox(height: 12),
                    
                    // Centered title
                    pw.Center(child: pw.Text('VERRES CORRECTEURS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.SizedBox(height: 4),
                    pw.Center(child: pw.Text(title, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                    pw.SizedBox(height: 10),
                    
                    // Both eyes side by side
                    _buildBothEyesOptique(
                      isNearVision ? _addValues(sphereOD, addition) : sphereOD, cylindreOD, axeOD,
                      isNearVision ? _addValues(sphereOG, addition) : sphereOG, cylindreOG, axeOG,
                    ),
                    
                    // Verres at bottom
                    if (glassType != null && glassType.isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      pw.Text('Verres : $glassType', style: const pw.TextStyle(fontSize: 11)),
                    ],
                    
                    pw.Spacer(),
                    // Footer removed
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static Future<Uint8List> _createOptiqueAllPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
    required String addition,
    String? glassType,
    String? age,
  }) async {
    final doc = pw.Document(
      title: 'Prescription Optique Complète - $patientName',
      author: 'MediCore Ophthalmology',
      creator: 'MediCore v1.0',
    );
    
    // Background image disabled for now
    // final bgImage = await _loadBackgroundImage();
    const pageFormat = a5Format;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Background image disabled
              // if (bgImage != null)
              //   pw.Positioned.fill(child: pw.Image(pw.MemoryImage(bgImage), fit: pw.BoxFit.cover)),
              
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 200, right: 0, top: 155, bottom: 8),
                child: pw.Builder(builder: (context) {
                  // Check if addition is valid (not empty and not "0" or "0.00")
                  final hasAddition = addition.isNotEmpty && 
                      addition != '0' && addition != '0.00' && addition != '+0.00';
                  
                  // Check if loin (distance) fields have any data
                  final hasLoinData = sphereOD.isNotEmpty || cylindreOD.isNotEmpty || axeOD.isNotEmpty ||
                      sphereOG.isNotEmpty || cylindreOG.isNotEmpty || axeOG.isNotEmpty;
                  
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildPatientInfoBox(patientName, patientCode, barcode, date, age: age),
                      pw.SizedBox(height: 10),
                      
                      // Centered title
                      pw.Center(child: pw.Text('VERRES CORRECTEURS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black))),
                      pw.SizedBox(height: 8),
                      
                      // Vision de Loin - only show if loin fields have data
                      if (hasLoinData) ...[  
                        pw.Text('Vision de Loin', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 4),
                        _buildBothEyesOptique(sphereOD, cylindreOD, axeOD, sphereOG, cylindreOG, axeOG),
                      ],
                      
                      // Vision de Près - only show if addition exists
                      if (hasAddition) ...[
                        pw.SizedBox(height: 8),
                        pw.Text('Vision de Près', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                        pw.SizedBox(height: 4),
                        _buildBothEyesOptique(
                          _addValues(sphereOD, addition), cylindreOD, axeOD,
                          _addValues(sphereOG, addition), cylindreOG, axeOG,
                        ),
                      ],
                      
                      // Verres at bottom
                      if (glassType != null && glassType.isNotEmpty) ...[
                        pw.SizedBox(height: 10),
                        pw.Text('Verres : $glassType', style: const pw.TextStyle(fontSize: 11)),
                      ],
                      
                      pw.Spacer(),
                      // Footer removed
                    ],
                  );
                }),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION - LENTILLES
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _createLentillesPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String puissanceOD,
    required String diametreOD,
    required String rayonOD,
    required String puissanceOG,
    required String diametreOG,
    required String rayonOG,
    required String marque,
    required String type,
    required bool isToric,
    String? age,
  }) async {
    final doc = pw.Document(
      title: 'Prescription Lentilles - $patientName',
      author: 'MediCore Ophthalmology',
      creator: 'MediCore v1.0',
    );
    
    // Background image disabled for now
    // final bgImage = await _loadBackgroundImage();
    const pageFormat = a5Format;

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Background image disabled
              // if (bgImage != null)
              //   pw.Positioned.fill(child: pw.Image(pw.MemoryImage(bgImage), fit: pw.BoxFit.cover)),
              
              pw.Padding(
                padding: const pw.EdgeInsets.only(left: 200, right: 0, top: 155, bottom: 8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfoBox(patientName, patientCode, barcode, date, age: age),
                    pw.SizedBox(height: 12),
                    
                    // Centered title
                    pw.Center(child: pw.Text('LENTILLES DE CONTACT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _titleColor))),
                    if (isToric) pw.Center(child: pw.Text('(Sphere Equivalente)', style: const pw.TextStyle(fontSize: 11))),
                    pw.SizedBox(height: 12),
                    
                    // Both eyes side by side
                    _buildBothEyesLentilles(puissanceOD, diametreOD, rayonOD, puissanceOG, diametreOG, rayonOG),
                    
                    // Type and Marque at bottom
                    if (type.isNotEmpty) ...[
                      pw.SizedBox(height: 10),
                      pw.Text('Type : $type', style: const pw.TextStyle(fontSize: 11)),
                    ],
                    if (marque.isNotEmpty) ...[
                      pw.SizedBox(height: 4),
                      pw.Text('Marque : $marque', style: const pw.TextStyle(fontSize: 11)),
                    ],
                    
                    pw.Spacer(),
                    // Footer removed
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION - ORDONNANCE
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _createOrdonnancePdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String content,
    required String documentType,
    String? printName,
    String? printPrenom,
    String? printAge,
    String? age,
    bool useA4 = false,
  }) async {
    final doc = pw.Document(
      title: 'Ordonnance - $patientName',
      author: 'MediCore Ophthalmology',
      creator: 'MediCore v1.0',
    );
    
    // Background image disabled for now
    // final bgImage = await _loadBackgroundImage();
    final pageFormat = useA4 ? a4Format : a5Format;

    // Determine what name to use for printing
    String displayName;
    String? displayAge;
    final bool isPrintingWithAnotherName = (printName != null && printName.isNotEmpty) || (printPrenom != null && printPrenom.isNotEmpty);
    
    if (isPrintingWithAnotherName) {
      // Use "print with another person" info
      final nom = printName ?? '';
      final prenom = printPrenom ?? '';
      displayName = '$prenom $nom'.trim();
      displayAge = printAge;
    } else {
      // Use patient info
      displayName = patientName;
      displayAge = age;
    }

    // Adjust padding - same as Optique/Lentilles (content on RIGHT side)
    final leftPad = useA4 ? 280.0 : 200.0;  // Same as Optique/Lentilles - content on RIGHT
    final rightPad = useA4 ? 0.0 : 0.0;   // No right padding
    final topPad = useA4 ? 200.0 : 155.0;   // Same as Optique/Lentilles
    final fontSize = useA4 ? 9.0 : 10.0;   // Text size
    final titleSize = useA4 ? 11.0 : 12.0;  // Title size

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.zero,
        build: (context) {
          return pw.Stack(
            children: [
              // Background image disabled
              // if (bgImage != null)
              //   pw.Positioned.fill(child: pw.Image(pw.MemoryImage(bgImage), fit: pw.BoxFit.cover)),
              
              pw.Padding(
                padding: pw.EdgeInsets.only(left: leftPad, right: rightPad, top: topPad, bottom: 12),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPatientInfoBox(displayName, patientCode, barcode, date, age: displayAge),
                    pw.SizedBox(height: 14),
                    
                    // Title with document icon ONLY when printing with another name
                    pw.Center(
                      child: isPrintingWithAnotherName
                        ? pw.Row(
                            mainAxisSize: pw.MainAxisSize.min,
                            children: [
                              pw.Container(
                                width: titleSize,
                                height: titleSize,
                                decoration: pw.BoxDecoration(
                                  border: pw.Border.all(color: PdfColors.black, width: 0.8),
                                ),
                                child: pw.Center(
                                  child: pw.Text('≡', style: pw.TextStyle(fontSize: titleSize * 0.7, fontWeight: pw.FontWeight.bold)),
                                ),
                              ),
                              pw.SizedBox(width: 6),
                              pw.Text(_sanitizeForPrint(documentType), style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold, color: _titleColor)),
                            ],
                          )
                        : pw.Text(_sanitizeForPrint(documentType), style: pw.TextStyle(fontSize: titleSize, fontWeight: pw.FontWeight.bold, color: _titleColor)),
                    ),
                    pw.SizedBox(height: 14),
                    
                    // Content - the prescription text, preserving formatting line by line
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: _buildContentLines(_sanitizeForPrint(content), fontSize),
                        ),
                      ),
                    ),
                    
                    // Footer removed
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PDF GENERATION - COMPTE RENDU (A4)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Uint8List> _createCompteRenduPdf({
    required String patientName,
    required String patientCode,
    required String barcode,
    required String date,
    required String content,
    required String documentType,
    String? printName,
    String? printPrenom,
    String? printAge,
    String? age,
  }) async {
    final doc = pw.Document(
      title: 'Compte Rendu - $patientName',
      author: 'MediCore Ophthalmology',
      creator: 'MediCore v1.0',
    );
    
    // No background image for Compte Rendu
    const pageFormat = a4Format;
    
    // Margins: same as Optique/Lentilles - content on RIGHT side
    const topMargin = 200.0;
    const bottomMargin = 100.0;
    const leftMargin = 280.0;  // Same as Optique/Lentilles - content on RIGHT
    const rightMargin = 0.0;  // No right margin

    // Determine what name to use for printing
    String displayName;
    String? displayAge;
    
    if ((printName != null && printName.isNotEmpty) || (printPrenom != null && printPrenom.isNotEmpty)) {
      final nom = printName ?? '';
      final prenom = printPrenom ?? '';
      displayName = '$prenom $nom'.trim();
      displayAge = printAge;
    } else {
      displayName = patientName;
      displayAge = age;
    }

    // Use MultiPage for automatic page breaks with background on each page
    doc.addPage(
      pw.MultiPage(
        pageFormat: pageFormat,
        margin: pw.EdgeInsets.only(
          top: topMargin,
          bottom: bottomMargin,
          left: leftMargin,
          right: rightMargin,
        ),
        header: (context) => pw.Container(), // Empty header (space reserved by margin)
        footer: (context) => pw.Container(), // Empty footer (space reserved by margin)
        build: (context) => [
          // Patient info box
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            margin: const pw.EdgeInsets.only(bottom: 15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Patient: $displayName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    if (displayAge != null && displayAge.isNotEmpty)
                      pw.Text('Âge: $displayAge ans', style: const pw.TextStyle(fontSize: 16)),
                    pw.Text('Code: $patientCode', style: const pw.TextStyle(fontSize: 16)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Date: $date', style: const pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 4),
                    pw.BarcodeWidget(data: barcode, barcode: pw.Barcode.code128(), width: 70, height: 18, drawText: false),
                  ],
                ),
              ],
            ),
          ),
          
          // Document title
          pw.Center(
            child: pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 15),
              child: pw.Text(
                _sanitizeForPrint(documentType),
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: _titleColor),
              ),
            ),
          ),
          
          // Content - preserves exact formatting with line breaks (line by line)
          ..._buildContentLines(_sanitizeForPrint(content), 18),
          
          // Signature area at bottom
          pw.SizedBox(height: 30),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Text('Signature et cachet', style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 35),
                  pw.Container(
                    width: 130,
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey400)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
        pageTheme: pw.PageTheme(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.only(
            top: topMargin,
            bottom: bottomMargin,
            left: leftMargin,
            right: rightMargin,
          ),
          // No background image
        ),
      ),
    );

    return doc.save();
  }
  
  static pw.Widget _buildLentillesSection({
    required String puissanceOD,
    required String diametreOD,
    required String rayonOD,
    required String puissanceOG,
    required String diametreOG,
    required String rayonOG,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Oeil Droit (OD)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
        pw.Text('   Puissance : $puissanceOD    Diamètre : $diametreOD    Rayon : $rayonOD', style: const pw.TextStyle(fontSize: 10)),
        pw.SizedBox(height: 5),
        pw.Text('Oeil Gauche (OG)', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
        pw.Text('   Puissance : $puissanceOG    Diamètre : $diametreOG    Rayon : $rayonOG', style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UI COMPONENTS - Word-like French style
  // ═══════════════════════════════════════════════════════════════════════════

  static pw.Widget _buildPatientInfoBox(String name, String code, String barcode, String date, {String? age}) {
    // Split name into parts (expecting "FirstName LastName" format)
    final parts = name.split(' ');
    final prenom = parts.isNotEmpty ? parts.first : '';
    final nom = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Line 1: First name (Prénom)
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: 'Prénom: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: prenom, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        // Line 2: Last name (Nom)
        pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(text: 'Nom: ', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: nom, style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
        pw.SizedBox(height: 3),
        // Line 3: Code, Date, Age on one line
        pw.Row(
          children: [
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: 'N° ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.TextSpan(text: code, style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ),
            pw.SizedBox(width: 10),
            pw.Text('Le $date', style: const pw.TextStyle(fontSize: 9)),
            if (age != null && age.isNotEmpty) ...[
              pw.SizedBox(width: 10),
              pw.RichText(
                text: pw.TextSpan(
                  children: [
                    pw.TextSpan(text: 'Age: ', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.TextSpan(text: '$age ans', style: const pw.TextStyle(fontSize: 9)),
                  ],
                ),
              ),
            ],
            pw.SizedBox(width: 10),
            pw.BarcodeWidget(data: barcode, barcode: pw.Barcode.code128(), width: 45, height: 14, drawText: false),
          ],
        ),
      ],
    );
  }

  // Professional table for Optique (SPHÈRE, CYLINDRE, AXE)
  static pw.Widget _buildProOptiqueTable(String eye, String sphere, String cylindre, String axe) {
    final eyeLabel = eye == 'OD' ? 'OEil Droit (OD)' : 'OEil Gauche (OG)';
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(eyeLabel, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Table(
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FixedColumnWidth(70),
            1: const pw.FixedColumnWidth(60),
          },
          children: [
            _proTableRow('SPHÈRE', '$sphere D'),
            _proTableRow('CYLINDRE', cylindre.isNotEmpty && cylindre != '0' ? '$cylindre D' : '-'),
            _proTableRow('AXE', axe.isNotEmpty && axe != '0' ? '$axe°' : '-'),
          ],
        ),
      ],
    );
  }

  // Professional table for Lentilles
  static pw.Widget _buildProLentilleSection(String eye, String puissance, String diametre, String rayon) {
    final eyeLabel = eye == 'OD' ? 'OEil Droit (OD)' : 'OEil Gauche (OG)';
    // Strip existing units to avoid duplicates
    final cleanPuissance = puissance.replaceAll(' D', '').replaceAll('D', '').trim();
    final cleanDiametre = diametre.replaceAll(' mm', '').replaceAll('mm', '').trim();
    final cleanRayon = rayon.replaceAll(' mm', '').replaceAll('mm', '').trim();
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(eyeLabel, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 2),
        pw.Table(
          border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FixedColumnWidth(75),
            1: const pw.FixedColumnWidth(60),
          },
          children: [
            _proTableRow('PUISSANCE', '$cleanPuissance D'),
            _proTableRow('DIAMÈTRE', '$cleanDiametre mm'),
            _proTableRow('RAYON', '$cleanRayon mm'),
          ],
        ),
      ],
    );
  }

  // Both eyes side by side for Optique
  static pw.Widget _buildBothEyesOptique(String sphereOD, String cylindreOD, String axeOD, 
                                          String sphereOG, String cylindreOG, String axeOG) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildProOptiqueTable('OD', sphereOD, cylindreOD, axeOD)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _buildProOptiqueTable('OG', sphereOG, cylindreOG, axeOG)),
      ],
    );
  }

  // Both eyes side by side for Lentilles
  static pw.Widget _buildBothEyesLentilles(String puissanceOD, String diametreOD, String rayonOD,
                                            String puissanceOG, String diametreOG, String rayonOG) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(child: _buildProLentilleSection('OD', puissanceOD, diametreOD, rayonOD)),
        pw.SizedBox(width: 8),
        pw.Expanded(child: _buildProLentilleSection('OG', puissanceOG, diametreOG, rayonOG)),
      ],
    );
  }

  static pw.TableRow _proTableRow(String label, String value) {
    return pw.TableRow(children: [
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ),
      pw.Container(
        padding: const pw.EdgeInsets.all(4),
        child: pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ),
    ]);
  }

  static pw.Widget _buildSimpleOptiqueTable({
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // OD Table
        _buildEyeTable('OD', sphereOD, cylindreOD, axeOD),
        pw.SizedBox(height: 8),
        // OG Table
        _buildEyeTable('OG', sphereOG, cylindreOG, axeOG),
      ],
    );
  }

  static pw.Widget _buildEyeTable(String eye, String sphere, String cylindre, String axe) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey500),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FixedColumnWidth(45),
        2: const pw.FixedColumnWidth(45),
        3: const pw.FixedColumnWidth(35),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _simpleCell(eye, header: true),
            _simpleCell('Sph', header: true),
            _simpleCell('Cyl', header: true),
            _simpleCell('Axe', header: true),
          ],
        ),
        pw.TableRow(children: [
          _simpleCell(''),
          _simpleCell(sphere),
          _simpleCell(cylindre),
          _simpleCell(axe),
        ]),
      ],
    );
  }

  static pw.Widget _buildSimpleLentillesTable({
    required String puissanceOD,
    required String diametreOD,
    required String rayonOD,
    required String puissanceOG,
    required String diametreOG,
    required String rayonOG,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // OD Table
        _buildLentilleEyeTable('OD', puissanceOD, diametreOD, rayonOD),
        pw.SizedBox(height: 8),
        // OG Table
        _buildLentilleEyeTable('OG', puissanceOG, diametreOG, rayonOG),
      ],
    );
  }

  static pw.Widget _buildLentilleEyeTable(String eye, String puissance, String diametre, String rayon) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.4, color: PdfColors.grey500),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FixedColumnWidth(45),
        2: const pw.FixedColumnWidth(40),
        3: const pw.FixedColumnWidth(40),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _simpleCell(eye, header: true),
            _simpleCell('Puis', header: true),
            _simpleCell('Dia', header: true),
            _simpleCell('Ray', header: true),
          ],
        ),
        pw.TableRow(children: [
          _simpleCell(''),
          _simpleCell(puissance),
          _simpleCell(diametre),
          _simpleCell(rayon),
        ]),
      ],
    );
  }

  static pw.Widget _simpleCell(String text, {bool header = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(3),
      alignment: pw.Alignment.center,
      child: pw.Text(text, style: pw.TextStyle(fontSize: 11, fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  static pw.Widget _buildOptiqueSection({
    required String eye,
    required String sphere,
    required String cylindre,
    required String axe,
    required bool isRight,
  }) {
    final color = isRight ? PdfColors.green800 : PdfColors.blue800;
    final label = isRight ? 'Oeil Droit (OD)' : 'Oeil Gauche (OG)';
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: color)),
        pw.SizedBox(height: 2),
        pw.Text('   Sphère : $sphere    Cylindre : $cylindre    Axe : $axe', style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }

  static pw.Widget _buildOptiqueTable({
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildOptiqueSection(eye: 'OD', sphere: sphereOD, cylindre: cylindreOD, axe: axeOD, isRight: true),
        pw.SizedBox(height: 6),
        _buildOptiqueSection(eye: 'OG', sphere: sphereOG, cylindre: cylindreOG, axe: axeOG, isRight: false),
      ],
    );
  }

  static pw.Widget _buildOptiqueTableOld({
    required String sphereOD,
    required String cylindreOD,
    required String axeOD,
    required String sphereOG,
    required String cylindreOG,
    required String axeOG,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.3, color: PdfColors.grey500),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.6),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(1.2),
        3: const pw.FlexColumnWidth(0.8),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _cell('', isHeader: true),
            _cell('Sphère', isHeader: true),
            _cell('Cylindre', isHeader: true),
            _cell('Axe', isHeader: true),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _cell('OD', isLabel: true, color: PdfColors.green800),
            _cell(sphereOD),
            _cell(cylindreOD),
            _cell(axeOD),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _cell('OG', isLabel: true, color: PdfColors.blue800),
            _cell(sphereOG),
            _cell(cylindreOG),
            _cell(axeOG),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildLentillesTable({
    required String puissanceOD,
    required String diametreOD,
    required String rayonOD,
    required String puissanceOG,
    required String diametreOG,
    required String rayonOG,
  }) {
    return pw.Table(
      border: pw.TableBorder.all(width: 0.5, color: PdfColors.grey600),
      columnWidths: {
        0: const pw.FlexColumnWidth(0.8),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.purple700),
          children: [
            _cell('', isHeader: true),
            _cell('PUISSANCE', isHeader: true),
            _cell('DIAMÈTRE', isHeader: true),
            _cell('RAYON', isHeader: true),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.green50),
          children: [
            _cell('OD', isLabel: true, color: PdfColors.green800),
            _cell(puissanceOD),
            _cell(diametreOD),
            _cell(rayonOD),
          ],
        ),
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
          children: [
            _cell('OG', isLabel: true, color: PdfColors.blue800),
            _cell(puissanceOG),
            _cell(diametreOG),
            _cell(rayonOG),
          ],
        ),
      ],
    );
  }

  static pw.Widget _cell(String text, {bool isHeader = false, bool isLabel = false, PdfColor? color}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      alignment: pw.Alignment.center,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 9 : 10,
          fontWeight: (isHeader || isLabel) ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : (color ?? PdfColors.black),
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  // Footer removed - no branding text on printed documents

  static String _addValues(String sphere, String? addition) {
    if (addition == null || addition.isEmpty) return sphere;
    final sphVal = double.tryParse(sphere.replaceAll('+', '')) ?? 0;
    final addVal = double.tryParse(addition.replaceAll('+', '')) ?? 0;
    final result = sphVal + addVal;
    return result >= 0 ? '+${result.toStringAsFixed(2)}' : result.toStringAsFixed(2);
  }
}
