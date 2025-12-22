import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/services/prescription_print_service.dart';
import '../../../core/providers/app_providers.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../messages/presentation/receive_messages_dialog.dart';
import '../../comptabilite/presentation/comptabilite_dialog.dart';
import '../../consultation/presentation/prescription_optique_dialog.dart';
import '../../consultation/presentation/prescription_lentilles_dialog.dart';
import '../../../core/types/proto_types.dart';

/// Ordonnance Page - 3 tabs with different document types
class OrdonnancePage extends ConsumerStatefulWidget {
  final Patient patient;

  const OrdonnancePage({super.key, required this.patient});

  @override
  ConsumerState<OrdonnancePage> createState() => _OrdonnancePageState();
}

class _OrdonnancePageState extends ConsumerState<OrdonnancePage> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  late TabController _tabController;
  
  DateTime _selectedDate = DateTime.now();
  
  // ALL documents for patient (shown in every tab)
  List<OrdonnanceDocument> _allDocuments = [];
  int _currentDocIndex = 0;
  bool _isLoadingDocs = true;
  
  // SEPARATE new document state per tab
  DocumentData? _newDocTab1;  // Prescriptions
  DocumentData? _newDocTab2;  // Bilan
  DocumentData? _newDocTab3;  // Comptes
  bool _isCreatingNewTab1 = false;
  bool _isCreatingNewTab2 = false;
  bool _isCreatingNewTab3 = false;
  
  // Tab-specific type selections for NEW documents
  String _selectedPrescriptionType = 'ORDONNANCE';
  String _selectedBilanType = 'DEMANDE DE BILAN';
  String _selectedCompteType = 'COMPTE RENDU MEDICAL';
  
  // Search and print
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _printNameController = TextEditingController();
  final _printPrenomController = TextEditingController();
  final _printAgeController = TextEditingController();
  
  // Focus nodes for print fields (Enter key navigation)
  final _printNameFocus = FocusNode();
  final _printPrenomFocus = FocusNode();
  final _printAgeFocus = FocusNode();
  
  // Bilan shortcuts
  final _jourController = TextEditingController(text: '0');
  
  // Medications from DB
  List<Medication> _medications = [];
  bool _isLoadingMeds = true;
  
  // Templates CR from DB (only for Comptes tab)
  List<Map<String, dynamic>> _templatesCR = [];
  bool _isLoadingTemplates = true;

  static const bilanTypes = [
    'TOUS',  // Shows all medications without filtering
    'DEMANDE DE BILAN',
    'CERTIFICAT MEDICAL',
    'CERTIFICAT D\'ARRÊT DE TRAVAIL',
    'CERTIFICAT D\'ARRÊT DE SCOLARITE',
    'ORIENTATION',
    'REPONSE',
    'LENTILLES DE CONTACT',
    'CORRECTION OPTIQUE',
    'PROTOCOLE OPERATOIRE',
  ];

  static const compteTypes = [
    'COMPTE RENDU MEDICAL',
    'COMPTE RENDU',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadDocuments();
      _loadMedications();
      _loadTemplatesCR();
    });
  }

  /// Load documents from database
  Future<void> _loadDocuments() async {
    setState(() => _isLoadingDocs = true);
    try {
      final repo = ref.read(ordonnancesRepositoryProvider);
      final docs = await repo.getDocumentsForPatient(widget.patient.code);
      setState(() {
        _allDocuments = docs;
        _currentDocIndex = 0;
        _isLoadingDocs = false;
      });
    } catch (e) {
      setState(() => _isLoadingDocs = false);
    }
  }

  /// Load medications from database
  Future<void> _loadMedications() async {
    setState(() => _isLoadingMeds = true);
    try {
      final repo = ref.read(medicationsRepositoryProvider);
      final meds = _searchQuery.isEmpty 
          ? await repo.getAllSortedByUsage()
          : await repo.searchByCode(_searchQuery);
      setState(() {
        _medications = meds;
        _isLoadingMeds = false;
      });
    } catch (e) {
      setState(() => _isLoadingMeds = false);
    }
  }

  /// Get current document or null if creating new
  OrdonnanceDocument? get _currentDocument {
    final isCreating = _tabController.index == 0 ? _isCreatingNewTab1 
        : _tabController.index == 1 ? _isCreatingNewTab2 : _isCreatingNewTab3;
    if (isCreating || _allDocuments.isEmpty) return null;
    if (_currentDocIndex >= 0 && _currentDocIndex < _allDocuments.length) {
      return _allDocuments[_currentDocIndex];
    }
    return null;
  }

  /// Navigate to next/previous document
  void _navigateDoc(int delta) {
    if (_allDocuments.isEmpty) return;
    final newIndex = _currentDocIndex + delta;
    if (newIndex >= 0 && newIndex < _allDocuments.length) {
      setState(() {
        _currentDocIndex = newIndex;
        // Cancel creating on any tab when navigating
        _isCreatingNewTab1 = false;
        _isCreatingNewTab2 = false;
        _isCreatingNewTab3 = false;
      });
    }
  }

  /// Start creating a new document for current tab
  void _startNewDocumentForTab(int tabIndex, String type) {
    setState(() {
      if (tabIndex == 0) {
        _isCreatingNewTab1 = true;
        _newDocTab1 = DocumentData(type: type);
      } else if (tabIndex == 1) {
        _isCreatingNewTab2 = true;
        _newDocTab2 = DocumentData(type: type);
      } else {
        _isCreatingNewTab3 = true;
        _newDocTab3 = DocumentData(type: type);
      }
    });
  }

  /// Cancel creating for current tab
  void _cancelNewDocumentForTab(int tabIndex) {
    setState(() {
      if (tabIndex == 0) {
        _isCreatingNewTab1 = false;
        _newDocTab1 = null;
      } else if (tabIndex == 1) {
        _isCreatingNewTab2 = false;
        _newDocTab2 = null;
      } else {
        _isCreatingNewTab3 = false;
        _newDocTab3 = null;
      }
    });
  }

  /// Get new document for tab
  DocumentData? _getNewDocForTab(int tabIndex) {
    return tabIndex == 0 ? _newDocTab1 : tabIndex == 1 ? _newDocTab2 : _newDocTab3;
  }

  /// Check if creating new for tab
  bool _isCreatingForTab(int tabIndex) {
    return tabIndex == 0 ? _isCreatingNewTab1 : tabIndex == 1 ? _isCreatingNewTab2 : _isCreatingNewTab3;
  }

  /// Load templates CR from database (remote in client mode)
  Future<void> _loadTemplatesCR() async {
    setState(() => _isLoadingTemplates = true);
    try {
      // Client mode: use remote API
      if (!GrpcClientConfig.isServer) {
        final templates = await MediCoreClient.instance.getAllTemplatesCR();
        setState(() {
          _templatesCR = templates.map((t) => {
            'id': (t['id'] as num).toInt(),
            'code': t['code'] as String,
            'content': t['content'] as String,
            'usageCount': (t['usage_count'] as num?)?.toInt() ?? 0,
          }).toList();
          _isLoadingTemplates = false;
        });
        return;
      }
      // TODO: Implement templates in gRPC mode
      // final db = AppDatabase.instance;
      // final results = await db.customSelect(...).get();
      setState(() {
        _templatesCR = [];
        _isLoadingTemplates = false;
      });
    } catch (e) {
      setState(() => _isLoadingTemplates = false);
    }
  }

  /// Insert template CR into document
  void _insertTemplateCR(Map<String, dynamic> template) async {
    final tabIndex = _tabController.index;
    
    if (!_isCreatingForTab(tabIndex)) {
      _startNewDocumentForTab(tabIndex, _selectedCompteType);
    }
    
    final doc = _getNewDocForTab(tabIndex);
    if (doc == null) return;
    
    final currentText = doc.plainText;
    final content = template['content'] as String;
    final newContent = currentText.isEmpty ? content : '$currentText\n\n$content';
    doc.setPlainText(newContent);
    
    // Increment usage count
    final id = template['id'] as int;
    if (!GrpcClientConfig.isServer) {
      // Client mode: use remote API
      await MediCoreClient.instance.incrementTemplateCRUsage(id);
    } else {
      // Server mode: use local DB
      final db = await AppDatabase.instance.database;
      await db.rawUpdate('UPDATE templates_cr SET usage_count = usage_count + 1 WHERE id = ?', [id]);
    }
    _loadTemplatesCR();
    
    setState(() {});
  }

  /// Show dialog to add new medication
  void _showAddMedicationDialog() async {
    final codeController = TextEditingController();
    final prescriptionController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(children: [
          Icon(Icons.add_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('Ajouter un médicament'),
        ]),
        content: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: codeController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nom / Code',
                hintText: 'Ex: Paracetamol 500mg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: prescriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Prescription / Posologie',
                hintText: 'Ex: 1 comprimé 3 fois par jour pendant 5 jours',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
    
    if (result == true && codeController.text.trim().isNotEmpty) {
      final repo = ref.read(medicationsRepositoryProvider);
      await repo.addMedication(
        code: codeController.text.trim(),
        prescription: prescriptionController.text.trim(),
      );
      _loadMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Médicament ajouté'), backgroundColor: Colors.green),
        );
      }
    }
  }

  /// Save document to database
  Future<bool> _saveDocumentToDb(int tabIndex, String documentType, String content) async {
    try {
      final p = widget.patient;
      final doctorName = ref.read(authStateProvider).user?.name ?? 'Docteur';
      // Get next sequence number based on existing documents count
      final sequence = _allDocuments.length + 1;
      
      // Client mode: use remote API
      if (!GrpcClientConfig.isServer) {
        final result = await MediCoreClient.instance.createOrdonnance({
          'patient_code': p.code,
          'sequence': sequence,
          'document_date': _selectedDate.toIso8601String(),
          'content1': content,
          'type1': documentType,
          'doctor_name': doctorName,
        });
        if (result > 0) {
          _loadDocuments();
          return true;
        }
        return false;
      }
      
      // Admin mode: use local database
      final db = await AppDatabase.instance.database;
      final newId = await db.rawInsert(
        '''INSERT INTO ordonnances (patient_code, sequence, document_date, content1, type1, doctor_name, created_at)
           VALUES (?, ?, ?, ?, ?, ?, ?)''',
        [
          p.code,
          sequence,
          _selectedDate.toIso8601String(),
          content,
          documentType,
          doctorName,
          DateTime.now().toIso8601String(),
        ],
      );
      
      // Reload documents
      _loadDocuments();
      return true;
    } catch (e) {
      debugPrint('❌ Error saving to DB: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de sauvegarde: $e'), backgroundColor: Colors.red),
        );
      }
      return false;
    }
  }

  /// Strip separator lines for printing (keep spacing with newlines)
  String _stripSeparatorsForPrint(String text) {
    // Replace separator line with just blank line to keep spacing
    return text.replaceAll(RegExp(r'─+'), '').replaceAll(RegExp(r'\n\s*\n\s*\n'), '\n\n');
  }

  /// Insert text into the document for a specific tab
  void _insertTextIntoDoc(int tabIndex, String text) {
    final newDoc = _getNewDocForTab(tabIndex);
    if (newDoc == null) return;
    
    // Insert text at current cursor position using Quill
    newDoc.insertText(text);
    setState(() {});
  }

  /// Insert ART (Work) certificate template
  void _insertArtTravail(int tabIndex) {
    final jours = int.tryParse(_jourController.text) ?? 0;
    final joursText = jours == 0 ? 'zéro (0)' : '$jours (${_numberToFrench(jours)})';
    final doctorName = ref.read(authStateProvider).user?.name ?? 'Dr KARKOURI.N';
    
    final text = '''Je soussigné, $doctorName, certifie avoir examiné, ce jour, le sus-nommé

dont l'état de santé nécessite un arrêt de travail de :

$joursText jours à compter d'aujourd'hui.


Sauf complications.




                                                      Dont certificat.''';
    
    _insertTextIntoDoc(tabIndex, text);
  }

  /// Insert ART (School) certificate template
  void _insertArtScolaire(int tabIndex) {
    final jours = int.tryParse(_jourController.text) ?? 0;
    final joursText = jours == 0 ? 'zéro (0)' : '$jours (${_numberToFrench(jours)})';
    final doctorName = ref.read(authStateProvider).user?.name ?? 'Dr KARKOURI.N';
    
    final text = '''Je soussigné, $doctorName, certifie avoir examiné, ce jour, le sus-nommé

dont l'état de santé nécessite une éviction scolaire de :

$joursText jours à compter d'aujourd'hui.


Sauf complications.




                                                      Dont certificat.''';
    
    _insertTextIntoDoc(tabIndex, text);
  }

  /// Convert number to French text
  String _numberToFrench(int n) {
    const units = ['zéro', 'un', 'deux', 'trois', 'quatre', 'cinq', 'six', 'sept', 'huit', 'neuf', 'dix', 'onze', 'douze', 'treize', 'quatorze', 'quinze', 'seize', 'dix-sept', 'dix-huit', 'dix-neuf', 'vingt'];
    if (n <= 20) return units[n];
    if (n < 30) return 'vingt-${units[n - 20]}';
    if (n < 40) return 'trente${n == 30 ? '' : '-${units[n - 30]}'}';
    if (n < 50) return 'quarante${n == 40 ? '' : '-${units[n - 40]}'}';
    if (n < 60) return 'cinquante${n == 50 ? '' : '-${units[n - 50]}'}';
    if (n < 70) return 'soixante${n == 60 ? '' : '-${units[n - 60]}'}';
    if (n < 80) return 'soixante-${units[n - 60]}';
    if (n < 90) return 'quatre-vingt${n == 80 ? 's' : '-${units[n - 80]}'}';
    if (n < 100) return 'quatre-vingt-${units[n - 80]}';
    return '$n';
  }

  /// Delete the current viewed document
  Future<void> _deleteCurrentDocument(OrdonnanceDocument doc) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le document?'),
        content: Text('Voulez-vous vraiment supprimer ce document du ${doc.formattedDate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('SUPPRIMER'),
          ),
        ],
      ),
    );
    
    if (confirmed != true) return;
    
    try {
      // Client mode: use remote API
      if (!GrpcClientConfig.isServer) {
        await MediCoreClient.instance.deleteOrdonnance(doc.id);
      } else {
        // Admin mode: use local database
        final db = AppDatabase.instance;
        await db.customStatement('DELETE FROM ordonnances WHERE id = ?', [doc.id]);
      }
      
      // Reload documents and reset index if needed
      _loadDocuments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Document supprimé'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  /// Print document - saves to DB first, uses "print with another name" fields if filled
  /// Tab 0 & 1 use A5, Tab 2 (Comptes) uses A4 - all same format, no background image
  Future<void> _printDocumentTab(int tabIndex, String documentType) async {
    final newDoc = _getNewDocForTab(tabIndex);
    if (newDoc == null || newDoc.plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rien à imprimer'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    // Only save if not already saved OR if content was edited
    bool didSave = false;
    if (!newDoc.isSaved || newDoc.wasEdited) {
      final saveSuccess = await _saveDocumentToDb(tabIndex, documentType, newDoc.plainText);
      if (!saveSuccess) {
        // Save failed - error already shown by _saveDocumentToDb
        return;
      }
      newDoc.markSaved();
      didSave = true;
    }
    
    // Strip separators for printing
    final printContent = _stripSeparatorsForPrint(newDoc.plainText);
    
    final p = widget.patient;
    
    // Tab 2 (Compte Rendu) uses A4, others use A5 - same format, no image
    final bool success = await PrescriptionPrintService.printOrdonnance(
      patientName: '${p.firstName} ${p.lastName}',
      patientCode: p.code.toString(),
      barcode: p.code.toString(),
      date: DateFormat('dd/MM/yyyy').format(_selectedDate),
      content: printContent,
      documentType: documentType,
      printName: _printNameController.text.isNotEmpty ? _printNameController.text : null,
      printPrenom: _printPrenomController.text.isNotEmpty ? _printPrenomController.text : null,
      printAge: _printAgeController.text.isNotEmpty ? _printAgeController.text : null,
      age: p.age?.toString(),
      useA4: tabIndex == 2, // Only Compte Rendu uses A4
    );
    
    // Clear print with another name fields after printing
    _printNameController.clear();
    _printPrenomController.clear();
    _printAgeController.clear();
    
    if (mounted) {
      final msg = success 
          ? (didSave ? 'Document sauvegardé et impression envoyée' : 'Impression envoyée')
          : (didSave ? 'Document sauvegardé, aucune imprimante' : 'Aucune imprimante connectée');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: success ? Colors.green : Colors.orange,
      ));
    }
  }

  /// Download document as PDF
  /// Tab 0 & 1 use A5, Tab 2 (Comptes) uses A4 - all same format, no background image
  Future<void> _downloadDocument(int tabIndex, String documentType) async {
    final newDoc = _getNewDocForTab(tabIndex);
    if (newDoc == null || newDoc.plainText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rien à télécharger'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    // Strip separators for PDF
    final pdfContent = _stripSeparatorsForPrint(newDoc.plainText);
    
    try {
      final p = widget.patient;
      
      // Tab 2 (Compte Rendu) uses A4, others use A5 - same format, no image
      final Uint8List pdf = await PrescriptionPrintService.generateOrdonnancePdf(
        patientName: '${p.firstName} ${p.lastName}',
        patientCode: p.code.toString(),
        barcode: p.code.toString(),
        date: DateFormat('dd/MM/yyyy').format(_selectedDate),
        content: pdfContent,
        documentType: documentType,
        printName: _printNameController.text.isNotEmpty ? _printNameController.text : null,
        printPrenom: _printPrenomController.text.isNotEmpty ? _printPrenomController.text : null,
        printAge: _printAgeController.text.isNotEmpty ? _printAgeController.text : null,
        age: p.age?.toString(),
        useA4: tabIndex == 2, // Only Compte Rendu uses A4
      );
      
      // Clean filename: replace spaces and special chars
      final cleanType = documentType.replaceAll(' ', '_').replaceAll("'", '');
      final path = await PrescriptionPrintService.downloadPdf(pdf, '${cleanType}_${p.code}.pdf');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF téléchargé: $path'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL: MEDICATIONS (Tab 1 & 2)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildMedicinePanel() {
    final meds = _filteredMedications;
    return Container(
      decoration: BoxDecoration(color: MediCoreColors.paperWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: MediCoreColors.steelOutline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(height: 50, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF1976D2)]), borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7))), padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [
          const Icon(Icons.medication, color: Colors.white, size: 20), 
          const SizedBox(width: 12), 
          const Text('MÉDICAMENTS', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)), 
          const Spacer(),
          // Add new medication button
          Material(
            color: Colors.green.shade600,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: _showAddMedicationDialog,
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.add, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('AJOUTER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('${meds.length}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ])),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: const BoxDecoration(color: Color(0xFFE3F2FD), border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline))),
          child: TextField(
            controller: _searchController, 
            onChanged: (v) {
              setState(() => _searchQuery = v);
              _loadMedications();
            }, 
            style: const TextStyle(fontSize: 14), 
            decoration: InputDecoration(
              hintText: 'Tapez pour filtrer...', 
              prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0), size: 20), 
              suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { 
                _searchController.clear(); 
                setState(() => _searchQuery = ''); 
                _loadMedications();
              }) : null, 
              filled: true, 
              fillColor: Colors.white, 
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)), 
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ),
        Container(height: 36, color: const Color(0xFFECEFF1), padding: const EdgeInsets.symmetric(horizontal: 12), child: const Row(children: [Expanded(flex: 5, child: Text('NOM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 50, child: Text('N°', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center))])),
        Expanded(
          child: _isLoadingMeds 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: meds.length,
                itemBuilder: (_, i) {
                  final m = meds[i];
                  return GestureDetector(
                    onDoubleTap: () => _insertMedication(m),
                    onLongPress: () => _showEditMedicationDialog(m),
                    onSecondaryTap: () => _showEditMedicationDialog(m),
                    child: Container(
                      height: 40, 
                      padding: const EdgeInsets.symmetric(horizontal: 12), 
                      decoration: BoxDecoration(color: i % 2 == 0 ? Colors.white : const Color(0xFFF5F5F5), border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5))), 
                      child: Row(children: [
                        Expanded(flex: 5, child: Text(m.code, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        // Edit button
                        InkWell(
                          onTap: () => _showEditMedicationDialog(m),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.edit, size: 14, color: Colors.grey.shade600),
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onDoubleTap: () => _editMedicationCount(m),
                          child: Container(
                            width: 40, 
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), 
                            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), borderRadius: BorderRadius.circular(10)), 
                            child: Text('${m.usageCount}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)), textAlign: TextAlign.center),
                          ),
                        ),
                      ]),
                    ),
                  );
                },
              ),
        ),
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFFE8F5E9), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7))), child: Row(children: [Icon(Icons.info_outline, color: Colors.green.shade700, size: 16), const SizedBox(width: 8), Expanded(child: Text('Double-clic: insérer | ✏️: modifier | Clic droit: éditer', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontStyle: FontStyle.italic)))])),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // RIGHT PANEL: MODÈLES CR (only for Comptes tab)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildTemplatePanel() {
    return Container(
      decoration: BoxDecoration(color: MediCoreColors.paperWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: MediCoreColors.steelOutline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(height: 50, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF7B1FA2), Color(0xFF9C27B0)]), borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7))), padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(children: [const Icon(Icons.description, color: Colors.white, size: 20), const SizedBox(width: 12), const Text('MODÈLES CR', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1)), const Spacer(), Text('${_templatesCR.length}', style: const TextStyle(color: Colors.white70, fontSize: 12))])),
        Container(height: 36, color: const Color(0xFFF3E5F5), padding: const EdgeInsets.symmetric(horizontal: 12), child: const Row(children: [Expanded(flex: 5, child: Text('NOM', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))), SizedBox(width: 40, child: Text('N°', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold), textAlign: TextAlign.center))])),
        Expanded(
          child: _isLoadingTemplates 
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _templatesCR.length,
                itemBuilder: (_, i) {
                  final t = _templatesCR[i];
                  return InkWell(
                    onDoubleTap: () => _insertTemplateCR(t),
                    child: Container(
                      height: 44, 
                      padding: const EdgeInsets.symmetric(horizontal: 12), 
                      decoration: BoxDecoration(color: i % 2 == 0 ? Colors.white : const Color(0xFFFAF5FC), border: const Border(bottom: BorderSide(color: Color(0xFFE0E0E0), width: 0.5))), 
                      child: Row(children: [
                        Expanded(flex: 5, child: Text(t['code'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
                        Container(
                          width: 40, 
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2), 
                          decoration: BoxDecoration(color: const Color(0xFFE1BEE7), borderRadius: BorderRadius.circular(10)), 
                          child: Text('${t['usageCount']}', style: const TextStyle(fontSize: 10, color: Color(0xFF7B1FA2), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                        ),
                      ]),
                    ),
                  );
                },
              ),
        ),
        Container(padding: const EdgeInsets.all(12), decoration: const BoxDecoration(color: Color(0xFFF3E5F5), borderRadius: BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7))), child: Row(children: [Icon(Icons.info_outline, color: Colors.purple.shade700, size: 16), const SizedBox(width: 8), Text('Double-clic pour insérer', style: TextStyle(color: Colors.purple.shade700, fontSize: 11, fontStyle: FontStyle.italic))])),
      ]),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      height: 56,
      decoration: const BoxDecoration(color: MediCoreColors.deepNavy, border: Border(top: BorderSide(color: MediCoreColors.steelOutline, width: 2))),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _CompactBtn(icon: Icons.send, label: 'ENVOYER', onPressed: _showSendMessageDialog),
        const SizedBox(width: 8),
        _CompactBtn(icon: Icons.inbox, label: 'RECEVOIR', onPressed: _showReceiveMessagesDialog),
        const SizedBox(width: 16),
        Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
        const SizedBox(width: 16),
        _CompactBtn(icon: Icons.preview, label: 'OPTIQUE', onPressed: _showOptiqueDialog),
        const SizedBox(width: 8),
        _CompactBtn(icon: Icons.blur_circular, label: 'LENTILLES', onPressed: _showLentillesDialog),
        const SizedBox(width: 8),
        _CompactBtn(icon: Icons.description_outlined, label: 'ORDO', onPressed: () {}, isActive: true),
        const SizedBox(width: 16),
        Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
        const SizedBox(width: 16),
        _CompactBtn(icon: Icons.account_balance_wallet, label: 'F5', onPressed: _showComptabiliteDialog, color: const Color(0xFF7B1FA2)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// RICH TEXT EDITOR WITH SELECTION-BASED FORMATTING
// ═══════════════════════════════════════════════════════════════════════════════

class _RichTextEditor extends StatefulWidget {
  final DocumentData doc;
  final VoidCallback onChanged;
  
  const _RichTextEditor({required this.doc, required this.onChanged});
  
  @override
  State<_RichTextEditor> createState() => _RichTextEditorState();
}

class _RichTextEditorState extends State<_RichTextEditor> {
  late FocusNode _focusNode;
  TextSelection _lastSelection = const TextSelection.collapsed(offset: 0);
  
  static const fonts = ['Arial', 'Times New Roman', 'Courier New', 'Georgia', 'Verdana', 'Tahoma', 'Helvetica'];
  static const sizes = [8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0, 72.0];
  static const colorOptions = [
    Colors.black, Color(0xFF424242), Color(0xFF757575), Colors.white,
    Color(0xFFC62828), Color(0xFFE53935), Color(0xFFEF5350), Color(0xFFFFCDD2),
    Color(0xFF1565C0), Color(0xFF1E88E5), Color(0xFF42A5F5), Color(0xFFBBDEFB),
    Color(0xFF2E7D32), Color(0xFF43A047), Color(0xFF66BB6A), Color(0xFFC8E6C9),
    Color(0xFFF57F17), Color(0xFFFFC107), Color(0xFFFFEB3B), Color(0xFFFFF9C4),
    Color(0xFF6A1B9A), Color(0xFF8E24AA), Color(0xFFAB47BC), Color(0xFFE1BEE7),
    Color(0xFF00838F), Color(0xFF00ACC1), Color(0xFF26C6DA), Color(0xFFB2EBF2),
    Color(0xFFD84315), Color(0xFFFF5722), Color(0xFFFF8A65), Color(0xFFFFCCBC),
  ];
  
  DocumentData get _doc => widget.doc;
  
  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _doc.controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    _doc.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }
  
  void _onTextChanged() {
    // Sync styles when text changes
    _doc._syncStyles();
  }
  
  TextSelection get _selection => _doc.controller.selection;
  bool get _hasSelection => _selection.isValid && _selection.start != _selection.end;
  
  void _applyFormat(CharStyle Function(CharStyle) modifier) {
    if (_hasSelection) {
      // Apply to selection only
      _doc.applyStyleToSelection(_selection.start, _selection.end, modifier);
    }
    // Always update current style for future typing
    _doc.currentStyle = modifier(_doc.currentStyle);
    
    // Force controller to rebuild text spans by triggering notifyListeners
    // This is done by setting text to itself with selection preserved
    final sel = _doc.controller.selection;
    final text = _doc.controller.text;
    _doc.controller.value = TextEditingValue(text: text, selection: sel);
    
    widget.onChanged();
    setState(() {});
  }
  
  void _setFontFamily(String font) {
    _applyFormat((s) => s.copyWith(fontFamily: font));
  }
  
  void _setFontSize(double size) {
    _applyFormat((s) => s.copyWith(fontSize: size));
  }
  
  void _toggleBold() {
    final willBeBold = _hasSelection 
        ? !_doc.selectionHasStyle(_selection.start, _selection.end, (s) => s.isBold)
        : !_doc.currentStyle.isBold;
    _applyFormat((s) => s.copyWith(isBold: willBeBold));
  }
  
  void _toggleItalic() {
    final willBeItalic = _hasSelection 
        ? !_doc.selectionHasStyle(_selection.start, _selection.end, (s) => s.isItalic)
        : !_doc.currentStyle.isItalic;
    _applyFormat((s) => s.copyWith(isItalic: willBeItalic));
  }
  
  void _toggleUnderline() {
    final willBeUnderline = _hasSelection 
        ? !_doc.selectionHasStyle(_selection.start, _selection.end, (s) => s.isUnderline)
        : !_doc.currentStyle.isUnderline;
    _applyFormat((s) => s.copyWith(isUnderline: willBeUnderline));
  }
  
  void _setColor(Color color) {
    _applyFormat((s) => s.copyWith(textColor: color));
  }
  
  void _clearFormatting() {
    if (_hasSelection) {
      _doc.applyStyleToSelection(_selection.start, _selection.end, (_) => const CharStyle());
    }
    _doc.currentStyle = const CharStyle();
    _doc.alignment = TextAlign.left;
    widget.onChanged();
    setState(() {});
  }
  
  bool get _isBoldActive => _hasSelection 
      ? _doc.selectionHasStyle(_selection.start, _selection.end, (s) => s.isBold)
      : _doc.currentStyle.isBold;
  
  bool get _isItalicActive => _hasSelection 
      ? _doc.selectionHasStyle(_selection.start, _selection.end, (s) => s.isItalic)
      : _doc.currentStyle.isItalic;
  
  bool get _isUnderlineActive => _hasSelection 
      ? _doc.selectionHasStyle(_selection.start, _selection.end, (s) => s.isUnderline)
      : _doc.currentStyle.isUnderline;
  
  String get _currentFont => _hasSelection && _selection.start < _doc.charStyles.length
      ? _doc.getStyleAt(_selection.start).fontFamily
      : _doc.currentStyle.fontFamily;
  
  double get _currentSize => _hasSelection && _selection.start < _doc.charStyles.length
      ? _doc.getStyleAt(_selection.start).fontSize
      : _doc.currentStyle.fontSize;
  
  Color get _currentColor => _hasSelection && _selection.start < _doc.charStyles.length
      ? _doc.getStyleAt(_selection.start).textColor
      : _doc.currentStyle.textColor;
  
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // Toolbar Row 1: Font, Size, Bold, Italic, Underline, Color
      Container(
        decoration: const BoxDecoration(color: Color(0xFFF8F9FA), border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          _buildFontDropdown(),
          const SizedBox(width: 6),
          _buildSizeDropdown(),
          _buildDivider(),
          _buildFormatBtn(Icons.format_bold, _isBoldActive, _toggleBold, 'Gras'),
          _buildFormatBtn(Icons.format_italic, _isItalicActive, _toggleItalic, 'Italique'),
          _buildFormatBtn(Icons.format_underline, _isUnderlineActive, _toggleUnderline, 'Souligné'),
          _buildDivider(),
          _buildColorBtn(),
          _buildDivider(),
          _buildFormatBtn(Icons.format_strikethrough, false, () {}, 'Barré'),
          _buildHighlightBtn(),
        ]),
      ),
      // Toolbar Row 2: Alignment, Lists, Special
      Container(
        decoration: const BoxDecoration(color: Color(0xFFF8F9FA), border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline))),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(children: [
          _buildAlignBtn(Icons.format_align_left, TextAlign.left),
          _buildAlignBtn(Icons.format_align_center, TextAlign.center),
          _buildAlignBtn(Icons.format_align_right, TextAlign.right),
          _buildAlignBtn(Icons.format_align_justify, TextAlign.justify),
          _buildDivider(),
          _buildActionBtn(Icons.format_list_bulleted, () => _doc.insertText('\n• '), 'Liste à puces'),
          _buildActionBtn(Icons.format_list_numbered, () { _doc.insertText('\n1. '); widget.onChanged(); }, 'Liste numérotée'),
          _buildDivider(),
          _buildActionBtn(Icons.horizontal_rule, () { _doc.insertText('\n────────────────────────────────────\n'); widget.onChanged(); }, 'Ligne'),
          _buildActionBtn(Icons.format_indent_increase, () { _doc.insertText('    '); widget.onChanged(); }, 'Indentation'),
          _buildDivider(),
          _buildActionBtn(Icons.format_clear, _clearFormatting, 'Effacer formatage'),
          const Spacer(),
          // Selection indicator
          if (_hasSelection)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF1565C0).withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
              child: Text('${_selection.end - _selection.start} sélectionnés', style: const TextStyle(fontSize: 10, color: Color(0xFF1565C0))),
            ),
        ]),
      ),
      // Editor area
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: MediCoreColors.steelOutline),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: _buildEditableArea(),
          ),
        ),
      ),
    ]);
  }
  
  Widget _buildEditableArea() {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - 32, minWidth: constraints.maxWidth - 32),
          child: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            behavior: HitTestBehavior.translucent,
            child: _buildRichTextField(),
          ),
        ),
      );
    });
  }
  
  Widget _buildRichTextField() {
    return TextField(
      controller: _doc.controller,
      focusNode: _focusNode,
      maxLines: null,
      textAlign: _doc.alignment,
      // Don't set style here - the controller's buildTextSpan handles it
      decoration: InputDecoration(
        hintText: 'Saisir le contenu du document...',
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
        border: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
      onChanged: (text) {
        // Handle text input - sync styles with text length
        _handleTextChange(text);
      },
      buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
      onTap: () => setState(() {}),
    );
  }
  
  void _handleTextChange(String newText) {
    final oldLength = _doc.charStyles.length;
    final newLength = newText.length;
    final cursorPos = _doc.controller.selection.baseOffset;
    
    if (newLength > oldLength) {
      // Text was added - insert styles at cursor position
      final addedCount = newLength - oldLength;
      final insertPos = (cursorPos - addedCount).clamp(0, _doc.charStyles.length);
      final newStyles = List.filled(addedCount, _doc.currentStyle);
      _doc.charStyles.insertAll(insertPos, newStyles);
    } else if (newLength < oldLength) {
      // Text was deleted - remove styles at deletion point
      final deletedCount = oldLength - newLength;
      final deleteStart = cursorPos.clamp(0, _doc.charStyles.length - deletedCount);
      if (deleteStart >= 0 && deleteStart + deletedCount <= _doc.charStyles.length) {
        _doc.charStyles.removeRange(deleteStart, deleteStart + deletedCount);
      } else {
        // Fallback: just trim to new length
        _doc.charStyles = _doc.charStyles.sublist(0, newLength.clamp(0, _doc.charStyles.length));
      }
    }
    
    // Ensure sync
    _doc._syncStyles();
    widget.onChanged();
  }
  
  Widget _buildFontDropdown() {
    final font = fonts.contains(_currentFont) ? _currentFont : 'Arial';
    return Container(
      width: 130, height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBDBDBD))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: font,
          isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          items: fonts.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: f, fontSize: 11)))).toList(),
          onChanged: (v) { if (v != null) _setFontFamily(v); },
        ),
      ),
    );
  }
  
  Widget _buildSizeDropdown() {
    final size = sizes.contains(_currentSize) ? _currentSize : 14.0;
    return Container(
      width: 60, height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBDBDBD))),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<double>(
          value: size,
          isExpanded: true, isDense: true,
          style: const TextStyle(fontSize: 11, color: Colors.black87),
          icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
          items: sizes.map((s) => DropdownMenuItem(value: s, child: Text('${s.toInt()}'))).toList(),
          onChanged: (v) { if (v != null) _setFontSize(v); },
        ),
      ),
    );
  }
  
  Widget _buildDivider() => Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6), color: const Color(0xFFBDBDBD));
  
  Widget _buildFormatBtn(IconData icon, bool active, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: active ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28, height: 28, alignment: Alignment.center,
            decoration: active ? BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF1565C0))) : null,
            child: Icon(icon, size: 18, color: active ? const Color(0xFF1565C0) : const Color(0xFF424242)),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAlignBtn(IconData icon, TextAlign align) {
    final active = _doc.alignment == align;
    return Tooltip(
      message: align == TextAlign.left ? 'Gauche' : align == TextAlign.center ? 'Centrer' : align == TextAlign.right ? 'Droite' : 'Justifier',
      child: Material(
        color: active ? const Color(0xFFE3F2FD) : Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: () { setState(() => _doc.alignment = align); widget.onChanged(); },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28, height: 28, alignment: Alignment.center,
            decoration: active ? BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF1565C0))) : null,
            child: Icon(icon, size: 18, color: active ? const Color(0xFF1565C0) : const Color(0xFF424242)),
          ),
        ),
      ),
    );
  }
  
  Widget _buildActionBtn(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(width: 28, height: 28, alignment: Alignment.center, child: Icon(icon, size: 18, color: const Color(0xFF424242))),
        ),
      ),
    );
  }
  
  Widget _buildColorBtn() {
    return Tooltip(
      message: 'Couleur du texte',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showColorPicker,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28, height: 28, alignment: Alignment.center,
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.format_color_text, size: 16, color: Color(0xFF424242)),
              Container(height: 3, width: 16, decoration: BoxDecoration(color: _currentColor, borderRadius: BorderRadius.circular(1))),
            ]),
          ),
        ),
      ),
    );
  }
  
  Widget _buildHighlightBtn() {
    return Tooltip(
      message: 'Surligner',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showHighlightPicker,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 28, height: 28, alignment: Alignment.center,
            child: const Icon(Icons.highlight, size: 18, color: Color(0xFF424242)),
          ),
        ),
      ),
    );
  }
  
  void _showColorPicker() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(children: [Icon(Icons.palette, color: Color(0xFF1565C0)), SizedBox(width: 8), Text('Couleur du texte')]),
        content: SizedBox(
          width: 280,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(
              spacing: 6, runSpacing: 6,
              children: colorOptions.map((col) => InkWell(
                onTap: () { _setColor(col); Navigator.pop(c); },
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: col,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: col == _currentColor ? const Color(0xFF1565C0) : Colors.grey.shade300, width: col == _currentColor ? 2 : 1),
                    boxShadow: col == Colors.white ? [BoxShadow(color: Colors.grey.shade300, blurRadius: 1)] : null,
                  ),
                ),
              )).toList(),
            ),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
        ],
      ),
    );
  }
  
  void _showHighlightPicker() {
    final highlights = [Colors.yellow, Colors.lime, Colors.cyan, Colors.pink, Colors.orange, Colors.transparent];
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(children: [Icon(Icons.highlight, color: Color(0xFFFFC107)), SizedBox(width: 8), Text('Surlignage')]),
        content: SizedBox(
          width: 200,
          child: Wrap(
            spacing: 8, runSpacing: 8,
            children: highlights.map((col) => InkWell(
              onTap: () { Navigator.pop(c); },
              child: Container(
                width: 32, height: 32,
                decoration: BoxDecoration(
                  color: col == Colors.transparent ? Colors.white : col.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: col == Colors.transparent ? const Icon(Icons.block, size: 16, color: Colors.grey) : null,
              ),
            )).toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Annuler')),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// HELPER WIDGETS & DATA
// ═══════════════════════════════════════════════════════════════════════════════

class _InfoChip extends StatelessWidget { final IconData icon; final String label; const _InfoChip({required this.icon, required this.label}); @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white70, size: 14), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12))])); }
class _CompactBtn extends StatelessWidget { final IconData icon; final String label; final VoidCallback onPressed; final Color? color; final bool isActive; const _CompactBtn({required this.icon, required this.label, required this.onPressed, this.color, this.isActive = false}); @override Widget build(BuildContext context) { final c = color ?? MediCoreColors.professionalBlue; return Material(color: isActive ? c : c.withOpacity(0.3), borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))])))); } }
class _NavBtn extends StatelessWidget { final IconData icon; final VoidCallback onTap; const _NavBtn({required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Material(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4), child: Container(width: 28, height: 28, alignment: Alignment.center, child: Icon(icon, color: Colors.white, size: 20)))); }
class _EyeChip extends StatelessWidget { final String label; final bool isSelected; final VoidCallback onTap; final Color color; const _EyeChip({required this.label, required this.isSelected, required this.onTap, required this.color}); @override Widget build(BuildContext context) => Material(color: isSelected ? color : Colors.white, borderRadius: BorderRadius.circular(20), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : MediCoreColors.steelOutline, width: 1.5)), child: Text(label, style: TextStyle(color: isSelected ? Colors.white : MediCoreColors.deepNavy, fontSize: 12, fontWeight: FontWeight.w600))))); }
class _EyeChipWithInsert extends StatelessWidget { final String label; final bool isSelected; final VoidCallback onTap; final VoidCallback onDoubleTap; final Color color; const _EyeChipWithInsert({required this.label, required this.isSelected, required this.onTap, required this.onDoubleTap, required this.color}); @override Widget build(BuildContext context) => Tooltip(message: 'Double-clic pour insérer', child: Material(color: isSelected ? color : Colors.white, borderRadius: BorderRadius.circular(20), child: InkWell(onTap: onTap, onDoubleTap: onDoubleTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: isSelected ? color : MediCoreColors.steelOutline, width: 1.5)), child: Text(label, style: TextStyle(color: isSelected ? Colors.white : MediCoreColors.deepNavy, fontSize: 12, fontWeight: FontWeight.w600)))))); }
class _SmallField extends StatelessWidget { final TextEditingController controller; final String label; final FocusNode? focusNode; final FocusNode? nextFocus; const _SmallField({required this.controller, required this.label, this.focusNode, this.nextFocus}); @override Widget build(BuildContext context) => TextField(controller: controller, focusNode: focusNode, style: const TextStyle(fontSize: 13), textInputAction: nextFocus != null ? TextInputAction.next : TextInputAction.done, onSubmitted: (_) { if (nextFocus != null) nextFocus!.requestFocus(); }, decoration: InputDecoration(labelText: label, labelStyle: const TextStyle(fontSize: 11, color: Colors.grey), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)), contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), isDense: true)); }
class _ToolbarBtn extends StatelessWidget { final IconData icon; final VoidCallback onTap; const _ToolbarBtn({required this.icon, required this.onTap}); @override Widget build(BuildContext context) => Material(color: Colors.transparent, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(4), child: Container(width: 32, height: 32, alignment: Alignment.center, child: Icon(icon, size: 20, color: const Color(0xFF424242))))); }
class _ActionBtn extends StatelessWidget { final IconData icon; final String label; final Color color; final VoidCallback onTap; final bool large; const _ActionBtn({required this.icon, required this.label, required this.color, required this.onTap, this.large = false}); @override Widget build(BuildContext context) => Material(color: color, borderRadius: BorderRadius.circular(6), elevation: 2, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(6), child: Container(padding: EdgeInsets.symmetric(horizontal: large ? 24 : 12, vertical: 10), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(label, style: TextStyle(color: Colors.white, fontSize: large ? 13 : 12, fontWeight: FontWeight.w600))])))); }

