import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../patients/data/age_calculator_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../messages/presentation/receive_messages_dialog.dart';
import '../../comptabilite/presentation/comptabilite_dialog.dart';
import '../../waiting_queue/presentation/waiting_queue_provider.dart';
import '../../comptabilite/presentation/payments_provider.dart';
import 'validate_payment_dialog.dart';
import 'prescription_optique_dialog.dart';
import 'prescription_lentilles_dialog.dart';
import '../../ordonnance/presentation/ordonnance_page.dart';
import '../../../core/types/proto_types.dart';

/// New Visit Page - For creating new visits or editing existing ones
class NewVisitPage extends ConsumerStatefulWidget {
  final Patient patient;
  final Visit? existingVisit; // If provided, we're editing an existing visit

  const NewVisitPage({super.key, required this.patient, this.existingVisit});

  @override
  ConsumerState<NewVisitPage> createState() => _NewVisitPageState();
}

class _NewVisitPageState extends ConsumerState<NewVisitPage> {
  final FocusNode _focusNode = FocusNode();
  
  // Keys to access eye panel state
  final _odPanelKey = GlobalKey<_NewVisitEyePanelState>();
  final _ogPanelKey = GlobalKey<_NewVisitEyePanelState>();
  
  // Consultation fields
  String? _selectedMotif;
  String _selectedCycloplegie = 'Aucune';
  
  // Actes controllers
  final _actesGenerauxController = TextEditingController();
  final _actesOphtalmoController = TextEditingController();
  
  // Change tracking
  bool _hasChanges = false;
  bool _isSaving = false;
  String? _initialMotif;
  String _initialCycloplegie = 'Aucune';
  String _initialActesGeneraux = '';
  String _initialActesOphtalmo = '';
  
  // Payment reminder
  bool _hasPaymentToday = true; // Assume true initially, check on load
  bool _hasStartedTyping = false;
  
  // Track saved visit ID to prevent duplicate saves
  int? _savedVisitId;
  Object? _savedVisitDate;
  
  bool get isEditMode => widget.existingVisit != null || _savedVisitId != null;
  
  /// Get the visit ID to use for updates (either from widget or from first save)
  Object? get _currentVisitId => widget.existingVisit?.id ?? _savedVisitId;

  Future<void> _showPrescriptionOptique() async {
    await _showPaymentReminderIfNeeded();
    if (!mounted) return;
    
    final vlOD = _odPanelKey.currentState?.vlValue ?? '';
    final vlOG = _ogPanelKey.currentState?.vlValue ?? '';
    final addition = _ogPanelKey.currentState?.addition;
    final patientName = '${widget.patient.firstName} ${widget.patient.lastName}';
    final patientCode = widget.patient.code.toString();
    final barcode = widget.patient.barcode;
    final age = widget.patient.currentAge?.toString();
    showDialog(context: context, builder: (context) => PrescriptionOptiqueDialog(
      vlOD: vlOD, vlOG: vlOG, addition: addition,
      patientName: patientName, patientCode: patientCode, barcode: barcode, age: age,
    ));
  }

