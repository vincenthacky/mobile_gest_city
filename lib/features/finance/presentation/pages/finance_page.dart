import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/finance_controller.dart';
import 'wallet_page.dart';
import 'payment_breakdown_page.dart';
import 'monthly_contributions_page.dart';

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> with TickerProviderStateMixin {
  late TabController _tabController;
  late FinanceController _financeController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _financeController = Provider.of<FinanceController>(context, listen: false);
    
    // Charger toutes les données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _financeController.refreshAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Bouton Compte à gauche
            TextButton.icon(
              onPressed: () => context.go('/compte'),
              icon: const Icon(
                Icons.account_circle_outlined,
                color: Color(0xFF4F46E5),
                size: 20,
              ),
              label: const Text(
                'Compte',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4F46E5),
                  fontFamily: 'Poppins',
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            
            // Titre Finance centré
            Expanded(
              child: Center(
                child: const Text(
                  'Finance',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            
            // Bouton notification à droite
            IconButton(
              onPressed: () {
                // TODO: Navigation vers les notifications
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifications - Fonctionnalité à venir'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(
                Icons.notifications_outlined,
                color: Color(0xFF6B7280),
                size: 24,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(40),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3B82F6),
                    Color(0xFF1D4ED8),
                  ],
                ),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorPadding: const EdgeInsets.all(4),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 16),
                      const SizedBox(width: 4),
                      Text('Portefeuille', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pie_chart, size: 16),
                      const SizedBox(width: 4),
                      Text('Ventilation', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.calendar_month, size: 16),
                      const SizedBox(width: 4),
                      Text('Cotisations', style: TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          WalletPage(),
          PaymentBreakdownPage(),
          MonthlyContributionsPage(),
        ],
      ),
    );
  }
}