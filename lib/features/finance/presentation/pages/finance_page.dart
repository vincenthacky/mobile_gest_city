import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        title: const Text(
          'Finance',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1F2937),
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              _financeController.refreshAll();
            },
            icon: const Icon(
              Icons.refresh,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(12),
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
              indicatorPadding: const EdgeInsets.all(6),
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                fontFamily: 'Poppins',
              ),
              tabs: const [
                Tab(
                  icon: Icon(Icons.account_balance_wallet, size: 18),
                  text: 'Portefeuille',
                ),
                Tab(
                  icon: Icon(Icons.pie_chart, size: 18),
                  text: 'Ventilation',
                ),
                Tab(
                  icon: Icon(Icons.calendar_month, size: 18),
                  text: 'Cotisations',
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