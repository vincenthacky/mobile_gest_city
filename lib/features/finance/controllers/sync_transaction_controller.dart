import 'package:flutter/material.dart';
import '../../../core/widgets/sync_notification.dart';
import '../data_sources/transaction_data_source.dart';
import '../models/transaction_sync_models.dart';
import '../services/transaction_local_storage_service.dart';
import '../services/transaction_sync_service.dart';
import '../services/finance_totals_local_storage_service.dart';
import '../data_source/cash_totals_data_source.dart';
enum TransactionSyncStatus { idle, syncing, success, error }

class SyncTransactionController extends ChangeNotifier {
  final TransactionDataSource _dataSource = TransactionDataSource();
  final CashTotalsDataSource _totalsDataSource = CashTotalsDataSource();
  
  // États de synchronisation
  TransactionSyncStatus _syncStatus = TransactionSyncStatus.idle;
  String? _syncErrorMessage;
  String? _syncSuccessMessage;

  // Notifications
  SyncNotificationType _notificationType = SyncNotificationType.none;
  String? _notificationMessage;

  // Données
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _transactions = [];
  
  // Filtres
  TransactionSyncFilters? _currentFilters;

  // Getters
  TransactionSyncStatus get syncStatus => _syncStatus;
  String? get syncErrorMessage => _syncErrorMessage;
  String? get syncSuccessMessage => _syncSuccessMessage;
  
  SyncNotificationType get notificationType => _notificationType;
  String? get notificationMessage => _notificationMessage;
  
  List<Map<String, dynamic>> get allTransactions => _allTransactions;
  List<Map<String, dynamic>> get transactions => _transactions;
  TransactionSyncFilters? get currentFilters => _currentFilters;
  
  bool get isLoading => _syncStatus == TransactionSyncStatus.syncing;
  bool get hasError => _syncStatus == TransactionSyncStatus.error;

  /// Initialise le controller
  Future<void> initialize() async {
    await _loadFromCache();
  }

  /// Charge les données depuis le cache local
  Future<void> _loadFromCache() async {
    try {
      _allTransactions = TransactionLocalStorageService.getAllTransactions();
      _applyFilters();
      notifyListeners();
      print('📱 [SYNC TRANSACTION] ${_allTransactions.length} transactions chargées du cache');
    } catch (e) {
      print('❌ [SYNC TRANSACTION] Erreur lors du chargement du cache: $e');
    }
  }

  /// Synchronise les transactions avec logique conditionnelle pour le solde
  Future<void> syncTransactions({
    bool showNotifications = true,
    bool forceFullSync = false,
    TransactionSyncFilters? filters,
  }) async {
    if (_syncStatus == TransactionSyncStatus.syncing) return;

    _changeSyncStatus(TransactionSyncStatus.syncing);
    
    if (showNotifications) {
      _showNotification(SyncNotificationType.syncing, 'Synchronisation des transactions...');
    }

    try {
      // 1. Détecter si c'est vraiment un premier lancement (cache complètement vide)
      final checksums = TransactionLocalStorageService.getAllChecksums();
      final isFirstLaunch = checksums.isEmpty && _allTransactions.isEmpty;
      
      debugPrint('🔍 [SYNC TRANSACTION] Détection: checksums=${checksums.length}, transactions=${_allTransactions.length}, isFirstLaunch=$isFirstLaunch, forceFullSync=$forceFullSync');
      
      // 2. Préparer la requête de synchronisation
      final request = TransactionSyncService.createSyncRequest(
        filters: filters ?? _currentFilters,
        isInitializing: forceFullSync || isFirstLaunch,
      );

      debugPrint('🔄 [SYNC TRANSACTION] Début de la synchronisation (isInitializing=${forceFullSync || isFirstLaunch})');

      // 2. Appeler l'API de synchronisation des transactions
      final response = await _dataSource.syncTransactions(request);

      // 3. Valider l'intégrité
      if (!TransactionSyncService.validateSyncIntegrity(response)) {
        throw Exception('Données de synchronisation invalides');
      }

      // 4. Traiter la réponse selon le type
      bool hasChanges = false;
      if (response.isFullSync) {
        await TransactionSyncService.processFullSync(response);
        hasChanges = response.items?.isNotEmpty ?? false;
      } else {
        await TransactionSyncService.processDifferentialSync(response);
        hasChanges = response.hasChanges;
      }

      // 5. LOGIQUE CONDITIONNELLE POUR LE SOLDE
      if (hasChanges) {
        print('💰 [SYNC TRANSACTION] Changements détectés → mise à jour du solde');
        
        // Recharger les transactions depuis le cache
        await _loadFromCache();
        
        // Déclencher la mise à jour du solde
        await _updateFinancialSummary();
        
        if (showNotifications) {
          final stats = response.stats;
          final message = _buildSyncSuccessMessage(stats, hasChanges: true);
          _showNotification(SyncNotificationType.syncComplete, message);
        }
      } else {
        // Pas de changements → pas de mise à jour du solde
        print('📊 [SYNC TRANSACTION] Aucun changement → solde non mis à jour');
        
        if (showNotifications) {
          _showNotification(SyncNotificationType.upToDate, 'Transactions à jour');
        }
      }

      _changeSyncStatus(TransactionSyncStatus.success);
      _syncSuccessMessage = 'Synchronisation réussie';

    } catch (e) {
      print('❌ [SYNC TRANSACTION] Erreur: $e');
      _changeSyncStatus(TransactionSyncStatus.error);
      _syncErrorMessage = e.toString();

      if (showNotifications) {
        _showNotification(SyncNotificationType.offline, 'Erreur de synchronisation');
      }
    }
  }