/// Rich text character style
class CharStyle {
  final String fontFamily;
  final double fontSize;
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final Color textColor;
  
  const CharStyle({
    this.fontFamily = 'Arial',
    this.fontSize = 14,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColor = Colors.black,
  });
  
  CharStyle copyWith({
    String? fontFamily,
    double? fontSize,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    Color? textColor,
  }) {
    return CharStyle(
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      textColor: textColor ?? this.textColor,
    );
  }
  
  TextStyle toTextStyle() {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isUnderline ? TextDecoration.underline : TextDecoration.none,
      color: textColor,
    );
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CharStyle &&
        other.fontFamily == fontFamily &&
        other.fontSize == fontSize &&
        other.isBold == isBold &&
        other.isItalic == isItalic &&
        other.isUnderline == isUnderline &&
        other.textColor == textColor;
  }
  
  @override
  int get hashCode => Object.hash(fontFamily, fontSize, isBold, isItalic, isUnderline, textColor);
}

/// Custom TextEditingController that displays styled text
class RichTextEditingController extends TextEditingController {
  final DocumentData Function() getDoc;
  
  RichTextEditingController({required this.getDoc});
  
  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final doc = getDoc();
    final text = this.text;
    
    if (text.isEmpty || doc.charStyles.isEmpty) {
      return TextSpan(text: text, style: style ?? doc.currentStyle.toTextStyle());
    }
    
