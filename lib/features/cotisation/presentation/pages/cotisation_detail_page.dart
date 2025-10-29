import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/payment_proofs_model.dart';

class CotisationDetailPage extends StatelessWidget {
  final Map<String, dynamic>? cotisation; // Pour compatibilité avec ancienne version
  final PaymentProof? paymentProof; // Nouvelles données depuis l'API

  const CotisationDetailPage({
    super.key,
    this.cotisation,
    this.paymentProof,
  }) : assert(cotisation != null || paymentProof != null, 'Either cotisation or paymentProof must be provided');

  @override
  Widget build(BuildContext context) {
    // Utiliser les données du PaymentProof si disponible, sinon utiliser les anciennes données
    late final bool isPaid;
    late final double montant;
    late final String title;
    late final String date;
    late final String paymentMethod;
    late final String cotisationId;
    
    if (paymentProof != null) {
      // Nouvelles données depuis l'API
      isPaid = paymentProof!.isValidated;
      montant = paymentProof!.amountPaid;
      title = paymentProof!.displayTitle;
      date = paymentProof!.formattedDate;
      paymentMethod = paymentProof!.formattedPaymentMethod; // Utiliser le vrai mode de paiement depuis l'API
      cotisationId = paymentProof!.id.toString(); // Utiliser l'ID réel du paiement au lieu de null
    } else {
      // Anciennes données (compatibilité)
      isPaid = cotisation!['isPaid'] as bool;
      montant = 5000.0; // Montant fixe des cotisations
      title = cotisation!['title'] as String;
      date = cotisation!['date'] as String;
      paymentMethod = cotisation!['paymentMethod'] ?? 'Code QR';
      cotisationId = 'COT${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    }

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
                      '+${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
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
                            '${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                            false,
                          ),
                          _buildDetailRow(
                            'Statut',
                            isPaid ? 'Validé' : 'En attente',
                            true,
                            valueColor: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
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
                            'ID de paiement',
                            cotisationId,
                            false,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Section informations du mode de paiement
                    if (paymentMethod == 'Code QR' || paymentMethod == 'Validé' || paymentMethod == 'Mobile Money') ...[
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
                                      color: _getPaymentMethodColor(paymentMethod).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getPaymentMethodIcon(paymentMethod),
                                      color: _getPaymentMethodColor(paymentMethod),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getPaymentMethodTitle(paymentMethod),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getPaymentMethodDescription(paymentMethod),
                                          style: const TextStyle(
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
                    ] else if (paymentMethod == 'Preuve' || paymentMethod == 'En attente' || paymentMethod == 'Main à main') ...[
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
                                      color: _getPaymentMethodColor(paymentMethod).withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getPaymentMethodIcon(paymentMethod),
                                      color: _getPaymentMethodColor(paymentMethod),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _getPaymentMethodTitle(paymentMethod),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          _getPaymentMethodDescription(paymentMethod),
                                          style: const TextStyle(
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
    // Utiliser les données appropriées selon la source
    late final String shareTitle;
    late final String shareAmount;
    late final String shareDate;
    late final String shareMode;
    late final String shareStatus;
    
    if (paymentProof != null) {
      shareTitle = paymentProof!.displayTitle;
      shareAmount = paymentProof!.formattedAmount;
      shareDate = paymentProof!.formattedDate;
      shareMode = paymentProof!.formattedPaymentMethod;
      shareStatus = paymentProof!.isValidated ? 'Validé' : 'En attente';
    } else {
      shareTitle = cotisation!['title'];
      shareAmount = '5 000 FCFA';
      shareDate = cotisation!['date'];
      shareMode = cotisation!['paymentMethod'] ?? 'Code QR';
      shareStatus = 'Payé';
    }
    
    final shareText = '''
Cotisation GestCity

Type: $shareTitle
Montant: +$shareAmount
Date: $shareDate
Mode: $shareMode
Statut: $shareStatus

Généré via GestCity
''';

    // TODO: Add share_plus dependency to pubspec.yaml and uncomment Share.share(shareText);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partager: $shareText')),
    );
  }

  // Méthodes helper pour les modes de paiement
  Color _getPaymentMethodColor(String paymentMethod) {
    switch (paymentMethod) {
      case 'Mobile Money':
        return const Color(0xFF059669); // Vert pour mobile money
      case 'Main à main':
        return const Color(0xFF7C3AED); // Violet pour main à main
      case 'Code QR':
      case 'Validé':
        return const Color(0xFF4F46E5); // Bleu pour QR/Validé
      case 'En attente':
        return const Color(0xFFF59E0B); // Orange pour en attente
      case 'Preuve':
        return const Color(0xFF1F2937); // Gris foncé pour preuve
      default:
        return const Color(0xFF6B7280); // Gris par défaut
    }
  }

  IconData _getPaymentMethodIcon(String paymentMethod) {
    switch (paymentMethod) {
      case 'Mobile Money':
        return Icons.phone_android;
      case 'Main à main':
        return Icons.handshake;
      case 'Code QR':
      case 'Validé':
        return Icons.qr_code;
      case 'En attente':
        return Icons.hourglass_empty;
      case 'Preuve':
        return Icons.receipt_long;
      default:
        return Icons.payment;
    }
  }

  String _getPaymentMethodTitle(String paymentMethod) {
    switch (paymentMethod) {
      case 'Mobile Money':
        return 'Paiement Mobile Money';
      case 'Main à main':
        return 'Paiement main à main';
      case 'Code QR':
        return 'Paiement par Code QR';
      case 'Validé':
        return 'Paiement validé';
      case 'En attente':
        return 'Paiement en attente';
      case 'Preuve':
        return 'Preuve de paiement';
      default:
        return 'Paiement';
    }
  }

  String _getPaymentMethodDescription(String paymentMethod) {
    switch (paymentMethod) {
      case 'Mobile Money':
        return 'Paiement effectué via Mobile Money';
      case 'Main à main':
        return 'Paiement effectué en espèces';
      case 'Code QR':
        return 'Code scanné par l\'administrateur';
      case 'Validé':
        return 'Paiement confirmé par l\'administrateur';
      case 'En attente':
        return 'En cours de validation par l\'administrateur';
      case 'Preuve':
        return 'Reçu téléchargé et validé';
      default:
        return 'Mode de paiement';
    }
  }
}