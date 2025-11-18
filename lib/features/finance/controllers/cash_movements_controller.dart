import 'package:flutter/material.dart';
import 'dart:async';
import '../data_source/cash_movements_data_source.dart';
import '../data_source/cash_totals_data_source.dart';
import '../models/cash_movement_model.dart';
import '../models/cash_movements_response_model.dart';
import '../models/cash_totals_model.dart';
import '../services/finance_totals_local_storage_service.dart';
import '../services/cash_movements_local_storage_service.dart';
import '../services/payment_sync_listener_service.dart';
import '../../../core/services/connectivity_service.dart';

enum CashMovementsStatus { initial, loading, loaded, error }

class CashMovementsController extends ChangeNotifier {
  final CashMovementsDataSource _dataSource = CashMovementsDataSource();
  final CashTotalsDataSource _totalsDataSource = CashTotalsDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();
  
  CashMovementsStatus _status = CashMovementsStatus.initial;
  List<CashMovement> _cashMovements = [];
  CashTotals? _cashTotals;
  Pagination? _pagination;
  String? _errorMessage;

  // Subscription pour écouter les changements de Transaction sync
  StreamSubscription<bool>? _syncSubscription;

  CashMovementsStatus get status => _status;
  List<CashMovement> get cashMovements => _cashMovements;
  CashTotals? get cashTotals => _cashTotals;
  Pagination? get pagination => _pagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == CashMovementsStatus.loading;
  bool get hasData => _cashMovements.isNotEmpty;

  // Initialise le controller et configure l'écoute de sync
  void initialize() {
    _setupSyncListener();
    CashMovementsLocalStorageService.initialize();
  }

  // Configure l'écoute des changements de Transaction sync
  void _setupSyncListener() {
    _syncSubscription = PaymentSyncListenerService.instance.paymentSyncTriggerStream.listen(
      (shouldSync) {
        if (shouldSync) {
          debugPrint('🔄 [CASH MOVEMENTS] Synchronisation déclenchée par Transaction sync');
          _syncCashMovementsData();
        }
      },
    );
  }

