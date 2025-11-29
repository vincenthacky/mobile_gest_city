import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final List<int> segmentMonths;
  final int currentMonth;
  final int? selectedMonth;
  final List<String> monthNames;
  final Function(int?) onMonthSelected;

  StickyHeaderDelegate({
    required this.segmentMonths,
    required this.currentMonth,
    required this.selectedMonth,
    required this.monthNames,
    required this.onMonthSelected,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: maxExtent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 100,
            child: Text(
              'Membre',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: segmentMonths.map((month) {
                final isCurrentMonth = month == currentMonth;
                final isSelected = month == selectedMonth;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onMonthSelected(month == selectedMonth ? null : month);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : isCurrentMonth
                                ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                                : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isCurrentMonth && !isSelected
                            ? Border.all(color: const Color(0xFF4F46E5), width: 1)
                            : null,
                      ),
                      child: Text(
                        monthNames[month - 1],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : isCurrentMonth
                                  ? const Color(0xFF4F46E5)
                                  : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 44.0;

  @override
  double get minExtent => 44.0;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => true;
}