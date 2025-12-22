import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../patients/presentation/patients_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/types/proto_types.dart';

/// Surgery Planning Dialog - View and manage surgery schedules
/// Clinic name: Thaziri
/// Works on both admin and client modes
class SurgeryPlanningDialog extends ConsumerStatefulWidget {
  const SurgeryPlanningDialog({super.key});

  @override
  ConsumerState<SurgeryPlanningDialog> createState() => _SurgeryPlanningDialogState();
}

class _SurgeryPlanningDialogState extends ConsumerState<SurgeryPlanningDialog> {
  DateTime _selectedDate = DateTime.now();
  List<SurgeryPlan> _surgeryPlans = [];
  bool _isLoading = true;
  bool _isAddingPatient = false;
  
  // Form controllers
  Patient? _selectedPatient;
  String _selectedSurgeryType = SurgeryPlansRepository.surgeryTypes.first;
  String _customSurgeryType = '';
  String _selectedEye = 'OD';
  final _hourController = TextEditingController(text: '08:00');
  final _implantPowerController = TextEditingController();
  final _tarifController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _surgeryDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    _loadSurgeryPlans();
  }
  
  @override
  void dispose() {
    _hourController.dispose();
    _implantPowerController.dispose();
    _tarifController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadSurgeryPlans() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(surgeryPlansRepositoryProvider);
      final plans = await repo.getSurgeryPlansForDate(_selectedDate);
      if (mounted) {
        setState(() {
          _surgeryPlans = plans;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadSurgeryPlans();
  }
  
  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadSurgeryPlans();
    }
  }
  
  void _showAddPatientForm() {
    setState(() {
      _isAddingPatient = true;
      _selectedPatient = null;
      _surgeryDate = _selectedDate;
      _selectedSurgeryType = SurgeryPlansRepository.surgeryTypes.first;
      _customSurgeryType = '';
      _selectedEye = 'OD';
      _hourController.text = '08:00';
      _implantPowerController.clear();
      _tarifController.clear();
      _notesController.clear();
    });
  }
  
  void _cancelAddPatient() {
    setState(() {
      _isAddingPatient = false;
      _selectedPatient = null;
    });
  }
  
  Future<void> _saveSurgeryPlan() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un patient'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final repo = ref.read(surgeryPlansRepositoryProvider);
    final authState = ref.read(authStateProvider);
    
    final surgeryType = _customSurgeryType.isNotEmpty ? _customSurgeryType : _selectedSurgeryType;
    
    await repo.addSurgeryPlan(
      surgeryDate: _surgeryDate,
      surgeryHour: _hourController.text.trim(),
      patientCode: _selectedPatient!.code,
      patientFirstName: _selectedPatient!.firstName,
      patientLastName: _selectedPatient!.lastName,
      patientAge: _selectedPatient!.age,
      patientPhone: _selectedPatient!.phone,
      surgeryType: surgeryType,
      eyeToOperate: _selectedEye,
      implantPower: _implantPowerController.text.isNotEmpty ? _implantPowerController.text.trim() : null,
      tarif: int.tryParse(_tarifController.text),
      notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      createdBy: authState.user?.name,
    );
    
    setState(() => _isAddingPatient = false);
    _loadSurgeryPlans();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Chirurgie programmée pour ${_selectedPatient!.lastName} ${_selectedPatient!.firstName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
  
  Future<void> _updatePaymentStatus(SurgeryPlan plan) async {
    String? selectedStatus = plan.paymentStatus;
    int? amountRemaining = plan.amountRemaining;
    final amountController = TextEditingController(text: amountRemaining?.toString() ?? '');
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('État du paiement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Statut de paiement',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'pending', child: Text('En attente')),
                  DropdownMenuItem(value: 'partial', child: Text('Partiel')),
                  DropdownMenuItem(value: 'paid', child: Text('Payé')),
                ],
                onChanged: (v) => setDialogState(() => selectedStatus = v),
              ),
              if (selectedStatus == 'partial') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Reste à payer (DA)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'status': selectedStatus,
                'remaining': int.tryParse(amountController.text),
              }),
              child: const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      final repo = ref.read(surgeryPlansRepositoryProvider);
      await repo.updateSurgeryPlan(
        plan.id,
        paymentStatus: result['status'],
        amountRemaining: result['remaining'],
      );
      _loadSurgeryPlans();
    }
  }
  
  Future<void> _updateSurgeryStatus(SurgeryPlan plan) async {
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('État de la chirurgie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.check_circle, color: Colors.green),
              title: const Text('Terminée'),
              subtitle: const Text('Le patient est venu et la chirurgie est faite'),
              onTap: () => Navigator.pop(ctx, 'done'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.cancel, color: Colors.red),
              title: const Text('Annulée'),
              subtitle: const Text('Supprimer de la liste'),
              onTap: () => Navigator.pop(ctx, 'cancelled'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.schedule, color: Colors.orange),
              title: const Text('Reporter'),
              subtitle: const Text('Choisir une nouvelle date'),
              onTap: () => Navigator.pop(ctx, 'reschedule'),
            ),
          ],
        ),
      ),
    );
    
    if (result == null) return;
    
    final repo = ref.read(surgeryPlansRepositoryProvider);
    
    if (result == 'done') {
      await repo.markAsDone(plan.id);
      _loadSurgeryPlans();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chirurgie marquée comme terminée'), backgroundColor: Colors.green),
        );
      }
    } else if (result == 'cancelled') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Confirmer l\'annulation'),
          content: Text('Voulez-vous vraiment annuler la chirurgie de ${plan.patientLastName} ${plan.patientFirstName}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NON')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('OUI, ANNULER', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await repo.cancelSurgery(plan.id);
        _loadSurgeryPlans();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Chirurgie annulée'), backgroundColor: Colors.red),
          );
        }
      }
    } else if (result == 'reschedule') {
      await _rescheduleSurgery(plan);
    }
  }
  
  Future<void> _rescheduleSurgery(SurgeryPlan plan) async {
    // Show reschedule dialog with options to edit
    String? newHour = plan.surgeryHour;
    String? newSurgeryType = plan.surgeryType;
    String? newEye = plan.eyeToOperate;
    String? newImplantPower = plan.implantPower;
    int? newTarif = plan.tarif;
    DateTime? newDate;
    
    final hourController = TextEditingController(text: newHour);
    final implantController = TextEditingController(text: newImplantPower ?? '');
    final tarifController = TextEditingController(text: newTarif?.toString() ?? '');
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Reporter la chirurgie'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Date picker
                  Row(
                    children: [
                      const Text('Nouvelle date: '),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: plan.surgeryDate.add(const Duration(days: 7)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) setDialogState(() => newDate = picked);
                        },
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(newDate != null 
                          ? DateFormat('dd/MM/yyyy').format(newDate!)
                          : 'Choisir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: hourController,
                    decoration: const InputDecoration(
                      labelText: 'Heure',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: SurgeryPlansRepository.surgeryTypes.contains(newSurgeryType) 
                      ? newSurgeryType 
                      : SurgeryPlansRepository.surgeryTypes.first,
                    decoration: const InputDecoration(
                      labelText: 'Type de chirurgie',
                      border: OutlineInputBorder(),
                    ),
                    items: SurgeryPlansRepository.surgeryTypes.map((t) => 
                      DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => newSurgeryType = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: newEye,
                    decoration: const InputDecoration(
                      labelText: 'Œil à opérer',
                      border: OutlineInputBorder(),
                    ),
                    items: SurgeryPlansRepository.eyeOptions.map((e) => 
                      DropdownMenuItem(value: e, child: Text(_getEyeLabel(e)))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => newEye = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: implantController,
                    decoration: const InputDecoration(
                      labelText: 'Puissance implant',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tarifController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarif (DA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
            ElevatedButton(
              onPressed: newDate != null ? () => Navigator.pop(ctx, {
                'date': newDate,
                'hour': hourController.text,
                'surgery_type': newSurgeryType,
                'eye': newEye,
                'implant_power': implantController.text,
                'tarif': int.tryParse(tarifController.text),
              }) : null,
              child: const Text('REPORTER'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null && result['date'] != null) {
      final repo = ref.read(surgeryPlansRepositoryProvider);
      await repo.rescheduleSurgery(
        plan.id,
        result['date'] as DateTime,
        surgeryHour: result['hour'] as String?,
        surgeryType: result['surgery_type'] as String?,
        eyeToOperate: result['eye'] as String?,
        implantPower: result['implant_power'] as String?,
        tarif: result['tarif'] as int?,
      );
      _loadSurgeryPlans();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chirurgie reportée au ${DateFormat('dd/MM/yyyy').format(result['date'] as DateTime)}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }
  
  Future<void> _editPlan(SurgeryPlan plan) async {
    final hourController = TextEditingController(text: plan.surgeryHour);
    final implantController = TextEditingController(text: plan.implantPower ?? '');
    final tarifController = TextEditingController(text: plan.tarif?.toString() ?? '');
    final notesController = TextEditingController(text: plan.notes ?? '');
    String surgeryType = plan.surgeryType;
    String eye = plan.eyeToOperate;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Modifier - ${plan.patientLastName} ${plan.patientFirstName}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: hourController,
                    decoration: const InputDecoration(
                      labelText: 'Heure',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: SurgeryPlansRepository.surgeryTypes.contains(surgeryType) 
                      ? surgeryType 
                      : null,
                    decoration: const InputDecoration(
                      labelText: 'Type de chirurgie',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      ...SurgeryPlansRepository.surgeryTypes.map((t) => 
                        DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))
                      ),
                      if (!SurgeryPlansRepository.surgeryTypes.contains(surgeryType))
                        DropdownMenuItem(value: surgeryType, child: Text(surgeryType, style: const TextStyle(fontSize: 12))),
                    ],
                    onChanged: (v) => setDialogState(() => surgeryType = v ?? surgeryType),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: eye,
                    decoration: const InputDecoration(
                      labelText: 'Œil à opérer',
                      border: OutlineInputBorder(),
                    ),
                    items: SurgeryPlansRepository.eyeOptions.map((e) => 
                      DropdownMenuItem(value: e, child: Text(_getEyeLabel(e)))
                    ).toList(),
                    onChanged: (v) => setDialogState(() => eye = v ?? eye),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: implantController,
                    decoration: const InputDecoration(
                      labelText: 'Puissance implant',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: tarifController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Tarif (DA)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {
                'hour': hourController.text,
                'surgery_type': surgeryType,
                'eye': eye,
                'implant_power': implantController.text,
                'tarif': int.tryParse(tarifController.text),
                'notes': notesController.text,
              }),
              child: const Text('ENREGISTRER'),
            ),
          ],
        ),
      ),
    );
    
    if (result != null) {
      final repo = ref.read(surgeryPlansRepositoryProvider);
      await repo.updateSurgeryPlan(
        plan.id,
        surgeryHour: result['hour'] as String?,
        surgeryType: result['surgery_type'] as String?,
        eyeToOperate: result['eye'] as String?,
        implantPower: result['implant_power'] as String?,
        tarif: result['tarif'] as int?,
        notes: result['notes'] as String?,
      );
      _loadSurgeryPlans();
    }
  }
  
  String _getEyeLabel(String eye) {
    switch (eye) {
      case 'OD': return 'OD (Œil Droit)';
      case 'OG': return 'OG (Œil Gauche)';
      case 'ODG': return 'ODG (Les Deux)';
      default: return eye;
    }
  }
  
  String _getPaymentStatusLabel(String status) {
    switch (status) {
      case 'pending': return 'En attente';
      case 'partial': return 'Partiel';
      case 'paid': return 'Payé';
      default: return status;
    }
  }
  
  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'partial': return Colors.blue;
      case 'paid': return Colors.green;
      default: return Colors.grey;
    }
  }
  
  Future<void> _printSchedule() async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(_selectedDate);
    final dayName = DateFormat('EEEE', 'fr_FR').format(_selectedDate);
    
    // Filter out cancelled surgeries and include done + scheduled
    final plansToShow = _surgeryPlans.where((p) => p.surgeryStatus != 'cancelled').toList();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with clinic name
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'CLINIQUE THAZIRI',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'PROGRAMME OPÉRATOIRE',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '$dayName $dateStr',
                      style: const pw.TextStyle(
                        fontSize: 14,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 1),
                columnWidths: {
                  0: const pw.FlexColumnWidth(0.8), // Code
                  1: const pw.FlexColumnWidth(2), // Nom
                  2: const pw.FlexColumnWidth(0.6), // Age
                  3: const pw.FlexColumnWidth(1.5), // Tel
                  4: const pw.FlexColumnWidth(2.5), // Chirurgie
                  5: const pw.FlexColumnWidth(0.6), // Oeil
                  6: const pw.FlexColumnWidth(1), // Implant
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                    children: [
                      _pdfHeaderCell('N°'),
                      _pdfHeaderCell('NOM & PRÉNOM'),
                      _pdfHeaderCell('ÂGE'),
                      _pdfHeaderCell('TÉL'),
                      _pdfHeaderCell('CHIRURGIE'),
                      _pdfHeaderCell('ŒIL'),
                      _pdfHeaderCell('IMPLANT'),
                    ],
                  ),
                  // Data rows
                  ...plansToShow.map((plan) => pw.TableRow(
                    decoration: plan.surgeryStatus == 'done' 
                      ? const pw.BoxDecoration(color: PdfColors.green50)
                      : null,
                    children: [
                      _pdfDataCell(plan.patientCode.toString()),
                      _pdfDataCell('${plan.patientLastName} ${plan.patientFirstName}'),
                      _pdfDataCell(plan.patientAge?.toString() ?? '-'),
                      _pdfDataCell(plan.patientPhone ?? '-'),
                      _pdfDataCell(plan.surgeryType),
                      _pdfDataCell(plan.eyeToOperate),
                      _pdfDataCell(plan.implantPower ?? '-'),
                    ],
                  )),
                ],
              ),
              
              pw.SizedBox(height: 20),
              pw.Text(
                'Total: ${plansToShow.length} patient(s)',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
              ),
            ],
          );
        },
      ),
    );
    
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Programme_Operatoire_$dateStr',
    );
  }
  
  pw.Widget _pdfHeaderCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
        textAlign: pw.TextAlign.center,
      ),
    );
  }
  
  pw.Widget _pdfDataCell(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 8),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year &&
                    _selectedDate.month == DateTime.now().month &&
                    _selectedDate.day == DateTime.now().day;
    
    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: 1100,
        height: 700,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medical_services, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text('PROGRAMME OPÉRATOIRE - THAZIRI', 
                    style: MediCoreTypography.sectionHeader.copyWith(color: Colors.white, fontSize: 18)),
                  const Spacer(),
                  // Print button
                  IconButton(
                    icon: const Icon(Icons.print, color: Colors.white),
                    tooltip: 'Imprimer',
                    onPressed: _printSchedule,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Date selector
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: const Color(0xFFE3F2FD),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => _changeDate(-1),
                  ),
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isToday ? const Color(0xFF1565C0) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF1565C0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: isToday ? Colors.white : const Color(0xFF1565C0)),
                          const SizedBox(width: 8),
                          Text(
                            isToday ? "AUJOURD'HUI" : DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.white : const Color(0xFF1565C0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => _changeDate(1),
                  ),
                  const Spacer(),
                  // Add patient button
                  ElevatedButton.icon(
                    onPressed: _showAddPatientForm,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('AJOUTER PATIENT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isAddingPatient 
                  ? _buildAddPatientForm()
                  : _buildSurgeryList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddPatientForm() {
    final patientsAsync = ref.watch(filteredPatientsProvider);
    
    return Row(
      children: [
        // Left: Patient search
        Expanded(
          flex: 2,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.person_search, color: Color(0xFF1565C0)),
                      const SizedBox(width: 8),
                      Text('Rechercher un patient', style: MediCoreTypography.sectionHeader),
                      const Spacer(),
                      TextButton(
                        onPressed: _cancelAddPatient,
                        child: const Text('ANNULER'),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) {
                      ref.read(patientSearchProvider.notifier).state = v;
                    },
                    decoration: InputDecoration(
                      hintText: 'Code, Nom ou Prénom...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: patientsAsync.when(
                    data: (patients) {
                      if (patients.isEmpty) {
                        return const Center(child: Text('Aucun patient trouvé'));
                      }
                      return ListView.builder(
                        itemCount: patients.length > 30 ? 30 : patients.length,
                        itemBuilder: (ctx, i) {
                          final p = patients[i];
                          final isSelected = _selectedPatient?.code == p.code;
                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF1565C0).withOpacity(0.1),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? const Color(0xFF1565C0) : Colors.grey.shade300,
                              child: Text(
                                p.code.toString(),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isSelected ? Colors.white : Colors.black54,
                                ),
                              ),
                            ),
                            title: Text('${p.lastName} ${p.firstName}'),
                            subtitle: Text('Âge: ${p.age ?? "-"} | Tél: ${p.phone ?? "-"}'),
                            onTap: () => setState(() => _selectedPatient = p),
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
        
        // Right: Surgery details form
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Détails de la chirurgie', style: MediCoreTypography.sectionHeader),
                const SizedBox(height: 16),
                
                // Selected patient info
                if (_selectedPatient != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1565C0).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF1565C0)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF1565C0)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_selectedPatient!.lastName} ${_selectedPatient!.firstName}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text('Code: ${_selectedPatient!.code} | Âge: ${_selectedPatient!.age ?? "-"} | Tél: ${_selectedPatient!.phone ?? "-"}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 12),
                        Text('Veuillez sélectionner un patient dans la liste'),
                      ],
                    ),
                  ),
                
                // Date and Hour
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Date de chirurgie'),
                          const SizedBox(height: 4),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _surgeryDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                              );
                              if (picked != null) setState(() => _surgeryDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(DateFormat('dd/MM/yyyy').format(_surgeryDate)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _hourController,
                        decoration: const InputDecoration(
                          labelText: 'Heure',
                          hintText: '08:00',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Surgery type
                DropdownButtonFormField<String>(
                  value: _selectedSurgeryType,
                  decoration: const InputDecoration(
                    labelText: 'Type de chirurgie',
                    border: OutlineInputBorder(),
                  ),
                  items: SurgeryPlansRepository.surgeryTypes.map((t) => 
                    DropdownMenuItem(value: t, child: Text(t))
                  ).toList(),
                  onChanged: (v) => setState(() => _selectedSurgeryType = v ?? _selectedSurgeryType),
                ),
                const SizedBox(height: 12),
                
                // Custom surgery type
                TextField(
                  onChanged: (v) => setState(() => _customSurgeryType = v),
                  decoration: const InputDecoration(
                    labelText: 'Ou type personnalisé',
                    hintText: 'Entrer un autre type...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Eye to operate
                Row(
                  children: [
                    const Text('Œil à opérer: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(width: 16),
                    ...SurgeryPlansRepository.eyeOptions.map((eye) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(_getEyeLabel(eye)),
                        selected: _selectedEye == eye,
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedEye = eye);
                        },
                        selectedColor: const Color(0xFF1565C0),
                        labelStyle: TextStyle(
                          color: _selectedEye == eye ? Colors.white : Colors.black,
                        ),
                      ),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Implant power and Tarif
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _implantPowerController,
                        decoration: const InputDecoration(
                          labelText: 'Puissance implant',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: _tarifController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Tarif (DA)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Notes
                TextField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Save button
                Center(
                  child: ElevatedButton.icon(
                    onPressed: _selectedPatient != null ? _saveSurgeryPlan : null,
                    icon: const Icon(Icons.save),
                    label: const Text('ENREGISTRER LA CHIRURGIE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSurgeryList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_surgeryPlans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucune chirurgie programmée pour cette date',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate),
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }
    
    return Column(
      children: [
        // Header
        Container(
          height: 45,
          color: MediCoreColors.deepNavy,
          child: const Row(
            children: [
              _HeaderCell('CODE', flex: 1),
              _HeaderCell('NOM', flex: 2),
              _HeaderCell('ÂGE', flex: 1),
              _HeaderCell('TÉL', flex: 2),
              _HeaderCell('CHIRURGIE', flex: 2),
              _HeaderCell('ŒIL', flex: 1),
              _HeaderCell('IMPLANT', flex: 1),
              _HeaderCell('TARIF', flex: 1),
              _HeaderCell('PAIEMENT', flex: 2),
              _HeaderCell('ÉTAT', flex: 2),
              _HeaderCell('ACTIONS', flex: 2),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _surgeryPlans.length,
            itemBuilder: (ctx, i) {
              final plan = _surgeryPlans[i];
              final isEven = i % 2 == 0;
              final isDone = plan.surgeryStatus == 'done';
              
              return Container(
                height: 50,
                color: isDone 
                    ? Colors.green.withOpacity(0.1)
                    : isEven ? Colors.white : Colors.grey.shade50,
                child: Row(
                  children: [
                    _DataCell(plan.patientCode.toString(), flex: 1, bold: true),
                    _DataCell('${plan.patientLastName} ${plan.patientFirstName}', flex: 2),
                    _DataCell(plan.patientAge?.toString() ?? '-', flex: 1),
                    _DataCell(plan.patientPhone ?? '-', flex: 2),
                    _DataCell(plan.surgeryType, flex: 2),
                    _DataCell(plan.eyeToOperate, flex: 1),
                    _DataCell(plan.implantPower ?? '-', flex: 1),
                    _DataCell(plan.tarif != null ? '${plan.tarif} DA' : '-', flex: 1),
                    // Payment status
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: () => _updatePaymentStatus(plan),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getPaymentStatusColor(plan.paymentStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _getPaymentStatusColor(plan.paymentStatus)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _getPaymentStatusLabel(plan.paymentStatus),
                                style: TextStyle(
                                  fontSize: 9,
                                  color: _getPaymentStatusColor(plan.paymentStatus),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (plan.paymentStatus == 'partial' && plan.amountRemaining != null)
                                Text(
                                  'Reste: ${plan.amountRemaining} DA',
                                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Surgery status
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: isDone ? null : () => _updateSurgeryStatus(plan),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDone ? Colors.green.withOpacity(0.2) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDone ? Colors.green : Colors.orange),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isDone ? Icons.check_circle : Icons.schedule,
                                size: 12,
                                color: isDone ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isDone ? 'TERMINÉE' : 'PROGRAMMÉE',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isDone ? Colors.green : Colors.orange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Actions
                    Expanded(
                      flex: 2,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16, color: Colors.blue),
                            tooltip: 'Modifier',
                            onPressed: () => _editPlan(plan),
                          ),
                          if (!isDone)
                            IconButton(
                              icon: const Icon(Icons.delete, size: 16, color: Colors.red),
                              tooltip: 'Supprimer',
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Confirmer'),
                                    content: Text('Supprimer la chirurgie de ${plan.patientLastName}?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('NON')),
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('OUI', style: TextStyle(color: Colors.red)),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final repo = ref.read(surgeryPlansRepositoryProvider);
                                  await repo.deleteSurgeryPlan(plan.id);
                                  _loadSurgeryPlans();
                                }
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // Footer with count
        Container(
          padding: const EdgeInsets.all(12),
          color: const Color(0xFFE3F2FD),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_surgeryPlans.length} chirurgie(s)',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1565C0)),
              ),
              const SizedBox(width: 16),
              Text(
                '${_surgeryPlans.where((s) => s.surgeryStatus == 'done').length} terminée(s)',
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(width: 16),
              Text(
                '${_surgeryPlans.where((s) => s.surgeryStatus == 'scheduled').length} en attente',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  const _HeaderCell(this.text, {this.flex = 1});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool bold;
  const _DataCell(this.text, {this.flex = 1, this.bold = false});
  
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          text, 
          style: TextStyle(fontSize: 11, fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
