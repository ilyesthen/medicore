import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/services/prescription_print_service.dart';

class PrescriptionOptiqueDialog extends StatefulWidget {
  final String? vlOD; // VL from right eye
  final String? vlOG; // VL from left eye
  final String? addition; // Addition value (triggers near vision section)
  final String? patientName; // Patient name for printing
  final String? patientCode; // Patient code (N°)
  final String? barcode; // Patient barcode
  final String? age; // Patient age

  const PrescriptionOptiqueDialog({super.key, this.vlOD, this.vlOG, this.addition, this.patientName, this.patientCode, this.barcode, this.age});

  @override
  State<PrescriptionOptiqueDialog> createState() => _PrescriptionOptiqueDialogState();
}

class _PrescriptionOptiqueDialogState extends State<PrescriptionOptiqueDialog> {
  // Distance vision controllers
  final _sphereOD = TextEditingController();
  final _cylindreOD = TextEditingController();
  final _axeOD = TextEditingController();
  final _sphereOG = TextEditingController();
  final _cylindreOG = TextEditingController();
  final _axeOG = TextEditingController();

  // Near vision controllers (calculated from distance + addition)
  final _sphereODNear = TextEditingController();
  final _cylindreODNear = TextEditingController();
  final _axeODNear = TextEditingController();
  final _sphereOGNear = TextEditingController();
  final _cylindreOGNear = TextEditingController();
  final _axeOGNear = TextEditingController();

  final _verresController = TextEditingController();
  
  static const _defaultVerresOptions = [
    'Verres transitions',
    'Verres cristallisés',
    'Organiques',
    'Minéraux',
    'Photochromiques PEG',
    'Photochromiques PEB',
    'Progressifs blancs',
    'Progressifs photochromiques',
    'Extrafins',
    'Verres HMC "Anti-Reflets"',
  ];
  
  List<String> _verresOptions = List.from(_defaultVerresOptions);
  static const _verresPrefsKey = 'optique_verres_options';

  @override
  void initState() {
    super.initState();
    _loadSavedOptions();
    _parseVL();
  }

  Future<void> _loadSavedOptions() async {
    final prefs = await SharedPreferences.getInstance();
    final savedVerres = prefs.getStringList(_verresPrefsKey);
    if (mounted && savedVerres != null && savedVerres.isNotEmpty) {
      setState(() {
        _verresOptions = savedVerres;
      });
    }
  }

  Future<void> _saveCustomOption(String value) async {
    if (value.isEmpty) return;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    // Check if already exists (case insensitive)
    if (_verresOptions.any((o) => o.toLowerCase() == trimmed.toLowerCase())) return;
    // Add new option and save
    final prefs = await SharedPreferences.getInstance();
    _verresOptions.add(trimmed);
    await prefs.setStringList(_verresPrefsKey, _verresOptions);
    if (mounted) setState(() {});
  }

  void _parseVL() {
    // Parse VL OD: format could be "+1.50 ( -0.75 à 90° )" or just "+1.50"
    if (widget.vlOD != null && widget.vlOD!.isNotEmpty) {
      final parsed = _parseVLString(widget.vlOD!);
      _sphereOD.text = parsed['sphere'] ?? '';
      _cylindreOD.text = parsed['cylindre'] ?? '';
      _axeOD.text = parsed['axe'] ?? '';
    }
    if (widget.vlOG != null && widget.vlOG!.isNotEmpty) {
      final parsed = _parseVLString(widget.vlOG!);
      _sphereOG.text = parsed['sphere'] ?? '';
      _cylindreOG.text = parsed['cylindre'] ?? '';
      _axeOG.text = parsed['axe'] ?? '';
    }
    // Calculate near vision if addition exists
    _calculateNearVision();
  }

  Map<String, String> _parseVLString(String vl) {
    // Format: "+1.50 ( -0.75 à 90° )" or "+1.50"
    final result = <String, String>{};
    final trimmed = vl.trim();
    
    if (trimmed.contains('(')) {
      // Has cylinder and axis
      final parts = trimmed.split('(');
      result['sphere'] = parts[0].trim();
      if (parts.length > 1) {
        final cylAxe = parts[1].replaceAll(')', '').trim();
        final cylParts = cylAxe.split('à');
        if (cylParts.isNotEmpty) result['cylindre'] = cylParts[0].trim();
        if (cylParts.length > 1) result['axe'] = cylParts[1].trim();
      }
    } else {
      result['sphere'] = trimmed;
    }
    return result;
  }

