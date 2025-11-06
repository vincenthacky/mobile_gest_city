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
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.analytics,
                    color: Color(0xFF3B82F6),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bilan Financier',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.selectedMonth != null
                            ? widget.monthNames[widget.selectedMonth! - 1]
                            : '${widget.selectedSegment == '1-6' ? 'Janvier-Juin' : 'Juillet-Décembre'} ${DateTime.now().year}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton d'expansion
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 300),
                    turns: _isExpanded ? 0.5 : 0,
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Informations essentielles (toujours visibles) - Montant réel et remboursement
            Row(
              children: [
                Expanded(
                  child: _buildModernInfoItem(
                    'Montant réel',
                    _formatCurrency(montantReel),
                    const Color(0xFF10B981),
                    Icons.check_circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildModernInfoItem(
                    'Remboursement',
                    _formatCurrency(montantRemboursement),
                    const Color(0xFF3B82F6),
                    Icons.replay,
                  ),
                ),
              ],
            ),
            
            // Détails expandables
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  
                  // Informations supplémentaires
                  Row(
                    children: [
                      Expanded(
                        child: _buildModernInfoItem(
                          'Montant avance',
                          _formatCurrency(montantAvance),
                          const Color(0xFF8B5CF6),
                          Icons.trending_up,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildModernInfoItem(
                          'Montant ventilé',
                          _formatCurrency(montantVentile),
                          const Color(0xFFF59E0B),
                          Icons.account_balance,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Indicateur visuel pour montrer qu'on peut cliquer
            if (!_isExpanded) ...[
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.touch_app,
                        size: 14,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Toucher pour voir plus de détails',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
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
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F';
  }
}