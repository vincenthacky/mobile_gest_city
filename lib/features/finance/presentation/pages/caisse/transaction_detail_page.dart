import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/widgets/app_header.dart';
import '../../../models/cash_movement_model.dart';

class TransactionDetailPage extends StatelessWidget {
  final CashMovement transaction;

  const TransactionDetailPage({
    super.key,
    required this.transaction,
  });

  @override
  Widget build(BuildContext context) {
    final isRecette = transaction.isCredit;
    final montant = transaction.amount;
    final type = transaction.typeDisplay;
    final description = '${transaction.methodDisplay} - ${transaction.statusDisplay}';
    final date = _formatDate(transaction.date);

    // Génération d'un ID de transaction fictif
    final transactionId = 'TXN${transaction.id}';
    
    // Extraction du nom de la personne depuis la description
    String getPersonName() {
      return transaction.methodDisplay;
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
                      'Détails de la transaction',
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
                    
                    // Icône de profil/transaction
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isRecette 
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: isRecette 
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 3,
                        ),
                      ),
                      child: Icon(
                        _getTransactionIcon(type),
                        color: isRecette ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 40,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Montant principal
                    Text(
                      '${isRecette ? '+' : '-'}${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}F',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: isRecette ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        letterSpacing: -1,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Nom/Description
                    Text(
                      getPersonName(),
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
                        onTap: () => _shareTransaction(context),
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
                    
                    // Détails de la transaction
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
                            isRecette ? 'Montant reçu' : 'Montant débité',
                            '${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}F',
                            false,
                          ),
                          _buildDetailRow(
                            'Statut',
                            transaction.statusDisplay,
                            true,
                            valueColor: transaction.status == 'VALIDATED' ? const Color(0xFF10B981) : 
                                       transaction.status == 'PENDING' ? const Color(0xFFF59E0B) : const Color(0xFFEF4444),
                            hasIcon: transaction.status == 'VALIDATED',
                          ),
                          _buildDetailRow(
                            'Type',
                            type,
                            false,
                          ),
                          _buildDetailRow(
                            'Méthode',
                            transaction.methodDisplay,
                            true,
                          ),
                          _buildDetailRow(
                            'Date et heure',
                            date,
                            false,
                          ),
                          _buildDetailRow(
                            'ID de transaction',
                            transactionId,
                            true,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),
                    
                    // Footer
                    Text(
                      'Transaction effectuée via GestCity',
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

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  IconData _getTransactionIcon(String type) {
    if (type.contains('Cotisation')) {
      return Icons.account_balance_wallet;
    } else if (type.contains('Financement') || type.contains('Projet')) {
      return Icons.business;
    } else if (type.contains('Achat') || type.contains('Matériel')) {
      return Icons.shopping_cart;
    } else if (type.contains('Don')) {
      return Icons.favorite;
    } else {
      return Icons.payments;
    }
  }

  void _shareTransaction(BuildContext context) {
    final isRecette = transaction.isCredit;
    final montant = transaction.amount;
    final type = transaction.typeDisplay;
    final date = _formatDate(transaction.date);
    
    final shareText = '''
Transaction GestCity

Type: $type
Montant: ${isRecette ? '+' : '-'}${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')}F
Méthode: ${transaction.methodDisplay}
Date: $date
Statut: ${transaction.statusDisplay}

Généré via GestCity
''';

    // Share.share(shareText);
    // TODO: Add share_plus dependency to pubspec.yaml and uncomment Share.share(shareText);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Partager: $shareText')),
    );
  }
}