  Future<void> _showPrescriptionLentilles() async {
    await _showPaymentReminderIfNeeded();
    if (!mounted) return;
    
    final vlOD = _odPanelKey.currentState?.vlValue ?? '';
    final vlOG = _ogPanelKey.currentState?.vlValue ?? '';
    final patientName = '${widget.patient.firstName} ${widget.patient.lastName}';
    final patientCode = widget.patient.code.toString();
    final barcode = widget.patient.barcode;
    final age = widget.patient.currentAge?.toString();
    showDialog(context: context, builder: (context) => PrescriptionLentillesDialog(
      vlOD: vlOD, vlOG: vlOG,
      patientName: patientName, patientCode: patientCode, barcode: barcode, age: age,
    ));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _loadExistingVisit();
      _checkPaymentStatus();
    });
    
    // Add listeners for change tracking
    _actesGenerauxController.addListener(_checkForChanges);
    _actesOphtalmoController.addListener(_checkForChanges);
  }
  
  Future<void> _checkPaymentStatus() async {
    // Check payment status for BOTH new and edit mode
    try {
      final repository = ref.read(paymentsRepositoryProvider);
      final today = DateTime.now();
      
      final count = await repository.countPaymentsByPatientAndDate(
        patientCode: widget.patient.code,
        date: today,
      );
      
      setState(() {
        _hasPaymentToday = count > 0;
      });
    } catch (e) {
      // If error, assume payment exists to avoid blocking
      setState(() => _hasPaymentToday = true);
    }
  }
  
  /// Show payment reminder dialog if no payment today. Returns true if action should proceed.
  Future<bool> _showPaymentReminderIfNeeded() async {
    // If payment already validated today, skip completely
    if (_hasPaymentToday) return true;
    
    // Re-check payment status first (in case it was validated elsewhere)
    await _checkPaymentStatus();
    if (_hasPaymentToday) return true;
    
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => ValidatePaymentDialog(
        patientCode: widget.patient.code,
        patientFirstName: widget.patient.firstName,
        patientLastName: widget.patient.lastName,
        currentUser: ref.read(authStateProvider).user,
        showIgnoreButton: true,
      ),
    );
    
    // If user validated payment (result == true), mark as done for this session
    if (result == true) {
      setState(() => _hasPaymentToday = true);
    }
    
    return result ?? true; // If dismissed, allow action
  }
  
  Future<void> _loadExistingVisit() async {
    if (widget.existingVisit != null) {
      final visit = widget.existingVisit!;
      setState(() {
        _selectedMotif = visit.motif;
        _initialMotif = visit.motif;
      });
      
      // Wait a bit for panels to be fully initialized
      await Future.delayed(const Duration(milliseconds: 100));
      
      // Load OD panel data
      _odPanelKey.currentState?.loadVisitData(
        sv: visit.odSv, av: visit.odAv, sphere: visit.odSphere, cylindre: visit.odCylinder,
        axe: visit.odAxis, k1: visit.odK1, k2: visit.odK2, r1: visit.odR1, r2: visit.odR2,
        r0: visit.odR0, pachy: visit.odPachy, toc: visit.odToc, to: visit.odTo,
        gonio: visit.odGonio, laf: visit.odLaf, fo: visit.odFo, conduct: visit.conduct,
        notes: visit.odNotes,
      );
      
      // Load OG panel data
      _ogPanelKey.currentState?.loadVisitData(
        sv: visit.ogSv, av: visit.ogAv, sphere: visit.ogSphere, cylindre: visit.ogCylinder,
        axe: visit.ogAxis, k1: visit.ogK1, k2: visit.ogK2, r1: visit.ogR1, r2: visit.ogR2,
        r0: visit.ogR0, pachy: visit.ogPachy, toc: visit.ogToc, to: visit.ogTo,
        gonio: visit.ogGonio, laf: visit.ogLaf, fo: visit.ogFo, 
        addition: visit.addition, dip: visit.dip, diag: visit.diagnosis,
        notes: visit.ogNotes,
      );
    }
  }
  
  void _checkForChanges() {
    final odHasChanges = _odPanelKey.currentState?.hasChanges ?? false;
    final ogHasChanges = _ogPanelKey.currentState?.hasChanges ?? false;
    final motifChanged = _selectedMotif != _initialMotif;
    final cycloplegieChanged = _selectedCycloplegie != _initialCycloplegie;
    final actesGenerauxChanged = _actesGenerauxController.text != _initialActesGeneraux;
    final actesOphtalmoChanged = _actesOphtalmoController.text != _initialActesOphtalmo;
    
    final hasChanges = odHasChanges || ogHasChanges || motifChanged || 
        cycloplegieChanged || actesGenerauxChanged || actesOphtalmoChanged;
    
    if (hasChanges != _hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _actesGenerauxController.dispose();
    _actesOphtalmoController.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f5) _showComptabiliteDialog();
      else if (event.logicalKey == LogicalKeyboardKey.escape) _handleBack();
    }
  }

  void _showComptabiliteDialog() {
    showDialog(context: context, builder: (context) => const ComptabiliteDialog());
  }
  
  Future<void> _handleBack() async {
    // Show payment reminder before leaving
    await _showPaymentReminderIfNeeded();
    if (!mounted) return;
    
    _checkForChanges();
    if (_hasChanges) {
      final result = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modifications non enregistrées'),
          content: const Text('Vous avez des modifications non enregistrées. Voulez-vous les sauvegarder ?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop('discard'), child: const Text('Non', style: TextStyle(color: Colors.red))),
            TextButton(onPressed: () => Navigator.of(context).pop('cancel'), child: const Text('Annuler')),
            ElevatedButton(onPressed: () => Navigator.of(context).pop('save'), style: ElevatedButton.styleFrom(backgroundColor: MediCoreColors.healthyGreen), child: const Text('Oui, Sauvegarder')),
          ],
        ),
      );
      
      if (result == 'save') {
        await _saveVisit();
        if (mounted) Navigator.of(context).pop();
      } else if (result == 'discard') {
        if (mounted) Navigator.of(context).pop();
      }
      // If 'cancel' or null, do nothing
    } else {
      Navigator.of(context).pop();
    }
  }
  
  Future<void> _saveVisit() async {
    if (_isSaving) return;
    
    // Show payment reminder before saving
    await _showPaymentReminderIfNeeded();
    if (!mounted) return;
    
    setState(() => _isSaving = true);
    
    try {
      final authState = ref.read(authStateProvider);
      final now = DateTime.now();
      
      final odState = _odPanelKey.currentState;
      final ogState = _ogPanelKey.currentState;
      
      // Use existing visit date or saved date for updates, current time for new visits
      final visitDate = widget.existingVisit?.visitDate ?? _savedVisitDate ?? now;
      final createdAt = widget.existingVisit?.createdAt ?? (isEditMode ? _savedVisitDate : now) ?? now;
      
      // TODO: Implement visits in gRPC mode
      // VisitsCompanion and Value are Drift constructs not available in gRPC
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('❌ Enregistrement de visite non disponible en mode gRPC'),
          backgroundColor: Colors.orange,
        ));
      }
      return;
      
      // Dead code - will be re-implemented with gRPC
      // final visitCompanion = {...};
      // final repository = ref.read(visitsRepositoryProvider);
      // if (_currentVisitId != null) {
      //   await repository.updateVisit(_currentVisitId!, visitCompanion);
      //   if (mounted) { ScaffoldMessenger.of(context).showSnackBar(...); }
      // } else {
      //   final newId = await repository.insertVisit(visitCompanion);
      //   if (newId > 0) { setState(() { _savedVisitId = newId; }); }
      // }
      // setState(() { _hasChanges = false; });
      // ref.invalidate(patientVisitsProvider(widget.patient.code));
      // ref.invalidate(patientVisitCountProvider(widget.patient.code));
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur lors de l\'enregistrement: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSendMessageDialog() {
    final authState = ref.read(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    if (authState.user != null && selectedRoom != null) {
      showDialog(context: context, builder: (context) => SendMessageDialog(preSelectedRoomId: selectedRoom.id.toString(), patientCode: widget.patient.code, patientName: '${widget.patient.firstName} ${widget.patient.lastName}'));
    }
  }

  void _showReceiveMessagesDialog() {
    final authState = ref.read(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    if (selectedRoom != null) {
      showDialog(context: context, builder: (context) => ReceiveMessagesDialog(doctorRoomId: selectedRoom.id.toString()));
    }
  }

  void _showValidatePaymentDialog() {
    final authState = ref.read(authStateProvider);
    showDialog(context: context, builder: (context) => ValidatePaymentDialog(patientCode: widget.patient.code, patientFirstName: widget.patient.firstName, patientLastName: widget.patient.lastName, currentUser: authState.user));
  }

  Future<void> _sendDilatation(String dilatationType) async {
    final authState = ref.read(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune salle sélectionnée'), backgroundColor: Colors.orange));
      return;
    }
    try {
      final repository = ref.read(waitingQueueRepositoryProvider);
      await repository.addToDilatation(patientCode: widget.patient.code, patientFirstName: widget.patient.firstName, patientLastName: widget.patient.lastName, patientBirthDate: widget.patient.dateOfBirth != null ? DateTime.tryParse(widget.patient.dateOfBirth!) : null, patientAge: widget.patient.age, patientCreatedAt: widget.patient.createdAt != null ? DateTime.tryParse(widget.patient.createdAt!) : null, roomId: selectedRoom.id.toString(), roomName: selectedRoom.name, dilatationType: dilatationType, sentByUserId: authState.user?.id ?? '', sentByUserName: authState.user?.name ?? '');
      final label = {'skiacol': 'Dilatation sous Skiacol', 'od': 'Dilatation OD', 'og': 'Dilatation OG', 'odg': 'Dilatation ODG'}[dilatationType] ?? dilatationType;
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.opacity, color: Colors.white), const SizedBox(width: 8), Expanded(child: Text('💊 $label envoyé pour ${widget.patient.firstName}'))]), backgroundColor: MediCoreColors.healthyGreen));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Utilisateur';
    final patient = widget.patient;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _handleBack();
      },
      child: KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        // Different background for new/edit visits - subtle warm tint
        backgroundColor: const Color(0xFFF5F0E8), // Warm cream background instead of grey
        body: Column(children: [
          // MODE INDICATOR STRIP - Shows clearly that we're editing/creating
          Container(
            height: 6,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isEditMode 
                    ? [const Color(0xFFFF9800), const Color(0xFFFFC107)] // Orange for edit mode
                    : [const Color(0xFF4CAF50), const Color(0xFF8BC34A)], // Green for new visit
              ),
            ),
          ),
          // TOP BAR - Different color tint for new/edit
          Container(
            height: 70,
            decoration: BoxDecoration(
              // Warmer navy with subtle tint based on mode
              color: isEditMode 
                  ? const Color(0xFF2D3A4A) // Slightly warmer navy for edit
                  : const Color(0xFF1E3D2F), // Green-tinted navy for new
              border: Border(bottom: BorderSide(
                color: isEditMode ? const Color(0xFFFF9800) : const Color(0xFF4CAF50), 
                width: 3,
              )),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              // MODE BADGE
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: isEditMode 
                      ? const Color(0xFFFF9800).withOpacity(0.2) 
                      : const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isEditMode ? const Color(0xFFFF9800) : const Color(0xFF4CAF50), 
                    width: 2,
                  ),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(
                    isEditMode ? Icons.edit_document : Icons.add_circle_outline, 
                    color: isEditMode ? const Color(0xFFFF9800) : const Color(0xFF4CAF50), 
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    isEditMode ? 'MODIFICATION' : 'NOUVELLE VISITE',
                    style: TextStyle(
                      color: isEditMode ? const Color(0xFFFF9800) : const Color(0xFF4CAF50),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: MediCoreColors.professionalBlue.withOpacity(0.3), borderRadius: BorderRadius.circular(4), border: Border.all(color: MediCoreColors.professionalBlue, width: 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person, color: Colors.white, size: 18), const SizedBox(width: 8), Text(userName.toUpperCase(), style: MediCoreTypography.button.copyWith(color: Colors.white, fontSize: 13, letterSpacing: 0.5))]),
              ),
              const SizedBox(width: 32),
              Container(width: 2, height: 40, color: MediCoreColors.steelOutline),
              const SizedBox(width: 32),
              Expanded(child: Row(children: [
                Container(width: 44, height: 44, decoration: BoxDecoration(color: MediCoreColors.healthyGreen.withOpacity(0.2), borderRadius: BorderRadius.circular(4), border: Border.all(color: MediCoreColors.healthyGreen, width: 1)), child: const Icon(Icons.person_outline, color: MediCoreColors.healthyGreen, size: 24)),
                const SizedBox(width: 16),
                Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${patient.lastName} ${patient.firstName}'.toUpperCase(), style: MediCoreTypography.sectionHeader.copyWith(color: Colors.white, fontSize: 16, letterSpacing: 0.5)),
                  Text('Code: ${patient.code} | Âge: ${patient.currentAge ?? patient.age ?? '-'} ans | Date de naissance: ${patient.dateOfBirth ?? '-'}', style: MediCoreTypography.body.copyWith(color: Colors.white.withOpacity(0.6), fontSize: 11)),
                ]),
                const SizedBox(width: 32),
                if (patient.currentAge != null) ...[_InfoChip(icon: Icons.cake_outlined, label: '${patient.currentAge} ans'), const SizedBox(width: 16)],
                if (patient.address != null && patient.address!.isNotEmpty) _InfoChip(icon: Icons.location_on_outlined, label: patient.address!, maxWidth: 200),
              ])),
              if (_hasChanges) Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.edit, color: Colors.orange, size: 14), SizedBox(width: 4), Text('Modifié', style: TextStyle(color: Colors.orange, fontSize: 11, fontWeight: FontWeight.w600))]),
              ),
              IconButton(onPressed: _handleBack, icon: const Icon(Icons.close, color: Colors.white), tooltip: 'Retour (Échap)'),
            ]),
          ),

          // MAIN CONTENT
          Expanded(
            child: Container(
              color: MediCoreColors.canvasGrey,
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                // TOP ROW
                SizedBox(
                  height: 130,
                  child: Row(children: [
                    // MOTIF + CYCLOPLÉGIE
                    Expanded(
                      flex: 5,
                      child: _MotifCycloplegieSection(selectedMotif: _selectedMotif, selectedCycloplegie: _selectedCycloplegie, onMotifChanged: (v) => setState(() => _selectedMotif = v), onCycloplegieChanged: (v) => setState(() => _selectedCycloplegie = v)),
                    ),
                    const SizedBox(width: 12),
                    // ACTES (editable)
                    Expanded(
                      flex: 2,
                      child: Row(children: [
                        Expanded(child: _ActesBoxEditable(title: 'Actes Généraux', controller: _actesGenerauxController)),
                        const SizedBox(width: 8),
                        Expanded(child: _ActesBoxEditable(title: 'Actes Ophtalmo', controller: _actesOphtalmoController)),
                      ]),
                    ),
                    const SizedBox(width: 12),
                    Row(children: [_QuickActionButton(icon: Icons.preview, tooltip: 'Prescription Optique', onPressed: _showPrescriptionOptique), const SizedBox(width: 6), _QuickActionButton(icon: Icons.blur_circular, tooltip: 'Prescription Lentilles', onPressed: _showPrescriptionLentilles), const SizedBox(width: 6), _QuickActionButton(icon: Icons.description, tooltip: 'Ordonnance', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrdonnancePage(patient: widget.patient))))]),
                  ]),
                ),
                const SizedBox(height: 10),
                // EYE PANELS
                Expanded(child: Row(children: [
                  Expanded(child: _NewVisitEyePanel(key: _odPanelKey, eyeLabel: 'OEIL DROIT (OD)', eyeColor: const Color(0xFF2E7D32), isRightEye: true, onChanged: _checkForChanges, onAxeSubmitted: () => _ogPanelKey.currentState?.focusOnSph())),
                  const SizedBox(width: 10),
                  Expanded(child: _NewVisitEyePanel(key: _ogPanelKey, eyeLabel: 'OEIL GAUCHE (OG)', eyeColor: const Color(0xFF1565C0), isRightEye: false, onChanged: _checkForChanges)),
                ])),
              ]),
            ),
          ),

          // BOTTOM BAR
          Container(
            height: 56,
            decoration: const BoxDecoration(color: MediCoreColors.deepNavy, border: Border(top: BorderSide(color: MediCoreColors.steelOutline, width: 2))),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _CompactButton(icon: Icons.send, label: 'ENVOYER', onPressed: _showSendMessageDialog),
              const SizedBox(width: 8),
              _CompactButton(icon: Icons.inbox, label: 'RECEVOIR', onPressed: _showReceiveMessagesDialog),
              const SizedBox(width: 16),
              Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
              const SizedBox(width: 16),
              _CompactButton(icon: Icons.preview, label: 'OPTIQUE', onPressed: _showPrescriptionOptique),
              const SizedBox(width: 8),
              _CompactButton(icon: Icons.blur_circular, label: 'LENTILLES', onPressed: _showPrescriptionLentilles),
              const SizedBox(width: 8),
              _CompactButton(icon: Icons.description_outlined, label: 'ORDO', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrdonnancePage(patient: widget.patient)))),
              const SizedBox(width: 16),
              Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
              const SizedBox(width: 16),
              _DilatationButton(label: 'S', tooltip: 'Dilatation sous Skiacol', onPressed: () => _sendDilatation('skiacol')),
              const SizedBox(width: 4),
              _DilatationButton(label: 'D', tooltip: 'Dilatation OD', onPressed: () => _sendDilatation('od')),
              const SizedBox(width: 4),
              _DilatationButton(label: 'G', tooltip: 'Dilatation OG', onPressed: () => _sendDilatation('og')),
              const SizedBox(width: 4),
              _DilatationButton(label: 'ODG', tooltip: 'Dilatation ODG', onPressed: () => _sendDilatation('odg')),
              const SizedBox(width: 16),
              Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
              const SizedBox(width: 16),
              _CompactButton(icon: Icons.account_balance_wallet, label: 'F5', onPressed: _showComptabiliteDialog, color: const Color(0xFF7B1FA2)),
              const SizedBox(width: 8),
              _CompactButton(icon: Icons.check_circle, label: 'VALIDER', onPressed: _showValidatePaymentDialog, color: const Color(0xFF00897B)),
              const SizedBox(width: 8),
              _CompactButton(icon: _isSaving ? Icons.hourglass_empty : Icons.save, label: _isSaving ? 'SAUVEGARDE...' : 'ENREGISTRER', onPressed: _isSaving ? () {} : _saveVisit, color: MediCoreColors.healthyGreen),
            ]),
          ),
        ]),
      ),
      ),
    );
  }
}

