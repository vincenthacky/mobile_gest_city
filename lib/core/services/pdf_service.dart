import 'dart:io';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/foundation.dart';

class PdfService {
  static Future<void> generateAndShareReceipt({
    required String title,
    required String amount,
    required String date,
    required String paymentMethod,
    required String paymentId,
    required String status,
  }) async {
    try {
      if (kDebugMode) {
        print('🔄 Début génération PDF...');
      }

      // Créer le document PDF
      final pdf = pw.Document();

      // Ajouter une page au PDF
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                _buildHeader(),
                pw.SizedBox(height: 40),
                
                // Titre du reçu
                pw.Center(
                  child: pw.Text(
                    'REÇU DE PAIEMENT',
                    style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.indigo,
                    ),
                  ),
                ),
                pw.SizedBox(height: 30),
                
                // Informations du paiement
                _buildPaymentInfo(
                  title: title,
                  amount: amount,
                  date: date,
                  paymentMethod: paymentMethod,
                  paymentId: paymentId,
                  status: status,
                ),
                
                pw.SizedBox(height: 40),
                
                // Section statut
                _buildStatusSection(status),
                
                pw.Spacer(),
                
                // Footer
                _buildFooter(),
              ],
            );
          },
        ),
      );

      if (kDebugMode) {
        print('📄 PDF créé, génération des bytes...');
      }

      // Sauvegarder et partager le PDF directement
      await _saveAndSharePdf(pdf);
      
      if (kDebugMode) {
        print('✅ PDF partagé avec succès');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur PDF: $e');
      }
      rethrow;
    }
  }

  static pw.Widget _buildHeader() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.indigo50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.indigo100),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'GestCity',
            style: pw.TextStyle(
              fontSize: 28,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.indigo,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Gestion intelligente de votre communauté',
            style: pw.TextStyle(
              fontSize: 14,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPaymentInfo({
    required String title,
    required String amount,
    required String date,
    required String paymentMethod,
    required String paymentId,
    required String status,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        children: [
          _buildInfoRow('Type de cotisation', title),
          pw.SizedBox(height: 15),
          _buildInfoRow('Montant payé', amount, isAmount: true),
          pw.SizedBox(height: 15),
          _buildInfoRow('Date et heure', date),
          pw.SizedBox(height: 15),
          _buildInfoRow('Mode de paiement', paymentMethod),
          pw.SizedBox(height: 15),
          _buildInfoRow('ID de paiement', paymentId),
        ],
      ),
    );
  }

  static pw.Widget _buildInfoRow(String label, String value, {bool isAmount = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.normal,
              color: PdfColors.grey700,
            ),
          ),
        ),
        pw.Expanded(
          flex: 3,
          child: pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: isAmount ? 18 : 14,
                fontWeight: isAmount ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isAmount ? PdfColors.green : PdfColors.grey900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildStatusSection(String status) {
    final isValidated = status.toLowerCase().contains('validé');
    final color = isValidated ? PdfColors.green : PdfColors.orange;
    
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: color.shade(0.1),
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: color),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            decoration: pw.BoxDecoration(
              color: color,
              borderRadius: pw.BorderRadius.circular(10),
            ),
            child: pw.Center(
              child: pw.Text(
                isValidated ? '✓' : '⏳',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Text(
            'Statut: $status',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 16),
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(
                'Reçu généré automatiquement par GestCity',
                style: pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Date de génération: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year} à ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
                style: pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Future<void> _saveAndSharePdf(pw.Document pdf) async {
    try {
      if (kDebugMode) {
        print('💾 Sauvegarde PDF...');
      }

      // Générer les bytes du PDF avec un timeout
      final Uint8List bytes = await pdf.save().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout lors de la génération du PDF');
        },
      );
      
      if (kDebugMode) {
        print('📁 Création du fichier temporaire...');
      }

      // Obtenir le répertoire temporaire
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName = 'recu_gestcity_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final String filePath = '${tempDir.path}/$fileName';
      
      // Créer le fichier
      final File file = File(filePath);
      await file.writeAsBytes(bytes);
      
      if (kDebugMode) {
        print('📤 Ouverture du partage natif...');
      }

      // Partager le fichier avec les applications natives
      // Utilisation de la nouvelle API optimisée
      final result = await Share.shareXFiles(
        [XFile(filePath, name: fileName, mimeType: 'application/pdf')],
        text: 'Reçu de cotisation - GestCity',
        subject: 'Reçu de paiement GestCity',
      );
      
      if (kDebugMode) {
        print('🎯 Résultat partage: ${result.status}');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur partage: $e');
      }
      rethrow;
    }
  }

}