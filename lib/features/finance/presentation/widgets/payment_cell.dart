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
    Color backgroundColor;
    Widget iconWidget;
    
    switch (status) {
      case 'paid':
        backgroundColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        iconWidget = const Text('✅', style: TextStyle(fontSize: 14));
        break;
      case 'pending':
        backgroundColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
        iconWidget = const Text('🟠', style: TextStyle(fontSize: 14));
        break;
      case 'unpaid':
        backgroundColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        iconWidget = const Text('❌', style: TextStyle(fontSize: 14));
        break;
      case 'future':
        backgroundColor = Colors.grey.shade50;
        iconWidget = const Text('➖', style: TextStyle(fontSize: 14, color: Colors.grey));
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        iconWidget = const Text('➖', style: TextStyle(fontSize: 14, color: Colors.grey));
        break;
    }
    
    if (isColumnSelected) {
      backgroundColor = const Color(0xFF4F46E5).withValues(alpha: 0.2);
    }
    
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: isColumnSelected 
            ? Border.all(color: const Color(0xFF4F46E5), width: 2)
            : null,
      ),
      child: Center(child: iconWidget),
    );
  }
}