  void _calculateNearVision() {
    if (widget.addition == null || widget.addition!.isEmpty) return;
    
    // Parse addition value
    final addStr = widget.addition!.replaceAll('+', '').trim();
    final addValue = double.tryParse(addStr) ?? 0;
    
    // Calculate near sphere = distance sphere + addition
    final sphereODVal = double.tryParse(_sphereOD.text.replaceAll('+', '')) ?? 0;
    final sphereOGVal = double.tryParse(_sphereOG.text.replaceAll('+', '')) ?? 0;
    
    final nearOD = sphereODVal + addValue;
    final nearOG = sphereOGVal + addValue;
    
    _sphereODNear.text = nearOD >= 0 ? '+${nearOD.toStringAsFixed(2)}' : nearOD.toStringAsFixed(2);
    _sphereOGNear.text = nearOG >= 0 ? '+${nearOG.toStringAsFixed(2)}' : nearOG.toStringAsFixed(2);
    
    // Cylinder and axis stay the same for near vision
    _cylindreODNear.text = _cylindreOD.text;
    _axeODNear.text = _axeOD.text;
    _cylindreOGNear.text = _cylindreOG.text;
    _axeOGNear.text = _axeOG.text;
  }

  @override
  void dispose() {
    _sphereOD.dispose();
    _cylindreOD.dispose();
    _axeOD.dispose();
    _sphereOG.dispose();
    _cylindreOG.dispose();
    _axeOG.dispose();
    _sphereODNear.dispose();
    _cylindreODNear.dispose();
    _axeODNear.dispose();
    _sphereOGNear.dispose();
    _cylindreOGNear.dispose();
    _axeOGNear.dispose();
    super.dispose();
  }

  String get _today => DateFormat('dd/MM/yyyy').format(DateTime.now());
  String get _patientName => widget.patientName ?? 'Patient';
  String get _patientCode => widget.patientCode ?? '0';
  String get _barcode => widget.barcode ?? '00000000';
  String? get _age => widget.age;

