import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
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

  List<int> get _segmentMonths {
    final startMonth = (selectedSegment == '1-6') ? 1 : 7;
    return List.generate(6, (index) => startMonth + index);
  }

  @override
  Widget build(BuildContext context) {
    final montantVentile = selectedMonth != null
        ? montantVentileRef[selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + montantVentileRef[month - 1]);
    
    final montantRecu = selectedMonth != null
        ? montantRecuParMois[selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + montantRecuParMois[month - 1]);
        
    final montantReel = selectedMonth != null
        ? montantReelParMois[selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + montantReelParMois[month - 1]);
        
    final montantRemboursement = selectedMonth != null
        ? montantRemboursementParMois[selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + montantRemboursementParMois[month - 1]);
        
    final montantAvance = selectedMonth != null
        ? montantAvanceParMois[selectedMonth! - 1]
        : _segmentMonths.fold(0, (sum, month) => sum + montantAvanceParMois[month - 1]);

    final titleText = selectedMonth != null
        ? 'Bilan ${monthNames[selectedMonth! - 1]} ${DateTime.now().year}'
        : 'Bilan ${selectedSegment == '1-6' ? 'Janvier-Juin' : 'Juillet-Décembre'} ${DateTime.now().year}';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
            Color(0xFF8B5CF6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bilan détaillé des montants',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.8,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: [
              _buildSummaryItem(
                'Montant réel',
                '${montantReel.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                Icons.check_circle,
                const Color(0xFF10B981),
              ),
              _buildSummaryItem(
                'Montant remboursement',
                '${montantRemboursement.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                Icons.replay,
                const Color(0xFF3B82F6),
              ),
              _buildSummaryItem(
                'Montant reçu',
                '${montantRecu.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                Icons.payments,
                const Color(0xFFF59E0B),
              ),
              _buildSummaryItem(
                'Montant avance',
                '${montantAvance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                Icons.trending_up,
                const Color(0xFF8B5CF6),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total reçu:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${montantRecu.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Différence:',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                    Text(
                      '${(montantRecu - montantVentile).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: (montantRecu - montantVentile) >= 0 
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}