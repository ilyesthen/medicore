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
import 'surgery_provider.dart';
import '../data/surgery_repository_stub.dart';

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
    double? amountRemaining = plan.amountRemaining;
    final amountController = TextEditingController(text: amountRemaining?.toStringAsFixed(0) ?? '');
    
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

// ...

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
                    _pdfDataCell('${plan.patientLastName ?? ''} ${plan.patientFirstName ?? ''}'),
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

// ...

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
                  _DataCell('${plan.patientLastName ?? ''} ${plan.patientFirstName ?? ''}', flex: 2),
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
                                  content: Text('Supprimer la chirurgie de ${plan.patientLastName ?? ''}?'),
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
                                await repo.deleteSurgeryPlan(int.tryParse(plan.id) ?? 0);
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
                                  await repo.deleteSurgeryPlan(int.tryParse(plan.id) ?? 0);
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
