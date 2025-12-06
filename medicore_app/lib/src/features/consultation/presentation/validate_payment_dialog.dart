import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../../core/database/app_database.dart' show MedicalAct;
import '../../users/data/models/user_model.dart';
import '../../comptabilite/presentation/payments_provider.dart';
import '../../honoraires/presentation/medical_acts_provider.dart';

/// Temporary payment entry for validation
class TempPayment {
  final int id;
  final int medicalActId;
  final String medicalActName;
  final int amount;
  bool isSelected;

  TempPayment({
    required this.id,
    required this.medicalActId,
    required this.medicalActName,
    required this.amount,
    this.isSelected = false,
  });

  TempPayment copyWith({
    int? id,
    int? medicalActId,
    String? medicalActName,
    int? amount,
    bool? isSelected,
  }) {
    return TempPayment(
      id: id ?? this.id,
      medicalActId: medicalActId ?? this.medicalActId,
      medicalActName: medicalActName ?? this.medicalActName,
      amount: amount ?? this.amount,
      isSelected: isSelected ?? this.isSelected,
    );
  }
}

/// Dialog for validating payments before saving to Comptabilité
/// Changes are temporary until validated
class ValidatePaymentDialog extends ConsumerStatefulWidget {
  final int patientCode;
  final String patientFirstName;
  final String patientLastName;
  final User? currentUser;
  final bool showIgnoreButton; // Show "Ignorer" button for payment reminders

  const ValidatePaymentDialog({
    super.key,
    required this.patientCode,
    required this.patientFirstName,
    required this.patientLastName,
    this.currentUser,
    this.showIgnoreButton = false,
  });
  
  /// Factory constructor to create from Patient object
  factory ValidatePaymentDialog.fromPatient({
    Key? key,
    required dynamic patient, // Patient object
    User? currentUser,
    bool showIgnoreButton = false,
  }) {
    return ValidatePaymentDialog(
      key: key,
      patientCode: patient.code as int,
      patientFirstName: patient.firstName as String,
      patientLastName: patient.lastName as String,
      currentUser: currentUser,
      showIgnoreButton: showIgnoreButton,
    );
  }

  @override
  ConsumerState<ValidatePaymentDialog> createState() => _ValidatePaymentDialogState();
}

class _ValidatePaymentDialogState extends ConsumerState<ValidatePaymentDialog> {
  Map<int, TempPayment> _paymentsMap = {};
  bool _isValidating = false;
  bool _initialized = false;

  void _initializePayments(List<MedicalAct> acts) {
    if (_initialized) return;
    _initialized = true;
    _paymentsMap = {
      for (final act in acts)
        act.id: TempPayment(
          id: act.id,
          medicalActId: act.id,
          medicalActName: act.name,
          amount: act.feeAmount,
        )
    };
  }

  List<TempPayment> get _payments => _paymentsMap.values.toList();

