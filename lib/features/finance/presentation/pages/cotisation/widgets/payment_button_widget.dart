import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../controllers/contribution_controller.dart';

class PaymentButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;

  const PaymentButtonWidget({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ContributionController>(
      builder: (context, controller, child) {
        final isOffline = controller.isOffline;
        final canPay = controller.hasData && !isOffline;

        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: canPay ? () {
                  HapticFeedback.mediumImpact();
                  onPressed();
                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isOffline
                      ? Colors.grey.shade400
                      : const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                  disabledForegroundColor: Colors.grey.shade500,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isOffline) ...[
                      const Icon(Icons.wifi_off, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      isOffline ? 'Connexion requise' : 'Payer cotisation',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Message d'aide quand hors ligne
            if (isOffline) ...[
              const SizedBox(height: 8),
              Text(
                'Connectez-vous à internet pour effectuer un paiement',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontFamily: 'Nunito',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        );
      },
    );
  }
}