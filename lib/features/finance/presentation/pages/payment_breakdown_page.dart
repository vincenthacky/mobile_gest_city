import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/segment_selector.dart';
import '../widgets/payment_table.dart';
import '../widgets/summary_card.dart';
import '../../services/pdf_export_service.dart';
import '../../controllers/payment_breakdown_controller.dart';

class PaymentBreakdownPage extends StatefulWidget {
  const PaymentBreakdownPage({super.key});

  @override
  State<PaymentBreakdownPage> createState() => _PaymentBreakdownPageState();
}

class _PaymentBreakdownPageState extends State<PaymentBreakdownPage> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  final GlobalKey _downloadButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setDefaultSegment();
    _loadData();
  }

  void _loadData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PaymentBreakdownController>();
      // ✅ Controller déjà initialisé dans bootstrap.dart
      // ✅ PUIS charger les données
      controller.loadPaymentBreakdownData();
    });
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  void _setDefaultSegment() {
    final now = DateTime.now();
    final currentMonth = now.month;
    final selectedSegment = (currentMonth <= 6) ? '1-6' : '7-12';
    
    // Définir le segment par défaut dans le controller
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = context.read<PaymentBreakdownController>();
      controller.updateSelectedSegment(selectedSegment);
      
      // Sélectionner automatiquement le mois actuel s'il est dans le segment
      final startMonth = (selectedSegment == '1-6') ? 1 : 7;
      final segmentMonths = List.generate(6, (index) => startMonth + index);
      if (segmentMonths.contains(currentMonth)) {
        controller.updateSelectedMonth(currentMonth);
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Header fixe
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Color(0xFF1F2937),
                            size: 22,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Ventilation des cotisation ${DateTime.now().year}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                      GestureDetector(
                        key: _downloadButtonKey,
                        onTap: _exportToPDF,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: const Icon(
                            Icons.file_download,
                            color: Color(0xFF4F46E5),
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Consumer<PaymentBreakdownController>(
                    builder: (context, controller, child) {
                      return SegmentSelector(
                        selectedSegment: controller.selectedSegment,
                        onSegmentChanged: _onSegmentChanged,
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // En-tête du tableau
            Consumer<PaymentBreakdownController>(
              builder: (context, controller, child) {
                if (!controller.isLoading && controller.errorMessage == null) {
                  final segmentMonths = List.generate(6, (index) => 
                    (controller.selectedSegment == '1-6' ? 1 : 7) + index);
                  final currentMonth = DateTime.now().month;
                  
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 100,
                          child: Text(
                            'Membre',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: segmentMonths.map((month) {
                              final isCurrentMonth = month == currentMonth;
                              final isSelected = month == controller.selectedMonth;
                              return Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    _onMonthSelected(month == controller.selectedMonth ? null : month);
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 4),
                                    margin: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? const Color(0xFF4F46E5)
                                          : isCurrentMonth
                                              ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                                              : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8),
                                      border: isCurrentMonth && !isSelected
                                          ? Border.all(color: const Color(0xFF4F46E5), width: 1)
                                          : null,
                                    ),
                                    child: Text(
                                      ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'][month - 1],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? Colors.white
                                            : isCurrentMonth
                                                ? const Color(0xFF4F46E5)
                                                : const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            // Bilan pliable
            Consumer<PaymentBreakdownController>(
              builder: (context, controller, child) {
                if (!controller.isLoading && controller.errorMessage == null) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SummaryCard(
                      selectedSegment: controller.selectedSegment,
                      selectedMonth: controller.selectedMonth,
                      monthNames: controller.monthNames,
                      montantVentileRef: controller.montantVentileRef,
                      montantRecuParMois: controller.montantRecuParMois,
                      montantReelParMois: controller.montantReelParMois,
                      montantRemboursementParMois: controller.montantRemboursementParMois,
                      montantAvanceParMois: controller.montantAvanceParMois,
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            
            Expanded(
              child: Consumer<PaymentBreakdownController>(
                builder: (context, controller, child) {
                  if (controller.isLoading) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF4F46E5),
                        ),
                      ),
                    );
                  }
                  
                  if (controller.errorMessage != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Erreur de chargement',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              controller.errorMessage!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: RefreshIndicator(
                        color: const Color(0xFF4F46E5),
                        onRefresh: _onRefresh,
                        child: PaymentTable(
                          selectedSegment: controller.selectedSegment,
                          selectedMonth: controller.selectedMonth,
                          members: controller.membersForTable,
                          monthNames: ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'],
                          onMonthSelected: _onMonthSelected,
                        ),
                      ),
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

  void _onSegmentChanged(String segment) {
    context.read<PaymentBreakdownController>().updateSelectedSegment(segment);
  }

  void _onMonthSelected(int? month) {
    context.read<PaymentBreakdownController>().updateSelectedMonth(month);
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    await context.read<PaymentBreakdownController>().refreshData();
    
    // Restart animations
    _fadeController.reset();
    _scaleController.reset();
    await Future.delayed(const Duration(milliseconds: 300));
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _exportToPDF() async {
    HapticFeedback.lightImpact();
    
    bool isDialogShown = false;
    
    try {
      // Afficher l'indicateur de chargement
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(color: Color(0xFF4F46E5)),
                SizedBox(width: 20),
                Expanded(
                  child: Text(
                    'Génération du PDF en cours...',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
      isDialogShown = true;
      
      final controller = context.read<PaymentBreakdownController>();
      
      // Attendre que les données soient complètement chargées
      if (controller.isLoading) {
        // Attendre maximum 10 secondes pour le chargement
        int attempts = 0;
        while (controller.isLoading && attempts < 100) {
          await Future.delayed(const Duration(milliseconds: 100));
          attempts++;
        }
      }
      
      // IMPORTANT: Attendre explicitement que toutes les statistiques annuelles soient chargées
      debugPrint('DEBUG: Statistiques avant attente: ${controller.annualStatisticsCount}/12');
      if (controller.annualStatisticsCount < 12) {
        debugPrint('DEBUG: Attente du chargement des 12 mois de statistiques...');
        await controller.ensureAnnualStatisticsLoaded();
        debugPrint('DEBUG: Statistiques après attente: ${controller.annualStatisticsCount}/12');
      }
      
      debugPrint('DEBUG: Export PDF avec ${controller.membersForTable.length} membres');
      debugPrint('DEBUG: Statistiques annuelles: ${controller.annualStatisticsCount} mois chargés');
      
      // Obtenir la position du bouton pour iPhone
      Rect? sharePositionOrigin;
      final RenderBox? renderBox = _downloadButtonKey.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        sharePositionOrigin = Rect.fromLTWH(position.dx, position.dy, renderBox.size.width, renderBox.size.height);
      }

      await PDFExportService.exportVentilationPDF(
        selectedMonth: controller.selectedMonth,
        members: controller.membersForTable,
        monthNamesFull: controller.monthNames,
        montantVentileRef: controller.montantVentileRef,
        montantRecuParMois: controller.montantRecuParMois,
        montantReelParMois: controller.montantReelParMois,
        montantRemboursementParMois: controller.montantRemboursementParMois,
        montantAvanceParMois: controller.montantAvanceParMois,
        sharePositionOrigin: sharePositionOrigin,
      );
      
      debugPrint('DEBUG: PDF export terminé avec succès');
      
      // Fermer l'indicateur de chargement avec gestion d'erreur
      if (mounted && isDialogShown) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogShown = false;
          debugPrint('DEBUG: Dialog fermé avec succès');
        } catch (e) {
          debugPrint('DEBUG: Erreur lors de la fermeture du dialog: $e');
        }
      }
      
      // Petite pause pour s'assurer que le dialog est fermé
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF généré et partagé avec succès'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 3),
          ),
        );
        debugPrint('DEBUG: SnackBar de succès affiché');
      }
    } catch (e) {
      debugPrint('DEBUG: Erreur lors de l\'export PDF: $e');
      
      // Fermer l'indicateur de chargement en cas d'erreur
      if (mounted && isDialogShown) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
          isDialogShown = false;
        } catch (popError) {
          debugPrint('DEBUG: Erreur lors de la fermeture du dialog (erreur): $popError');
        }
      }
      
      // Petite pause pour s'assurer que le dialog est fermé
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération du PDF: $e'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}