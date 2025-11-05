import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'payment_cell.dart';

class PaymentTable extends StatelessWidget {
  final String selectedSegment;
  final int? selectedMonth;
  final List<Map<String, dynamic>> members;
  final List<String> monthNames;
  final Function(int?) onMonthSelected;

  const PaymentTable({
    super.key,
    required this.selectedSegment,
    required this.selectedMonth,
    required this.members,
    required this.monthNames,
    required this.onMonthSelected,
  });

  List<int> get segmentMonths {
    final startMonth = (selectedSegment == '1-6') ? 1 : 7;
    return List.generate(6, (index) => startMonth + index);
  }

  @override
  Widget build(BuildContext context) {
    final segmentMonths = this.segmentMonths;
    final currentMonth = DateTime.now().month;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec les mois
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
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
                            padding: const EdgeInsets.symmetric(vertical: 8),
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
          ),
          
          // Lignes des membres
          ...members.asMap().entries.map((entry) {
            final index = entry.key;
            final member = entry.value;
            final isLast = index == members.length - 1;
            
            return Container(
              decoration: BoxDecoration(
                border: isLast ? null : Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade100,
                    width: 1,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: Text(
                        member['name'].split(' ')[0], // Juste le prénom pour mobile
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: segmentMonths.map((month) {
                          final monthIndex = month - 1;
                          final paymentStatus = member['payments'][monthIndex];
                          final isColumnSelected = month == selectedMonth;
                          
                          return Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: PaymentCell(
                                status: paymentStatus,
                                isColumnSelected: isColumnSelected,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}