  /// Met à jour le résumé financier (solde, recettes, dépenses)
  Future<void> _updateFinancialSummary() async {
    try {
      print('💰 [FINANCE] Mise à jour du résumé financier...');
      
      // Récupérer les totaux financiers depuis l'API
      final response = await _totalsDataSource.getCashTotals();
      
      if (response.success) {
        // Sauvegarder les nouveaux totaux en cache local
        await FinanceTotalsLocalStorageService.saveTotals(response.data.totals);
        
        print('✅ [FINANCE] Résumé financier mis à jour et sauvegardé en cache: Solde=${response.data.totals.balance}, Recettes=${response.data.totals.totalReceipts}, Dépenses=${response.data.totals.totalExpenses}');
      } else {
        print('❌ [FINANCE] Erreur API lors de la mise à jour du résumé: ${response.message}');
      }
    } catch (e) {
      print('❌ [FINANCE] Erreur lors de la mise à jour du résumé: $e');
      // Ne pas faire échouer la sync des transactions pour une erreur de solde
    }
  }

  /// Construit le message de succès de synchronisation
  String _buildSyncSuccessMessage(TransactionSyncStats? stats, {bool hasChanges = false}) {
    if (stats == null || !hasChanges) {
      return 'Transactions à jour';
    }

    final parts = <String>[];
    if (stats.addedCount > 0) parts.add('${stats.addedCount} ajoutée(s)');
    if (stats.updatedCount > 0) parts.add('${stats.updatedCount} mise(s) à jour');
    if (stats.deletedCount > 0) parts.add('${stats.deletedCount} supprimée(s)');

    if (parts.isEmpty) return 'Transactions synchronisées';
    return 'Transactions: ${parts.join(', ')}';
  }

  /// Applique les filtres aux transactions
  void _applyFilters() {
    if (_currentFilters == null || _currentFilters!.isEmpty) {
      _transactions = List.from(_allTransactions);
    } else {
      _transactions = _allTransactions.where((transaction) {
        // Filtre par statut
        if (_currentFilters!.status != null && 
            transaction['status']?.toString() != _currentFilters!.status) {
          return false;
        }
        
        // Filtre par type
        if (_currentFilters!.kind != null && 
            transaction['kind'] != _currentFilters!.kind) {
          return false;
        }
        
        // Filtre par méthode de paiement
        if (_currentFilters!.method != null && 
            transaction['method'] != _currentFilters!.method) {
          return false;
        }

        return true;
      }).toList();
    }
  }

  /// Applique un filtre spécifique
  Future<void> applyFilters(TransactionSyncFilters? filters) async {
    _currentFilters = filters;
    _applyFilters();
    notifyListeners();
  }

  /// Change le statut de synchronisation
  void _changeSyncStatus(TransactionSyncStatus newStatus) {
    print('🔄 [SYNC TRANSACTION] Changement de statut: ${_syncStatus.name} → ${newStatus.name}');
    _syncStatus = newStatus;
    notifyListeners();
  }

  /// Affiche une notification
  void _showNotification(SyncNotificationType type, String message) {
    _notificationType = type;
    _notificationMessage = message;
    notifyListeners();
  }

  /// Efface les notifications
  void clearNotification() {
    _notificationType = SyncNotificationType.none;
    _notificationMessage = null;
    notifyListeners();
  }

  /// Affiche une notification hors ligne
  void showOfflineNotification() {
    _showNotification(
      SyncNotificationType.offline, 
      'Mode hors ligne - ${_allTransactions.length} transactions disponibles'
    );
  }

  /// Actualise les données
  Future<void> refresh() async {
    await syncTransactions(showNotifications: true, forceFullSync: true);
  }

  /// Nettoie le cache
  Future<void> clearCache() async {
    await TransactionLocalStorageService.clearCache();
    _allTransactions.clear();
    _transactions.clear();
    _currentFilters = null;
    notifyListeners();
  }

  /// Obtient les statistiques de synchronisation
  Map<String, dynamic> getSyncStats() {
    return TransactionSyncService.getSyncSummary();
  }

}