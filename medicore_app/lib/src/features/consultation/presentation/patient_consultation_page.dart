import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart';
import '../../patients/data/age_calculator_service.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../messages/presentation/send_message_dialog.dart';
import '../../messages/presentation/receive_messages_dialog.dart';
import '../../comptabilite/presentation/comptabilite_dialog.dart';
import '../../comptabilite/presentation/payments_provider.dart';
import '../../visits/data/visits_repository.dart';
import '../../waiting_queue/presentation/waiting_queue_provider.dart';
import '../../patients/presentation/patient_form_dialog.dart';
import '../../patients/presentation/patients_provider.dart';
import 'validate_payment_dialog.dart';
import 'new_visit_page.dart';
import 'prescription_optique_dialog.dart';
import 'prescription_lentilles_dialog.dart';
import 'historic_payments_dialog.dart';
import '../../ordonnance/presentation/ordonnance_page.dart';
import '../../../core/generated/medicore.pb.dart';

/// Patient Consultation Page - The heart of the application
/// Opens when double-clicking on a patient from the dashboard
/// Fixed layout: Top bar (patient info) + Content area + Bottom bar (actions)
class PatientConsultationPage extends ConsumerStatefulWidget {
  final Patient patient;

  const PatientConsultationPage({
    super.key,
    required this.patient,
  });

  @override
  ConsumerState<PatientConsultationPage> createState() => _PatientConsultationPageState();
}

class _PatientConsultationPageState extends ConsumerState<PatientConsultationPage> {
  final FocusNode _focusNode = FocusNode();
  Visit? _selectedVisit;
  List<Visit> _allVisits = [];

  @override
  void initState() {
    super.initState();
    // Request focus for keyboard shortcuts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  void _selectVisit(Visit visit) {
    setState(() {
      _selectedVisit = visit;
    });
  }
  