  // ═══════════════════════════════════════════════════════════════════════════
  // PRINT METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showPrintResult(bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(success ? 'Impression envoyée' : 'Aucune imprimante connectée'),
      backgroundColor: success ? Colors.green : Colors.orange,
      duration: const Duration(seconds: 2),
    ));
    // Auto-close dialog after successful print
    if (success) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _printLoin() async {
    final success = await PrescriptionPrintService.printOptiqueLoin(
      patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
      sphereOD: _sphereOD.text, cylindreOD: _cylindreOD.text, axeOD: _axeOD.text,
      sphereOG: _sphereOG.text, cylindreOG: _cylindreOG.text, axeOG: _axeOG.text,
      glassType: _verresController.text.isNotEmpty ? _verresController.text : null, age: _age,
    );
    _showPrintResult(success);
  }

  Future<void> _printPres() async {
    final success = await PrescriptionPrintService.printOptiquePres(
      patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
      sphereOD: _sphereOD.text, cylindreOD: _cylindreOD.text, axeOD: _axeOD.text,
      sphereOG: _sphereOG.text, cylindreOG: _cylindreOG.text, axeOG: _axeOG.text,
      addition: widget.addition ?? '', glassType: _verresController.text.isNotEmpty ? _verresController.text : null, age: _age,
    );
    _showPrintResult(success);
  }

  Future<void> _printAll() async {
    final success = await PrescriptionPrintService.printOptiqueAll(
      patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
      sphereOD: _sphereOD.text, cylindreOD: _cylindreOD.text, axeOD: _axeOD.text,
      sphereOG: _sphereOG.text, cylindreOG: _cylindreOG.text, axeOG: _axeOG.text,
      addition: widget.addition ?? '', glassType: _verresController.text.isNotEmpty ? _verresController.text : null, age: _age,
    );
    _showPrintResult(success);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNLOAD METHODS
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _downloadLoin() async {
    try {
      final pdf = await PrescriptionPrintService.generateOptiqueLoinPdf(
        patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
        sphereOD: _sphereOD.text, cylindreOD: _cylindreOD.text, axeOD: _axeOD.text,
        sphereOG: _sphereOG.text, cylindreOG: _cylindreOG.text, axeOG: _axeOG.text,
        glassType: _verresController.text.isNotEmpty ? _verresController.text : null, age: _age,
      );
      final path = await PrescriptionPrintService.downloadPdf(pdf, 'Optique_Loin_$_barcode.pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF téléchargé: $path'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _downloadPres() async {
    try {
      final pdf = await PrescriptionPrintService.generateOptiquePresPdf(
        patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
        sphereOD: _sphereOD.text, cylindreOD: _cylindreOD.text, axeOD: _axeOD.text,
        sphereOG: _sphereOG.text, cylindreOG: _cylindreOG.text, axeOG: _axeOG.text,
        addition: widget.addition ?? '', glassType: _verresController.text.isNotEmpty ? _verresController.text : null, age: _age,
      );
      final path = await PrescriptionPrintService.downloadPdf(pdf, 'Optique_Pres_$_barcode.pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF téléchargé: $path'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _downloadAll() async {
    try {
      final pdf = await PrescriptionPrintService.generateOptiqueAllPdf(
        patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
        sphereOD: _sphereOD.text, cylindreOD: _cylindreOD.text, axeOD: _axeOD.text,
        sphereOG: _sphereOG.text, cylindreOG: _cylindreOG.text, axeOG: _axeOG.text,
        addition: widget.addition ?? '', glassType: _verresController.text.isNotEmpty ? _verresController.text : null, age: _age,
      );
      final path = await PrescriptionPrintService.downloadPdf(pdf, 'Optique_Complet_$_barcode.pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF téléchargé: $path'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if addition is valid (not null, not empty, and not "0" or "0.00")
    final additionStr = widget.addition ?? '';
    final additionValue = double.tryParse(additionStr.replaceAll('+', '')) ?? 0;
    final hasAddition = additionStr.isNotEmpty && additionValue != 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.remove_red_eye_outlined, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Prescription Optique', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
                  IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Distance Vision Section
                    _buildVisionSection(
                      title: '🔭 Vision de loin',
                      sphereOD: _sphereOD,
                      cylindreOD: _cylindreOD,
                      axeOD: _axeOD,
                      sphereOG: _sphereOG,
                      cylindreOG: _cylindreOG,
                      axeOG: _axeOG,
                      printLabel: 'Imprimer Loin',
                      onPrint: _printLoin,
                      onDownload: _downloadLoin,
                    ),
                    
                    // Near Vision Section (only if addition exists)
                    if (hasAddition) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: MediCoreColors.professionalBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: MediCoreColors.professionalBlue),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_circle, color: MediCoreColors.professionalBlue, size: 18),
                            const SizedBox(width: 8),
                            Text('ADDITION: ${widget.addition}', style: const TextStyle(fontWeight: FontWeight.bold, color: MediCoreColors.professionalBlue, fontSize: 14)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildVisionSection(
                        title: '📖 Vision de près',
                        sphereOD: _sphereODNear,
                        cylindreOD: _cylindreODNear,
                        axeOD: _axeODNear,
                        sphereOG: _sphereOGNear,
                        cylindreOG: _cylindreOGNear,
                        axeOG: _axeOGNear,
                        printLabel: 'Imprimer Près',
                        onPrint: _printPres,
                        onDownload: _downloadPres,
                      ),
                    ],
                    
                    // Type de verres
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MediCoreColors.steelOutline),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('🔍 Type de verres', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MediCoreColors.deepNavy)),
                          const SizedBox(height: 12),
                          Autocomplete<String>(
                            optionsBuilder: (textValue) {
                              if (textValue.text.isEmpty) return _verresOptions;
                              return _verresOptions.where((o) => o.toLowerCase().contains(textValue.text.toLowerCase()));
                            },
                            onSelected: (selection) => _verresController.text = selection,
                            fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
                              // Sync controllers
                              if (textController.text != _verresController.text) {
                                textController.text = _verresController.text;
                              }
                              textController.addListener(() => _verresController.text = textController.text);
                              return TextField(
                                controller: textController,
                                focusNode: focusNode,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                  hintText: 'Saisir ou sélectionner le type de verres...',
                                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onSubmitted: (value) {
                                  _saveCustomOption(value);
                                },
                                onEditingComplete: () {
                                  _saveCustomOption(textController.text);
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Print All buttons
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _printAll,
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Imprimer Tout'),
                          style: ElevatedButton.styleFrom(backgroundColor: MediCoreColors.professionalBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _downloadAll,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Télécharger Tout'),
                          style: OutlinedButton.styleFrom(foregroundColor: MediCoreColors.professionalBlue, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisionSection({
    required String title,
    required TextEditingController sphereOD,
    required TextEditingController cylindreOD,
    required TextEditingController axeOD,
    required TextEditingController sphereOG,
    required TextEditingController cylindreOG,
    required TextEditingController axeOG,
    required String printLabel,
    required VoidCallback onPrint,
    required VoidCallback onDownload,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MediCoreColors.steelOutline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: MediCoreColors.deepNavy)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildEyeColumn('👁️ Œil Droit (OD)', sphereOD, cylindreOD, axeOD, const Color(0xFF2E7D32))),
              const SizedBox(width: 20),
              Expanded(child: _buildEyeColumn('👁️ Œil Gauche (OG)', sphereOG, cylindreOG, axeOG, const Color(0xFF1565C0))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: onPrint,
                icon: const Icon(Icons.print, size: 16),
                label: Text(printLabel),
                style: OutlinedButton.styleFrom(foregroundColor: MediCoreColors.deepNavy),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: onDownload,
                icon: const Icon(Icons.download, size: 16),
                label: const Text('Télécharger'),
                style: OutlinedButton.styleFrom(foregroundColor: MediCoreColors.professionalBlue),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEyeColumn(String title, TextEditingController sphere, TextEditingController cylindre, TextEditingController axe, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: color)),
          const SizedBox(height: 12),
          _buildField('SPHÈRE', sphere),
          const SizedBox(height: 8),
          _buildField('CYLINDRE', cylindre),
          const SizedBox(height: 8),
          _buildField('AXE', axe),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Row(
      children: [
        SizedBox(width: 70, child: Text('$label:', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        Expanded(
          child: TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}
