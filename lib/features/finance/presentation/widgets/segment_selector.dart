import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SegmentSelector extends StatelessWidget {
  final String selectedSegment;
  final Function(String) onSegmentChanged;

  const SegmentSelector({
    super.key,
    required this.selectedSegment,
    required this.onSegmentChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentButton('1-6', 'Janvier → Juin'),
          ),
          Expanded(
            child: _buildSegmentButton('7-12', 'Juillet → Décembre'),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentButton(String segment, String label) {
    final isSelected = selectedSegment == segment;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onSegmentChanged(segment);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4F46E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}