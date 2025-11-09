import 'package:flutter/material.dart';
import 'payment_cell.dart';
import 'sticky_header_delegate.dart';
import 'legend_widget.dart';

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
    
    return CustomScrollView(
      slivers: [
        // Sticky header
        SliverPersistentHeader(
          pinned: true,
          delegate: StickyHeaderDelegate(
            segmentMonths: segmentMonths,
            currentMonth: currentMonth,
            selectedMonth: selectedMonth,
            monthNames: monthNames,
            onMonthSelected: onMonthSelected,
          ),
        ),
        
        // White container background for table
        SliverToBoxAdapter(
          child: Container(
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
                // Member rows
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
                      borderRadius: isLast
                          ? const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            )
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 100,
                            child: Text(
                              member['name'].split(' ')[0],
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
          ),
        ),
        
        // Legend at the bottom
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.only(top: 20, bottom: 80),
            child: LegendWidget(),
          ),
        ),
      ],
    );
  }
}