  void _editAmount(TempPayment payment) {
    final controller = TextEditingController(text: payment.amount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier ${payment.medicalActName}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Montant (DA)',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final newAmount = int.tryParse(controller.text) ?? payment.amount;
              setState(() {
                _paymentsMap[payment.id] = payment.copyWith(amount: newAmount);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00897B), foregroundColor: Colors.white),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(TempPayment payment) {
    setState(() {
      _paymentsMap[payment.id] = payment.copyWith(isSelected: !payment.isSelected);
    });
  }

  void _toggleSelectAll() {
    final allSelected = _payments.every((p) => p.isSelected);
    setState(() {
      for (final key in _paymentsMap.keys) {
        _paymentsMap[key] = _paymentsMap[key]!.copyWith(isSelected: !allSelected);
      }
    });
  }

  Future<void> _validateSelectedPayments() async {
    final selectedPayments = _payments.where((p) => p.isSelected).toList();
    if (selectedPayments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sélectionnez au moins un paiement à valider')),
      );
      return;
    }

    setState(() => _isValidating = true);

    try {
      final repository = ref.read(paymentsRepositoryProvider);
      final now = DateTime.now();

      for (final payment in selectedPayments) {
        await repository.createPayment(
          medicalActId: payment.medicalActId,
          medicalActName: payment.medicalActName,
          amount: payment.amount,
          userId: widget.currentUser?.id ?? '',
          userName: widget.currentUser?.name ?? 'Utilisateur',
          patientCode: widget.patientCode,
          patientFirstName: widget.patientFirstName,
          patientLastName: widget.patientLastName,
          paymentTime: now,
        );
      }

      // Refresh comptabilité data
      ref.invalidate(paymentsListProvider);
      ref.invalidate(paymentsSummaryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${selectedPayments.length} paiement(s) validé(s) avec succès'),
            backgroundColor: MediCoreColors.healthyGreen,
          ),
        );
        // Close dialog after successful validation
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la validation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  int get _totalAmount => _payments.fold(0, (sum, p) => sum + p.amount);
  int get _selectedCount => _payments.where((p) => p.isSelected).length;
  int get _selectedAmount => _payments.where((p) => p.isSelected).fold(0, (sum, p) => sum + p.amount);

  @override
  Widget build(BuildContext context) {
    final medicalActsAsync = ref.watch(medicalActsListProvider);

    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.steelOutline, width: 2),
        ),
        child: medicalActsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Erreur: $e')),
          data: (acts) {
            _initializePayments(acts);
            return Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF00897B),
                    border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.white, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'VALIDER PAIEMENT - ${widget.patientFirstName} ${widget.patientLastName}',
                        style: MediCoreTypography.pageTitle.copyWith(color: Colors.white, fontSize: 18),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Control bar
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: MediCoreColors.paneTitleBar,
                    border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
                  ),
                  child: Row(
                    children: [
                      // Select all
                      TextButton.icon(
                        onPressed: _payments.isEmpty ? null : _toggleSelectAll,
                        icon: Icon(
                          _payments.isNotEmpty && _payments.every((p) => p.isSelected)
                              ? Icons.check_box
                              : Icons.check_box_outline_blank,
                          size: 18,
                        ),
                        label: const Text('Tout sélectionner'),
                      ),
                      const Spacer(),
                      // Summary
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: MediCoreColors.paperWhite,
                          border: Border.all(color: MediCoreColors.steelOutline),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            Text('Sélectionné: ', style: MediCoreTypography.body.copyWith(fontWeight: FontWeight.w600)),
                            Text('$_selectedAmount DA ($_selectedCount actes)', style: MediCoreTypography.body.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF00897B))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Table
                Expanded(
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        height: 40,
                        color: MediCoreColors.deepNavy,
                        child: const Row(
                          children: [
                            _HeaderCell('', width: 50), // Checkbox
                            _HeaderCell('ACTE MÉDICAL', flex: 3),
                            _HeaderCell('MONTANT', flex: 2),
                            _HeaderCell('', width: 60), // Edit button
                          ],
                        ),
                      ),
                      // Table rows
                      Expanded(
                        child: ListView.builder(
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                        final payment = _payments[index];
                        return _PaymentRow(
                          payment: payment,
                          onToggleSelect: () => _toggleSelection(payment),
                          onEditAmount: () => _editAmount(payment),
                        );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Footer with Validate button
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: MediCoreColors.paneTitleBar,
                    border: Border(top: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
                  ),
                  child: Row(
                    children: [
                      if (widget.showIgnoreButton) ...[
                        // Reminder text
                        const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Rappel: Paiement non validé pour ce patient',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500),
                        ),
                      ],
                      const Spacer(),
                      if (widget.showIgnoreButton) ...[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true), // Ignore and continue
                          child: const Text('Ignorer', style: TextStyle(color: Colors.grey)),
                        ),
                        const SizedBox(width: 8),
                      ],
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        onPressed: _isValidating || _selectedCount == 0 ? null : _validateSelectedPayments,
                        icon: _isValidating
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check, size: 18),
                        label: Text(_isValidating ? 'Validation...' : 'Valider ($_selectedCount)'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;
  final double? width;

  const _HeaderCell(this.text, {this.flex = 1, this.width});

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
    return width != null
        ? SizedBox(width: width, child: child)
        : Expanded(flex: flex, child: child);
  }
}

class _PaymentRow extends StatelessWidget {
  final TempPayment payment;
  final VoidCallback onToggleSelect;
  final VoidCallback onEditAmount;

  const _PaymentRow({
    required this.payment,
    required this.onToggleSelect,
    required this.onEditAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: payment.isSelected ? const Color(0xFF00897B).withOpacity(0.1) : Colors.transparent,
        border: const Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 0.5)),
      ),
      child: Row(
        children: [
          // Checkbox
          SizedBox(
            width: 50,
            child: Checkbox(
              value: payment.isSelected,
              onChanged: (_) => onToggleSelect(),
              activeColor: const Color(0xFF00897B),
            ),
          ),
          // Medical act
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(payment.medicalActName, style: const TextStyle(fontSize: 13)),
            ),
          ),
          // Amount
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '${payment.amount} DA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: payment.isSelected ? const Color(0xFF00897B) : MediCoreColors.deepNavy,
                ),
              ),
            ),
          ),
          // Edit button
          SizedBox(
            width: 60,
            child: IconButton(
              icon: const Icon(Icons.edit, size: 18, color: MediCoreColors.professionalBlue),
              onPressed: onEditAmount,
              tooltip: 'Modifier montant',
            ),
          ),
        ],
      ),
    );
  }
}
