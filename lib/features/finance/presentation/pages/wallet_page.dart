import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'caisse/transaction_detail_page.dart';
import '../../controllers/cash_movements_controller.dart';
import '../../controllers/sync_transaction_controller.dart';
import '../../models/cash_movement_model.dart';
import '../../../../core/widgets/sync_notification.dart';
import '../../../../core/services/connectivity_service.dart';

class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> with TickerProviderStateMixin {
  String _selectedView = 'Compte en T'; // 'Liste' ou 'Compte en T'
  bool _sortDescending = true; // true = plus récent d'abord, false = plus ancien d'abord
  String _selectedFilter = 'Tous'; // 'Tous', 'Débit', 'Crédit' - pour la vue Liste uniquement
  
  // Animation controllers
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  
  // Animations
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  // Controllers
  late SyncTransactionController _syncTransactionController;
  late ConnectivityService _connectivityService;

  final List<String> _viewTypes = ['Compte en T', 'Liste'];

  List<CashMovement> get _transactions {
    final controller = context.read<CashMovementsController>();
    List<CashMovement> transactions = List<CashMovement>.from(controller.cashMovements);
    
    // Appliquer le filtre seulement pour la vue Liste
    if (_selectedView == 'Liste') {
      switch (_selectedFilter) {
        case 'Débit':
          transactions = transactions.where((t) => t.isDebit).toList();
          break;
        case 'Crédit':
          transactions = transactions.where((t) => t.isCredit).toList();
          break;
        case 'Tous':
        default:
          // Garder toutes les transactions
          break;
      }
    }
    
    _sortTransactions(transactions);
    return transactions;
  }

  List<CashMovement> get _debits {
    final debits = _transactions.where((t) => t.isDebit).toList();
    _sortTransactions(debits);
    return debits;
  }

  List<CashMovement> get _credits {
    return _transactions.where((t) => t.isCredit).toList();
  }