  Future<void> _editVisit(Visit visit) async {
    final editedVisitId = visit.id;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewVisitPage(patient: widget.patient, existingVisit: visit),
      ),
    );
    // Refresh visits list after returning from edit page
    if (mounted) {
      ref.invalidate(patientVisitsProvider(widget.patient.code));
      ref.invalidate(patientVisitCountProvider(widget.patient.code));
      
      // Fetch fresh visits and update selected visit with new data
      final freshVisits = await ref.read(patientVisitsProvider(widget.patient.code).future);
      final updatedVisit = freshVisits.where((v) => v.id == editedVisitId).firstOrNull;
      if (updatedVisit != null) {
        setState(() {
          _selectedVisit = updatedVisit;
          _allVisits = freshVisits;
        });
      }
    }
  }
  
  Future<void> _deleteVisit(Visit visit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer la visite'),
        content: Text('Voulez-vous vraiment supprimer la visite du ${DateFormat('dd/MM/yyyy').format(visit.visitDate)} ?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final repository = ref.read(visitsRepositoryProvider);
      await repository.deleteVisit(visit.id);
      
      // Refresh visits list and count
      ref.invalidate(patientVisitsProvider(widget.patient.code));
      ref.invalidate(patientVisitCountProvider(widget.patient.code));
      
      // Clear selection if deleted visit was selected
      if (_selectedVisit?.id == visit.id) {
        setState(() => _selectedVisit = null);
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Visite supprimée'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  void _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      // F5 - Open Historic Payments
      if (event.logicalKey == LogicalKeyboardKey.f5) {
        _showHistoricPaymentsDialog();
      }
      // Escape - Go back
      else if (event.logicalKey == LogicalKeyboardKey.escape) {
        Navigator.of(context).pop();
      }
      // Arrow Up - Previous visit
      else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _navigateVisit(-1);
      }
      // Arrow Down - Next visit
      else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _navigateVisit(1);
      }
    }
  }

  void _navigateVisit(int direction) {
    if (_allVisits.isEmpty || _selectedVisit == null) return;
    final currentIndex = _allVisits.indexWhere((v) => v.id == _selectedVisit!.id);
    if (currentIndex == -1) return;
    final newIndex = currentIndex + direction;
    if (newIndex >= 0 && newIndex < _allVisits.length) {
      setState(() {
        _selectedVisit = _allVisits[newIndex];
      });
    }
  }

  void _updateVisitsList(List<Visit> visits) {
    _allVisits = visits;
  }

  void _showHistoricPaymentsDialog() {
    showDialog(
      context: context,
      builder: (context) => HistoricPaymentsDialog(
        patientCode: widget.patient.code,
        patientFirstName: widget.patient.firstName,
        patientLastName: widget.patient.lastName,
      ),
    );
  }
  
  void _showEditPatientDialog() async {
    await showDialog(
      context: context,
      builder: (context) => PatientFormDialog(patient: widget.patient),
    );
    // Refresh patient data after edit
    ref.invalidate(allFilteredPatientsProvider);
  }

  Future<void> _openNewVisit() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewVisitPage(patient: widget.patient),
      ),
    );
    // Refresh visits list after returning from new visit page
    if (mounted) {
      ref.invalidate(patientVisitsProvider(widget.patient.code));
      ref.invalidate(patientVisitCountProvider(widget.patient.code));
    }
  }

  // Calculate VL from visit data
  String _calculateVL(String? sphere, String? cylinder, String? axis) {
    if (sphere == null || sphere.isEmpty) return '';
    if (cylinder == null || cylinder.isEmpty || cylinder == '+0.00' || cylinder == '0.00') return sphere;
    return '$sphere ( $cylinder à ${axis ?? '0°'} )';
  }

  void _showPrescriptionOptique() {
    if (_selectedVisit == null) return;
    final visit = _selectedVisit!;
    final vlOD = _calculateVL(visit.odSphere, visit.odCylinder, visit.odAxis);
    final vlOG = _calculateVL(visit.ogSphere, visit.ogCylinder, visit.ogAxis);
    final patientName = '${widget.patient.firstName} ${widget.patient.lastName}';
    final patientCode = widget.patient.code.toString();
    final barcode = widget.patient.barcode;
    final age = widget.patient.currentAge?.toString();
    showDialog(
      context: context,
      builder: (context) => PrescriptionOptiqueDialog(
        vlOD: vlOD, vlOG: vlOG, addition: visit.addition, // Pass the addition value for Vision de Près
        patientName: patientName, patientCode: patientCode, barcode: barcode, age: age,
      ),
    );
  }

  void _showPrescriptionLentilles() {
    if (_selectedVisit == null) return;
    final visit = _selectedVisit!;
    final vlOD = _calculateVL(visit.odSphere, visit.odCylinder, visit.odAxis);
    final vlOG = _calculateVL(visit.ogSphere, visit.ogCylinder, visit.ogAxis);
    final patientName = '${widget.patient.firstName} ${widget.patient.lastName}';
    final patientCode = widget.patient.code.toString();
    final barcode = widget.patient.barcode;
    final age = widget.patient.currentAge?.toString();
    showDialog(
      context: context,
      builder: (context) => PrescriptionLentillesDialog(
        vlOD: vlOD, vlOG: vlOG,
        patientName: patientName, patientCode: patientCode, barcode: barcode, age: age,
      ),
    );
  }

  void _showSendMessageDialog() {
    final authState = ref.read(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    
    if (authState.user != null && selectedRoom != null) {
      showDialog(
        context: context,
        builder: (context) => SendMessageDialog(
          preSelectedRoomId: selectedRoom.id,
          // Link patient to the message
          patientCode: widget.patient.code,
          patientName: '${widget.patient.firstName} ${widget.patient.lastName}',
        ),
      );
    }
  }

  void _showReceiveMessagesDialog() {
    final authState = ref.read(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    
    if (selectedRoom != null) {
      showDialog(
        context: context,
        builder: (context) => ReceiveMessagesDialog(
          doctorRoomId: selectedRoom.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final userName = authState.user?.name ?? 'Utilisateur';
    final patient = widget.patient;

    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: MediCoreColors.canvasGrey,
        body: Column(
          children: [
            // ═══════════════════════════════════════════════════════════
            // TOP BAR - User & Patient Information
            // ═══════════════════════════════════════════════════════════
            Container(
              height: 70,
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // User name (Doctor/Assistant)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: MediCoreColors.professionalBlue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: MediCoreColors.professionalBlue,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userName.toUpperCase(),
                          style: MediCoreTypography.button.copyWith(
                            color: Colors.white,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Vertical divider
                  Container(
                    width: 2,
                    height: 40,
                    color: MediCoreColors.steelOutline,
                  ),
                  
                  const SizedBox(width: 32),
                  
                  // Patient Information
                  Expanded(
                    child: Row(
                      children: [
                        // Patient icon
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: MediCoreColors.healthyGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: MediCoreColors.healthyGreen,
                              width: 1,
                            ),
                          ),
                          child: const Icon(
                            Icons.person_outline,
                            color: MediCoreColors.healthyGreen,
                            size: 24,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Patient name
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${patient.lastName} ${patient.firstName}'.toUpperCase(),
                              style: MediCoreTypography.sectionHeader.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Patient N° ${patient.code}',
                              style: MediCoreTypography.body.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(width: 32),
                        
                        // Age
                        if (patient.currentAge != null) ...[
                          _InfoChip(
                            icon: Icons.cake_outlined,
                            label: '${patient.currentAge} ans',
                          ),
                          const SizedBox(width: 16),
                        ],
                        
                        // Address
                        if (patient.address != null && patient.address!.isNotEmpty) ...[
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: patient.address!,
                            maxWidth: 200,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Edit Patient button
                  IconButton(
                    onPressed: _showEditPatientDialog,
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Modifier le patient',
                  ),
                  const SizedBox(width: 8),
                  
                  // Back button
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                    tooltip: 'Retour (Échap)',
                  ),
                ],
              ),
            ),

            // ═══════════════════════════════════════════════════════════
            // MAIN CONTENT AREA - Ophthalmology Consultation Form
            // ═══════════════════════════════════════════════════════════
            Expanded(
              child: Container(
                color: MediCoreColors.canvasGrey,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    // ─────────────────────────────────────────────────────
                    // TOP ROW: Past Visits | Actes | Quick Actions
                    // ─────────────────────────────────────────────────────
                    SizedBox(
                      height: 130,
                      child: Row(
                        children: [
                          // Past Visits Table with total count
                          Expanded(
                            flex: 5,
                            child: _PastVisitsSection(
                              patientCode: patient.code,
                              selectedVisit: _selectedVisit,
                              onVisitSelected: _selectVisit,
                              onVisitsLoaded: _updateVisitsList,
                              onVisitDoubleClick: _editVisit,
                              onVisitDelete: _deleteVisit,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Actes Boxes
                          Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                const Expanded(child: _ActesBox(title: 'Actes Généraux')),
                                const SizedBox(width: 8),
                                const Expanded(child: _ActesBox(title: 'Actes Ophtalmo')),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Quick Action Buttons
                          Row(
                            children: [
                              _QuickActionButton(icon: Icons.add_circle_outline, tooltip: 'Nouvelle Visite', onPressed: _openNewVisit),
                              const SizedBox(width: 6),
                              _QuickActionButton(icon: Icons.preview, tooltip: 'Prescription Optique', onPressed: _showPrescriptionOptique),
                              const SizedBox(width: 6),
                              _QuickActionButton(icon: Icons.blur_circular, tooltip: 'Prescription Lentilles', onPressed: _showPrescriptionLentilles),
                              const SizedBox(width: 6),
                              _QuickActionButton(icon: Icons.description, tooltip: 'Ordonnance', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrdonnancePage(patient: widget.patient)))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 10),
                    
                    // ─────────────────────────────────────────────────────
                    // MAIN AREA: Right Eye (OD) | Left Eye (OG)
                    // ─────────────────────────────────────────────────────
                    Expanded(
                      child: Row(
                        children: [
                          // RIGHT EYE (OD) - Left side of screen
                          Expanded(
                            child: _EyeExamPanel(
                              eyeLabel: 'OEIL DROIT (OD)',
                              eyeColor: const Color(0xFF2E7D32), // Green
                              isRightEye: true,
                              visit: _selectedVisit,
                            ),
                          ),
                          
                          const SizedBox(width: 10),
                          
                          // LEFT EYE (OG) - Right side of screen
                          Expanded(
                            child: _EyeExamPanel(
                              eyeLabel: 'OEIL GAUCHE (OG)',
                              eyeColor: const Color(0xFF1565C0), // Blue
                              isRightEye: false,
                              visit: _selectedVisit,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ═══════════════════════════════════════════════════════════
            // BOTTOM BAR - Action Buttons (Compact)
            // ═══════════════════════════════════════════════════════════
            Container(
              height: 56,
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                border: Border(
                  top: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 2,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Send Message Button
                  _CompactButton(icon: Icons.send, label: 'ENVOYER', onPressed: _showSendMessageDialog),
                  const SizedBox(width: 8),
                  _CompactButton(icon: Icons.inbox, label: 'RECEVOIR', onPressed: _showReceiveMessagesDialog),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
                  const SizedBox(width: 16),
                  _CompactButton(icon: Icons.add_circle_outline, label: 'VISITE', onPressed: () => _openNewVisit(), color: MediCoreColors.healthyGreen),
                  const SizedBox(width: 8),
                  _CompactButton(icon: Icons.preview, label: 'OPTIQUE', onPressed: _showPrescriptionOptique),
                  const SizedBox(width: 8),
                  _CompactButton(icon: Icons.blur_circular, label: 'LENTILLES', onPressed: _showPrescriptionLentilles),
                  const SizedBox(width: 8),
                  _CompactButton(icon: Icons.description_outlined, label: 'ORDO', onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OrdonnancePage(patient: widget.patient)))),
                  const SizedBox(width: 16),
                  Container(width: 1, height: 32, color: MediCoreColors.steelOutline),
                  const SizedBox(width: 16),
                  // Dilatation buttons
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
                  _CompactButton(icon: Icons.history, label: 'HISTORIQUE', onPressed: _showHistoricPaymentsDialog, color: const Color(0xFF7B1FA2)),
                  const SizedBox(width: 8),
                  _CompactButton(icon: Icons.check_circle, label: 'VALIDER', onPressed: _showValidatePaymentDialog, color: const Color(0xFF00897B)),
                  const SizedBox(width: 8),
                  _CompactButton(icon: Icons.delete_forever, label: 'SUPPRIMER', onPressed: _deletePatientPaymentsToday, color: Colors.red),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showValidatePaymentDialog() {
    final authState = ref.read(authStateProvider);
    showDialog(
      context: context,
      builder: (context) => ValidatePaymentDialog(
        patientCode: widget.patient.code,
        patientFirstName: widget.patient.firstName,
        patientLastName: widget.patient.lastName,
        currentUser: authState.user,
      ),
    );
  }

  Future<void> _deletePatientPaymentsToday() async {
    final repository = ref.read(paymentsRepositoryProvider);
    final today = DateTime.now();
    
    // First count how many payments exist for this patient today
    final count = await repository.countPaymentsByPatientAndDate(
      patientCode: widget.patient.code,
      date: today,
    );
    
    if (count == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucun paiement à supprimer pour ce patient aujourd\'hui'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer les paiements'),
        content: Text(
          'Voulez-vous supprimer $count paiement(s) pour ${widget.patient.firstName} ${widget.patient.lastName} aujourd\'hui?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final deleted = await repository.deletePaymentsByPatientAndDate(
        patientCode: widget.patient.code,
        date: today,
      );
      
      // Refresh comptabilité data
      ref.invalidate(paymentsListProvider);
      ref.invalidate(paymentsSummaryProvider);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$deleted paiement(s) supprimé(s)'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendDilatation(String dilatationType) async {
    final authState = ref.read(authStateProvider);
    final selectedRoom = authState.selectedRoom;
    
    if (selectedRoom == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Aucune salle sélectionnée'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final repository = ref.read(waitingQueueRepositoryProvider);
      await repository.addToDilatation(
        patientCode: widget.patient.code,
        patientFirstName: widget.patient.firstName,
        patientLastName: widget.patient.lastName,
        patientBirthDate: widget.patient.dateOfBirth,
        patientAge: widget.patient.age,
        patientCreatedAt: widget.patient.createdAt,
        roomId: selectedRoom.id,
        roomName: selectedRoom.name,
        dilatationType: dilatationType,
        sentByUserId: authState.user?.id ?? '',
        sentByUserName: authState.user?.name ?? '',
      );

      final label = {
        'skiacol': 'Dilatation sous Skiacol',
        'od': 'Dilatation OD',
        'og': 'Dilatation OG',
        'odg': 'Dilatation ODG',
      }[dilatationType] ?? dilatationType;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.opacity, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('💊 $label envoyé pour ${widget.patient.firstName}')),
              ],
            ),
            backgroundColor: MediCoreColors.healthyGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Dilatation button widget (S, D, G, ODG)
class _DilatationButton extends StatelessWidget {
  final String label;
  final String tooltip;
  final VoidCallback onPressed;

  const _DilatationButton({
    required this.label,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: MediCoreColors.healthyGreen,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: label.length > 1 ? 40 : 32,
            height: 32,
            alignment: Alignment.center,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Info chip widget for patient details in top bar
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
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: MediCoreColors.steelOutline, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.7), size: 13),
          const SizedBox(width: 5),
          Flexible(
            child: Text(label,
              style: MediCoreTypography.body.copyWith(color: Colors.white.withOpacity(0.9), fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact bottom bar button
class _CompactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;

  const _CompactButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.color = MediCoreColors.professionalBlue,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(3),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: Colors.white),
              const SizedBox(width: 5),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action button (top right icons)
class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _QuickActionButton({required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: MediCoreColors.deepNavy,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: MediCoreColors.steelOutline, width: 1),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

/// Past visits section with total count badge
class _PastVisitsSection extends ConsumerWidget {
  final int patientCode;
  final Visit? selectedVisit;
  final Function(Visit) onVisitSelected;
  final Function(List<Visit>) onVisitsLoaded;
  final Function(Visit)? onVisitDoubleClick;
  final Function(Visit)? onVisitDelete;

  const _PastVisitsSection({
    required this.patientCode,
    required this.selectedVisit,
    required this.onVisitSelected,
    required this.onVisitsLoaded,
    this.onVisitDoubleClick,
    this.onVisitDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitsAsync = ref.watch(patientVisitsProvider(patientCode));
    final countAsync = ref.watch(patientVisitCountProvider(patientCode));

    return Row(
      children: [
        // Total visits badge
        Container(
          width: 50,
          margin: const EdgeInsets.only(right: 8),
          decoration: BoxDecoration(
            color: MediCoreColors.deepNavy,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('TOTAL', style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              countAsync.when(
                data: (count) => Text('$count', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                loading: () => const Text('-', style: TextStyle(color: Colors.white, fontSize: 22)),
                error: (_, __) => const Text('0', style: TextStyle(color: Colors.white, fontSize: 22)),
              ),
              const Text('visites', style: TextStyle(color: Colors.white70, fontSize: 9)),
            ],
          ),
        ),
        // Visits table
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: MediCoreColors.paperWhite,
              border: Border.all(color: MediCoreColors.steelOutline, width: 1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  height: 30,
                  decoration: const BoxDecoration(
                    color: MediCoreColors.deepNavy,
                    borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
                  ),
                  child: const Row(
                    children: [
                      _TableHeader('N', flex: 1),
                      _TableHeader('DATE', flex: 2),
                      _TableHeader('MOTIF DE CONSULTATION', flex: 5),
                      _TableHeader('DOCTEUR', flex: 2),
                    ],
                  ),
                ),
                // Rows
                Expanded(
                  child: visitsAsync.when(
                    data: (visits) {
                      if (visits.isEmpty) {
                        return const Center(child: Text('Aucune visite', style: TextStyle(color: Colors.grey)));
                      }
                      // Notify parent of visits list for keyboard navigation
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        onVisitsLoaded(visits);
                        // Auto-select first visit if none selected
                        if (selectedVisit == null && visits.isNotEmpty) {
                          onVisitSelected(visits.first);
                        }
                      });
                      return ListView.builder(
                        itemCount: visits.length,
                        itemBuilder: (context, index) {
                          final visit = visits[index];
                          final isSelected = selectedVisit?.id == visit.id;
                          return _VisitRow(
                            visit: visit,
                            index: index + 1,
                            isSelected: isSelected,
                            onTap: () => onVisitSelected(visit),
                            onDoubleTap: onVisitDoubleClick != null ? () => onVisitDoubleClick!(visit) : null,
                            onRightClick: onVisitDelete != null ? () => onVisitDelete!(visit) : null,
                          );
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Center(child: Text('Erreur: $e')),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String text;
  final int flex;
  const _TableHeader(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _VisitRow extends StatelessWidget {
  final Visit visit;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onRightClick;

  const _VisitRow({required this.visit, required this.index, required this.isSelected, required this.onTap, this.onDoubleTap, this.onRightClick});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy').format(visit.visitDate);
    return GestureDetector(
      onDoubleTap: onDoubleTap,
      onSecondaryTap: onRightClick,
      child: InkWell(
      onTap: onTap,
      child: Container(
        height: 28,
        decoration: BoxDecoration(
          color: isSelected ? MediCoreColors.professionalBlue.withOpacity(0.2) : Colors.transparent,
          border: const Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 0.5)),
        ),
        child: Row(
          children: [
            _VisitCell('$index', flex: 1),
            _VisitCell(dateStr, flex: 2),
            _VisitCell(visit.motif ?? '-', flex: 5),
            _VisitCell(visit.doctorName, flex: 2),
          ],
        ),
      ),
      ),
    );
  }
}

class _VisitCell extends StatelessWidget {
  final String text;
  final int flex;
  const _VisitCell(this.text, {this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Actes box (Généraux / Ophtalmologiques)
class _ActesBox extends StatelessWidget {
  final String title;
  final int? count;

  const _ActesBox({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    final hasData = count != null && count! > 0;
    return Container(
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border.all(color: MediCoreColors.steelOutline, width: 1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        children: [
          Container(
            height: 24,
            decoration: const BoxDecoration(
              color: MediCoreColors.deepNavy,
              borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
            ),
            alignment: Alignment.center,
            child: Text(title, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Center(
              child: hasData
                  ? Text('$count', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: MediCoreColors.deepNavy))
                  : Text('-', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey.shade400)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Eye examination panel (OD/OG) - Professional Ophthalmology Layout
class _EyeExamPanel extends StatelessWidget {
  final String eyeLabel;
  final Color eyeColor;
  final bool isRightEye;
  final Visit? visit;

  const _EyeExamPanel({required this.eyeLabel, required this.eyeColor, required this.isRightEye, this.visit});

  // Calculate VL from SPH, CYL, AXE
  String _calculateVL(String? sph, String? cyl, String? axe) {
    if (sph == null || sph.isEmpty) return '';
    if (cyl == null || cyl.isEmpty || cyl == '+0.00' || cyl == '0.00') return sph;
    return '$sph ( $cyl à ${axe ?? '0°'} )';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border.all(color: eyeColor, width: 2),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: eyeColor.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Eye header with icon
          Container(
            height: 32,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [eyeColor, eyeColor.withOpacity(0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isRightEye ? Icons.visibility : Icons.visibility_outlined, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Text(eyeLabel, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              ],
            ),
          ),
          // Fields - balanced spacing with visit data
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  // SV | AV
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('SV', value: isRightEye ? visit?.odSv : visit?.ogSv),
                    _FieldBig('AV', value: isRightEye ? visit?.odAv : visit?.ogAv),
                  ])),
                  const SizedBox(height: 6),
                  
                  // SPH | CYL | AXE | VL (VL calculated from SPH, CYL, AXE)
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('SPH', value: isRightEye ? visit?.odSphere : visit?.ogSphere),
                    _FieldBig('CYL', value: isRightEye ? visit?.odCylinder : visit?.ogCylinder),
                    _FieldBig('AXE', value: isRightEye ? visit?.odAxis : visit?.ogAxis),
                    Expanded(flex: 2, child: _FieldBig('VL', value: _calculateVL(
                      isRightEye ? visit?.odSphere : visit?.ogSphere,
                      isRightEye ? visit?.odCylinder : visit?.ogCylinder,
                      isRightEye ? visit?.odAxis : visit?.ogAxis,
                    ), green: true)),
                  ])),
                  const SizedBox(height: 6),
                  
                  // K1 | K2 (yellow) | R0
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('K1', yellow: true, value: isRightEye ? visit?.odK1 : visit?.ogK1),
                    _FieldBig('K2', yellow: true, value: isRightEye ? visit?.odK2 : visit?.ogK2),
                    _FieldBig('R0', value: isRightEye ? visit?.odR0 : visit?.ogR0),
                  ])),
                  const SizedBox(height: 6),
                  
                  // R1 | R2 (blue/derived)
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('R1', derived: true, value: isRightEye ? visit?.odR1 : visit?.ogR1),
                    _FieldBig('R2', derived: true, value: isRightEye ? visit?.odR2 : visit?.ogR2),
                  ])),
                  const SizedBox(height: 6),
                  
                  // PACHY | T.O.C (+ D.I.P for left)
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('PACHY', value: isRightEye ? visit?.odPachy : visit?.ogPachy),
                    _FieldBig('T.O.C', value: isRightEye ? visit?.odToc : visit?.ogToc),
                    if (!isRightEye) _FieldBig('D.I.P', highlight: true, value: visit?.dip),
                  ])),
                  const SizedBox(height: 6),
                  
                  // NOTES (bigger)
                  Expanded(
                    flex: 3,
                    child: _NotesField(value: isRightEye ? visit?.odNotes : visit?.ogNotes),
                  ),
                  const SizedBox(height: 6),
                  
                  // GONIO | T.O
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('GONIO', value: isRightEye ? visit?.odGonio : visit?.ogGonio),
                    _FieldBig('T.O', value: isRightEye ? visit?.odTo : visit?.ogTo),
                  ])),
                  const SizedBox(height: 6),
                  
                  // L.A.F
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('L.A.F', value: isRightEye ? visit?.odLaf : visit?.ogLaf),
                  ])),
                  const SizedBox(height: 6),
                  
                  // F.O
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig('F.O', value: isRightEye ? visit?.odFo : visit?.ogFo),
                  ])),
                  const SizedBox(height: 6),
                  
                  // CONDUITE A TENIR / DIAG
                  Expanded(child: _FieldRowFlex(children: [
                    _FieldBig(isRightEye ? 'CONDUITE A TENIR' : 'DIAG', value: isRightEye ? visit?.conduct : visit?.diagnosis),
                  ])),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Flexible row that fills available height
class _FieldRowFlex extends StatelessWidget {
  final List<Widget> children;
  const _FieldRowFlex({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: children.map((child) {
        if (child is Expanded) return child;
        return Expanded(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: child,
        ));
      }).toList(),
    );
  }
}

/// Big field with label on left - supports yellow (K1/K2), derived (R1/R2), highlight (ADD/D.I.P), green (VL)
class _FieldBig extends StatelessWidget {
  final String label;
  final bool highlight; // Orange for ADD, D.I.P
  final bool yellow;    // Yellow for K1, K2
  final bool derived;   // Blue for R1, R2
  final bool green;     // Green for VL
  final String? value;  // Display value

  const _FieldBig(this.label, {this.highlight = false, this.yellow = false, this.derived = false, this.green = false, this.value});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on type
    Color bgColor;
    Color borderColor;
    Color labelBgColor;
    Color labelTextColor;

    if (green) {
      // Green for VL
      bgColor = const Color(0xFFE8F5E9);
      borderColor = const Color(0xFF4CAF50);
      labelBgColor = const Color(0xFFC8E6C9);
      labelTextColor = const Color(0xFF2E7D32);
    } else if (highlight) {
      // Orange for ADD, D.I.P
      bgColor = const Color(0xFFFFF3E0);
      borderColor = const Color(0xFFFF9800);
      labelBgColor = const Color(0xFFFFE0B2);
      labelTextColor = const Color(0xFFE65100);
    } else if (yellow) {
      // Yellow for K1, K2
      bgColor = const Color(0xFFFFFDE7);
      borderColor = const Color(0xFFFFD54F);
      labelBgColor = const Color(0xFFFFECB3);
      labelTextColor = const Color(0xFFF57C00);
    } else if (derived) {
      // Blue for R1, R2
      bgColor = const Color(0xFFE3F2FD);
      borderColor = const Color(0xFF64B5F6);
      labelBgColor = const Color(0xFFBBDEFB);
      labelTextColor = const Color(0xFF1565C0);
    } else {
      // Default gray
      bgColor = Colors.white;
      borderColor = MediCoreColors.steelOutline;
      labelBgColor = const Color(0xFFECEFF1);
      labelTextColor = MediCoreColors.deepNavy;
    }

    // Clean display value (handle "0" as empty)
    final displayValue = (value != null && value!.isNotEmpty && value != '0') ? value! : '';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: labelBgColor,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(2), bottomLeft: Radius.circular(2)),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelTextColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              alignment: Alignment.center,
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: displayValue.isNotEmpty ? FontWeight.w600 : FontWeight.normal,
                  color: MediCoreColors.deepNavy,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Notes field (medium height, stands out)
class _NotesField extends StatelessWidget {
  final String? value;

  const _NotesField({this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFFDE7),
        border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD54F).withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: const BoxDecoration(
              color: Color(0xFFFFECB3),
              borderRadius: BorderRadius.only(topLeft: Radius.circular(3), topRight: Radius.circular(3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.edit_note, size: 12, color: Color(0xFFF57C00)),
                SizedBox(width: 4),
                Text('NOTES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFFF57C00), letterSpacing: 0.5)),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                value ?? '',
                style: const TextStyle(fontSize: 16, color: Color(0xFF424242), fontWeight: FontWeight.w500),
                overflow: TextOverflow.fade,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

