import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'preuve_paiement_page.dart';
import 'qr_paiement_page.dart';
import 'cotisation_detail_page.dart';
import '../../../../core/widgets/app_header.dart';

class CotisationsPage extends StatefulWidget {
  const CotisationsPage({super.key});

  @override
  State<CotisationsPage> createState() => _CotisationsPageState();
}

class _CotisationsPageState extends State<CotisationsPage> with TickerProviderStateMixin {
  bool _showingPayments = true;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Initialize animation controllers
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // Initialize animations
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOutBack,
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _fadeController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _slideController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _scaleController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
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
              child: const AppHeader(
                title: 'Cotisations',
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: () async {
                  HapticFeedback.lightImpact();
                  // Restart animations on refresh
                  _fadeController.reset();
                  _slideController.reset();
                  _scaleController.reset();
                  
                  await Future.delayed(const Duration(milliseconds: 800));
                  
                  // Restart animations
                  _startAnimations();
                  setState(() {});
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Contenu avec padding sauf pour la liste
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Card cotisation mensuelle avec animations
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: _buildCotisationCard(),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Bouton payer cotisation avec animation
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
                                )),
                                child: _buildPayButton(),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Section filtres avec animation
                            FadeTransition(
                              opacity: _fadeAnimation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0, 0.2),
                                  end: Offset.zero,
                                ).animate(CurvedAnimation(
                                  parent: _slideController,
                                  curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
                                )),
                                child: _buildToggleSection(),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      
                      // Liste des paiements sans padding avec animation
                      Column(
                        children: _getPaymentItems().asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 600 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: item,
                                ),
                              );
                            },
                          );
                        }).toList(),
                      ),
                      
                      // Padding bottom pour le scroll
                      const SizedBox(height: 96),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCotisationCard() {
    return Container(
      height: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF4F46E5),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Informations en grille
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date début',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '01/01/2024',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Fin',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '31/12/2024',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Expanded(
                child: Text(
                  '10 000 FCFA / mois',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Somme cible',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      '120 000 FCFA',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Montant et progression
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text(
                '80 000',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                ' / 120 000',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          
          // Barre de progression
          Container(
            width: double.infinity,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Container(
                  width: MediaQuery.of(context).size.width * 0.67 * 0.8,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPayButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          HapticFeedback.mediumImpact();
          _showPaymentMethodModal(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
          shadowColor: const Color(0xFF10B981).withValues(alpha: 0.3),
        ),
        child: const Text(
          'Payer cotisation',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade300,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showingPayments = true;
                  });
                },
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _showingPayments ? const Color(0xFF4F46E5) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 16,
                        color: _showingPayments ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Payés',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _showingPayments ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _showingPayments = false;
                  });
                },
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: !_showingPayments ? const Color(0xFFEF4444) : Colors.transparent,
                    borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 16,
                        color: !_showingPayments ? Colors.white : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Retards',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: !_showingPayments ? Colors.white : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _getPaymentItems() {
    return _showingPayments ? [
      _buildPaymentItem(
        'Cotisation Mensuelle Novembre',
        '26 octobre 2025 à 20:43',
        '5.000F',
        true,
        false,
        paymentMethod: 'Code QR',
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Octobre',
        '26 octobre 2025 à 20:27',
        '5.000F',
        true,
        false,
        paymentMethod: 'Preuve',
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Septembre',
        '24 octobre 2025 à 11:08',
        '5.000F',
        true,
        false,
        paymentMethod: 'Code QR',
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Août',
        '15 août 2025 à 14:30',
        '5.000F',
        true,
        false,
        paymentMethod: 'Preuve',
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Juillet',
        '10 juillet 2025 à 09:15',
        '5.000F',
        true,
        true, // isLast
        paymentMethod: 'Code QR',
      ),
    ] : [
      _buildPaymentItem(
        'Cotisation Mensuelle Juin',
        '30 juin 2025',
        '5.000F',
        false,
        false,
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Mai',
        '31 mai 2025',
        '5.000F',
        false,
        false,
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Avril',
        '30 avril 2025',
        '5.000F',
        false,
        false,
      ),
      _buildPaymentItem(
        'Cotisation Mensuelle Mars',
        '31 mars 2025',
        '5.000F',
        false,
        true, // isLast
      ),
    ];
  }

  Widget _buildPaymentItem(String title, String date, String amount, bool isPaid, bool isLast, {String? paymentMethod}) {
    // Fonction pour obtenir l'icône selon le type
    IconData getPaymentIcon() {
      return Icons.account_balance_wallet; // Icône de portefeuille pour cotisations
    }
    
    Widget buildContent() {
      return Container(
        decoration: BoxDecoration(
          border: isLast ? null : Border(
            bottom: BorderSide(
              color: Colors.grey.shade100,
              width: 1,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Section gauche : Icône + Info
              Expanded(
                child: Row(
                  children: [
                    // Icône de cotisation
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isPaid 
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isPaid 
                              ? const Color(0xFF10B981).withValues(alpha: 0.3)
                              : const Color(0xFFEF4444).withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        getPaymentIcon(),
                        color: isPaid ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    
                    // Informations du paiement
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
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isPaid ? date : 'Échéance: $date',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Section droite : Montant + Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$amount F',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isPaid 
                          ? const Color(0xFF10B981)
                          : const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isPaid ? '✓' : '!',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: isPaid 
        ? InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CotisationDetailPage(
                    cotisation: {
                      'title': title,
                      'date': date,
                      'amount': amount,
                      'isPaid': isPaid,
                      'paymentMethod': paymentMethod ?? 'Code QR',
                    },
                  ),
                ),
              );
            },
            child: buildContent(),
          )
        : buildContent(),
    );
  }

  void _showPaymentMethodModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            
            // Titre
            const Text(
              'Comment voulez-vous payer ?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Cotisation Mensuelle',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Montant : 10 000 FCFA',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 32),
            
            // Options
            Column(
              children: [
                // Option QR Code
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const QrPaiementPage(
                            cotisationTitle: 'Cotisation Mensuelle',
                            montant: 10000,
                            cotisationId: '1',
                          ),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF4F46E5),
                      side: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
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
                                'Afficher code QR',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'L\'admin scannera votre code',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF4F46E5),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Option Preuve de paiement
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PreuvePaiementPage(
                            cotisationTitle: 'Cotisation Mensuelle',
                            montant: 10000,
                            cotisationId: 1,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1F2937),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.all(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prouver un paiement',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Télécharger un reçu de paiement',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}