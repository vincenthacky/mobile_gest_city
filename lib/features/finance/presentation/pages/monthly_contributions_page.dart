import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/contribution_controller.dart';
import '../../../authentification/controller/auth_controller.dart';
import 'cotisation/widgets/widgets.dart';
import 'cotisation/widgets/unified_payment_items_widget.dart';

class MonthlyContributionsPage extends StatefulWidget {
  const MonthlyContributionsPage({super.key});

  @override
  State<MonthlyContributionsPage> createState() => _MonthlyContributionsPageState();
}

class _MonthlyContributionsPageState extends State<MonthlyContributionsPage> with TickerProviderStateMixin {
  
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
    _loadContributionData();
  }

  void _initializeAnimations() {
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

  void _loadContributionData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authController = context.read<AuthController>();
      final userId = authController.user?.id;
      final controller = context.read<ContributionController>();
      
      // ✅ Controller déjà initialisé dans bootstrap.dart
      // ✅ PUIS charger les données
      controller.loadContribution(userId: userId);
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
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedContent(),
                      _buildAnimatedPaymentItems(),
                      const SizedBox(height: 32),
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


  Widget _buildAnimatedContent() {
    return Padding(
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
                child: const CotisationCardWidget(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Bouton payer cotisation avec animation
          FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _createStaggeredAnimation(0.2),
              child: PaymentButtonWidget(
                onPressed: _showPaymentMethodModal,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAnimatedPaymentItems() {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: const UnifiedPaymentItemsWidget(),
          ),
        );
      },
    );
  }

  Animation<Offset> _createStaggeredAnimation(double intervalStart) {
    return Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Interval(intervalStart, 1.0, curve: Curves.easeOut),
    ));
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.lightImpact();
    await context.read<ContributionController>().refreshContribution();
    
    // Restart animations on refresh
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    
    await Future.delayed(const Duration(milliseconds: 800));
    
    _startAnimations();
    setState(() {});
  }


  void _showPaymentMethodModal() {
    final controller = context.read<ContributionController>();
    final data = controller.contributionData;
    
    if (data != null) {
      PaymentMethodModal.show(context, data);
    }
  }
}