    doc._syncStyles();
    
    final spans = <TextSpan>[];
    int spanStart = 0;
    CharStyle lastStyle = doc.charStyles.isNotEmpty ? doc.charStyles[0] : doc.currentStyle;
    
    for (int i = 0; i <= text.length; i++) {
      final currentCharStyle = i < doc.charStyles.length ? doc.charStyles[i] : doc.currentStyle;
      if (i == text.length || currentCharStyle != lastStyle) {
        if (spanStart < i) {
          spans.add(TextSpan(
            text: text.substring(spanStart, i),
            style: lastStyle.toTextStyle(),
          ));
        }
        spanStart = i;
        lastStyle = currentCharStyle;
      }
    }
    
    return TextSpan(children: spans.isEmpty ? [TextSpan(text: text, style: doc.currentStyle.toTextStyle())] : spans);
  }
}

class DocumentData {
  String type;
  String eyeSelection = 'BOTH';
  late final RichTextEditingController controller;
  
  // Per-character styles (index = character position)
  List<CharStyle> charStyles = [];
  
  // Current typing style (applied to new characters)
  CharStyle currentStyle = const CharStyle();
  
  TextAlign alignment = TextAlign.left;
  bool isSaved = false;
  String? savedContent;
  
  DocumentData({required this.type}) {
    controller = RichTextEditingController(getDoc: () => this);
  }
  
