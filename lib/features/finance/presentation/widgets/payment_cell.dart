import 'package:flutter/material.dart';

class PaymentCell extends StatelessWidget {
  final String status;
  final bool isColumnSelected;

  const PaymentCell({
    super.key,
    required this.status,
    required this.isColumnSelected,
  });

  @override
  Widget build(BuildContext context) {
    Color textColor;
    String symbol;
    
    switch (status) {
      case 'paid':
        textColor = const Color(0xFF2EC27E); // Couleur success du HTML
        symbol = '✓';
        break;
      case 'pending':
        textColor = const Color(0xFFF59E0B);
        symbol = '🟠';
        break;
      case 'unpaid':
        textColor = const Color(0xFFFF6B6B); // Couleur danger du HTML
        symbol = '✕';
        break;
      case 'future':
        textColor = const Color(0xFF9A9AA0); // Couleur muted du HTML
        symbol = '➖';
        break;
      default:
        textColor = const Color(0xFF9A9AA0);
        symbol = '✕';
        break;
    }
    
    return SizedBox(
      height: 24,
      child: Center(
        child: Text(
          symbol,
          style: TextStyle(
            fontSize: 18,
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}