import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/payment_proofs_model.dart';
import '../../../../core/services/pdf_service.dart';

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
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final screenWidth = constraints.maxWidth;
                  final screenHeight = MediaQuery.of(context).size.height;
                  final isVerySmall = screenWidth < 320;
                  final isSmall = screenWidth < 375;
                  final isShortScreen = screenHeight < 700;
                  
                  // Responsive padding
                  final horizontalPadding = isVerySmall ? 12.0 : (isSmall ? 16.0 : 24.0);
                  final verticalPadding = isShortScreen ? 12.0 : 24.0;
                  
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
                    child: Column(
                      children: [
                        SizedBox(height: isShortScreen ? 16 : 32),
                        
                        // Icône de cotisation - Responsive
                        Container(
                          width: isVerySmall ? 60 : (isSmall ? 70 : 80),
                          height: isVerySmall ? 60 : (isSmall ? 70 : 80),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(isVerySmall ? 30 : (isSmall ? 35 : 40)),
                            border: Border.all(
                              color: const Color(0xFF10B981).withValues(alpha: 0.3),
                              width: isVerySmall ? 2 : 3,
                            ),
                          ),
                          child: Icon(
                            Icons.account_balance_wallet,
                            color: const Color(0xFF10B981),
                            size: isVerySmall ? 28 : (isSmall ? 35 : 40),
                          ),
                        ),
                    
                        SizedBox(height: isShortScreen ? 16 : 24),
                        
                        // Montant principal - Responsive
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '+${montant.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
                            style: TextStyle(
                              fontSize: isVerySmall ? 32 : (isSmall ? 40 : 48),
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF10B981),
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                    
                        SizedBox(height: isShortScreen ? 6 : 8),
                        
                        // Titre de la cotisation - Responsive
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: isVerySmall ? 8 : 16),
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: isVerySmall ? 14 : (isSmall ? 16 : 18),
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF6B7280),
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    
                        SizedBox(height: isShortScreen ? 24 : 40),
                        
                        // Bouton Partager - Responsive
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: isSmall ? double.infinity : 200,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _showShareOptions(context, title, montant.toStringAsFixed(0), date, paymentMethod, cotisationId, isPaid ? 'Validé' : 'En attente'),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isVerySmall ? 16 : 24, 
                                vertical: isVerySmall ? 12 : 16
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.share,
                                    color: Colors.grey.shade600,
                                    size: isVerySmall ? 18 : 20,
                                  ),
                                  SizedBox(width: isVerySmall ? 6 : 8),
                                  Text(
                                    'Partager',
                                    style: TextStyle(
                                      fontSize: isVerySmall ? 14 : 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    
                        SizedBox(height: isShortScreen ? 32 : 48),
                        
                        // Détails de la cotisation - Responsive
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
                                isVerySmall: isVerySmall,
                                isSmall: isSmall,
                              ),
                              _buildDetailRow(
                                'Statut',
                                isPaid ? 'Validé' : 'En attente',
                                true,
                                valueColor: isPaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                hasIcon: true,
                                isVerySmall: isVerySmall,
                                isSmall: isSmall,
                              ),
                              _buildDetailRow(
                                'Mode de paiement',
                                paymentMethod,
                                false,
                                hasPaymentIcon: true,
                                isVerySmall: isVerySmall,
                                isSmall: isSmall,
                              ),
                              _buildDetailRow(
                                'Date et heure',
                                date,
                                true,
                                isVerySmall: isVerySmall,
                                isSmall: isSmall,
                              ),
                              _buildDetailRow(
                                'ID de paiement',
                                cotisationId,
                                false,
                                isLast: true,
                                isVerySmall: isVerySmall,
                                isSmall: isSmall,
                              ),
                        ],
                      ),
                    ),
                    
                        SizedBox(height: isShortScreen ? 32 : 48),
                        
                        // Section informations du mode de paiement - Responsive
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
                                  padding: EdgeInsets.all(isVerySmall ? 12 : (isSmall ? 16 : 20)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isVerySmall ? 8 : (isSmall ? 10 : 12)),
                                        decoration: BoxDecoration(
                                          color: _getPaymentMethodColor(paymentMethod).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getPaymentMethodIcon(paymentMethod),
                                          color: _getPaymentMethodColor(paymentMethod),
                                          size: isVerySmall ? 18 : (isSmall ? 20 : 24),
                                        ),
                                      ),
                                      SizedBox(width: isVerySmall ? 12 : 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getPaymentMethodTitle(paymentMethod),
                                              style: TextStyle(
                                                fontSize: isVerySmall ? 14 : (isSmall ? 15 : 16),
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1F2937),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: isVerySmall ? 2 : 4),
                                            Text(
                                              _getPaymentMethodDescription(paymentMethod),
                                              style: TextStyle(
                                                fontSize: isVerySmall ? 12 : (isSmall ? 13 : 14),
                                                color: const Color(0xFF6B7280),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                                  padding: EdgeInsets.all(isVerySmall ? 12 : (isSmall ? 16 : 20)),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(isVerySmall ? 8 : (isSmall ? 10 : 12)),
                                        decoration: BoxDecoration(
                                          color: _getPaymentMethodColor(paymentMethod).withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          _getPaymentMethodIcon(paymentMethod),
                                          color: _getPaymentMethodColor(paymentMethod),
                                          size: isVerySmall ? 18 : (isSmall ? 20 : 24),
                                        ),
                                      ),
                                      SizedBox(width: isVerySmall ? 12 : 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _getPaymentMethodTitle(paymentMethod),
                                              style: TextStyle(
                                                fontSize: isVerySmall ? 14 : (isSmall ? 15 : 16),
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xFF1F2937),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            SizedBox(height: isVerySmall ? 2 : 4),
                                            Text(
                                              _getPaymentMethodDescription(paymentMethod),
                                              style: TextStyle(
                                                fontSize: isVerySmall ? 12 : (isSmall ? 13 : 14),
                                                color: const Color(0xFF6B7280),
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
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
                        
                        SizedBox(height: isShortScreen ? 32 : 48),
                        
                        // Footer - Responsive
                        Text(
                          'Cotisation effectuée via GestCity',
                          style: TextStyle(
                            fontSize: isVerySmall ? 12 : 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        
                        SizedBox(height: isShortScreen ? 16 : 32),
                      ],
                    ),
                  );
                },
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
    bool isVerySmall = false,
    bool isSmall = false,
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
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmall ? 12 : (isSmall ? 16 : 20), 
        vertical: isVerySmall ? 12 : 16
      ),
      child: Column(
        children: [
          // Pour les très petits écrans, afficher en colonne
          if (isVerySmall) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF1F2937),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (hasIcon) ...[ 
                  Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                if (hasPaymentIcon) ...[
                  Icon(
                    _getPaymentMethodIcon(value),
                    color: _getPaymentMethodColor(value),
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ] else ...[
            // Pour les écrans normaux, afficher en ligne
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: isSmall ? 14 : 16,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (hasIcon) ...[ 
                        Container(
                          width: isSmall ? 18 : 20,
                          height: isSmall ? 18 : 20,
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: BorderRadius.circular(isSmall ? 9 : 10),
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: isSmall ? 12 : 14,
                          ),
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                      ],
                      if (hasPaymentIcon) ...[
                        Icon(
                          _getPaymentMethodIcon(value),
                          color: _getPaymentMethodColor(value),
                          size: isSmall ? 14 : 16,
                        ),
                        SizedBox(width: isSmall ? 6 : 8),
                      ],
                      Flexible(
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: isSmall ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: valueColor ?? const Color(0xFF6B7280),
                          ),
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
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

    // Utilisation du nouveau système de partage PDF (obsolète)
    _showShareOptions(context, shareTitle, shareAmount, shareDate, shareMode, '', shareStatus);
  }

  // Nouvelle méthode pour afficher les options de partage
  void _showShareOptions(BuildContext context, String title, String amount, String date, String paymentMethod, String paymentId, String status) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Header
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.share,
                        size: 48,
                        color: Color(0xFF4F46E5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Partager le reçu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choisissez comment vous souhaitez partager votre reçu',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                // Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Option PDF + Partage natif
                      _buildShareOption(
                        context: context,
                        icon: Icons.picture_as_pdf,
                        title: 'Générer et partager PDF',
                        subtitle: 'Créer un reçu PDF et le partager',
                        color: const Color(0xFFDC2626),
                        onTap: () async {
                          Navigator.pop(context);
                          await _generateAndSharePdf(context, title, amount, date, paymentMethod, paymentId, status);
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Option Preview + Imprimer
                      _buildShareOption(
                        context: context,
                        icon: Icons.print,
                        title: 'Aperçu et impression',
                        subtitle: 'Voir le reçu et choisir les options',
                        color: const Color(0xFF4F46E5),
                        onTap: () async {
                          Navigator.pop(context);
                          await _showPrintPreview(context, title, amount, date, paymentMethod, paymentId, status);
                        },
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Option Texte simple
                      _buildShareOption(
                        context: context,
                        icon: Icons.text_format,
                        title: 'Partager en texte',
                        subtitle: 'Partager les informations en texte simple',
                        color: const Color(0xFF059669),
                        onTap: () {
                          Navigator.pop(context);
                          _shareAsText(context, title, amount, date, paymentMethod, paymentId, status);
                        },
                      ),
                    ],
                  ),
                ),
                
                // Bouton Annuler
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Annuler',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShareOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  // Générer et partager le PDF
  Future<void> _generateAndSharePdf(BuildContext context, String title, String amount, String date, String paymentMethod, String paymentId, String status) async {
    try {
      // Afficher un indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Génération du PDF...'),
              ],
            ),
          );
        },
      );

      await PdfService.generateAndShareReceipt(
        title: title,
        amount: '$amount FCFA',
        date: date,
        paymentMethod: paymentMethod,
        paymentId: paymentId,
        status: status,
      );

      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialogue de chargement
      }
      
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Fermer le dialogue de chargement
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Afficher l'aperçu et les options d'impression
  Future<void> _showPrintPreview(BuildContext context, String title, String amount, String date, String paymentMethod, String paymentId, String status) async {
    try {
      await PdfService.showPrintOptions(
        title: title,
        amount: '$amount FCFA',
        date: date,
        paymentMethod: paymentMethod,
        paymentId: paymentId,
        status: status,
      );
      
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Partager en texte simple (méthode existante améliorée)
  void _shareAsText(BuildContext context, String title, String amount, String date, String paymentMethod, String paymentId, String status) {
    final shareText = '''
🏦 REÇU DE PAIEMENT - GestCity

📋 Type: $title
💰 Montant: +$amount FCFA
📅 Date: $date
🔄 Mode: $paymentMethod
🆔 ID: $paymentId
✅ Statut: $status

Généré via GestCity
''';

    try {
      // Utiliser le package share_plus pour partager le texte
      Share.share(shareText, subject: 'Reçu de cotisation GestCity');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
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