// MOTIF + CYCLOPLÉGIE with autocomplete
class _MotifCycloplegieSection extends StatefulWidget {
  final String? selectedMotif;
  final String selectedCycloplegie;
  final ValueChanged<String?> onMotifChanged;
  final ValueChanged<String> onCycloplegieChanged;

  const _MotifCycloplegieSection({required this.selectedMotif, required this.selectedCycloplegie, required this.onMotifChanged, required this.onCycloplegieChanged});

  static const motifs = ['BAV loin', 'Certificat', 'FO', 'RAS', 'Bav de près', 'Douleurs oculaires', 'Calcul OD', 'Calcul', 'Calcul OG', 'OR', 'Céphalées', 'Allergie', 'Contrôle', 'Pentacam', 'Picotement', 'Strabisme', 'BAV loin OD', 'BAV loin OG', 'Larmoiement', 'ORD', 'CalculOD', 'Myodesopsie', 'Céphalée', 'CalculOG', 'BAV de près', 'CHZ', 'Myodesopsie OD', 'Myodesopsie OG', 'Larmoiement OD'];
  static const cycloplegies = ['Aucune', 'Atropine 0.3', 'Atropine 0.5', 'Atropine 1%', 'Mydriaticum', 'Skiacol', 'Melange (M + N)'];

