import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/medicore_colors.dart';
import '../../../core/theme/medicore_typography.dart';
import '../../comptabilite/presentation/payments_provider.dart';

/// Dialog showing all payment history for a specific patient
class HistoricPaymentsDialog extends ConsumerWidget {
  final int patientCode;
  final String patientFirstName;
  final String patientLastName;

  const HistoricPaymentsDialog({
    super.key,
    required this.patientCode,
    required this.patientFirstName,
    required this.patientLastName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(patientPaymentsHistoryProvider(patientCode));

    return Dialog(
      backgroundColor: MediCoreColors.canvasGrey,
      child: Container(
        width: 900,
        height: 600,
        decoration: BoxDecoration(
          color: MediCoreColors.paperWhite,
          border: Border.all(color: MediCoreColors.steelOutline, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFF7B1FA2), // Purple
                border: Border(bottom: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'HISTORIQUE PAIEMENTS - $patientFirstName $patientLastName',
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

            // Table header
            Container(
              height: 40,
              color: MediCoreColors.deepNavy,
              child: const Row(
                children: [
                  _HeaderCell('DATE', flex: 2),
                  _HeaderCell('ACTE MÉDICAL', flex: 3),
                  _HeaderCell('MONTANT', flex: 2),
                ],
              ),
            ),

            // Table content
            Expanded(
              child: paymentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erreur: $e')),
                data: (payments) {
                  if (payments.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Aucun paiement trouvé pour ce patient',
                            style: TextStyle(color: Colors.grey[600], fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: payments.length,
                    itemBuilder: (context, index) {
                      final payment = payments[index];
                      final isEven = index % 2 == 0;
                      return Container(
                        height: 44,
                        color: isEven ? Colors.white : const Color(0xFFF5F5F5),
                        child: Row(
                          children: [
                            _DataCell(
                              payment.paymentTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(payment.paymentTime!) : '',
                              flex: 2,
                            ),
                            _DataCell(payment.medicalActName ?? '', flex: 3),
                            _DataCell(
                              '${payment.amount ?? 0} DA',
                              flex: 2,
                              isBold: true,
                              color: const Color(0xFF00897B),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Footer with total
            paymentsAsync.when(
              data: (payments) {
                final total = payments.fold<int>(0, (sum, p) => sum + (p.amount ?? 0));
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: MediCoreColors.paneTitleBar,
                    border: Border(top: BorderSide(color: MediCoreColors.steelOutline, width: 1)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${payments.length} paiement(s)',
                        style: MediCoreTypography.body.copyWith(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7B1FA2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'TOTAL: ',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              '$total DA',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (_, __) => const SizedBox(height: 60),
            ),
          ],
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
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final int flex;
  final double? width;
  final bool isBold;
  final Color? color;

  const _DataCell(this.text, {this.flex = 1, this.width, this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          color: color ?? MediCoreColors.deepNavy,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );

    if (width != null) {
      return SizedBox(width: width, child: child);
    }
    return Expanded(flex: flex, child: child);
  }
}
