import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../auth/presentation/auth_provider.dart';
import '../../users/data/models/user_model.dart';
import 'payments_provider.dart';
import '../core/types/proto_types.dart';

/// Comptabilité (Accounting) dialog for all roles
/// - Doctor: Views their own payments
/// - Assistant: Views doctor's payments + their percentage-based earnings
/// - Nurse: Can select any doctor and see all assistants' earnings
class ComptabiliteDialog extends ConsumerWidget {
  const ComptabiliteDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final currentUser = authState.user;
    final userRole = currentUser?.role ?? '';
    final selectedDate = ref.watch(selectedDateProvider);
    final timeFilter = ref.watch(timeFilterProvider);
    final paymentsAsync = ref.watch(paymentsListProvider);
    final summary = ref.watch(paymentsSummaryProvider);
    final selectedDoctor = ref.watch(selectedDoctorProvider);
    final allDoctorsAsync = ref.watch(allDoctorsProvider);
    final allAssistantsAsync = ref.watch(allAssistantsProvider);

    // Determine role type
    final viewIsNurse = isNurse(userRole);
    final viewIsAssistant = isAssistant(userRole);
    final viewIsDoctor = isDoctor(userRole);

    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: viewIsNurse ? 1400 : 1300, // Wider for nurse (more columns)
        height: 800,
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(
            color: MediCoreColors.steelOutline,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            // Header bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: MediCoreColors.deepNavy,
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'COMPTABILITÉ',
                    style: MediCoreTypography.pageTitle.copyWith(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Control bar (user/selector, date, time filter, print)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: MediCoreColors.paneTitleBar,
                border: Border(
                  bottom: BorderSide(
                    color: MediCoreColors.steelOutline,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  // User name or Doctor selector (for Nurse)
                  if (viewIsNurse) ...[
                    // Doctor dropdown for nurse
                    _DoctorSelector(
                      selectedDoctor: selectedDoctor,
                      allDoctorsAsync: allDoctorsAsync,
                      onDoctorChanged: (doctor) {
                        ref.read(selectedDoctorProvider.notifier).state = doctor;
                      },
                    ),
                  ] else ...[
                    // Static user name for Doctor/Assistant
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: MediCoreColors.paperWhite,
                        border: Border.all(
                          color: MediCoreColors.steelOutline,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.person,
                            size: 18,
                            color: MediCoreColors.professionalBlue,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            currentUser?.name ?? 'Utilisateur',
                            style: MediCoreTypography.sectionHeader.copyWith(
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(width: 16),

                  // Date selector
                  _DateSelector(
                    selectedDate: selectedDate,
                    onDateChanged: (date) {
                      ref.read(selectedDateProvider.notifier).state = date;
                    },
                  ),
                  const SizedBox(width: 24),

                  // Time filter buttons
                  _TimeFilterButtons(
                    selectedFilter: timeFilter,
                    onFilterChanged: (filter) {
                      ref.read(timeFilterProvider.notifier).state = filter;
                    },
                  ),
                  const SizedBox(width: 24),

                  // Print button
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Impression en cours de développement'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('IMPRIMER'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: MediCoreColors.professionalBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main content area with tables
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Main payments table (larger)
                    Expanded(
                      flex: 7,
                      child: _RoleBasedPaymentsTable(
                        paymentsAsync: paymentsAsync,
                        summary: summary,
                        isNurse: viewIsNurse,
                        isAssistant: viewIsAssistant,
                        currentUser: currentUser,
                        allAssistantsAsync: allAssistantsAsync,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Summary table (smaller)
                    Expanded(
                      flex: 3,
                      child: _SummaryTable(
                        summary: summary,
                        isAssistant: viewIsAssistant,
                        isNurse: viewIsNurse,
                        currentUser: currentUser,
                        allAssistantsAsync: allAssistantsAsync,
                      ),
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
}

/// Doctor selector dropdown for Nurse view
class _DoctorSelector extends StatelessWidget {
  final User? selectedDoctor;
  final AsyncValue<List<User>> allDoctorsAsync;
  final Function(User?) onDoctorChanged;

  const _DoctorSelector({
    required this.selectedDoctor,
    required this.allDoctorsAsync,
    required this.onDoctorChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border.all(
          color: MediCoreColors.steelOutline,
          width: 1,
        ),
      ),
      child: allDoctorsAsync.when(
        data: (doctors) => DropdownButtonHideUnderline(
          child: DropdownButton<User>(
            value: selectedDoctor,
            hint: Row(
              children: [
                const Icon(
                  Icons.person_search,
                  size: 18,
                  color: MediCoreColors.professionalBlue,
                ),
                const SizedBox(width: 8),
                Text(
                  'Sélectionner un utilisateur',
                  style: MediCoreTypography.body.copyWith(fontSize: 13),
                ),
              ],
            ),
            items: doctors.map((doctor) => DropdownMenuItem<User>(
              value: doctor,
              child: Text(
                doctor.name,
                style: MediCoreTypography.sectionHeader.copyWith(fontSize: 13),
              ),
            )).toList(),
            onChanged: onDoctorChanged,
          ),
        ),
        loading: () => const SizedBox(
          width: 150,
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => const Text('Erreur'),
      ),
    );
  }
}

/// Date selector widget
class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final Function(DateTime) onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedDate,
          firstDate: DateTime(2010),
          lastDate: DateTime.now().add(const Duration(days: 365)),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: const ColorScheme.light(
                  primary: MediCoreColors.professionalBlue,
                ),
              ),
              child: child!,
            );
          },
        );
        if (picked != null) {
          onDateChanged(picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(
            color: MediCoreColors.steelOutline,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today,
              size: 18,
              color: MediCoreColors.professionalBlue,
            ),
            const SizedBox(width: 8),
            Text(
              DateFormat('dd/MM/yyyy').format(selectedDate),
              style: MediCoreTypography.body.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time filter buttons (Journée Complète, Matinée, Après-midi)
class _TimeFilterButtons extends StatelessWidget {
  final String selectedFilter;
  final Function(String) onFilterChanged;

  const _TimeFilterButtons({
    required this.selectedFilter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _FilterButton(
          label: 'Journée Complète',
          value: 'all',
          isSelected: selectedFilter == 'all',
          onTap: () => onFilterChanged('all'),
        ),
        const SizedBox(width: 8),
        _FilterButton(
          label: 'Matinée',
          value: 'morning',
          isSelected: selectedFilter == 'morning',
          onTap: () => onFilterChanged('morning'),
        ),
        const SizedBox(width: 8),
        _FilterButton(
          label: 'Après-midi',
          value: 'afternoon',
          isSelected: selectedFilter == 'afternoon',
          onTap: () => onFilterChanged('afternoon'),
        ),
      ],
    );
  }
}

/// Individual filter button
class _FilterButton extends StatelessWidget {
  final String label;
  final String value;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterButton({
    required this.label,
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? MediCoreColors.professionalBlue
              : MediCoreColors.paperWhite,
          border: Border.all(
            color: MediCoreColors.steelOutline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          label,
          style: MediCoreTypography.button.copyWith(
            fontSize: 12,
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Role-based payments table with different columns per role
class _RoleBasedPaymentsTable extends StatelessWidget {
  final AsyncValue<List<Payment>> paymentsAsync;
  final Map<String, dynamic> summary;
  final bool isNurse;
  final bool isAssistant;
  final User? currentUser;
  final AsyncValue<List<User>> allAssistantsAsync;

  const _RoleBasedPaymentsTable({
    required this.paymentsAsync,
    required this.summary,
    required this.isNurse,
    required this.isAssistant,
    required this.currentUser,
    required this.allAssistantsAsync,
  });

  @override
  Widget build(BuildContext context) {
    // Get assistants for calculating per-row earnings
    final assistants = allAssistantsAsync.valueOrNull ?? [];
    
    return Container(
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border.all(
          color: MediCoreColors.steelOutline,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Table header - varies by role
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: MediCoreColors.deepNavy,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                _TableHeaderCell('HORAIRE', flex: 1),
                _TableHeaderCell('NOM PATIENT', flex: 2),
                _TableHeaderCell('PRÉNOM', flex: 2),
                _TableHeaderCell('ACTE PRATIQUÉ', flex: 3),
                _TableHeaderCell('MONTANT', flex: 2),
                // Assistant: show MY PART column
                if (isAssistant)
                  _TableHeaderCell('MA PART (${currentUser?.percentage?.toInt() ?? 0}%)', flex: 2),
                // Nurse: show columns for each assistant
                if (isNurse)
                  ...assistants.map((a) => _TableHeaderCell(
                    '${a.name.split(' ').first} (${a.percentage?.toInt() ?? 0}%)',
                    flex: 2,
                  )),
              ],
            ),
          ),

          // Table body
          Expanded(
            child: paymentsAsync.when(
              data: (payments) {
                if (payments.isEmpty) {
                  return const Center(
                    child: Text(
                      'Aucun paiement pour cette période',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final isEven = index % 2 == 0;
                    
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          // Return patient info to filter dashboard
                          Navigator.of(context).pop({
                            'patientName': '${payment.patientLastName} ${payment.patientFirstName}',
                            'patientCode': payment.patientCode,
                          });
                        },
                        hoverColor: MediCoreColors.professionalBlue.withOpacity(0.1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isEven
                                ? MediCoreColors.paperWhite
                                : MediCoreColors.zebraRowAlt,
                            border: const Border(
                              bottom: BorderSide(
                                color: MediCoreColors.gridLines,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Row(
                            children: [
                              _TableCell(
                                DateFormat('HH:mm').format(payment.paymentTime),
                                flex: 1,
                              ),
                              _TableCell(
                                payment.patientLastName,
                                flex: 2,
                                isClickable: true,
                              ),
                              _TableCell(
                                payment.patientFirstName,
                                flex: 2,
                                isClickable: true,
                              ),
                              _TableCell(
                                payment.medicalActName,
                                flex: 3,
                              ),
                              _TableCell(
                                _formatCurrency(payment.amount),
                                flex: 2,
                                isAmount: true,
                              ),
                              // Assistant: show their earnings for this payment
                              if (isAssistant)
                                _TableCell(
                                  _formatCurrency((payment.amount * (currentUser?.percentage ?? 0) / 100).round()),
                                  flex: 2,
                                  isAmount: true,
                                  isHighlight: true,
                                ),
                              // Nurse: show each assistant's earnings for this payment
                              if (isNurse)
                                ...assistants.map((a) => _TableCell(
                                  _formatCurrency((payment.amount * (a.percentage ?? 0) / 100).round()),
                                  flex: 2,
                                  isAmount: true,
                                )),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, _) => Center(
                child: Text('Erreur: $error'),
              ),
            ),
          ),

          // Footer with totals
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: MediCoreColors.paneTitleBar,
              border: Border(
                top: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Nombre de patients: ',
                        style: MediCoreTypography.sectionHeader.copyWith(
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${summary['patientCount']}',
                        style: MediCoreTypography.sectionHeader.copyWith(
                          fontSize: 13,
                          color: MediCoreColors.professionalBlue,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'TOTAL: ',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatCurrency(summary['totalAmount'] as int),
                  style: MediCoreTypography.sectionHeader.copyWith(
                    fontSize: 16,
                    color: MediCoreColors.healthyGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                // Assistant: show their total earnings
                if (isAssistant) ...[
                  const SizedBox(width: 24),
                  Text(
                    'MA PART: ',
                    style: MediCoreTypography.sectionHeader.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    _formatCurrency(summary['myEarnings'] as int? ?? 0),
                    style: MediCoreTypography.sectionHeader.copyWith(
                      fontSize: 16,
                      color: MediCoreColors.professionalBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Summary table (Récap par Actes Regroupés) with role-specific sections
class _SummaryTable extends StatelessWidget {
  final Map<String, dynamic> summary;
  final bool isAssistant;
  final bool isNurse;
  final User? currentUser;
  final AsyncValue<List<User>> allAssistantsAsync;

  const _SummaryTable({
    required this.summary,
    this.isAssistant = false,
    this.isNurse = false,
    this.currentUser,
    required this.allAssistantsAsync,
  });

  @override
  Widget build(BuildContext context) {
    final groupedByAct = summary['groupedByAct'] as Map<String, Map<String, int>>;
    
    return Container(
      decoration: BoxDecoration(
        color: MediCoreColors.paperWhite,
        border: Border.all(
          color: MediCoreColors.steelOutline,
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: MediCoreColors.deepNavy,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
            ),
            child: Center(
              child: Text(
                'RÉCAP PAR ACTES REGROUPÉS',
                style: MediCoreTypography.sectionHeader.copyWith(
                  color: Colors.white,
                  fontSize: 12,
                ),
              ),
            ),
          ),

          // Column headers
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: MediCoreColors.paneTitleBar,
              border: Border(
                bottom: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'ACTES PRATIQUÉS',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'NOMBRE',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'MONTANT',
                    style: MediCoreTypography.label.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),

          // Table body
          Expanded(
            child: groupedByAct.isEmpty
                ? const Center(
                    child: Text(
                      'Aucune donnée',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: groupedByAct.length,
                    itemBuilder: (context, index) {
                      final entry = groupedByAct.entries.elementAt(index);
                      final actName = entry.key;
                      final count = entry.value['count'] ?? 0;
                      final totalAmount = entry.value['totalAmount'] ?? 0;
                      final isEven = index % 2 == 0;

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isEven
                              ? MediCoreColors.paperWhite
                              : MediCoreColors.zebraRowAlt,
                          border: const Border(
                            bottom: BorderSide(
                              color: MediCoreColors.gridLines,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(
                                actName,
                                style: MediCoreTypography.body.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text(
                                count.toString(),
                                style: MediCoreTypography.body.copyWith(
                                  fontSize: 11,
                                  color: MediCoreColors.professionalBlue,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                _formatCurrency(totalAmount),
                                style: MediCoreTypography.body.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Footer with total
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: MediCoreColors.paneTitleBar,
              border: Border(
                top: BorderSide(
                  color: MediCoreColors.steelOutline,
                  width: 2,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'TOTAL:',
                  style: MediCoreTypography.sectionHeader.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _formatCurrency(summary['totalAmount'] as int),
                  style: MediCoreTypography.sectionHeader.copyWith(
                    fontSize: 14,
                    color: MediCoreColors.healthyGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Table header cell widget
class _TableHeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _TableHeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: MediCoreTypography.sectionHeader.copyWith(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Table cell widget
class _TableCell extends StatelessWidget {
  final String text;
  final int flex;
  final bool isAmount;
  final bool isHighlight;
  final bool isClickable;

  const _TableCell(
    this.text, {
    required this.flex,
    this.isAmount = false,
    this.isHighlight = false,
    this.isClickable = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: MediCoreTypography.body.copyWith(
          fontSize: 12,
          fontWeight: isAmount ? FontWeight.w600 : FontWeight.normal,
          color: isClickable 
              ? MediCoreColors.professionalBlue 
              : (isHighlight ? MediCoreColors.professionalBlue : null),
          decoration: isClickable ? TextDecoration.underline : null,
        ),
        textAlign: isAmount ? TextAlign.right : TextAlign.left,
      ),
    );
  }
}

/// Format currency helper
String _formatCurrency(int amount) {
  final formatter = NumberFormat('#,###', 'fr_FR');
  return '${formatter.format(amount)} DA';
}
