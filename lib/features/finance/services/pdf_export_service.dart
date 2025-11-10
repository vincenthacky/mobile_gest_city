import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:intl/intl.dart';

class PDFExportService {
  static const int _montantCotisationIndividuelle = 25000; // F CFA

  static Future<void> exportVentilationPDF({
    required int? selectedMonth,
    required List<Map<String, dynamic>> members,
    required List<String> monthNamesFull,
    required List<int> montantVentileRef,
    required List<int> montantRecuParMois,
    required List<int> montantReelParMois,
    required List<int> montantRemboursementParMois,
    required List<int> montantAvanceParMois,
    Rect? sharePositionOrigin,
  }) async {
    // Couleurs app adaptées
    const primaryColor = PdfColor.fromInt(0xFF4F46E5);
    const darkGray = PdfColor.fromInt(0xFF2D2D2F);
    const lightGray = PdfColor.fromInt(0xFF9A9AA0);
    const successColor = PdfColor.fromInt(0xFF10B981);
    const dangerColor = PdfColor.fromInt(0xFFEF4444);
    
    final pdf = pw.Document();
    
    // Page 1: Tableau principal
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPDFHeader(primaryColor),
              pw.SizedBox(height: 20),
              pw.Expanded(
                child: _buildPDFTable(
                  primaryColor, darkGray, lightGray, successColor, dangerColor,
                  selectedMonth, members, monthNamesFull,
                ),
              ),
              pw.SizedBox(height: 20),
              _buildPDFSummary(
                primaryColor, darkGray, lightGray, successColor, dangerColor,
                selectedMonth, members, monthNamesFull, montantVentileRef, montantRecuParMois,
              ),
            ],
          );
        },
      ),
    );
    
    // Page 2: Bilan annuel avec cartes mensuelles
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.portrait,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // En-tête
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                color: primaryColor,
                child: pw.Text(
                  'Bilan Annuel ${DateTime.now().year}',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Grille simple 3x4 pour les 12 mois avec vraies données
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  child: pw.Column(
                    children: [
                      // Première ligne (Janvier à Mars)
                      pw.Row(
                        children: [
                          _buildMonthCard(monthNamesFull[0], 
                            montantReelParMois.isNotEmpty ? montantReelParMois[0] : 0,
                            montantRemboursementParMois.isNotEmpty ? montantRemboursementParMois[0] : 0,
                            montantRecuParMois.isNotEmpty ? montantRecuParMois[0] : 0,
                            montantAvanceParMois.isNotEmpty ? montantAvanceParMois[0] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[1], 
                            montantReelParMois.length > 1 ? montantReelParMois[1] : 0,
                            montantRemboursementParMois.length > 1 ? montantRemboursementParMois[1] : 0,
                            montantRecuParMois.length > 1 ? montantRecuParMois[1] : 0,
                            montantAvanceParMois.length > 1 ? montantAvanceParMois[1] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[2], 
                            montantReelParMois.length > 2 ? montantReelParMois[2] : 0,
                            montantRemboursementParMois.length > 2 ? montantRemboursementParMois[2] : 0,
                            montantRecuParMois.length > 2 ? montantRecuParMois[2] : 0,
                            montantAvanceParMois.length > 2 ? montantAvanceParMois[2] : 0,
                            successColor),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      
                      // Deuxième ligne (Avril à Juin)
                      pw.Row(
                        children: [
                          _buildMonthCard(monthNamesFull[3], 
                            montantReelParMois.length > 3 ? montantReelParMois[3] : 0,
                            montantRemboursementParMois.length > 3 ? montantRemboursementParMois[3] : 0,
                            montantRecuParMois.length > 3 ? montantRecuParMois[3] : 0,
                            montantAvanceParMois.length > 3 ? montantAvanceParMois[3] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[4], 
                            montantReelParMois.length > 4 ? montantReelParMois[4] : 0,
                            montantRemboursementParMois.length > 4 ? montantRemboursementParMois[4] : 0,
                            montantRecuParMois.length > 4 ? montantRecuParMois[4] : 0,
                            montantAvanceParMois.length > 4 ? montantAvanceParMois[4] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[5], 
                            montantReelParMois.length > 5 ? montantReelParMois[5] : 0,
                            montantRemboursementParMois.length > 5 ? montantRemboursementParMois[5] : 0,
                            montantRecuParMois.length > 5 ? montantRecuParMois[5] : 0,
                            montantAvanceParMois.length > 5 ? montantAvanceParMois[5] : 0,
                            successColor),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      
                      // Troisième ligne (Juillet à Septembre)
                      pw.Row(
                        children: [
                          _buildMonthCard(monthNamesFull[6], 
                            montantReelParMois.length > 6 ? montantReelParMois[6] : 0,
                            montantRemboursementParMois.length > 6 ? montantRemboursementParMois[6] : 0,
                            montantRecuParMois.length > 6 ? montantRecuParMois[6] : 0,
                            montantAvanceParMois.length > 6 ? montantAvanceParMois[6] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[7], 
                            montantReelParMois.length > 7 ? montantReelParMois[7] : 0,
                            montantRemboursementParMois.length > 7 ? montantRemboursementParMois[7] : 0,
                            montantRecuParMois.length > 7 ? montantRecuParMois[7] : 0,
                            montantAvanceParMois.length > 7 ? montantAvanceParMois[7] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[8], 
                            montantReelParMois.length > 8 ? montantReelParMois[8] : 0,
                            montantRemboursementParMois.length > 8 ? montantRemboursementParMois[8] : 0,
                            montantRecuParMois.length > 8 ? montantRecuParMois[8] : 0,
                            montantAvanceParMois.length > 8 ? montantAvanceParMois[8] : 0,
                            successColor),
                        ],
                      ),
                      pw.SizedBox(height: 15),
                      
                      // Quatrième ligne (Octobre à Décembre)
                      pw.Row(
                        children: [
                          _buildMonthCard(monthNamesFull[9], 
                            montantReelParMois.length > 9 ? montantReelParMois[9] : 0,
                            montantRemboursementParMois.length > 9 ? montantRemboursementParMois[9] : 0,
                            montantRecuParMois.length > 9 ? montantRecuParMois[9] : 0,
                            montantAvanceParMois.length > 9 ? montantAvanceParMois[9] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[10], 
                            montantReelParMois.length > 10 ? montantReelParMois[10] : 0,
                            montantRemboursementParMois.length > 10 ? montantRemboursementParMois[10] : 0,
                            montantRecuParMois.length > 10 ? montantRecuParMois[10] : 0,
                            montantAvanceParMois.length > 10 ? montantAvanceParMois[10] : 0,
                            successColor),
                          pw.SizedBox(width: 15),
                          _buildMonthCard(monthNamesFull[11], 
                            montantReelParMois.length > 11 ? montantReelParMois[11] : 0,
                            montantRemboursementParMois.length > 11 ? montantRemboursementParMois[11] : 0,
                            montantRecuParMois.length > 11 ? montantRecuParMois[11] : 0,
                            montantAvanceParMois.length > 11 ? montantAvanceParMois[11] : 0,
                            successColor),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
    
    // Sauvegarder et partager le PDF
    final output = await getTemporaryDirectory();
    final fileName = 'ventilation_${DateFormat('yyyy-MM-dd').format(DateTime.now())}.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    
    await Share.shareXFiles(
      [XFile(file.path)], 
      text: 'Tableau de Ventilation des Cotisations',
      sharePositionOrigin: sharePositionOrigin,
    );
  }

  static pw.Widget _buildPDFHeader(PdfColor primaryColor) {
    return pw.Container(
      width: double.infinity,
      child: pw.Column(
        children: [
          // En-tête coloré
          pw.Container(
            width: double.infinity,
            height: 25,
            color: primaryColor,
            padding: const pw.EdgeInsets.symmetric(horizontal: 15),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.center,
                  children: [
                    pw.Text(
                      'Tableau de Ventilation des Cotisations ${DateTime.now().year}',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Date de génération
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(left: 15, top: 5),
            child: pw.Text(
              'Généré le ${DateFormat('dd/MM/yyyy').format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPDFTable(
    PdfColor primaryColor, PdfColor darkGray, PdfColor lightGray, 
    PdfColor successColor, PdfColor dangerColor,
    int? selectedMonth, List<Map<String, dynamic>> members, List<String> monthNamesFull,
  ) {
    // Préparer les données du tableau (tous les 12 mois)
    final headers = ['Membre', ...monthNamesFull];
    final tableData = <List<String>>[];
    
    // Vérifications de debug
    debugPrint('DEBUG PDF: Nombre de membres: ${members.length}');
    
    if (members.isEmpty) {
      // Créer une ligne vide pour indiquer qu'il n'y a pas de données
      tableData.add(['Aucune donnée disponible', ...List.filled(12, '---')]);
    } else {
      for (final member in members) {
        debugPrint('DEBUG PDF: Membre: ${member['name']}, Payments: ${member['payments']}');
        
        final row = <String>[member['name'] ?? 'Nom inconnu'];
        final payments = member['payments'] as List<dynamic>? ?? [];
        
        for (int i = 0; i < 12; i++) {
          String status = 'unpaid';
          if (i < payments.length) {
            status = payments[i]?.toString() ?? 'unpaid';
          }
          
          final now = DateTime.now();
          if ((i + 1) > now.month) status = 'future';
          
          if (status == 'paid') {
            row.add('OUI');
          } else if (status == 'future') {
            row.add('---');
          } else if (status == 'pending') {
            row.add('ATT');
          } else {
            row.add('NON');
          }
        }
        tableData.add(row);
      }
    }
    
    // Vérifier si on a des données à afficher
    if (tableData.isEmpty) {
      debugPrint('DEBUG PDF: Aucune donnée dans tableData, création d\'une ligne par défaut');
      tableData.add(['Aucune donnée', ...List.filled(12, '---')]);
    }
    
    debugPrint('DEBUG PDF: Création du tableau avec ${tableData.length} lignes');
    
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FixedColumnWidth(60), // Colonne membre plus large
      },
      children: [
        // En-tête
        pw.TableRow(
          decoration: pw.BoxDecoration(color: primaryColor),
          children: headers.asMap().entries.map((entry) {
            final index = entry.key;
            final header = entry.value;
            // L'index 0 est "Membre", les mois vont de l'index 1 à 12
            // selectedMonth va de 1 à 12, donc on compare directement avec index
            final isSelectedColumn = selectedMonth != null && index > 0 && index == selectedMonth;
            
            return pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: isSelectedColumn 
                  ? pw.BoxDecoration(
                      color: primaryColor,
                      border: pw.Border.all(color: primaryColor, width: 2),
                    )
                  : null,
              child: pw.Text(
                header,
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
                textAlign: pw.TextAlign.center,
              ),
            );
          }).toList(),
        ),
        // Lignes de données
        ...tableData.asMap().entries.map((entry) {
          final rowIndex = entry.key;
          final rowData = entry.value;
          final isAlternate = rowIndex % 2 == 1;
          
          return pw.TableRow(
            decoration: pw.BoxDecoration(
              color: isAlternate ? PdfColors.grey100 : PdfColors.white,
            ),
            children: rowData.asMap().entries.map((cellEntry) {
              final cellIndex = cellEntry.key;
              final cellValue = cellEntry.value;
              // L'index 0 est "Membre", les mois vont de l'index 1 à 12
              // selectedMonth va de 1 à 12, donc on compare directement avec cellIndex
              final isSelectedColumn = selectedMonth != null && cellIndex > 0 && cellIndex == selectedMonth;
              final isMemberColumn = cellIndex == 0;
              
              PdfColor textColor = darkGray;
              PdfColor? backgroundColor;
              pw.FontWeight fontWeight = pw.FontWeight.normal;
              
              if (!isMemberColumn) {
                if (isSelectedColumn) {
                  backgroundColor = const PdfColor.fromInt(0xFFFFF0F5); // Rose très clair
                }
                
                if (cellValue == 'OUI') {
                  textColor = successColor;
                  fontWeight = pw.FontWeight.bold;
                  if (!isSelectedColumn) {
                    backgroundColor = const PdfColor.fromInt(0xFFF0FDF4); // Vert très clair
                  }
                } else if (cellValue == 'NON') {
                  textColor = dangerColor;
                  fontWeight = pw.FontWeight.bold;
                  if (!isSelectedColumn) {
                    backgroundColor = const PdfColor.fromInt(0xFFFEF2F2); // Rouge très clair
                  }
                } else if (cellValue == '---') {
                  textColor = lightGray;
                  if (!isSelectedColumn) {
                    backgroundColor = PdfColors.grey50;
                  }
                }
              } else {
                fontWeight = pw.FontWeight.bold;
              }
              
              return pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: backgroundColor != null 
                    ? pw.BoxDecoration(color: backgroundColor)
                    : null,
                child: pw.Text(
                  cellValue,
                  style: pw.TextStyle(
                    fontSize: isMemberColumn ? 8 : 8,
                    fontWeight: fontWeight,
                    color: textColor,
                  ),
                  textAlign: isMemberColumn ? pw.TextAlign.left : pw.TextAlign.center,
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildPDFSummary(
    PdfColor primaryColor, PdfColor darkGray, PdfColor lightGray, 
    PdfColor successColor, PdfColor dangerColor,
    int? selectedMonth, List<Map<String, dynamic>> members, List<String> monthNamesFull,
    List<int> montantVentileRef, List<int> montantRecuParMois,
  ) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Titre du bilan (comme dans le HTML)
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          color: primaryColor,
          child: pw.Text(
            selectedMonth != null
                ? 'Bilan détaillé - ${monthNamesFull[selectedMonth - 1]} ${DateTime.now().year}'
                : 'Bilan détaillé - Semestre complet',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Contenu du bilan
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              if (selectedMonth != null) 
                ..._buildDetailedSummary(darkGray, lightGray, successColor, dangerColor, 
                    selectedMonth, members, montantVentileRef, montantRecuParMois)
              else 
                ..._buildGenericSummary(darkGray),
            ],
          ),
        ),
      ],
    );
  }

  static List<pw.Widget> _buildDetailedSummary(
    PdfColor darkGray, PdfColor lightGray, PdfColor successColor, PdfColor dangerColor,
    int selectedMonth, List<Map<String, dynamic>> members,
    List<int> montantVentileRef, List<int> montantRecuParMois,
  ) {
    final monthIndex = selectedMonth - 1;
    final montantVentile = montantVentileRef[monthIndex];
    final montantRecu = montantRecuParMois[monthIndex];
    
    // Compter le nombre de personnes qui ont payé ce mois
    final personnesPayees = members.where((member) {
      final status = member['payments'][monthIndex] ?? 'unpaid';
      return status == 'paid';
    }).length;
    
    final montantTheorique = personnesPayees * _montantCotisationIndividuelle;
    final ecart = montantRecu - montantTheorique;
    
    return [
      // Résultats financiers
      pw.Text(
        'Résultats financiers :',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGray),
      ),
      pw.SizedBox(height: 5),
      pw.Text('• Montant ventilé : ${NumberFormat('#,###').format(montantVentile)} F CFA', 
               style: pw.TextStyle(fontSize: 10, color: darkGray)),
      pw.Text('• Montant reçu : ${NumberFormat('#,###').format(montantRecu)} F CFA',
               style: pw.TextStyle(fontSize: 10, color: darkGray)),
      pw.SizedBox(height: 10),
      
      // Calculs détaillés
      pw.Text(
        'Calculs détaillés :',
        style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGray),
      ),
      pw.SizedBox(height: 5),
      pw.Text('• Nombre de personnes ayant payé : $personnesPayees',
               style: pw.TextStyle(fontSize: 10, color: darkGray)),
      pw.Text('• Cotisation individuelle : ${NumberFormat('#,###').format(_montantCotisationIndividuelle)} F CFA',
               style: pw.TextStyle(fontSize: 10, color: darkGray)),
      pw.SizedBox(height: 5),
      
      // Formule de calcul
      pw.Text(
        'Montant théorique = ${NumberFormat('#,###').format(_montantCotisationIndividuelle)} F CFA × $personnesPayees personnes = ${NumberFormat('#,###').format(montantTheorique)} F CFA',
        style: pw.TextStyle(fontSize: 10, fontStyle: pw.FontStyle.italic, color: darkGray),
      ),
      pw.SizedBox(height: 8),
      
      // Analyse de l'écart
      pw.Text(
        ecart > 0 
            ? 'Excédent : +${NumberFormat('#,###').format(ecart)} F CFA'
            : ecart < 0
                ? 'Déficit : ${NumberFormat('#,###').format(ecart)} F CFA'
                : 'Montant exact conforme aux cotisations',
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: pw.FontWeight.bold,
          color: ecart > 0 ? successColor : ecart < 0 ? dangerColor : darkGray,
        ),
      ),
    ];
  }

  static List<pw.Widget> _buildGenericSummary(PdfColor darkGray) {
    return [
      pw.Text(
        'Veuillez sélectionner un mois spécifique pour voir les calculs détaillés.',
        style: pw.TextStyle(fontSize: 10, color: darkGray),
      ),
    ];
  }

  static pw.Widget _buildAnnualSummary(
    PdfColor primaryColor, PdfColor darkGray, PdfColor lightGray, PdfColor successColor,
    List<String> monthNamesFull,
    List<int> montantReelParMois,
    List<int> montantRemboursementParMois,
    List<int> montantRecuParMois,
    List<int> montantAvanceParMois,
  ) {
    debugPrint('DEBUG PDF Bilan Annuel:');
    debugPrint('- Montant réel: $montantReelParMois');
    debugPrint('- Montant remboursement: $montantRemboursementParMois');
    debugPrint('- Montant reçu: $montantRecuParMois');
    debugPrint('- Montant avance: $montantAvanceParMois');
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Titre du bilan annuel
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 15, vertical: 6),
          color: primaryColor,
          child: pw.Text(
            'Bilan Annuel ${DateTime.now().year}',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
          ),
        ),
        pw.SizedBox(height: 15),
        
        // Grille des cartes mensuelles
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5),
          child: pw.Wrap(
            spacing: 15,
            runSpacing: 15,
            children: List.generate(12, (index) {
              final monthName = monthNamesFull[index];
              // Utiliser les vraies données
              final montantReel = index < montantReelParMois.length ? montantReelParMois[index] : 0;
              final montantRemboursement = index < montantRemboursementParMois.length ? montantRemboursementParMois[index] : 0;
              final montantRecu = index < montantRecuParMois.length ? montantRecuParMois[index] : 0;
              final montantAvance = index < montantAvanceParMois.length ? montantAvanceParMois[index] : 0;
              
              debugPrint('DEBUG: Mois $monthName - Réel: $montantReel, Remb: $montantRemboursement, Reçu: $montantRecu, Avance: $montantAvance');
              
              return pw.Container(
                width: 180,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // En-tête du mois
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: const PdfColor.fromInt(0xFFF5F5F5),
                        borderRadius: const pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(8),
                          topRight: pw.Radius.circular(8),
                        ),
                      ),
                      child: pw.Text(
                        monthName,
                        style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: darkGray,
                        ),
                        textAlign: pw.TextAlign.center,
                      ),
                    ),
                    
                    // Contenu des montants
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(12),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildAmountRow('Montant réel', montantReel, successColor),
                          pw.SizedBox(height: 6),
                          _buildAmountRow('Remboursement', montantRemboursement, PdfColors.orange),
                          pw.SizedBox(height: 6),
                          _buildAmountRow('Montant reçu', montantRecu, PdfColors.blue),
                          pw.SizedBox(height: 6),
                          _buildAmountRow('Avance', montantAvance, PdfColors.purple),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
  
  static pw.Widget _buildAmountRow(String label, int amount, PdfColor color) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.Text(
          '${NumberFormat('#,###').format(amount)} F',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: amount > 0 ? color : PdfColors.grey400,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildMonthCard(String monthName, int montantReel, int montantRemboursement, int montantRecu, int montantAvance, PdfColor successColor) {
    return pw.Expanded(
      child: pw.Container(
        height: 120,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // En-tête du mois
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0xFFF5F5F5),
                borderRadius: const pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(8),
                  topRight: pw.Radius.circular(8),
                ),
              ),
              child: pw.Text(
                monthName,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.black,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            
            // Contenu des montants
            pw.Expanded(
              child: pw.Padding(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAmountRow('Réel', montantReel, successColor),
                    _buildAmountRow('Remb.', montantRemboursement, PdfColors.orange),
                    _buildAmountRow('Reçu', montantRecu, PdfColors.blue),
                    _buildAmountRow('Avance', montantAvance, PdfColors.purple),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}