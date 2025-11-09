import 'package:flutter/material.dart';

class SummaryCard extends StatefulWidget {
  final String selectedSegment;
  final int? selectedMonth;
  final List<String> monthNames;
  final List<int> montantVentileRef;
  final List<int> montantRecuParMois;
  final List<int> montantReelParMois;
  final List<int> montantRemboursementParMois;
  final List<int> montantAvanceParMois;

  const SummaryCard({
    super.key,
    required this.selectedSegment,
    required this.selectedMonth,
    required this.monthNames,
    required this.montantVentileRef,
    required this.montantRecuParMois,
    required this.montantReelParMois,
    required this.montantRemboursementParMois,
    required this.montantAvanceParMois,
  });

  @override
  State<SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<SummaryCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  List<int> get _segmentMonths {
    final startMonth = (widget.selectedSegment == '1-6') ? 1 : 7;
    return List.generate(6, (index) => startMonth + index);
  }

  @override
  Widget build(BuildContext context) {
    final montantVentile = widget.selectedMonth != null
        ? widget.montantVentileRef[widget.selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + widget.montantVentileRef[month - 1]);
    
        
    final montantReel = widget.selectedMonth != null
        ? widget.montantReelParMois[widget.selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + widget.montantReelParMois[month - 1]);
        
    final montantRemboursement = widget.selectedMonth != null
        ? widget.montantRemboursementParMois[widget.selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + widget.montantRemboursementParMois[month - 1]);
        
    final montantAvance = widget.selectedMonth != null
        ? widget.montantAvanceParMois[widget.selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + widget.montantAvanceParMois[month - 1]);

    
    return GestureDetector(
      onTap: _toggleExpanded,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec icône et titre + bouton expand
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF3B82F6),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          text: 'Bilan Financier ',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                            fontFamily: 'Poppins',
                          ),
                          children: [
                            TextSpan(
                              text: widget.selectedMonth != null
                                  ? widget.monthNames[widget.selectedMonth! - 1]
                                  : '${widget.selectedSegment == '1-6' ? 'Janv-Juin' : 'Juil-Déc'} ${DateTime.now().year}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                                fontFamily: 'Nunito',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Informations compactes sur une seule ligne
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildCompactInfoItem('M.réel', _formatCurrency(montantReel), const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _buildCompactInfoItem('Rembours.', _formatCurrency(montantRemboursement), const Color(0xFF3B82F6)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildCompactInfoItem('M.avance', _formatCurrency(montantAvance), const Color(0xFF8B5CF6)),
                      const SizedBox(width: 8),
                      _buildCompactInfoItem('M.ventilé', _formatCurrency(montantVentile), const Color(0xFFF59E0B)),
                    ],
                  ),
                ],
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  Widget _buildModernInfoItem(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontFamily: 'Nunito',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
              fontFamily: 'Poppins',
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '${millions.toStringAsFixed(millions == millions.roundToDouble() ? 0 : 1)}M F';
    } else if (amount >= 1000) {
      final thousands = amount / 1000;
      return '${thousands.toStringAsFixed(thousands == thousands.roundToDouble() ? 0 : 1)}k F';
    } else {
      return '$amount F';
    }
  }

  Widget _buildCompactInfoItem(String label, String value, Color color) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$label: $value',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}