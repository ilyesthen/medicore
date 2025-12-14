import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../../core/api/grpc_client.dart';
import '../../../core/api/medicore_client.dart';
import '../../../core/services/prescription_print_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../messages/presentation/receive_messages_dialog.dart';
import '../../comptabilite/presentation/comptabilite_dialog.dart';
import '../data/ordonnances_repository.dart';
import '../data/medications_repository.dart';
import '../../consultation/presentation/prescription_optique_dialog.dart';
import '../../consultation/presentation/prescription_lentilles_dialog.dart';

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
      // Server mode: use local DB
      final db = AppDatabase.instance;
      final results = await db.customSelect(
        'SELECT id, code, content, usage_count FROM templates_cr ORDER BY usage_count DESC'
      ).get();
      setState(() {
        _templatesCR = results.map((row) => {
          'id': row.read<int>('id'),
          'code': row.read<String>('code'),
          'content': row.read<String>('content'),
          'usageCount': row.read<int>('usage_count'),
        }).toList();
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
      await AppDatabase.instance.customStatement(
        'UPDATE templates_cr SET usage_count = usage_count + 1 WHERE id = ?',
        [id],
      );
    }
    _loadTemplatesCR();
    
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    _focusNode.dispose();
    _searchController.dispose();
    _printNameController.dispose();
    _printPrenomController.dispose();
    _printAgeController.dispose();
    _printNameFocus.dispose();
    _printPrenomFocus.dispose();
    _printAgeFocus.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f5) _showComptabiliteDialog();
      else if (event.logicalKey == LogicalKeyboardKey.escape) Navigator.of(context).pop();
    }
  }

  void _showComptabiliteDialog() => showDialog(context: context, builder: (_) => const ComptabiliteDialog());

  void _showSendMessageDialog() {
    final authState = ref.read(authStateProvider);
    if (authState.user != null && authState.selectedRoom != null) {
      showDialog(context: context, builder: (_) => SendMessageDialog(
        preSelectedRoomId: authState.selectedRoom!.id,
        patientCode: widget.patient.code,
        patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
      ));
    }
  }

  void _showReceiveMessagesDialog() {
    final authState = ref.read(authStateProvider);
    if (authState.selectedRoom != null) {
      showDialog(context: context, builder: (_) => ReceiveMessagesDialog(doctorRoomId: authState.selectedRoom!.id));
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.dark(primary: MediCoreColors.professionalBlue, surface: MediCoreColors.deepNavy)), child: child!),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  /// Show Optique prescription dialog
  void _showOptiqueDialog() {
    final p = widget.patient;
    showDialog(
      context: context,
      builder: (_) => PrescriptionOptiqueDialog(
        patientName: '${p.firstName} ${p.lastName}',
        patientCode: p.code.toString(),
        barcode: p.code.toString(),
        age: p.age?.toString(),
      ),
    );
  }

  /// Show Lentilles prescription dialog
  void _showLentillesDialog() {
    final p = widget.patient;
    showDialog(
      context: context,
      builder: (_) => PrescriptionLentillesDialog(
        patientName: '${p.firstName} ${p.lastName}',
        patientCode: p.code.toString(),
        barcode: p.code.toString(),
        age: p.age?.toString(),
      ),
    );
  }

  /// Get prefix filter based on selected bilan type
  String? _getBilanTypePrefix(String bilanType) {
    switch (bilanType) {
      case 'DEMANDE DE BILAN':
        return 'bilan';
      case 'CERTIFICAT MEDICAL':
      case 'CERTIFICAT D\'ARRÊT DE TRAVAIL':
      case 'CERTIFICAT D\'ARRÊT DE SCOLARITE':
        return 'ctf';
      case 'ORIENTATION':
        return 'orientation';
      case 'REPONSE':
        return 'reponse';
      case 'PROTOCOLE OPERATOIRE':
        return 'cpt';
      default:
        return null; // No filter for LENTILLES, CORRECTION OPTIQUE
    }
  }

  /// Get filtered medications (search by code starting with query)
  /// In Bilan tab (index 1), also filters by selected type prefix
  List<Medication> get _filteredMedications {
    var meds = _medications;
    
    // In Bilan tab, filter by selected type prefix
    if (_tabController.index == 1) {
      final prefix = _getBilanTypePrefix(_selectedBilanType);
      if (prefix != null) {
        meds = meds.where((m) => 
          m.code.toLowerCase().startsWith(prefix.toLowerCase())
        ).toList();
      }
    }
    
    // Apply search query filter
    if (_searchQuery.isNotEmpty) {
      meds = meds.where((m) => 
        m.code.toLowerCase().startsWith(_searchQuery.toLowerCase())
      ).toList();
    }
    
    return meds;
  }

  /// Insert medication into current tab's document
  void _insertMedication(Medication med) async {
    final tabIndex = _tabController.index;
    final type = tabIndex == 0 ? _selectedPrescriptionType : _selectedBilanType;
    
    // Start new doc if not already creating
    if (!_isCreatingForTab(tabIndex)) {
      _startNewDocumentForTab(tabIndex, type);
    }
    
    final doc = _getNewDocForTab(tabIndex);
    if (doc == null) return;
    
    final currentText = doc.plainText;
    // Use the prescription text from DB, preserving format
    final line = med.prescription;
    // Add separator line between medications
    final newContent = currentText.isEmpty ? line : '$currentText\n\n────────────────────────────────────\n\n$line';
    doc.setPlainText(newContent);
    
    // Increment usage count
    final repo = ref.read(medicationsRepositoryProvider);
    await repo.incrementUsage(med.id);
    
    // Clear search query instantly after selection
    _searchController.clear();
    _searchQuery = '';
    
    // Refresh medications list
    _loadMedications();
    
    setState(() {});
  }

  /// Edit medication usage count
  void _editMedicationCount(Medication med) async {
    final controller = TextEditingController(text: med.usageCount.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Modifier le compteur: ${med.code}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nouveau compteur'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, 0), child: const Text('Réinitialiser à 0')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, int.tryParse(controller.text) ?? med.usageCount),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    if (result != null) {
      final repo = ref.read(medicationsRepositoryProvider);
      await repo.setUsageCount(med.id, result);
      _loadMedications();
    }
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

  /// Show dialog to edit medication
  void _showEditMedicationDialog(Medication med) async {
    final codeController = TextEditingController(text: med.code);
    final prescriptionController = TextEditingController(text: med.prescription);
    
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(Icons.edit, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          const Expanded(child: Text('Modifier le médicament')),
        ]),
        content: SizedBox(
          width: 500,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: codeController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nom / Code',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: prescriptionController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'Prescription / Posologie',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, 'delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (codeController.text.trim().isNotEmpty) {
                Navigator.pop(ctx, 'save');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
    
    if (result == 'save' && codeController.text.trim().isNotEmpty) {
      final repo = ref.read(medicationsRepositoryProvider);
      await repo.updateMedication(
        id: med.id,
        code: codeController.text.trim(),
        prescription: prescriptionController.text.trim(),
      );
      _loadMedications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✓ Médicament modifié'), backgroundColor: Colors.blue),
        );
      }
    } else if (result == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer la suppression'),
          content: Text('Supprimer "${med.code}" ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Supprimer'),
            ),
          ],
        ),
      );
      if (confirm == true) {
        final repo = ref.read(medicationsRepositoryProvider);
        await repo.deleteMedication(med.id);
        _loadMedications();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✓ Médicament supprimé'), backgroundColor: Colors.orange),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Utilisateur';

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: MediCoreColors.canvasGrey,
        body: Column(children: [
          _buildTopBar(userName),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildPrescriptionsTab(),
                _buildBilanTab(),
                _buildComptesTab(),
              ],
            ),
          ),
          _buildBottomBar(),
        ]),
      ),
    );
  }

  Widget _buildTopBar(String userName) {
    final p = widget.patient;
    return Container(
      height: 70,
      decoration: const BoxDecoration(color: MediCoreColors.deepNavy, border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 2))),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: MediCoreColors.professionalBlue.withOpacity(0.3), borderRadius: BorderRadius.circular(4), border: Border.all(color: MediCoreColors.professionalBlue)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person, color: Colors.white, size: 18), const SizedBox(width: 8), Text(userName.toUpperCase(), style: MediCoreTypography.button.copyWith(color: Colors.white, fontSize: 13))])),
        const SizedBox(width: 32),
        Container(width: 2, height: 40, color: MediCoreColors.steelOutline),
        const SizedBox(width: 32),
        Container(width: 44, height: 44, decoration: BoxDecoration(color: MediCoreColors.healthyGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: MediCoreColors.healthyGreen)), child: const Icon(Icons.person_outline, color: MediCoreColors.healthyGreen, size: 24)),
        const SizedBox(width: 16),
        Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p.lastName} ${p.firstName}'.toUpperCase(), style: MediCoreTypography.sectionHeader.copyWith(color: Colors.white, fontSize: 16)), Text('Patient N° ${p.code}', style: MediCoreTypography.body.copyWith(color: Colors.white60, fontSize: 11))]),
        const SizedBox(width: 32),
        if (p.age != null) _InfoChip(icon: Icons.cake_outlined, label: '${p.age} ans'),
        const Spacer(),
        InkWell(onTap: _selectDate, borderRadius: BorderRadius.circular(4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF2E7D32).withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF4CAF50))), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.calendar_today, color: Color(0xFF81C784), size: 16), const SizedBox(width: 8), Text(DateFormat('dd/MM/yyyy').format(_selectedDate), style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)), const SizedBox(width: 4), const Icon(Icons.edit, color: Color(0xFF81C784), size: 12)]))),
        const SizedBox(width: 16),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, color: Colors.white)),
      ]),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 48,
      decoration: const BoxDecoration(color: MediCoreColors.deepNavy, border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline))),
      child: TabBar(
        controller: _tabController,
        indicatorColor: MediCoreColors.healthyGreen,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Text('📝', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Text('PRESCRIPTIONS')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Text('🧪', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Text('BILAN')])),
          Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [Text('📄', style: TextStyle(fontSize: 16)), SizedBox(width: 8), Text('COMPTES')])),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 1: PRESCRIPTIONS (View ALL docs + Medicines + Print with another name)
  // ════════════════════════════════════════════════════════════════════════════
  
  Widget _buildPrescriptionsTab() {
    return Container(
      color: MediCoreColors.canvasGrey,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(flex: 3, child: _buildUnifiedDocViewer(
          tabIndex: 0,
          showPrintWithAnother: true,
          newDocType: _selectedPrescriptionType,
          typeOptions: const ['ORDONNANCE', 'CORRECTION OPTIQUE', 'LENTILLES DE CONTACT'],
          selectedType: _selectedPrescriptionType,
          onTypeChanged: (v) => setState(() => _selectedPrescriptionType = v),
        )),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildMedicinePanel()),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 2: BILAN (View ALL docs + Medications - NOT templates!)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildBilanTab() {
    return Container(
      color: MediCoreColors.canvasGrey,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(flex: 3, child: _buildUnifiedDocViewer(
          tabIndex: 1,
          showPrintWithAnother: false,  // Bilan has NO print with another name
          newDocType: _selectedBilanType,
          typeOptions: bilanTypes,
          selectedType: _selectedBilanType,
          onTypeChanged: (v) { setState(() => _selectedBilanType = v); },
        )),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: Column(children: [
          // ART Shortcuts panel
          _buildArtShortcutsPanel(),
          const SizedBox(height: 16),
          // Medications panel
          Expanded(child: _buildMedicinePanel()),
        ])),
      ]),
    );
  }

  /// ART shortcuts panel for Bilan tab
  Widget _buildArtShortcutsPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: MediCoreColors.steelOutline),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.medical_services, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          const Text('Raccourcis Certificats', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          // Jour field
          const Text('Jours:', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 8),
          SizedBox(
            width: 60,
            child: TextField(
              controller: _jourController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ART (W) button
          Tooltip(
            message: 'Arrêt de travail',
            child: Material(
              color: Colors.orange.shade600,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => _insertArtTravail(1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('ART (W)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // ART (scol) button
          Tooltip(
            message: 'Éviction scolaire',
            child: Material(
              color: Colors.purple.shade600,
              borderRadius: BorderRadius.circular(6),
              child: InkWell(
                onTap: () => _insertArtScolaire(1),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('ART (scol)', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 8),
        Text('Cliquez sur le bouton pour insérer le certificat', style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontStyle: FontStyle.italic)),
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // TAB 3: COMPTES RENDUS (View ALL docs + Templates)
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildComptesTab() {
    return Container(
      color: MediCoreColors.canvasGrey,
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        Expanded(flex: 3, child: _buildUnifiedDocViewer(
          tabIndex: 2,
          showPrintWithAnother: false,  // Comptes has NO print with another name
          newDocType: _selectedCompteType,
          typeOptions: compteTypes,
          selectedType: _selectedCompteType,
          onTypeChanged: (v) => setState(() => _selectedCompteType = v),
        )),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: _buildTemplatePanel()),  // Only Comptes has templates
      ]),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // UNIFIED DOCUMENT VIEWER - Shows ALL documents for patient
  // ════════════════════════════════════════════════════════════════════════════
  
  Widget _buildUnifiedDocViewer({
    required int tabIndex,
    required bool showPrintWithAnother,
    required String newDocType,
    required List<String> typeOptions,
    required String selectedType,
    required ValueChanged<String> onTypeChanged,
  }) {
    final currentDoc = _currentDocument;
    final total = _allDocuments.length;
    final isCreating = _isCreatingForTab(tabIndex);
    final isViewing = !isCreating && currentDoc != null;
    
    return Container(
      decoration: BoxDecoration(color: MediCoreColors.paperWhite, borderRadius: BorderRadius.circular(8), border: Border.all(color: MediCoreColors.steelOutline), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        // Header with navigation
        Container(
          height: 50,
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [MediCoreColors.deepNavy, Color(0xFF2A3F5F)]), borderRadius: BorderRadius.only(topLeft: Radius.circular(7), topRight: Radius.circular(7))),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            // Navigation arrows
            _NavBtn(icon: Icons.chevron_left, onTap: () => _navigateDoc(-1)),
            const SizedBox(width: 8),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4), decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(4)), child: Text(isCreating ? 'NOUVEAU' : '${_currentDocIndex + 1} / $total', style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold))),
            const SizedBox(width: 8),
            _NavBtn(icon: Icons.chevron_right, onTap: () => _navigateDoc(1)),
            const SizedBox(width: 16),
            
            // Document title - shows type from DB or dropdown for new
            const Icon(Icons.description, color: Colors.white70, size: 18),
            const SizedBox(width: 8),
            if (isViewing)
              Expanded(child: Text(currentDoc.displayTitle, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis))
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.white30)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedType,
                    dropdownColor: MediCoreColors.deepNavy,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.white70, size: 18),
                    items: typeOptions.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) => onTypeChanged(v ?? selectedType),
                  ),
                ),
              ),
            
            const Spacer(),
            
            // Add new button
            if (!isCreating)
              Material(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _startNewDocumentForTab(tabIndex, selectedType),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('NOUVEAU', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
            
            // Cancel new button
            if (isCreating)
              Material(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _cancelNewDocumentForTab(tabIndex),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.close, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text('ANNULER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
          ]),
        ),
        
        // Date info for viewed document + delete button
        if (isViewing && currentDoc.documentDate != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(color: const Color(0xFFE3F2FD), border: Border(bottom: BorderSide(color: Colors.blue.shade200))),
            child: Row(children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Text('Date: ${currentDoc.formattedDate}', style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.w500)),
              if (currentDoc.doctorName != null) ...[
                const SizedBox(width: 24),
                Icon(Icons.person, size: 14, color: Colors.blue.shade700),
                const SizedBox(width: 4),
                Text(currentDoc.doctorName!, style: TextStyle(fontSize: 12, color: Colors.blue.shade800)),
              ],
              const Spacer(),
              // Delete button
              Material(
                color: Colors.red.shade400,
                borderRadius: BorderRadius.circular(4),
                child: InkWell(
                  onTap: () => _deleteCurrentDocument(currentDoc),
                  borderRadius: BorderRadius.circular(4),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delete, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text('SUPPRIMER', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ]),
                  ),
                ),
              ),
            ]),
          ),
        
        // Content area
        Expanded(
          child: _isLoadingDocs
              ? const Center(child: CircularProgressIndicator())
              : isViewing
                  ? _buildDocumentContent(currentDoc)
                  : _buildNewDocumentEditor(tabIndex, showPrintWithAnother),
        ),
        
        // Bottom actions - print/download buttons
        if (isCreating)
          tabIndex == 0 
              ? _buildPrintWithAnotherSection(tabIndex, selectedType)
              : _buildSimplePrintSection(tabIndex, selectedType),
      ]),
    );
  }

  /// Simple print/download buttons (for Bilan and Comptes - no "print with another name")
  Widget _buildSimplePrintSection(int tabIndex, String documentType) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9).withOpacity(0.5), border: const Border(top: BorderSide(color: MediCoreColors.steelOutline)), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7))),
      child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
        // Download button
        Material(
          color: const Color(0xFF1565C0),
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _downloadDocument(tabIndex, documentType),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.download, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('TÉLÉCHARGER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Print button
        Material(
          color: MediCoreColors.healthyGreen,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _printDocumentTab(tabIndex, documentType),
            borderRadius: BorderRadius.circular(4),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.print, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text('IMPRIMER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
  
  /// Display existing document content (read-only, preserves formatting)
  Widget _buildDocumentContent(OrdonnanceDocument doc) {
    return Column(children: [
      Expanded(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: MediCoreColors.steelOutline),
          ),
          child: SingleChildScrollView(
            child: SelectableText(
              doc.content,
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Courier New',
                height: 1.5,
                color: Colors.black87,
              ),
            ),
          ),
        ),
      ),
      // Print button for existing documents
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFE8F5E9).withOpacity(0.5), border: const Border(top: BorderSide(color: MediCoreColors.steelOutline)), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7))),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // Download button
          Material(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () => _downloadExistingDocument(doc),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('TÉLÉCHARGER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Print button
          Material(
            color: MediCoreColors.healthyGreen,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () => _printExistingDocument(doc),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.print, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('IMPRIMER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ]),
      ),
    ]);
  }

  /// Print existing document (no save needed)
  /// Tab 0 & 1 use A5, Tab 2 (Comptes) uses A4 - all same format, no background image
  Future<void> _printExistingDocument(OrdonnanceDocument doc) async {
    final printContent = _stripSeparatorsForPrint(doc.content);
    final p = widget.patient;
    final tabIndex = _tabController.index;
    
    // Tab 2 (Compte Rendu) uses A4, others use A5 - same format, no image
    final bool success = await PrescriptionPrintService.printOrdonnance(
      patientName: '${p.firstName} ${p.lastName}',
      patientCode: p.code.toString(),
      barcode: p.code.toString(),
      date: doc.formattedDate,
      content: printContent,
      documentType: doc.type ?? 'ORDONNANCE',
      age: p.age?.toString(),
      useA4: tabIndex == 2, // Only Compte Rendu uses A4
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(success ? 'Impression envoyée' : 'Aucune imprimante connectée'),
        backgroundColor: success ? Colors.green : Colors.orange,
      ));
    }
  }

  /// Download existing document as PDF
  /// Tab 0 & 1 use A5, Tab 2 (Comptes) uses A4 - all same format, no background image
  Future<void> _downloadExistingDocument(OrdonnanceDocument doc) async {
    final pdfContent = _stripSeparatorsForPrint(doc.content);
    final p = widget.patient;
    final tabIndex = _tabController.index;
    
    try {
      // Tab 2 (Compte Rendu) uses A4, others use A5 - same format, no image
      final Uint8List pdf = await PrescriptionPrintService.generateOrdonnancePdf(
        patientName: '${p.firstName} ${p.lastName}',
        patientCode: p.code.toString(),
        barcode: p.code.toString(),
        date: doc.formattedDate,
        content: pdfContent,
        documentType: doc.type ?? 'ORDONNANCE',
        age: p.age?.toString(),
        useA4: tabIndex == 2, // Only Compte Rendu uses A4
      );
      
      final cleanType = (doc.type ?? 'ORDONNANCE').replaceAll(' ', '_').replaceAll("'", '');
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
  
  /// Editor for new documents
  Widget _buildNewDocumentEditor(int tabIndex, bool showPrintWithAnother) {
    final newDoc = _getNewDocForTab(tabIndex);
    if (newDoc == null) {
      return const Center(child: Text('Cliquez sur NOUVEAU pour créer un document'));
    }
    
    return Column(children: [
      // Eye selection (click to insert text with line break)
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: MediCoreColors.canvasGrey.withOpacity(0.5), border: const Border(bottom: BorderSide(color: MediCoreColors.steelOutline))),
        child: Row(children: [
          _EyeChip(
            label: '👁️ Opéré', 
            isSelected: newDoc.eyeSelection == 'OPERE', 
            onTap: () {
              setState(() => newDoc.eyeSelection = 'OPERE');
              _insertTextIntoDoc(tabIndex, "\n\nMettre uniquement dans l'œil opéré\n");
            },
            color: const Color(0xFF7B1FA2),
          ),
          const SizedBox(width: 8),
          _EyeChip(
            label: '👁️👁️ Les deux', 
            isSelected: newDoc.eyeSelection == 'BOTH', 
            onTap: () {
              setState(() => newDoc.eyeSelection = 'BOTH');
              _insertTextIntoDoc(tabIndex, "\n\nMettre dans les deux yeux\n");
            },
            color: const Color(0xFF1565C0),
          ),
          const SizedBox(width: 8),
          _EyeChip(
            label: 'OD', 
            isSelected: newDoc.eyeSelection == 'OD', 
            onTap: () {
              setState(() => newDoc.eyeSelection = 'OD');
              _insertTextIntoDoc(tabIndex, "\n\nMettre uniquement dans l'œil droit\n");
            },
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(width: 8),
          _EyeChip(
            label: 'OG', 
            isSelected: newDoc.eyeSelection == 'OG', 
            onTap: () {
              setState(() => newDoc.eyeSelection = 'OG');
              _insertTextIntoDoc(tabIndex, "\n\nMettre uniquement dans l'œil gauche\n");
            },
            color: const Color(0xFF0277BD),
          ),
        ]),
      ),
      // Word-like professional toolbar
      _ProfessionalToolbar(doc: newDoc, onChanged: () => setState(() {})),
      // Text Editor - preserves exact formatting
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: MediCoreColors.steelOutline)),
          child: TextField(
            controller: newDoc.controller,
            maxLines: null,
            expands: true,
            style: TextStyle(fontSize: newDoc.fontSize, fontFamily: newDoc.fontFamily, fontWeight: newDoc.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: newDoc.isItalic ? FontStyle.italic : FontStyle.normal, decoration: newDoc.isUnderline ? TextDecoration.underline : null, color: newDoc.textColor),
            textAlign: newDoc.alignment,
            decoration: InputDecoration(hintText: 'Saisir le contenu...', hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13), border: InputBorder.none, contentPadding: const EdgeInsets.all(16)),
          ),
        ),
      ),
    ]);
  }
  
  Widget _buildPrintWithAnotherSection(int tabIndex, String documentType) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: const Color(0xFFFFF3E0).withOpacity(0.5), border: const Border(top: BorderSide(color: MediCoreColors.steelOutline)), borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(7), bottomRight: Radius.circular(7))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Icon(Icons.print, color: Colors.orange.shade700, size: 16), const SizedBox(width: 6), Icon(Icons.description, color: Colors.orange.shade600, size: 14), const SizedBox(width: 8), Text('Imprimer avec un autre nom', style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.w600))]),
        const SizedBox(height: 10),
        Row(children: [
          Expanded(child: _SmallField(controller: _printNameController, label: 'Nom', focusNode: _printNameFocus, nextFocus: _printPrenomFocus)),
          const SizedBox(width: 8),
          Expanded(child: _SmallField(controller: _printPrenomController, label: 'Prénom', focusNode: _printPrenomFocus, nextFocus: _printAgeFocus)),
          const SizedBox(width: 8),
          SizedBox(width: 80, child: _SmallField(controller: _printAgeController, label: 'Âge', focusNode: _printAgeFocus)),
        ]),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          // Download button
          Material(
            color: const Color(0xFF1565C0),
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () => _downloadDocument(tabIndex, documentType),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.download, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('TÉLÉCHARGER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Print button
          Material(
            color: MediCoreColors.healthyGreen,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              onTap: () => _printDocumentTab(tabIndex, documentType),
              borderRadius: BorderRadius.circular(4),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.print, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('IMPRIMER', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ]),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  /// Save document to database
  Future<bool> _saveDocumentToDb(int tabIndex, String documentType, String content) async {
    try {
      final p = widget.patient;
      final doctorName = ref.read(authStateProvider).user?.name ?? 'Docteur';
      
      // Client mode: use remote API
      if (!GrpcClientConfig.isServer) {
        final result = await MediCoreClient.instance.createOrdonnance({
          'patient_code': p.code,
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
      final db = AppDatabase.instance;
      await db.customStatement(
        '''INSERT INTO ordonnances (patient_code, document_date, content1, type1, doctor_name, created_at)
           VALUES (?, ?, ?, ?, ?, ?)''',
        [
          p.code,
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
// PROFESSIONAL TOOLBAR (Word-like)
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfessionalToolbar extends StatefulWidget {
  final DocumentData doc;
  final VoidCallback onChanged;
  const _ProfessionalToolbar({required this.doc, required this.onChanged});
  @override
  State<_ProfessionalToolbar> createState() => _ProfessionalToolbarState();
}

class _ProfessionalToolbarState extends State<_ProfessionalToolbar> {
  static const fonts = ['Arial', 'Times New Roman', 'Courier New', 'Georgia', 'Verdana', 'Tahoma', 'Helvetica'];
  static const sizes = [8.0, 9.0, 10.0, 11.0, 12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0, 36.0, 48.0];
  static const colors = [Colors.black, Colors.grey, Colors.red, Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.brown];

  DocumentData get _doc => widget.doc;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Color(0xFFF8F9FA), border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline))),
      child: Column(children: [
        // Row 1: Font, Size, Bold, Italic, Underline, Color
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(children: [
            _fontDropdown(),
            const SizedBox(width: 6),
            _sizeDropdown(),
            _divider(),
            _formatBtn(Icons.format_bold, _doc.isBold, () => setState(() => _doc.isBold = !_doc.isBold)),
            _formatBtn(Icons.format_italic, _doc.isItalic, () => setState(() => _doc.isItalic = !_doc.isItalic)),
            _formatBtn(Icons.format_underline, _doc.isUnderline, () => setState(() => _doc.isUnderline = !_doc.isUnderline)),
            _divider(),
            _colorBtn(),
          ]),
        ),
        // Row 2: Alignment, Lists, Line, Clear
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFFE0E0E0)))),
          child: Row(children: [
            _alignBtn(Icons.format_align_left, TextAlign.left),
            _alignBtn(Icons.format_align_center, TextAlign.center),
            _alignBtn(Icons.format_align_right, TextAlign.right),
            _divider(),
            _actionBtn(Icons.format_list_bulleted, () => _doc.insertText('\n• ')),
            _actionBtn(Icons.format_list_numbered, () => _doc.insertText('\n1. ')),
            _divider(),
            _actionBtn(Icons.horizontal_rule, () => _doc.insertText('\n────────────────────────────────────\n')),
            _divider(),
            _actionBtn(Icons.format_clear, _clearFormatting),
            const Spacer(),
          ]),
        ),
      ]),
    );
  }

  Widget _fontDropdown() => Container(
    width: 120, height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBDBDBD))),
    child: DropdownButtonHideUnderline(child: DropdownButton<String>(
      value: fonts.contains(_doc.fontFamily) ? _doc.fontFamily : 'Arial',
      isExpanded: true, isDense: true,
      style: const TextStyle(fontSize: 11, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
      items: fonts.map((f) => DropdownMenuItem(value: f, child: Text(f, overflow: TextOverflow.ellipsis, style: TextStyle(fontFamily: f, fontSize: 11)))).toList(),
      onChanged: (v) { setState(() => _doc.fontFamily = v ?? 'Arial'); widget.onChanged(); },
    )),
  );

  Widget _sizeDropdown() => Container(
    width: 55, height: 28,
    padding: const EdgeInsets.symmetric(horizontal: 6),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFFBDBDBD))),
    child: DropdownButtonHideUnderline(child: DropdownButton<double>(
      value: sizes.contains(_doc.fontSize) ? _doc.fontSize : 14.0,
      isExpanded: true, isDense: true,
      style: const TextStyle(fontSize: 11, color: Colors.black87),
      icon: const Icon(Icons.arrow_drop_down, size: 16, color: Colors.grey),
      items: sizes.map((s) => DropdownMenuItem(value: s, child: Text('${s.toInt()}'))).toList(),
      onChanged: (v) { setState(() => _doc.fontSize = v ?? 14); widget.onChanged(); },
    )),
  );

  Widget _divider() => Container(width: 1, height: 20, margin: const EdgeInsets.symmetric(horizontal: 6), color: const Color(0xFFBDBDBD));

  Widget _formatBtn(IconData icon, bool active, VoidCallback onTap) => Material(
    color: active ? const Color(0xFFE3F2FD) : Colors.transparent,
    borderRadius: BorderRadius.circular(4),
    child: InkWell(
      onTap: () { onTap(); widget.onChanged(); },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28, height: 28, alignment: Alignment.center,
        decoration: active ? BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF1565C0))) : null,
        child: Icon(icon, size: 18, color: active ? const Color(0xFF1565C0) : const Color(0xFF424242)),
      ),
    ),
  );

  Widget _alignBtn(IconData icon, TextAlign align) {
    final active = _doc.alignment == align;
    return Material(
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
    );
  }

  Widget _actionBtn(IconData icon, VoidCallback onTap) => Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(4),
    child: InkWell(
      onTap: () { onTap(); widget.onChanged(); },
      borderRadius: BorderRadius.circular(4),
      child: Container(width: 28, height: 28, alignment: Alignment.center, child: Icon(icon, size: 18, color: const Color(0xFF424242))),
    ),
  );

  Widget _colorBtn() => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _showColorPicker,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        width: 28, height: 28, alignment: Alignment.center,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.format_color_text, size: 16, color: Color(0xFF424242)),
          Container(height: 3, width: 16, decoration: BoxDecoration(color: _doc.textColor, borderRadius: BorderRadius.circular(1))),
        ]),
      ),
    ),
  );

  void _showColorPicker() => showDialog(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Couleur du texte'),
      content: SizedBox(
        width: 200,
        child: Wrap(spacing: 8, runSpacing: 8, children: colors.map((col) => InkWell(
          onTap: () { setState(() => _doc.textColor = col); Navigator.pop(c); widget.onChanged(); },
          child: Container(width: 32, height: 32, decoration: BoxDecoration(color: col, borderRadius: BorderRadius.circular(4), border: Border.all(color: col == _doc.textColor ? const Color(0xFF1565C0) : Colors.grey.shade300, width: col == _doc.textColor ? 2 : 1))),
        )).toList()),
      ),
    ),
  );

  void _clearFormatting() {
    setState(() {
      _doc.isBold = false;
      _doc.isItalic = false;
      _doc.isUnderline = false;
      _doc.alignment = TextAlign.left;
      _doc.textColor = Colors.black;
      _doc.fontSize = 14;
      _doc.fontFamily = 'Arial';
    });
    widget.onChanged();
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

class DocumentData {
  String type;
  String eyeSelection = 'BOTH';
  final TextEditingController controller = TextEditingController();
  String fontFamily = 'Arial';
  double fontSize = 14;
  bool isBold = false, isItalic = false, isUnderline = false;
  Color textColor = Colors.black;
  TextAlign alignment = TextAlign.left;
  bool isSaved = false;  // Track if already saved to DB
  String? savedContent;  // Content when last saved (to detect edits)
  DocumentData({required this.type});
  
  /// Get plain text content
  String get plainText => controller.text;
  
  /// Set plain text content
  void setPlainText(String text) {
    controller.text = text;
    controller.selection = TextSelection.collapsed(offset: text.length);
  }
  
  /// Check if content was edited since last save
  bool get wasEdited => savedContent != null && controller.text != savedContent;
  
  /// Mark as saved with current content
  void markSaved() {
    isSaved = true;
    savedContent = controller.text;
  }
  
  /// Insert text at current cursor position
  void insertText(String text) {
    final currentText = controller.text;
    final selection = controller.selection;
    final insertPos = selection.isValid ? selection.start : currentText.length;
    final newText = currentText.substring(0, insertPos) + text + currentText.substring(selection.isValid ? selection.end : currentText.length);
    controller.text = newText;
    controller.selection = TextSelection.collapsed(offset: insertPos + text.length);
  }
}

class MedicineItem { final String code, name, category; final int stock; MedicineItem({required this.code, required this.name, required this.category, required this.stock}); }