  @override
  State<_MotifCycloplegieSection> createState() => _MotifCycloplegieSectionState();
}

class _MotifCycloplegieSectionState extends State<_MotifCycloplegieSection> {
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _AutocompleteBox(
        title: 'MOTIF DE CONSULTATION',
        value: widget.selectedMotif,
        options: _MotifCycloplegieSection.motifs,
        onChanged: widget.onMotifChanged,
      )),
      const SizedBox(width: 8),
      Expanded(child: _AutocompleteBox(
        title: 'CYCLOPLÉGIE',
        value: widget.selectedCycloplegie,
        options: _MotifCycloplegieSection.cycloplegies,
        onChanged: (v) => widget.onCycloplegieChanged(v ?? 'Aucune'),
      )),
    ]);
  }
}

// Autocomplete box for MOTIF/CYCLOPLÉGIE
class _AutocompleteBox extends StatefulWidget {
  final String title;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;

  const _AutocompleteBox({required this.title, this.value, required this.options, required this.onChanged});

  @override
  State<_AutocompleteBox> createState() => _AutocompleteBoxState();
}

class _AutocompleteBoxState extends State<_AutocompleteBox> {
  late TextEditingController _controller;
  final _layerLink = LayerLink();
  final _focusNode = FocusNode();
  OverlayEntry? _overlayEntry;
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_AutocompleteBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onFocusChanged() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    }
  }

  void _onTextChanged() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isNotEmpty && text != _filterText) {
      _filterText = text;
      _showFilteredDropdown(text);
    } else if (text.isEmpty) {
      _removeOverlay();
    }
    widget.onChanged(_controller.text.isEmpty ? null : _controller.text);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showFilteredDropdown(String filter) {
    _removeOverlay();
    
    final filtered = widget.options.where((o) => 
      o.toLowerCase().contains(filter.toLowerCase())
    ).toList();
    
    if (filtered.isEmpty) return;
    
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 16,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(8, size.height - 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: MediCoreColors.steelOutline), borderRadius: BorderRadius.circular(4)),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: filtered.map((o) => InkWell(
                  onTap: () {
                    _selectOption(o);
                  },
                  child: Container(
                    color: o.toLowerCase().startsWith(filter.toLowerCase()) ? const Color(0xFFE3F2FD) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text(o, style: const TextStyle(fontSize: 12)),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }
  
  void _selectOption(String option) {
    // Remove listener temporarily to avoid triggering _onTextChanged
    _controller.removeListener(_onTextChanged);
    _controller.text = option;
    _controller.addListener(_onTextChanged);
    
    // Call the callback with selected value
    widget.onChanged(option);
    
    // Reset filter and close
    _filterText = '';
    _removeOverlay();
    _focusNode.unfocus();
  }

  void _showAllOptions() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 16,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(8, size.height - 8),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: MediCoreColors.steelOutline), borderRadius: BorderRadius.circular(4)),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.options.map((o) => InkWell(
                  onTap: () {
                    _selectOption(o);
                  },
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), child: Text(o, style: const TextStyle(fontSize: 12))),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(color: MediCoreColors.paperWhite, border: Border.all(color: MediCoreColors.steelOutline, width: 1), borderRadius: BorderRadius.circular(4)),
        child: Column(children: [
          Container(height: 30, decoration: const BoxDecoration(color: MediCoreColors.deepNavy, borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))), alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: 12), child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))),
          Expanded(child: Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              decoration: BoxDecoration(border: Border.all(color: MediCoreColors.steelOutline), borderRadius: BorderRadius.circular(4)),
              child: Row(children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(fontSize: 12),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      hintText: 'Sélectionner...',
                      hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                ),
                InkWell(
                  onTap: _showAllOptions,
                  child: const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Icon(Icons.arrow_drop_down, size: 20, color: MediCoreColors.deepNavy)),
                ),
              ]),
            ),
          )),
        ]),
      ),
    );
  }
}

// EYE PANEL
class _NewVisitEyePanel extends StatefulWidget {
  final String eyeLabel;
  final Color eyeColor;
  final bool isRightEye;
  final VoidCallback? onChanged; // Callback when any field changes
  final VoidCallback? onAxeSubmitted; // Callback when Enter pressed on AXE field

  const _NewVisitEyePanel({super.key, required this.eyeLabel, required this.eyeColor, required this.isRightEye, this.onChanged, this.onAxeSubmitted});

  @override
  State<_NewVisitEyePanel> createState() => _NewVisitEyePanelState();
}

class _NewVisitEyePanelState extends State<_NewVisitEyePanel> {
  final _conduiteController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false; // Flag to prevent notifications during load
  
  // Focus nodes for SPH/CYL/AXE navigation with Enter key
  final _sphFocusNode = FocusNode();
  final _cylFocusNode = FocusNode();
  final _axeFocusNode = FocusNode();
  
  /// Request focus on SPH field (called from parent to chain panels)
  void focusOnSph() {
    _sphFocusNode.requestFocus();
  }
  
  // Controllers for input fields
  final _k1Controller = TextEditingController();
  final _k2Controller = TextEditingController();
  final _pachyController = TextEditingController();
  final _addController = TextEditingController();
  final _toController = TextEditingController();
  final _dipController = TextEditingController();
  
  // Controllers for auto-calc but editable fields
  final _r1Controller = TextEditingController();
  final _r2Controller = TextEditingController();
  final _r0Controller = TextEditingController();
  final _tocController = TextEditingController();
  final _vlController = TextEditingController();
  
  // Dropdown values
  String? _sv, _av, _sphere, _cylindre, _axe, _gonio, _laf, _fo, _diag;
  
  // Change tracking - initial values
  String? _initialSv, _initialAv, _initialSphere, _initialCylindre, _initialAxe;
  String? _initialGonio, _initialLaf, _initialFo, _initialDiag;
  String _initialK1 = '', _initialK2 = '', _initialPachy = '', _initialTo = '';
  String _initialAdd = '', _initialDip = '', _initialConduite = '', _initialNotes = '';
  
