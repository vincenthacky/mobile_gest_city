import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PaymentToggleWidget extends StatelessWidget {
  final bool showingPayments;
  final bool showingValidated;
  final Function(bool showingPayments, bool showingValidated) onToggleChanged;

  const PaymentToggleWidget({
    super.key,
    required this.showingPayments,
    required this.showingValidated,
    required this.onToggleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Paiements Validés
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleChanged(true, true);
                  },
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (showingPayments && showingValidated) ? const Color(0xFF10B981) : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: (showingPayments && showingValidated) ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Validés',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (showingPayments && showingValidated) ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Paiements en Attente
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleChanged(true, false);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: (showingPayments && !showingValidated) ? const Color(0xFFF59E0B) : Colors.transparent,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.hourglass_empty,
                          size: 14,
                          color: (showingPayments && !showingValidated) ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'En attente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: (showingPayments && !showingValidated) ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Retards
                InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onToggleChanged(false, false);
                  },
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: !showingPayments ? const Color(0xFFEF4444) : Colors.transparent,
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 14,
                          color: !showingPayments ? Colors.white : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Retards',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: !showingPayments ? Colors.white : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
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