  // Synchronisation des mouvements de caisse (déclenchée par Transaction sync)
  Future<void> _syncCashMovementsData() async {
    if (!_connectivityService.isConnected) {
      debugPrint('📱 [CASH MOVEMENTS] Pas de connexion, pas de sync');
      return;
    }

    try {
      debugPrint('🔄 [CASH MOVEMENTS] Début synchronisation...');
      
      // Synchroniser les mouvements sans pagination (première page)
      final response = await _dataSource.getCashMovements(page: 1, perPage: 50);
      if (response.success) {
        _cashMovements = response.data.cashMovements;
        _pagination = response.pagination;
        
        // Sauvegarder en cache
        await CashMovementsLocalStorageService.saveCashMovements(
          _cashMovements, _pagination
        );
        debugPrint('✅ [CASH MOVEMENTS] Mouvements synchronisés');
      }

      // Synchroniser les totaux
      await loadCashTotals(forceFromCache: false);
      
      notifyListeners();
      debugPrint('✅ [CASH MOVEMENTS] Synchronisation terminée');
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS] Erreur synchronisation: $e');
    }
  }

  Future<void> loadCashMovements({
    String? filter,
    int page = 1,
    int perPage = 15,
  }) async {
    _setStatus(CashMovementsStatus.loading);
    _clearError();
    
    try {
      // TOUJOURS charger depuis le cache uniquement (affichage)
      final cachedData = CashMovementsLocalStorageService.getCashMovements(filter: filter);
      
      if (cachedData != null) {
        _cashMovements = cachedData.cashMovements;
        _pagination = cachedData.pagination;
        _setStatus(CashMovementsStatus.loaded);
        debugPrint('✅ [CASH MOVEMENTS] Données chargées depuis le cache');
      } else {
        // Données vides si pas de cache
        _cashMovements = [];
        _pagination = null;
        _setStatus(CashMovementsStatus.loaded);
        debugPrint('📱 [CASH MOVEMENTS] Pas de cache, données vides affichées');
      }
    } catch (e) {
      _setError(e.toString());
      _setStatus(CashMovementsStatus.error);
    }
  }

  Future<void> refreshCashMovements({String? filter}) async {
    await loadCashMovements(filter: filter);
  }

  Future<void> loadMoreCashMovements({String? filter}) async {
    if (_pagination?.currentPage != null && 
        _pagination!.currentPage < _pagination!.lastPage &&
        _connectivityService.isConnected) {
      
      try {
        final nextPage = _pagination!.currentPage + 1;
        final response = await _dataSource.getCashMovements(
          filter: filter,
          page: nextPage,
        );
        
        if (response.success) {
          _cashMovements.addAll(response.data.cashMovements);
          _pagination = response.pagination;
          
          // Mettre à jour le cache avec les nouveaux mouvements
          await CashMovementsLocalStorageService.addMoreCashMovements(
            response.data.cashMovements, _pagination, filter: filter
          );
          
          notifyListeners();
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement de plus de mouvements: $e');
      }
    }
  }

  void _setStatus(CashMovementsStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearData() {
    _cashMovements = [];
    _cashTotals = null;
    _pagination = null;
    _errorMessage = null;
    _status = CashMovementsStatus.initial;
    notifyListeners();
  }

  Future<void> loadCashTotals({bool forceFromCache = false}) async {
    try {
      final connectivityService = ConnectivityService();
      final isConnected = connectivityService.isConnected;
      
      // Si pas de connexion ou force cache, charger depuis le cache local
      if (!isConnected || forceFromCache) {
        final cachedTotals = await FinanceTotalsLocalStorageService.getCachedTotals();
        if (cachedTotals != null) {
          _cashTotals = cachedTotals;
          debugPrint('💾 [CACHE] Totaux chargés depuis le cache: Recettes=${_cashTotals!.totalReceipts}, Dépenses=${_cashTotals!.totalExpenses}, Solde=${_cashTotals!.balance}');
          notifyListeners();
          return;
        } else {
          debugPrint('📂 [CACHE] Aucun total en cache, impossible de charger hors ligne');
          _setError('Aucune donnée financière disponible hors ligne');
          return;
        }
      }
      
      // Si connecté, charger depuis l'API
      final response = await _totalsDataSource.getCashTotals();
      if (response.success) {
        _cashTotals = response.data.totals;
        
        // Sauvegarder en cache pour usage hors ligne
        await FinanceTotalsLocalStorageService.saveTotals(_cashTotals!);
        
        debugPrint('🌐 [API] Totaux chargés avec succès: Recettes=${_cashTotals!.totalReceipts}, Dépenses=${_cashTotals!.totalExpenses}, Solde=${_cashTotals!.balance}');
        notifyListeners();
      } else {
        debugPrint('❌ [API] Erreur lors du chargement des totaux: ${response.message}');
        
        // En cas d'erreur API, essayer de charger depuis le cache
        final cachedTotals = await FinanceTotalsLocalStorageService.getCachedTotals();
        if (cachedTotals != null) {
          _cashTotals = cachedTotals;
          debugPrint('💾 [FALLBACK] Totaux chargés depuis le cache après erreur API');
          notifyListeners();
        } else {
          _setError('Erreur lors du chargement des totaux: ${response.message}');
        }
      }
    } catch (e) {
      debugPrint('❌ [ERROR] Erreur lors du chargement des totaux: $e');
      
      // En cas d'erreur, essayer de charger depuis le cache
      final cachedTotals = await FinanceTotalsLocalStorageService.getCachedTotals();
      if (cachedTotals != null) {
        _cashTotals = cachedTotals;
        debugPrint('💾 [FALLBACK] Totaux chargés depuis le cache après erreur réseau');
        notifyListeners();
      } else {
        _setError('Erreur lors du chargement des totaux: $e');
      }
    }
  }

  // Getters pour les totaux
  double get totalRecettes {
    final value = _cashTotals?.totalReceipts.toDouble() ?? 0.0;
    debugPrint('Getter totalRecettes: $_cashTotals -> $value');
    return value;
  }
  
  double get totalDepenses {
    final value = _cashTotals?.totalExpenses.toDouble() ?? 0.0;
    debugPrint('Getter totalDepenses: $_cashTotals -> $value');
    return value;
  }
  
  double get soldeActuel {
    final value = _cashTotals?.balance.toDouble() ?? 0.0;
    debugPrint('Getter soldeActuel: $_cashTotals -> $value');
    return value;
  }

  // Filtres
  List<CashMovement> getFilteredMovements({
    String? typeFilter,
    DateTimeRange? dateRange,
  }) {
    List<CashMovement> filtered = List.from(_cashMovements);

    // Filtre par type
    if (typeFilter == 'Recettes') {
      filtered = filtered.where((t) => t.isCredit).toList();
    } else if (typeFilter == 'Dépenses') {
      filtered = filtered.where((t) => t.isDebit).toList();
    }

    // Filtre par date
    if (dateRange != null) {
      filtered = filtered.where((t) {
        return t.date.isAfter(dateRange.start.subtract(const Duration(days: 1))) &&
               t.date.isBefore(dateRange.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}