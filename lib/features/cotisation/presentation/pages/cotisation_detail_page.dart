import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CotisationDetailPage extends StatelessWidget {
  final Map<String, dynamic> cotisation;

  const CotisationDetailPage({
    super.key,
    required this.cotisation,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = cotisation['isPaid'] as bool;
    final montant = 5000; // Montant fixe des cotisations
    final title = cotisation['title'] as String;
    final date = cotisation['date'] as String;
    final paymentMethod = cotisation['paymentMethod'] ?? 'Code QR'; // Code QR ou Preuve

    // Génération d'un ID de cotisation fictif
    final cotisationId = 'COT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header avec bouton retour
            Container(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF1F2937),
                      size: 24,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Détails de la cotisation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer le bouton retour
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    
                    // Icône de cotisation
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet,
                        color: Color(0xFF10B981),
                        size: 40,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Montant principal
                    Text(
                      '+${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}F',
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                        letterSpacing: -1,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Titre de la cotisation
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF6B7280),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Bouton Partager
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _shareCotisation(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.share,
                                color: Colors.grey.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Partager',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Détails de la cotisation
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Montant payé',
                            '${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}F',
                            false,
                          ),
                          _buildDetailRow(
                            'Statut',
                            'Payé',
                            true,
                            valueColor: const Color(0xFF10B981),
                            hasIcon: true,
                          ),
                          _buildDetailRow(
                            'Mode de paiement',
                            paymentMethod,
                            false,
                            hasPaymentIcon: true,
                          ),
                          _buildDetailRow(
                            'Date et heure',
                            date,
                            true,
                          ),
                          _buildDetailRow(
                            'ID de cotisation',
                            cotisationId,
                            false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Section informations du mode de paiement
                    if (paymentMethod == 'Code QR') ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.qr_code,
                                      color: Color(0xFF4F46E5),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Paiement par Code QR',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Code scanné par l\'administrateur',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
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
                      ),
                    ] else if (paymentMethod == 'Preuve') ...[
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1F2937).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.receipt_long,
                                      color: Color(0xFF1F2937),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Preuve de paiement',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Reçu téléchargé et validé',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Color(0xFF6B7280),
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
                      ),
                    ],
                    
                    const SizedBox(height: 48),
                    
                    // Footer
                    Text(
                      'Cotisation effectuée via GestCity',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label, 
    String value, 
    bool isEven, {
    Color? valueColor,
    bool hasIcon = false,
    bool hasPaymentIcon = false,
    bool isLast = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? Colors.grey.shade50 : Colors.white,
        border: isLast ? null : Border(
          bottom: BorderSide(
            color: Colors.grey.shade100,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF1F2937),
            ),
          ),
          Row(
            children: [
              if (hasIcon) ...[ 
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              if (hasPaymentIcon) ...[
                Icon(
                  value == 'Code QR' ? Icons.qr_code : Icons.receipt_long,
                  color: value == 'Code QR' ? const Color(0xFF4F46E5) : const Color(0xFF1F2937),
                  size: 16,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareCotisation(BuildContext context) {
    final shareText = '''
Cotisation GestCity

Type: ${cotisation['title']}
Montant: +5 000F
Date: ${cotisation['date']}
Mode: ${cotisation['paymentMethod'] ?? 'Code QR'}
Statut: Payé

Généré via GestCity
''';

    // TODO: Add share_plus dependency to pubspec.yaml and uncomment Share.share(shareText);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partager: $shareText')),
    );
  }
}