  // Value getters for saving
  String? get svValue => _sv;
  String? get avValue => _av;
  String? get sphereValue => _sphere;
  String? get cylindreValue => _cylindre;
  String? get axeValue => _axe?.replaceAll('°', '');
  String? get vlValue => _vlController.text.isEmpty ? null : _vlController.text;
  String? get gonioValue => _gonio;
  String? get lafValue => _laf;
  String? get foValue => _fo;
  String? get diagValue => _diag;
  String? get k1Value => _k1Controller.text.isEmpty ? null : _k1Controller.text;
  String? get k2Value => _k2Controller.text.isEmpty ? null : _k2Controller.text;
  String? get r1Value => _r1Controller.text.isEmpty ? null : _r1Controller.text;
  String? get r2Value => _r2Controller.text.isEmpty ? null : _r2Controller.text;
  String? get r0Value => _r0Controller.text.isEmpty ? null : _r0Controller.text;
  String? get pachyValue => _pachyController.text.isEmpty ? null : _pachyController.text;
  String? get tocValue => _tocController.text.isEmpty ? null : _tocController.text;
  String? get toValue => _toController.text.isEmpty ? null : _toController.text;
  String? get addValue => _addController.text.isEmpty ? null : _addController.text;
  String? get dipValue => _dipController.text.isEmpty ? null : _dipController.text;
  String? get conduiteValue => _conduiteController.text.isEmpty ? null : _conduiteController.text;
  String? get notesValue => _notesController.text.isEmpty ? null : _notesController.text;
  String? get addition => _addController.text.isEmpty ? null : _addController.text;
  
  bool get hasChanges {
    return _sv != _initialSv || _av != _initialAv || _sphere != _initialSphere ||
        _cylindre != _initialCylindre || _axe != _initialAxe || _gonio != _initialGonio ||
        _laf != _initialLaf || _fo != _initialFo || _diag != _initialDiag ||
        _k1Controller.text != _initialK1 || _k2Controller.text != _initialK2 ||
        _pachyController.text != _initialPachy || _toController.text != _initialTo ||
        _addController.text != _initialAdd || _dipController.text != _initialDip ||
        _conduiteController.text != _initialConduite || _notesController.text != _initialNotes;
  }
  
  void resetChangeTracking() {
    _initialSv = _sv; _initialAv = _av; _initialSphere = _sphere;
    _initialCylindre = _cylindre; _initialAxe = _axe; _initialGonio = _gonio;
    _initialLaf = _laf; _initialFo = _fo; _initialDiag = _diag;
    _initialK1 = _k1Controller.text; _initialK2 = _k2Controller.text;
    _initialPachy = _pachyController.text; _initialTo = _toController.text;
    _initialAdd = _addController.text; _initialDip = _dipController.text;
    _initialConduite = _conduiteController.text; _initialNotes = _notesController.text;
  }
  
  void loadVisitData({
    String? sv, String? av, String? sphere, String? cylindre, String? axe,
    String? k1, String? k2, String? r1, String? r2, String? r0,
    String? pachy, String? toc, String? to, String? gonio, String? laf, String? fo,
    String? conduct, String? addition, String? dip, String? diag, String? notes,
  }) {
    _isLoading = true; // Prevent change notifications during load
    
    setState(() {
      _sv = sv; _av = av; _sphere = sphere; _cylindre = cylindre;
      _axe = axe != null && !axe.contains('°') ? '$axe°' : axe;
      _gonio = gonio; _laf = laf; _fo = fo; _diag = diag;
    });
    _k1Controller.text = k1 ?? '';
    _k2Controller.text = k2 ?? '';
    _r1Controller.text = r1 ?? '';
    _r2Controller.text = r2 ?? '';
    _r0Controller.text = r0 ?? '';
    _pachyController.text = pachy ?? '';
    _tocController.text = toc ?? '';
    _toController.text = to ?? '';
    _addController.text = addition ?? '';
    _dipController.text = dip ?? '';
    _conduiteController.text = conduct ?? '';
    _notesController.text = notes ?? '';
    _updateVL();
    
    // Set initial values for change tracking
    resetChangeTracking();
    
    _isLoading = false; // Re-enable change notifications
  }

  // Shortcuts with full meanings (double-click inserts full meaning)
  static const conduiteShortcuts = {'OCT': 'Optical Coherence Tomography', 'CO': 'Correction Optique', 'TM': 'Traitement Médical', 'Pentacam': 'Pentacam', 'FO': 'Fond d\'Œil'};

  // SV options (Sans Correction)
  static const svOptions = ['01/10', '02/10', '03/10', '04/10', '05/10', '06/10', '07/10', '08/10', '09/10', '10/10', 'CLD', 'VBDB', 'MDM', 'PL+', 'PL-', 'Suit la lumière', 'Ne suit pas la lumière', 'Strabisme', 'Micro-strabisme', 'Nystagmus', 'Amblyopie', 'Ésotropie', 'Exotropie'];
  static const svOptionsOG = ['01/10', '02/10', '03/10', '04/10', '05/10', '06/10', '07/10', '08/10', '09/10', '10/10', 'CLD', 'VBDB', 'MDM', 'PL+', 'PL-', 'Suit la lumière', 'Ne suit pas la lumière', 'Strabisme', 'Micro-strabisme', 'Nystagmus', 'Amblyopie', 'Ésotropie', 'Exotropie', 'Hypertropisie'];

  // AV options (Avec Correction)
  static const avOptions = ['01/10', '02/10', '03/10', '04/10', '05/10', '06/10', '07/10', '08/10', '09/10', '10/10', 'CLD', 'MDM', 'PL+', 'PL-', 'Amélioration', 'Stable', 'Dégradation', 'Amblyopie résiduelle', 'Vision corrigée'];
  static const avOptionsOG = ['01/10', '02/10', '03/10', '04/10', '05/10', '06/10', '07/10', '08/10', '09/10', '10/10', 'CLD', 'MDM', 'PL+', 'PL-', 'Amélioration', 'Stable', 'Dégradation', 'Amblyopie résiduelle', 'Vision corrigée', 'Hypertropisie', 'Hypotropie', 'Cyclotropie'];

  static const gonioOD = ['AIC normal', 'AIC stade 3', 'ouvert 3-4', 'recession angulaire large', 'recession angulaire minime', 'no'];
  static const gonioOG = ['AIC normal', 'AIC fermé sur 360', 'AIC fermé sur 270 degré', 'AIC fermé sur 3/4', 'ouvert 3-4'];
  static const lafOptions = ['RAS', 'Cat N ++', 'Cat evo', 'Pseudo simple', 'Cat N +', 'Conj allergique', 'Cat N +++', 'ET', 'Conj all', 'Cat II', 'Cat ss cap ++', 'Cat ss cap +', 'Cat N dense', 'KPS', 'ICP', 'sd sec', 'XT', 'Cat N ss cap', 'cat evo', 'Cat corticale', 'Cat ss cap', 'KPS+', 'Cat corticale +', 'Blepharite', 'NORMAL', 'ICP +', 'Cat Post', 'Cat mixte', 'Chalazion', 'Cat I'];
  static const foOptions = ['NORMAL', 'RD -', 'pas de rétinopathie diabétique', 'Myopique', 'RDNP modérée', 'RDNP minime', 'RAS', 'C/D 0.8', 'barrage d\'une lésion rétinienne', 'C/D 0.9', 'C/D 0.7', 'pas de signe de rétinopathie...', 'C/D 1', 'RDPP', 'C/D 0.6', 'idem', 'C/D 0.4', 'RD non proliférante minime', 'C/D 0.5', 'C/D 0.3', 'RAP', 'HTA', 'C/D 0.2', 'atrophie', 'DMLA', 'Normal', 'RD + barrage', 'C/D 1.0'];
  static const diagOptions = ['Conj allergiq', 'Sd sec', 'Conj allerg', 'Rhinoconj allergiq', 'Conj viral', 'Conj ADV', 'A', 'V3m pas LPDR', 'Conj bact', 'Conj aller', 'Conj all', 'Conj', 'Blepharite', 'An', 'Xt predomine OG', 'Xt intermitente alternante', 'Xt alternante predominant OG', 'V3m pas LPDR diminution de phosphene', 'Uveite ant', 'Strabsisme convergent alternat', 'Strabismùe convergent alternant', 'Strabisme convergent predominant OG', 'Strabisme convergent bilaterale predomin OG', 'Strabisme convergent', 'Strabisme alternant', 'Stenose de VLN bilaterale', 'Sd sec / blepharite'];