  @override
  void initState() {
    super.initState();
    _syncTransactionController = Provider.of<SyncTransactionController>(context, listen: false);
    _connectivityService = ConnectivityService();
    
    _initializeAnimations();
    _setupConnectivityListener();
    
    // Démarrer le monitoring de connectivité
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _connectivityService.startMonitoring();
    });
    
    // Charger les données après que le widget soit complètement initialisé
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
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

  void _setupConnectivityListener() {
    _connectivityService.addListener(() {
      if (_connectivityService.isConnected) {
        // Quand la connexion revient, déclencher une synchronisation
        debugPrint('🌐 [FINANCE] Connexion détectée - synchronisation automatique');
        // Synchronisation avec notification
        _syncTransactionController.syncTransactions(showNotifications: true);
      } else {
        // Afficher notification hors ligne si on a des données en cache
        if (_syncTransactionController.allTransactions.isNotEmpty) {
          _syncTransactionController.showOfflineNotification();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final cashController = context.read<CashMovementsController>();

    // 1️⃣ Toujours afficher d'abord les données locales (offline-first)
    //    - Totaux (solde, recettes, dépenses) depuis le cache
    //    - Mouvements depuis le cache
    await cashController.loadCashTotals(forceFromCache: true);
    await cashController.loadCashMovements();

    if (mounted) {
      _startAnimations();
    }

    // 2️⃣ Ensuite seulement lancer la synchronisation en arrière-plan
    if (_connectivityService.isConnected) {
      // Lancer la sync sans attendre pour ne pas bloquer l'affichage
      _syncTransactionController.syncTransactions(
        showNotifications: true,
        forceFullSync: false,
      );
    } else {
      // Pas de connexion : si on a déjà des données, afficher la bannière hors ligne
      if (_syncTransactionController.allTransactions.isNotEmpty || cashController.hasData) {
        _syncTransactionController.showOfflineNotification();
      }
    }
  }

  Future<void> _loadCashMovements() async {
    // Charger tous les mouvements sans filtre
    await context.read<CashMovementsController>().loadCashMovements();
  }

  Future<void> _onRefresh() async {
    HapticFeedback.lightImpact();
    _fadeController.reset();
    _slideController.reset();
    _scaleController.reset();
    
    await _loadInitialData();
  }

  void _onViewChanged(String view) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedView = view;
    });
  }

  void _sortTransactions(List<CashMovement> transactions) {
    transactions.sort((a, b) {
      return _sortDescending ? b.date.compareTo(a.date) : a.date.compareTo(b.date);
    });
  }

  void _toggleSortOrder() {
    HapticFeedback.lightImpact();
    setState(() {
      _sortDescending = !_sortDescending;
    });
  }

  void _onFilterChanged(String filter) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedFilter = filter;
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _scaleController.dispose();
    _connectivityService.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Notification de synchronisation
            Consumer<SyncTransactionController>(
              builder: (context, syncController, child) {
                return SyncNotification(
                  type: syncController.notificationType,
                  customMessage: syncController.notificationMessage,
                  onDismiss: () => syncController.clearNotification(),
                );
              },
            ),
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF4F46E5),
                backgroundColor: Colors.white,
                strokeWidth: 2.5,
                onRefresh: _onRefresh,
                child: Consumer<CashMovementsController>(
                  builder: (context, controller, child) {
                    if (controller.isLoading) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(
                            color: Color(0xFF4F46E5),
                          ),
                        ),
                      );
                    }

                    if (controller.errorMessage != null) {
                      return Center(
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
                                controller.errorMessage!,
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
                      );
                    }

                    return SingleChildScrollView(
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
                                      child: _buildSummaryCard(controller),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
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
                                    child: _buildViewSelector(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          ),
                          
                          // Contenu selon la vue sélectionnée
                          _selectedView == 'Compte en T' 
                              ? _buildCompteEnT()
                              : _buildTransactionsList(),
                          
                          // Padding bottom pour le scroll
                          const SizedBox(height: 96),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(CashMovementsController controller) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Text(
                'Solde Actuel de la cite ',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              Consumer<SyncTransactionController>(
                builder: (context, syncController, child) {
                  if (syncController.lastSyncDateTime != null) {
                    final lastSync = syncController.lastSyncDateTime!;
                    final formattedDate = '${lastSync.day.toString().padLeft(2, '0')}/${lastSync.month.toString().padLeft(2, '0')}/${lastSync.year}';
                    final formattedTime = '${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}';
                    return Text(
                      '$formattedDate $formattedTime',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${controller.soldeActuel.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_upward,
                            color: Color(0xFF10B981),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recettes',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.totalRecettes.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                      style: const TextStyle(
                        fontSize: 16,
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
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Color(0xFFEF4444),
                            size: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Dépenses',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${controller.totalDepenses.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} F',
                      style: const TextStyle(
                        fontSize: 16,
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

  Widget _buildViewSelector() {
    return Column(
      children: [
        // Boutons de vue et tri
        SizedBox(
          height: 40,
          child: Row(
            children: [
              // Boutons de vue
              Row(
                children: _viewTypes.asMap().entries.map((entry) {
                  final index = entry.key;
                  final viewType = entry.value;
                  final isSelected = _selectedView == viewType;
              
                  return Container(
                    margin: EdgeInsets.only(right: index < _viewTypes.length - 1 ? 6 : 0),
                    child: InkWell(
                      onTap: () => _onViewChanged(viewType),
                      borderRadius: BorderRadius.circular(15),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                      child: Center(
                        child: Text(
                          viewType,
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
                  ),
                );
                }).toList(),
              ),
              const SizedBox(width: 6),
              // Bouton de tri
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF4F46E5),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: InkWell(
                  onTap: _toggleSortOrder,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Icon(
                      _sortDescending ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: const Color(0xFF4F46E5),
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Boutons de filtre pour la vue Liste uniquement
        if (_selectedView == 'Liste') ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFilterButton('Tous', Colors.grey.shade700),
              const SizedBox(width: 6),
              _buildFilterButton('Débit', const Color(0xFFEF4444)),
              const SizedBox(width: 6),
              _buildFilterButton('Crédit', const Color(0xFF10B981)),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildFilterButton(String filter, Color color) {
    final isSelected = _selectedFilter == filter;
    return InkWell(
      onTap: () => _onFilterChanged(filter),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          filter,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? color : color.withValues(alpha: 0.7),
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(CashMovement transaction, bool isLast) {
    final isRecette = transaction.isCredit;
    final montant = transaction.amount;
    
    // Fonction pour obtenir l'icône selon le type de transaction
    IconData getTransactionIcon(CashMovement transaction) {
      switch (transaction.kind) {
        case 'contribution_payment':
          return Icons.account_balance_wallet;
        case 'withdrawal':
          if (transaction.project != null) {
            return Icons.business;
          } else if (transaction.user != null) {
            return Icons.person;
          } else {
            return Icons.money_off;
          }
        case 'deposit':
          return Icons.add_circle;
        default:
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
                          getTransactionIcon(transaction),
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
                              transaction.description,
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

  Widget _buildTransactionsList() {
    return Column(
      children: _transactions.asMap().entries.map((entry) {
        final index = entry.key;
        final transaction = entry.value;
        final isLast = index == _transactions.length - 1;
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
    );
  }

  Widget _buildCompteEnT() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // En-tête du compte en T
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: Text(
                      'DÉBIT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFEF4444),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  height: 20,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'CRÉDIT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Ligne de séparation
          Container(
            height: 2,
            color: Colors.grey.shade300,
          ),
          
          // Contenu du compte en T
          Container(
            constraints: BoxConstraints(
              minHeight: 200,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Colonne Débits (gauche)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _debits.map((transaction) => _buildCompteEnTItem(transaction, true)).toList(),
                      ),
                    ),
                  ),
                  
                  // Séparateur vertical
                  Container(
                    width: 2,
                    color: Colors.grey.shade300,
                  ),
                  
                  // Colonne Crédits (droite)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _credits.map((transaction) => _buildCompteEnTItem(transaction, false)).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildCompteEnTItem(CashMovement transaction, bool isDebit) {
    final date = '${transaction.date.day.toString().padLeft(2, '0')}/${transaction.date.month.toString().padLeft(2, '0')}';
    final amount = transaction.amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), 
      (Match m) => '${m[1]} '
    );
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF374151),
            height: 1.3,
          ),
          children: [
            TextSpan(
              text: '$date  ',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
            TextSpan(
              text: '${transaction.description} - $amount FCFA',
              style: const TextStyle(
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}