import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/services/prescription_print_service.dart';

class PrescriptionLentillesDialog extends StatefulWidget {
  final String? vlOD; // VL from right eye
  final String? vlOG; // VL from left eye
  final String? patientName; // Patient name for printing
  final String? patientCode; // Patient code
  final String? barcode; // Patient barcode
  final String? age; // Patient age

  const PrescriptionLentillesDialog({super.key, this.vlOD, this.vlOG, this.patientName, this.patientCode, this.barcode, this.age});

  @override
  State<PrescriptionLentillesDialog> createState() => _PrescriptionLentillesDialogState();
}

class _PrescriptionLentillesDialogState extends State<PrescriptionLentillesDialog> {
  final _marqueController = TextEditingController();
  final _typeController = TextEditingController();
  bool _isToric = false; // false = Sphère Équivalente, true = Lentilles Toriques

  // OD fields
  final _puissanceOD = TextEditingController();
  final _diametreOD = TextEditingController();
  final _rayonOD = TextEditingController();
  final _cylindreOD = TextEditingController();
  final _axeOD = TextEditingController();

  // OG fields
  final _puissanceOG = TextEditingController();
  final _diametreOG = TextEditingController();
  final _rayonOG = TextEditingController();
  final _cylindreOG = TextEditingController();
  final _axeOG = TextEditingController();

  static const marqueOptions = ['Menicon', 'Bausch et Lomb', 'Precilens', 'LCS', 'Comelia'];
  static const typeOptions = [
    'Souple sphérique à port journalier',
    'Souple à port permanent',
    'Souple torique à port journalier',
    'Rigide perméable au gaz',
  ];

  @override
  void initState() {
    super.initState();
    _calculateFromVL();
  }

  /// Convert glasses power to contact lens power using vertex distance formula
  /// Only applies when power >= 4.00D
  /// F_lens = F_glasses / (1 - d × F_glasses) where d = 0.012 (12mm)
  double _vertexConversion(double glassesP) {
    const d = 0.012; // 12mm vertex distance in meters
    if (glassesP == 0) return 0;
    // Only convert if absolute power >= 4.00
    if (glassesP.abs() < 4.0) return glassesP;
    return glassesP / (1 - d * glassesP);
  }

  void _calculateFromVL() {
    // Parse VL values and calculate contact lens powers
    if (widget.vlOD != null && widget.vlOD!.isNotEmpty) {
      final parsed = _parseVLString(widget.vlOD!);
      _calculateForEye(parsed, _puissanceOD, _cylindreOD, _axeOD);
    }
    if (widget.vlOG != null && widget.vlOG!.isNotEmpty) {
      final parsed = _parseVLString(widget.vlOG!);
      _calculateForEye(parsed, _puissanceOG, _cylindreOG, _axeOG);
    }
  }

  void _calculateForEye(Map<String, String> parsed, TextEditingController puissance, TextEditingController cylindre, TextEditingController axe) {
    final sphereStr = parsed['sphere']?.replaceAll('+', '') ?? '0';
    final cylStr = parsed['cylindre']?.replaceAll('+', '') ?? '0';
    final axeStr = parsed['axe'] ?? '0°';

    final sphereVal = double.tryParse(sphereStr) ?? 0;
    final cylVal = double.tryParse(cylStr) ?? 0;

    if (_isToric) {
      // Lentilles Toriques: Combined string "SPH (CYL) × AXE°"
      final convertedSphere = _vertexConversion(sphereVal);
      final convertedCyl = _vertexConversion(cylVal);
      final sphFormatted = convertedSphere >= 0 ? '+${convertedSphere.toStringAsFixed(2)}' : convertedSphere.toStringAsFixed(2);
      
      if (cylVal != 0) {
        final cylFormatted = convertedCyl >= 0 ? '(+${convertedCyl.toStringAsFixed(2)})' : '(${convertedCyl.toStringAsFixed(2)})';
        puissance.text = '$sphFormatted $cylFormatted × $axeStr';
      } else {
        puissance.text = '$sphFormatted D';
      }
    } else {
      // Sphère Équivalente: Just the sphere (converted if >= 4.00D)
      final converted = _vertexConversion(sphereVal);
      final formatted = converted >= 0 ? '+${converted.toStringAsFixed(2)}' : converted.toStringAsFixed(2);
      puissance.text = '$formatted D';
    }
  }