  List<String> get sphereCylindreValues {
    List<String> values = [];
    for (double v = -20.0; v <= 17.0; v += 0.25) {
      values.add(v >= 0 ? '+${v.toStringAsFixed(2)}' : v.toStringAsFixed(2));
    }
    return values;
  }
  List<String> get axeValues => List.generate(37, (i) => '${i * 5}°');

  // Update VL from SPH, CYL, AXE
  void _updateVL() {
    String vl = '';
    if (_sphere != null && _sphere!.isNotEmpty) {
      if (_cylindre == null || _cylindre!.isEmpty || _cylindre == '+0.00') {
        vl = _sphere!;
      } else {
        vl = '$_sphere ( $_cylindre à ${_axe ?? '0°'} )';
      }
    }
    _vlController.text = vl;
  }

  @override
  void initState() {
    super.initState();
    _k1Controller.addListener(_calculateFromK);
    _k2Controller.addListener(_calculateFromK);
    _pachyController.addListener(_calculateTOC);
    
    // Add change listeners for all controllers
    _k1Controller.addListener(_notifyChange);
    _k2Controller.addListener(_notifyChange);
    _pachyController.addListener(_notifyChange);
    _addController.addListener(_notifyChange);
    _toController.addListener(_notifyChange);
    _dipController.addListener(_notifyChange);
    _conduiteController.addListener(_notifyChange);
    _notesController.addListener(_notifyChange);
  }
  
  void _notifyChange() {
    if (!_isLoading) {
      widget.onChanged?.call();
    }
  }

  // R1 = 337.5 / K1, R2 = 337.5 / K2, R0 = (R1 + R2) / 2 + 0.8
  void _calculateFromK() {
    final k1 = double.tryParse(_k1Controller.text);
    final k2 = double.tryParse(_k2Controller.text);
    
    double r1Val = 0, r2Val = 0;
    
    if (k1 != null && k1 > 0) {
      r1Val = 337.5 / k1;
      _r1Controller.text = r1Val.toStringAsFixed(2);
    }
    if (k2 != null && k2 > 0) {
      r2Val = 337.5 / k2;
      _r2Controller.text = r2Val.toStringAsFixed(2);
    }
    if (r1Val > 0 && r2Val > 0) {
      _r0Controller.text = ((r1Val + r2Val) / 2 + 0.8).toStringAsFixed(2);
    }
  }

  // T.O.C = (545 - PACHY) × 0.071
  void _calculateTOC() {
    final pachy = double.tryParse(_pachyController.text);
    if (pachy != null && pachy > 0) {
      _tocController.text = ((545 - pachy) * 0.071).toStringAsFixed(2);
    }
  }

  void _addConduite(String fullMeaning) {
    final current = _conduiteController.text;
    _conduiteController.text = current.isNotEmpty ? '$current + $fullMeaning' : fullMeaning;
    setState(() {});
  }

  @override
  void dispose() {
    _conduiteController.dispose();
    _notesController.dispose();
    _k1Controller.dispose();
    _k2Controller.dispose();
    _pachyController.dispose();
    _addController.dispose();
    _toController.dispose();
    _dipController.dispose();
    _r1Controller.dispose();
    _r2Controller.dispose();
    _r0Controller.dispose();
    _tocController.dispose();
    _vlController.dispose();
    _sphFocusNode.dispose();
    _cylFocusNode.dispose();
    _axeFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gonioOptions = widget.isRightEye ? gonioOD : gonioOG;

    return Container(
      decoration: BoxDecoration(color: MediCoreColors.paperWhite, border: Border.all(color: widget.eyeColor, width: 2), borderRadius: BorderRadius.circular(6), boxShadow: [BoxShadow(color: widget.eyeColor.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(children: [
        Container(
          height: 32,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [widget.eyeColor, widget.eyeColor.withOpacity(0.85)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4))),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(widget.isRightEye ? Icons.visibility : Icons.visibility_outlined, color: Colors.white, size: 16), const SizedBox(width: 8), Text(widget.eyeLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5))]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(children: [
              Expanded(child: _FieldRowFlex(children: [
                _FieldDropdown('SV', _sv, widget.isRightEye ? svOptions : svOptionsOG, (v) { setState(() => _sv = v); _notifyChange(); }),
                _FieldDropdown('AV', _av, widget.isRightEye ? avOptions : avOptionsOG, (v) { setState(() => _av = v); _notifyChange(); }),
              ])),
              const SizedBox(height: 6),
              Expanded(child: Row(children: [
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _FieldDropdown('SPH', _sphere, sphereCylindreValues, (v) { setState(() => _sphere = v); _updateVL(); _notifyChange(); }, focusNode: _sphFocusNode, onFieldSubmitted: () => _cylFocusNode.requestFocus()))),
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _FieldDropdown('CYL', _cylindre, sphereCylindreValues, (v) { setState(() => _cylindre = v); _updateVL(); _notifyChange(); }, focusNode: _cylFocusNode, onFieldSubmitted: () => _axeFocusNode.requestFocus()))),
                Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _FieldDropdown('AXE', _axe, axeValues, (v) { setState(() => _axe = v); _updateVL(); _notifyChange(); }, focusNode: _axeFocusNode, onFieldSubmitted: () => widget.onAxeSubmitted?.call()))),
                Expanded(flex: 2, child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: _FieldAutoCalc('VL', _vlController, green: true))),
              ])),
              const SizedBox(height: 6),
              Expanded(child: _FieldRowFlex(children: [
                _FieldControlled('K1', _k1Controller, yellow: true), 
                _FieldControlled('K2', _k2Controller, yellow: true), 
                if (!widget.isRightEye) _FieldControlled('ADD', _addController, highlight: true), 
                _FieldAutoCalc('R0', _r0Controller),
              ])),
              const SizedBox(height: 6),
              Expanded(child: _FieldRowFlex(children: [_FieldAutoCalc('R1', _r1Controller, derived: true), _FieldAutoCalc('R2', _r2Controller, derived: true)])),
              const SizedBox(height: 6),
              Expanded(child: _FieldRowFlex(children: [
                _FieldControlled('PACHY', _pachyController), 
                _FieldAutoCalc('T.O.C', _tocController), 
                if (!widget.isRightEye) _FieldControlled('D.I.P', _dipController, highlight: true),
              ])),
              const SizedBox(height: 6),
              Expanded(flex: 2, child: _NotesInput(controller: _notesController)),
              const SizedBox(height: 6),
              Expanded(child: _FieldRowFlex(children: [_FieldDropdown('GONIO', _gonio, gonioOptions, (v) { setState(() => _gonio = v); _notifyChange(); }), _FieldControlled('T.O', _toController)])),
              const SizedBox(height: 6),
              Expanded(child: _FieldRowFlex(children: [_FieldDropdown('L.A.F', _laf, lafOptions, (v) { setState(() => _laf = v); _notifyChange(); })])),
              const SizedBox(height: 6),
              Expanded(child: _FieldRowFlex(children: [_FieldDropdown('F.O', _fo, foOptions, (v) { setState(() => _fo = v); _notifyChange(); })])),
              const SizedBox(height: 6),
              Expanded(flex: 2, child: widget.isRightEye 
                ? _ConduiteInput(controller: _conduiteController, shortcuts: conduiteShortcuts, onShortcut: _addConduite)
                : _FieldDropdown('DIAG', _diag, diagOptions, (v) { setState(() => _diag = v); _notifyChange(); })),
            ]),
          ),
        ),
      ]),
    );
  }
}

