import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/widgets/app_header.dart';
import 'transaction_detail_page.dart';
import '../../data/datasource/cash_movements_data_source.dart';
import '../../data/models/cash_movement.dart';
import '../../data/models/cash_movements_response.dart';

class CaissePage extends StatefulWidget {
  const CaissePage({super.key});

  @override
  State<CaissePage> createState() => _CaissePageState();
}

class _CaissePageState extends State<CaissePage> with TickerProviderStateMixin {
  String _selectedFilter = 'Tous';
  DateTimeRange? _selectedDateRange;
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _filters = ['Tous', 'Recettes', 'Dépenses'];
  
  // Data source
  final CashMovementsDataSource _dataSource = CashMovementsDataSource();
  
  // State management
  bool _isLoading = true;
  String? _error;
  List<CashMovement> _cashMovements = [];
  Totals? _totals;


  List<CashMovement> get _filteredTransactions {
    List<CashMovement> filtered = _cashMovements;

    // Filtre par type
    if (_selectedFilter == 'Recettes') {
      filtered = filtered.where((t) => t.isCredit).toList();
    } else if (_selectedFilter == 'Dépenses') {
      filtered = filtered.where((t) => t.isDebit).toList();
    }

    // Filtre par date
    if (_selectedDateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(_selectedDateRange!.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  double get _totalRecettes {
    return _totals?.totalReceipts.toDouble() ?? 0.0;
  }

  double get _totalDepenses {
    return _totals?.totalExpenses.toDouble() ?? 0.0;
  }

  double get _soldeActuel {
    return _totals?.balance.toDouble() ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadCashMovements();
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

  Future<void> _loadCashMovements() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      String? apiFilter;
      if (_selectedFilter == 'Recettes') {
        apiFilter = 'recette';
      } else if (_selectedFilter == 'Dépenses') {
        apiFilter = 'depense';
      }

      final response = await _dataSource.getCashMovements(filter: apiFilter);
      
      if (mounted) {
        setState(() {
          _cashMovements = response.data.cashMovements;
          _totals = response.data.totals;
          _isLoading = false;
        });
        _startAnimations();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    
    await _loadCashMovements();
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFilter = filter;
    });
    _loadCashMovements();
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
                title: 'Caisse Commune',
              ),
            ),
            
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: _onRefresh,
                child: _isLoading
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      )
                    : _error != null
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    size: 64,
                                    color: Colors.grey.shade400,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Erreur de chargement',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _error!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loadCashMovements,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Réessayer'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : SingleChildScrollView(
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
                            // Card de résumé avec animations
                            SlideTransition(
                              position: _slideAnimation,
                              child: FadeTransition(
                                opacity: _fadeAnimation,
                                child: ScaleTransition(
                                  scale: _scaleAnimation,
                                  child: _buildSummaryCard(),
                                ),
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
                                  curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                                )),
                                child: _buildFiltersSection(),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                      
                      // Liste des transactions sans padding avec animation
                      Column(
                        children: _filteredTransactions.asMap().entries.map((entry) {
                          final index = entry.key;
                          final transaction = entry.value;
                          final isLast = index == _filteredTransactions.length - 1;
                          return TweenAnimationBuilder<double>(
                            duration: Duration(milliseconds: 600 + (index * 100)),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Transform.translate(
                                offset: Offset(0, 50 * (1 - value)),
                                child: Opacity(
                                  opacity: value,
                                  child: _buildTransactionItem(transaction, isLast),
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

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4F46E5),
            Color(0xFF7C3AED),
            Color(0xFF8B5CF6),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Solde Actuel',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_soldeActuel.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Color(0xFF10B981),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recettes',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_totalRecettes.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Color(0xFFEF4444),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dépenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_totalDepenses.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            InkWell(
              onTap: _showDatePicker,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: _selectedDateRange != null 
                      ? const Color(0xFF4F46E5).withValues(alpha: 0.1)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _selectedDateRange != null 
                        ? const Color(0xFF4F46E5)
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.date_range,
                      size: 16,
                      color: _selectedDateRange != null 
                          ? const Color(0xFF4F46E5)
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _selectedDateRange != null 
                          ? 'Filtré'
                          : 'Période',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _selectedDateRange != null 
                            ? const Color(0xFF4F46E5)
                            : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Filtres par type
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _filters.length,
            itemBuilder: (context, index) {
              final filter = _filters[index];
              final isSelected = _selectedFilter == filter;
              
              return Container(
                margin: EdgeInsets.only(right: index < _filters.length - 1 ? 12 : 0),
                child: InkWell(
                  onTap: () => _onFilterChanged(filter),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF4F46E5) 
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF4F46E5) 
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [
                        BoxShadow(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ] : [],
                    ),
                    child: Text(
                      filter,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected 
                            ? Colors.white 
                            : Colors.grey.shade700,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        
        // Bouton clear filters si filters actifs
        if (_selectedDateRange != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  _selectedDateRange = null;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.clear,
                      size: 16,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Effacer filtres',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTransactionItem(CashMovement transaction, bool isLast) {
    final isRecette = transaction.isCredit;
    final montant = transaction.amount;
    final type = transaction.typeDisplay;
    
    // Fonction pour obtenir l'icône selon le type de transaction
    IconData getTransactionIcon(String type) {
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
    
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailPage(
                transaction: transaction,
              ),
            ),
          );
        },
        child: Container(
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
                      // Icône adaptée au type de transaction
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isRecette 
                              ? const Color(0xFF10B981).withValues(alpha: 0.1)
                              : const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isRecette 
                                ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                : const Color(0xFFEF4444).withValues(alpha: 0.3),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          getTransactionIcon(type),
                          color: isRecette ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Informations de la transaction
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              transaction.typeDisplay,
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
                              '${transaction.methodDisplay} - ${transaction.statusDisplay}',
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
                      '${montant.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
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
                        color: isRecette 
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isRecette ? '+' : '-',
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
        ),
      ),
    );
  }

  void _showDatePicker() async {
    // Date picker implementation - simplified for this demo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sélecteur de date - à implémenter')),
    );
  }
}