  Map<String, String> _parseVLString(String vl) {
    final result = <String, String>{};
    final trimmed = vl.trim();
    
    if (trimmed.contains('(')) {
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

  void _recalculate() {
    _calculateFromVL();
    setState(() {});
  }

  String get _today => DateFormat('dd/MM/yyyy').format(DateTime.now());
  String get _patientName => widget.patientName ?? 'Patient';
  String get _patientCode => widget.patientCode ?? '0';
  String get _barcode => widget.barcode ?? '00000000';
  String? get _age => widget.age;

  Future<void> _print() async {
    final success = await PrescriptionPrintService.printLentilles(
      patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
      puissanceOD: _puissanceOD.text, diametreOD: _diametreOD.text, rayonOD: _rayonOD.text,
      puissanceOG: _puissanceOG.text, diametreOG: _diametreOG.text, rayonOG: _rayonOG.text,
      marque: _marqueController.text, type: _typeController.text, isToric: _isToric, age: _age,
    );
    if (mounted) {
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
  }

  Future<void> _download() async {
    try {
      final pdf = await PrescriptionPrintService.generateLentillesPdf(
        patientName: _patientName, patientCode: _patientCode, barcode: _barcode, date: _today,
        puissanceOD: _puissanceOD.text, diametreOD: _diametreOD.text, rayonOD: _rayonOD.text,
        puissanceOG: _puissanceOG.text, diametreOG: _diametreOG.text, rayonOG: _rayonOG.text,
        marque: _marqueController.text, type: _typeController.text, isToric: _isToric, age: _age,
      );
      final path = await PrescriptionPrintService.downloadPdf(pdf, 'Lentilles_$_barcode.pdf');
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF téléchargé: $path'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  void dispose() {
    _marqueController.dispose();
    _typeController.dispose();
    _puissanceOD.dispose();
    _diametreOD.dispose();
    _rayonOD.dispose();
    _cylindreOD.dispose();
    _axeOD.dispose();
    _puissanceOG.dispose();
    _diametreOG.dispose();
    _rayonOG.dispose();
    _cylindreOG.dispose();
    _axeOG.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 650,
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
                  const Icon(Icons.blur_circular, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Prescription de Lentilles de Contact', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold))),
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
                    // Marque & Type (editable dropdowns)
                    Row(
                      children: [
                        Expanded(child: _buildEditableDropdown('Marque', _marqueController, marqueOptions)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildEditableDropdown('Type', _typeController, typeOptions)),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Mode toggle
                    Container(
                      decoration: BoxDecoration(
                        color: MediCoreColors.canvasGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _buildModeButton('Sphère Équivalente', !_isToric, () { setState(() => _isToric = false); _recalculate(); })),
                          Expanded(child: _buildModeButton('Lentilles Toriques', _isToric, () { setState(() => _isToric = true); _recalculate(); })),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Eye data table
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: MediCoreColors.steelOutline),
                      ),
                      child: Column(
                        children: [
                          // Header row
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: const BoxDecoration(
                              color: MediCoreColors.deepNavy,
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7)),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(width: 100),
                                Expanded(child: Center(child: Text('👁️ Œil Droit (OD)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                                Expanded(child: Center(child: Text('👁️ Œil Gauche (OG)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)))),
                              ],
                            ),
                          ),
                          // Data rows - Puissance, Diamètre, Rayon only
                          _buildDataRow('Puissance', _puissanceOD, _puissanceOG),
                          _buildDataRow('Diamètre', _diametreOD, _diametreOG),
                          _buildDataRow('Rayon', _rayonOD, _rayonOG),
                        ],
                      ),
                    ),

                    // Action buttons
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _print,
                          icon: const Icon(Icons.print, size: 18),
                          label: const Text('Imprimer'),
                          style: ElevatedButton.styleFrom(backgroundColor: MediCoreColors.professionalBlue, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _download,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Télécharger'),
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

  Widget _buildEditableDropdown(String label, TextEditingController controller, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: MediCoreColors.deepNavy)),
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (textValue) {
            if (textValue.text.isEmpty) return options;
            return options.where((o) => o.toLowerCase().contains(textValue.text.toLowerCase()));
          },
          onSelected: (selection) => controller.text = selection,
          fieldViewBuilder: (context, textController, focusNode, onSubmitted) {
            // Sync controllers
            if (textController.text != controller.text) {
              textController.text = controller.text;
            }
            textController.addListener(() => controller.text = textController.text);
            return TextField(
              controller: textController,
              focusNode: focusNode,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Saisir ou sélectionner...',
                hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildModeButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? MediCoreColors.professionalBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : MediCoreColors.deepNavy,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, TextEditingController odController, TextEditingController ogController) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline.withOpacity(0.5)))),
      child: Row(
        children: [
          SizedBox(width: 88, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13))),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: odController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                filled: true,
                fillColor: const Color(0xFFE8F5E9),
              ),
            ),
          )),
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: ogController,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                filled: true,
                fillColor: const Color(0xFFE3F2FD),
              ),
            ),
          )),
        ],
      ),
    );
  }
}