// FIELD COMPONENTS
class _FieldRowFlex extends StatelessWidget {
  final List<Widget> children;
  const _FieldRowFlex({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(children: children.map((child) => child is Expanded ? child : Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: child))).toList());
  }
}

class _FieldInput extends StatelessWidget {
  final String label;
  final bool highlight, yellow, derived;

  const _FieldInput(this.label, {this.highlight = false, this.yellow = false, this.derived = false});

  @override
  Widget build(BuildContext context) {
    Color bgColor, borderColor, labelBgColor, labelTextColor;
    if (highlight) { bgColor = const Color(0xFFFFF3E0); borderColor = const Color(0xFFFF9800); labelBgColor = const Color(0xFFFFE0B2); labelTextColor = const Color(0xFFE65100); }
    else if (yellow) { bgColor = const Color(0xFFFFFDE7); borderColor = const Color(0xFFFFD54F); labelBgColor = const Color(0xFFFFECB3); labelTextColor = const Color(0xFFF57C00); }
    else if (derived) { bgColor = const Color(0xFFE3F2FD); borderColor = const Color(0xFF64B5F6); labelBgColor = const Color(0xFFBBDEFB); labelTextColor = const Color(0xFF1565C0); }
    else { bgColor = Colors.white; borderColor = MediCoreColors.steelOutline; labelBgColor = const Color(0xFFECEFF1); labelTextColor = MediCoreColors.deepNavy; }

    return Container(
      decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 1), borderRadius: BorderRadius.circular(3)),
      child: Row(children: [
        Container(width: 55, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: labelBgColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))), alignment: Alignment.center, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelTextColor), overflow: TextOverflow.ellipsis)),
        Expanded(child: TextField(style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MediCoreColors.deepNavy), textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)))),
      ]),
    );
  }
}

// Field with controller for editable inputs
class _FieldControlled extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool highlight, yellow;

  const _FieldControlled(this.label, this.controller, {this.highlight = false, this.yellow = false});

  @override
  Widget build(BuildContext context) {
    Color bgColor, borderColor, labelBgColor, labelTextColor;
    if (highlight) { bgColor = const Color(0xFFFFF3E0); borderColor = const Color(0xFFFF9800); labelBgColor = const Color(0xFFFFE0B2); labelTextColor = const Color(0xFFE65100); }
    else if (yellow) { bgColor = const Color(0xFFFFFDE7); borderColor = const Color(0xFFFFD54F); labelBgColor = const Color(0xFFFFECB3); labelTextColor = const Color(0xFFF57C00); }
    else { bgColor = Colors.white; borderColor = MediCoreColors.steelOutline; labelBgColor = const Color(0xFFECEFF1); labelTextColor = MediCoreColors.deepNavy; }

    return Container(
      decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 1), borderRadius: BorderRadius.circular(3)),
      child: Row(children: [
        Container(width: 55, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: labelBgColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))), alignment: Alignment.center, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelTextColor), overflow: TextOverflow.ellipsis)),
        Expanded(child: TextField(controller: controller, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MediCoreColors.deepNavy), textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)))),
      ]),
    );
  }
}

// Auto-calculated but editable field
class _FieldAutoCalc extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool derived, green;

  const _FieldAutoCalc(this.label, this.controller, {this.derived = false, this.green = false});

  @override
  Widget build(BuildContext context) {
    Color bgColor, borderColor, labelBgColor, labelTextColor, valueColor;
    if (green) { bgColor = const Color(0xFFE8F5E9); borderColor = const Color(0xFF4CAF50); labelBgColor = const Color(0xFFC8E6C9); labelTextColor = const Color(0xFF2E7D32); valueColor = const Color(0xFF2E7D32); }
    else if (derived) { bgColor = const Color(0xFFE3F2FD); borderColor = const Color(0xFF64B5F6); labelBgColor = const Color(0xFFBBDEFB); labelTextColor = const Color(0xFF1565C0); valueColor = const Color(0xFF1565C0); }
    else { bgColor = const Color(0xFFF5F5F5); borderColor = MediCoreColors.steelOutline; labelBgColor = const Color(0xFFECEFF1); labelTextColor = MediCoreColors.deepNavy; valueColor = MediCoreColors.deepNavy; }

    return Container(
      decoration: BoxDecoration(color: bgColor, border: Border.all(color: borderColor, width: 1), borderRadius: BorderRadius.circular(3)),
      child: Row(children: [
        Container(width: 55, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: BoxDecoration(color: labelBgColor, borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))), alignment: Alignment.center, child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: labelTextColor), overflow: TextOverflow.ellipsis)),
        Expanded(child: TextField(controller: controller, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor), textAlign: TextAlign.center, decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)))),
      ]),
    );
  }
}

class _FieldDropdown extends StatefulWidget {
  final String label;
  final String? value;
  final List<String> options;
  final ValueChanged<String?> onChanged;
  final FocusNode? focusNode; // Optional external focus node
  final VoidCallback? onFieldSubmitted; // Called when Enter is pressed

  const _FieldDropdown(this.label, this.value, this.options, this.onChanged, {this.focusNode, this.onFieldSubmitted});

  @override
  State<_FieldDropdown> createState() => _FieldDropdownState();
}