  /// Get plain text content
  String get plainText => controller.text;
  
  /// Set plain text content (resets all styles to default)
  void setPlainText(String text) {
    controller.text = text;
    charStyles = List.filled(text.length, const CharStyle());
    controller.selection = TextSelection.collapsed(offset: text.length);
  }
  
  /// Check if content was edited since last save
  bool get wasEdited => savedContent != null && controller.text != savedContent;
  
  /// Mark as saved with current content
  void markSaved() {
    isSaved = true;
    savedContent = controller.text;
  }
  
  /// Insert text at current cursor position with current style
  void insertText(String text) {
    final currentText = controller.text;
    final selection = controller.selection;
    final insertPos = selection.isValid ? selection.start : currentText.length;
    final endPos = selection.isValid ? selection.end : currentText.length;
    
    // Remove styles for deleted selection
    if (endPos > insertPos && charStyles.isNotEmpty) {
      charStyles.removeRange(insertPos.clamp(0, charStyles.length), endPos.clamp(0, charStyles.length));
    }
    
    // Insert new styles
    final newStyles = List.filled(text.length, currentStyle);
    if (insertPos <= charStyles.length) {
      charStyles.insertAll(insertPos, newStyles);
    } else {
      charStyles.addAll(newStyles);
    }
    
    final newText = currentText.substring(0, insertPos) + text + currentText.substring(endPos);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: insertPos + text.length);
  }
  
  /// Apply style to selection range
  void applyStyleToSelection(int start, int end, CharStyle Function(CharStyle) modifier) {
    if (start < 0 || end <= start) return;
    
    // Ensure charStyles matches text length
    _syncStyles();
    
    for (int i = start; i < end && i < charStyles.length; i++) {
      charStyles[i] = modifier(charStyles[i]);
    }
  }
  
  /// Get style at position
  CharStyle getStyleAt(int pos) {
    _syncStyles();
    if (pos >= 0 && pos < charStyles.length) {
      return charStyles[pos];
    }
    return currentStyle;
  }
  
  /// Check if selection has uniform style property
  bool selectionHasStyle(int start, int end, bool Function(CharStyle) checker) {
    if (start < 0 || end <= start) return checker(currentStyle);
    _syncStyles();
    for (int i = start; i < end && i < charStyles.length; i++) {
      if (!checker(charStyles[i])) return false;
    }
    return true;
  }
  
  /// Sync charStyles array with text length
  void _syncStyles() {
    final textLen = controller.text.length;
    if (charStyles.length < textLen) {
      charStyles.addAll(List.filled(textLen - charStyles.length, currentStyle));
    } else if (charStyles.length > textLen) {
      charStyles = charStyles.sublist(0, textLen);
    }
  }
  
  /// Build TextSpan with proper styling
  TextSpan buildStyledText() {
    _syncStyles();
    final text = controller.text;
    if (text.isEmpty) return const TextSpan(text: '');
    
    final spans = <TextSpan>[];
    int spanStart = 0;
    CharStyle? lastStyle = charStyles.isNotEmpty ? charStyles[0] : currentStyle;
    
    for (int i = 0; i <= text.length; i++) {
      final currentCharStyle = i < charStyles.length ? charStyles[i] : currentStyle;
      if (i == text.length || currentCharStyle != lastStyle) {
        if (spanStart < i) {
          spans.add(TextSpan(
            text: text.substring(spanStart, i),
            style: lastStyle?.toTextStyle(),
          ));
        }
        spanStart = i;
        lastStyle = currentCharStyle;
      }
    }
    
    return TextSpan(children: spans);
  }
  
  /// Clear all formatting
  void clearFormatting() {
    currentStyle = const CharStyle();
    charStyles = List.filled(controller.text.length, const CharStyle());
  }
}

class MedicineItem { final String code, name, category; final int stock; MedicineItem({required this.code, required this.name, required this.category, required this.stock}); }
