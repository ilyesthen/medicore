import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../patients/presentation/patients_provider.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../../core/types/proto_types.dart';

/// Appointments Dialog - View and manage patient appointments
/// Works on both admin and client modes
class AppointmentsDialog extends ConsumerStatefulWidget {
  const AppointmentsDialog({super.key});

  @override
  ConsumerState<AppointmentsDialog> createState() => _AppointmentsDialogState();
}

class _AppointmentsDialogState extends ConsumerState<AppointmentsDialog> {
  DateTime _selectedDate = DateTime.now();
  List<Appointment> _appointments = [];
  bool _isLoading = true;
  bool _isAddingNew = false;
  bool _isAddingExisting = false;
  
  // Form controllers for new appointment
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _appointmentDate = DateTime.now();
  
  // For adding existing patient
  Patient? _selectedPatient;
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadAppointments();
    _cleanupPastAppointments();
  }
  
  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadAppointments() async {
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final appointments = await repo.getAppointmentsForDate(_selectedDate);
      if (mounted) {
        setState(() {
          _appointments = appointments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  Future<void> _cleanupPastAppointments() async {
    try {
      final repo = ref.read(appointmentsRepositoryProvider);
      final deleted = await repo.cleanupPastAppointments();
      if (deleted > 0) {
        print('🗑️ Cleaned up $deleted past appointments');
      }
    } catch (e) {
      print('⚠️ Error cleaning up appointments: $e');
    }
  }
  
  void _changeDate(int days) {
    setState(() {
      _selectedDate = _selectedDate.add(Duration(days: days));
    });
    _loadAppointments();
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
      _loadAppointments();
    }
  }
  
  void _showAddNewForm() {
    setState(() {
      _isAddingNew = true;
      _isAddingExisting = false;
      _appointmentDate = _selectedDate;
      _clearForm();
    });
  }
  
  void _showAddExistingForm() {
    setState(() {
      _isAddingExisting = true;
      _isAddingNew = false;
      _appointmentDate = _selectedDate;
      _selectedPatient = null;
      _searchQuery = '';
    });
  }
  
  void _clearForm() {
    _firstNameController.clear();
    _lastNameController.clear();
    _ageController.clear();
    _phoneController.clear();
    _addressController.clear();
    _notesController.clear();
  }
  
  Future<void> _saveNewAppointment() async {
    if (_firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et prénom obligatoires'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final repo = ref.read(appointmentsRepositoryProvider);
    final authState = ref.read(authStateProvider);
    
    await repo.addAppointment(
      appointmentDate: _appointmentDate,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      age: int.tryParse(_ageController.text),
      phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text.trim() : null,
      address: _addressController.text.isNotEmpty ? _addressController.text.trim() : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text.trim() : null,
      createdBy: authState.user?.name,
    );
    
    setState(() => _isAddingNew = false);
    _loadAppointments();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous ajouté'), backgroundColor: Colors.green),
      );
    }
  }
  
  Future<void> _saveExistingPatientAppointment() async {
    if (_selectedPatient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un patient'), backgroundColor: Colors.orange),
      );
      return;
    }
    
    final repo = ref.read(appointmentsRepositoryProvider);
    final authState = ref.read(authStateProvider);
    
    await repo.addAppointment(
      appointmentDate: _appointmentDate,
      firstName: _selectedPatient!.firstName,
      lastName: _selectedPatient!.lastName,
      age: _selectedPatient!.age,
      dateOfBirth: _selectedPatient!.dateOfBirth,
      phoneNumber: _selectedPatient!.phoneNumber,
      address: _selectedPatient!.address,
      existingPatientCode: _selectedPatient!.code,
      createdBy: authState.user?.name,
    );
    
    setState(() {
      _isAddingExisting = false;
      _selectedPatient = null;
    });
    _loadAppointments();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rendez-vous ajouté pour patient existant'), backgroundColor: Colors.green),
      );
    }
  }
  
  Future<void> _addToPatients(Appointment apt) async {
    // If already linked to existing patient, just mark as added
    if (apt.existingPatientCode != null) {
      final repo = ref.read(appointmentsRepositoryProvider);
      await repo.markAsAdded(apt.id);
      _loadAppointments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${apt.firstName} ${apt.lastName} - Patient existant'), backgroundColor: Colors.blue),
        );
      }
      return;
    }
    
    // Create new patient
    final patientsRepo = ref.read(patientsRepositoryProvider);
    try {
      await patientsRepo.createPatient(
        firstName: apt.firstName,
        lastName: apt.lastName,
        age: apt.age,
        dateOfBirth: apt.dateOfBirth,
        phoneNumber: apt.phoneNumber,
        address: apt.address,
        otherInfo: apt.notes,
      );
      
      // Mark appointment as added
      final repo = ref.read(appointmentsRepositoryProvider);
      await repo.markAsAdded(apt.id);
      
      // Refresh patient list
      ref.invalidate(filteredPatientsProvider);
      _loadAppointments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${apt.firstName} ${apt.lastName} ajouté aux patients'), backgroundColor: Colors.green),
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
  
  Future<void> _deleteAppointment(Appointment apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer le rendez-vous?'),
        content: Text('Voulez-vous supprimer le rendez-vous de ${apt.firstName} ${apt.lastName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ANNULER')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: const Text('SUPPRIMER', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      final repo = ref.read(appointmentsRepositoryProvider);
      await repo.deleteAppointment(apt.id);
      _loadAppointments();
    }
  }
  
  Future<void> _moveAppointment(Appointment apt) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: apt.appointmentDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    
    if (picked != null && picked != apt.appointmentDate) {
      final repo = ref.read(appointmentsRepositoryProvider);
      await repo.updateAppointmentDate(apt.id, picked);
      _loadAppointments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rendez-vous déplacé au ${DateFormat('dd/MM/yyyy').format(picked)}'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToday = _selectedDate.year == DateTime.now().year &&
                    _selectedDate.month == DateTime.now().month &&
                    _selectedDate.day == DateTime.now().day;
    
    return Dialog(
      backgroundColor: MediCoreColors.paperWhite,
      child: Container(
        width: 900,
        height: 650,
        padding: const EdgeInsets.all(0),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6A1B9A), Color(0xFF9C27B0)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  Text('RENDEZ-VOUS', style: MediCoreTypography.sectionHeader.copyWith(color: Colors.white, fontSize: 18)),
                  const Spacer(),
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
              color: const Color(0xFFF3E5F5),
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
                        color: isToday ? const Color(0xFF9C27B0) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF9C27B0)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: isToday ? Colors.white : const Color(0xFF9C27B0)),
                          const SizedBox(width: 8),
                          Text(
                            isToday ? "AUJOURD'HUI" : DateFormat('EEEE dd MMMM yyyy', 'fr_FR').format(_selectedDate),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isToday ? Colors.white : const Color(0xFF9C27B0),
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
                  // Add buttons
                  ElevatedButton.icon(
                    onPressed: _showAddNewForm,
                    icon: const Icon(Icons.person_add, size: 18),
                    label: const Text('NOUVEAU PATIENT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _showAddExistingForm,
                    icon: const Icon(Icons.person_search, size: 18),
                    label: const Text('PATIENT EXISTANT'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2196F3),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: _isAddingNew 
                  ? _buildAddNewForm()
                  : _isAddingExisting
                      ? _buildAddExistingForm()
                      : _buildAppointmentsList(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAddNewForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_add, color: Color(0xFF4CAF50)),
              const SizedBox(width: 8),
              Text('Nouveau rendez-vous', style: MediCoreTypography.sectionHeader),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _isAddingNew = false),
                child: const Text('ANNULER'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Date picker
          Row(
            children: [
              const Text('Date du rendez-vous: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _appointmentDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _appointmentDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(DateFormat('dd/MM/yyyy').format(_appointmentDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Form fields
          Row(
            children: [
              Expanded(child: _buildTextField(_lastNameController, 'Nom *')),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_firstNameController, 'Prénom *')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(width: 100, child: _buildTextField(_ageController, 'Âge', isNumber: true)),
              const SizedBox(width: 16),
              Expanded(child: _buildTextField(_phoneController, 'Téléphone')),
            ],
          ),
          const SizedBox(height: 12),
          _buildTextField(_addressController, 'Adresse'),
          const SizedBox(height: 12),
          _buildTextField(_notesController, 'Notes', maxLines: 2),
          const SizedBox(height: 24),
          
          Center(
            child: ElevatedButton.icon(
              onPressed: _saveNewAppointment,
              icon: const Icon(Icons.save),
              label: const Text('ENREGISTRER LE RENDEZ-VOUS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAddExistingForm() {
    final patientsAsync = ref.watch(filteredPatientsProvider);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search, color: Color(0xFF2196F3)),
              const SizedBox(width: 8),
              Text('Ajouter patient existant', style: MediCoreTypography.sectionHeader),
              const Spacer(),
              TextButton(
                onPressed: () => setState(() => _isAddingExisting = false),
                child: const Text('ANNULER'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Date picker
          Row(
            children: [
              const Text('Date du rendez-vous: ', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _appointmentDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                  );
                  if (picked != null) setState(() => _appointmentDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(DateFormat('dd/MM/yyyy').format(_appointmentDate)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search field
          TextField(
            onChanged: (v) {
              ref.read(patientSearchProvider.notifier).state = v;
              setState(() => _searchQuery = v);
            },
            decoration: InputDecoration(
              hintText: 'Rechercher un patient...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),
          
          // Patient list
          Expanded(
            child: patientsAsync.when(
              data: (patients) {
                if (patients.isEmpty) {
                  return const Center(child: Text('Aucun patient trouvé'));
                }
                return ListView.builder(
                  itemCount: patients.length > 20 ? 20 : patients.length,
                  itemBuilder: (ctx, i) {
                    final p = patients[i];
                    final isSelected = _selectedPatient?.code == p.code;
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: const Color(0xFF2196F3).withOpacity(0.1),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? const Color(0xFF2196F3) : Colors.grey.shade300,
                        child: Text(p.firstName.isNotEmpty ? p.firstName[0].toUpperCase() : '?',
                          style: TextStyle(color: isSelected ? Colors.white : Colors.black54)),
                      ),
                      title: Text('${p.lastName} ${p.firstName}'),
                      subtitle: Text('Code: ${p.code} | Âge: ${p.age ?? "-"}'),
                      onTap: () => setState(() => _selectedPatient = p),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Erreur: $e')),
            ),
          ),
          
          const SizedBox(height: 16),
          Center(
            child: ElevatedButton.icon(
              onPressed: _selectedPatient != null ? _saveExistingPatientAppointment : null,
              icon: const Icon(Icons.save),
              label: Text(_selectedPatient != null 
                  ? 'AJOUTER ${_selectedPatient!.lastName.toUpperCase()}'
                  : 'SÉLECTIONNEZ UN PATIENT'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2196F3),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppointmentsList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'Aucun rendez-vous pour cette date',
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
          height: 40,
          color: MediCoreColors.deepNavy,
          child: const Row(
            children: [
              _HeaderCell('NOM', flex: 2),
              _HeaderCell('PRÉNOM', flex: 2),
              _HeaderCell('ÂGE', flex: 1),
              _HeaderCell('TÉLÉPHONE', flex: 2),
              _HeaderCell('NOTES', flex: 2),
              _HeaderCell('ACTIONS', flex: 3),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _appointments.length,
            itemBuilder: (ctx, i) {
              final apt = _appointments[i];
              final isEven = i % 2 == 0;
              final isExisting = apt.existingPatientCode != null;
              
              return Container(
                height: 48,
                color: apt.wasAdded 
                    ? Colors.green.withOpacity(0.1)
                    : isEven ? Colors.white : Colors.grey.shade50,
                child: Row(
                  children: [
                    _DataCell(apt.lastName, flex: 2, bold: true),
                    _DataCell(apt.firstName, flex: 2),
                    _DataCell(apt.age?.toString() ?? '-', flex: 1),
                    _DataCell(apt.phoneNumber ?? '-', flex: 2),
                    _DataCell(apt.notes ?? '-', flex: 2),
                    Expanded(
                      flex: 3,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!apt.wasAdded) ...[
                            _ActionButton(
                              icon: Icons.person_add,
                              label: isExisting ? 'EXISTANT' : 'AJOUTER',
                              color: isExisting ? Colors.blue : Colors.green,
                              onTap: () => _addToPatients(apt),
                            ),
                            const SizedBox(width: 4),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check, size: 14, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text('AJOUTÉ', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          _ActionButton(
                            icon: Icons.calendar_month,
                            label: 'DÉPLACER',
                            color: Colors.orange,
                            onTap: () => _moveAppointment(apt),
                          ),
                          const SizedBox(width: 4),
                          _ActionButton(
                            icon: Icons.delete,
                            label: 'SUPPR',
                            color: Colors.red,
                            onTap: () => _deleteAppointment(apt),
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
          color: const Color(0xFFF3E5F5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_appointments.length} rendez-vous',
                style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF6A1B9A)),
              ),
              const SizedBox(width: 16),
              Text(
                '${_appointments.where((a) => a.wasAdded).length} ajoutés',
                style: const TextStyle(color: Colors.green),
              ),
              const SizedBox(width: 16),
              Text(
                '${_appointments.where((a) => !a.wasAdded).length} en attente',
                style: const TextStyle(color: Colors.orange),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildTextField(TextEditingController controller, String label, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          text, 
          style: TextStyle(fontSize: 12, fontWeight: bold ? FontWeight.w600 : FontWeight.normal),
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  
  const _ActionButton({required this.icon, required this.label, required this.color, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 2),
            Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
