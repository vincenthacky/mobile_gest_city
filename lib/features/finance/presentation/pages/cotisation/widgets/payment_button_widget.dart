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
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: controller.hasData ? () {
              HapticFeedback.mediumImpact();
              onPressed();
            } : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
            ),
            child: const Text(
              'Payer cotisation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      },
    );
  }
}