class _FieldDropdownState extends State<_FieldDropdown> {
  late TextEditingController _controller;
  FocusNode? _internalFocusNode;
  FocusNode get _focusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());
  OverlayEntry? _overlayEntry;
  final _layerLink = LayerLink();
  String _filterText = '';

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_FieldDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && widget.value != _controller.text) {
      _controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _internalFocusNode?.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _onTextChanged() {
    final text = _controller.text.trim().toLowerCase();
    if (text.isNotEmpty && text != _filterText) {
      _filterText = text;
      _showFilteredDropdown(text);
    } else if (text.isEmpty) {
      _removeOverlay();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showFilteredDropdown(String filter) {
    _removeOverlay();
    
    // Filter options based on typed text
    final filtered = widget.options.where((o) => 
      o.toLowerCase().contains(filter.toLowerCase())
    ).toList();
    
    if (filtered.isEmpty) return;
    
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 55,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(55, size.height),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: MediCoreColors.steelOutline), borderRadius: BorderRadius.circular(4)),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: filtered.map((o) => InkWell(
                  onTap: () {
                    _controller.text = o;
                    widget.onChanged(o);
                    _removeOverlay();
                    _filterText = '';
                  },
                  child: Container(
                    color: o.toLowerCase().startsWith(filter.toLowerCase()) ? const Color(0xFFE3F2FD) : Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Text(o, style: const TextStyle(fontSize: 14)),
                  ),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _showDropdown() {
    _removeOverlay();
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 55,
        child: CompositedTransformFollower(
          link: _layerLink,
          offset: Offset(55, size.height),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: MediCoreColors.steelOutline), borderRadius: BorderRadius.circular(4)),
              child: ListView(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                children: widget.options.map((o) => InkWell(
                  onTap: () {
                    _controller.text = o;
                    widget.onChanged(o);
                    _removeOverlay();
                  },
                  child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), child: Text(o, style: const TextStyle(fontSize: 14))),
                )).toList(),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: Container(
        decoration: BoxDecoration(color: Colors.white, border: Border.all(color: MediCoreColors.steelOutline, width: 1), borderRadius: BorderRadius.circular(3)),
        child: Row(children: [
          Container(width: 55, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: const BoxDecoration(color: Color(0xFFECEFF1), borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))), alignment: Alignment.center, child: Text(widget.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: MediCoreColors.deepNavy), overflow: TextOverflow.ellipsis)),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: MediCoreColors.deepNavy),
              textAlign: TextAlign.center,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8)),
              onChanged: (v) => widget.onChanged(v.isEmpty ? null : v),
              onSubmitted: (_) {
                _removeOverlay();
                widget.onFieldSubmitted?.call();
              },
            ),
          ),
          InkWell(
            onTap: _showDropdown,
            child: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.arrow_drop_down, size: 20, color: MediCoreColors.deepNavy)),
          ),
        ]),
      ),
    );
  }
}

class _FieldDisplay extends StatelessWidget {
  final String label;
  final String value;

  const _FieldDisplay(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFE8F5E9), border: Border.all(color: const Color(0xFF4CAF50), width: 1), borderRadius: BorderRadius.circular(3)),
      child: Row(children: [
        Container(width: 55, padding: const EdgeInsets.symmetric(horizontal: 4), decoration: const BoxDecoration(color: Color(0xFFC8E6C9), borderRadius: BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2))), alignment: Alignment.center, child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF2E7D32)), overflow: TextOverflow.ellipsis)),
        Expanded(child: Center(child: Text(value.isEmpty ? '—' : value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF2E7D32)), overflow: TextOverflow.ellipsis))),
      ]),
    );
  }
}

class _NotesInput extends StatelessWidget {
  final TextEditingController controller;
  
  const _NotesInput({required this.controller});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFFFFFDE7), border: Border.all(color: const Color(0xFFFFD54F), width: 1.5), borderRadius: BorderRadius.circular(4), boxShadow: [BoxShadow(color: const Color(0xFFFFD54F).withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 1))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: const BoxDecoration(color: Color(0xFFFFECB3), borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))), child: const Row(children: [Icon(Icons.edit_note, size: 12, color: Color(0xFFF57C00)), SizedBox(width: 4), Text('NOTES', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Color(0xFFF57C00), letterSpacing: 0.5))])),
        Expanded(child: Padding(padding: const EdgeInsets.all(6), child: TextField(controller: controller, maxLines: null, expands: true, style: const TextStyle(fontSize: 14, color: Color(0xFF424242)), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)))),
      ]),
    );
  }
}

class _ConduiteInput extends StatelessWidget {
  final TextEditingController controller;
  final Map<String, String> shortcuts;
  final ValueChanged<String> onShortcut;

  const _ConduiteInput({required this.controller, required this.shortcuts, required this.onShortcut});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: MediCoreColors.steelOutline, width: 1), borderRadius: BorderRadius.circular(3)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: const BoxDecoration(color: Color(0xFFECEFF1), borderRadius: BorderRadius.only(topLeft: Radius.circular(2), topRight: Radius.circular(2))),
          child: Row(children: [
            const Text('CONDUITE A TENIR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: MediCoreColors.deepNavy)),
            const Spacer(),
            ...shortcuts.entries.map((e) => Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Tooltip(
                message: 'Double-clic: ${e.value}',
                child: GestureDetector(
                  onDoubleTap: () => onShortcut(e.value),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: MediCoreColors.professionalBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(3), border: Border.all(color: MediCoreColors.professionalBlue.withOpacity(0.3))),
                    child: Text(e.key, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: MediCoreColors.professionalBlue)),
                  ),
                ),
              ),
            )),
          ]),
        ),
        Expanded(child: Padding(padding: const EdgeInsets.all(6), child: TextField(controller: controller, maxLines: null, expands: true, style: const TextStyle(fontSize: 14, color: MediCoreColors.deepNavy), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero)))),
      ]),
    );
  }
}

// SHARED WIDGETS
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final double? maxWidth;

  const _InfoChip({required this.icon, required this.label, this.maxWidth});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: maxWidth != null ? BoxConstraints(maxWidth: maxWidth!) : null,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(3), border: Border.all(color: MediCoreColors.steelOutline, width: 1)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white.withOpacity(0.7), size: 13), const SizedBox(width: 5), Flexible(child: Text(label, style: MediCoreTypography.body.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 11), overflow: TextOverflow.ellipsis))]),
    );
  }
}

class _ActesBoxEditable extends StatelessWidget {
  final String title;
  final TextEditingController controller;

  const _ActesBoxEditable({required this.title, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: MediCoreColors.paperWhite, border: Border.all(color: MediCoreColors.steelOutline, width: 1), borderRadius: BorderRadius.circular(4)),
      child: Column(children: [
        Container(height: 24, decoration: const BoxDecoration(color: MediCoreColors.deepNavy, borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3))), alignment: Alignment.center, child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600))),
        Expanded(child: Padding(padding: const EdgeInsets.all(6), child: TextField(controller: controller, maxLines: null, expands: true, style: const TextStyle(fontSize: 14), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero, hintText: '...', hintStyle: TextStyle(color: Colors.grey))))),
      ]),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _QuickActionButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: tooltip, child: Material(color: MediCoreColors.deepNavy, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(4), child: Container(width: 42, height: 42, decoration: BoxDecoration(borderRadius: BorderRadius.circular(4), border: Border.all(color: MediCoreColors.steelOutline, width: 1)), child: Icon(icon, color: Colors.white, size: 20)))));
  }
}

class _CompactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color? color;

  const _CompactButton({required this.icon, required this.label, required this.onPressed, this.color});

  @override
  Widget build(BuildContext context) {
    return Material(color: color ?? MediCoreColors.professionalBlue, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(4), child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 16), const SizedBox(width: 6), Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]))));
  }
}

class _DilatationButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _DilatationButton({required this.label, required this.tooltip, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(message: tooltip, child: Material(color: MediCoreColors.healthyGreen, borderRadius: BorderRadius.circular(4), child: InkWell(onTap: onPressed, borderRadius: BorderRadius.circular(4), child: Container(width: label.length > 1 ? 40 : 32, height: 32, alignment: Alignment.center, child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))))));
  }
}
