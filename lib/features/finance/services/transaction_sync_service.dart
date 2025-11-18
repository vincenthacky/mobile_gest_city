import '../models/transaction_sync_models.dart';
import 'transaction_local_storage_service.dart';
import 'payment_sync_listener_service.dart';

class TransactionSyncService {
  /// Traite une réponse de synchronisation complète
  static Future<void> processFullSync(TransactionSyncResponse response) async {
    if (response.items == null || response.items!.isEmpty) {
      print('🔄 [TRANSACTION SYNC] Full sync: aucune transaction reçue');
      return;
    }

    final transactions = response.items!;
    
    // Sauvegarder toutes les transactions et leurs checksums
    await TransactionLocalStorageService.saveTransactions(transactions);
    await TransactionLocalStorageService.saveChecksums(
      transactions,
      response.globalChecksum ?? '',
    );

    print('🔄 [TRANSACTION SYNC] Full sync: ${transactions.length} transactions synchronisées');
    
    // Notifier les services esclaves qu'il y a eu des changements
    PaymentSyncListenerService.instance.notifyTransactionSync(true);
  }

  /// Traite une réponse de synchronisation différentielle
  static Future<void> processDifferentialSync(TransactionSyncResponse response) async {
    if (response.changes == null) {
      print('🔄 [TRANSACTION SYNC] Diff sync: aucun changement');
      return;
    }

    final changes = response.changes!;
    int totalChanges = 0;

    // Traiter les ajouts
    if (changes.added != null && changes.added!.isNotEmpty) {
      await TransactionLocalStorageService.addTransactions(changes.added!);
      totalChanges += changes.added!.length;
      print('➕ [TRANSACTION SYNC] ${changes.added!.length} transactions ajoutées');
    }

    // Traiter les mises à jour
    if (changes.updated != null && changes.updated!.isNotEmpty) {
      await TransactionLocalStorageService.updateTransactions(changes.updated!);
      totalChanges += changes.updated!.length;
      print('🔄 [TRANSACTION SYNC] ${changes.updated!.length} transactions mises à jour');
    }

    // Traiter les suppressions
    if (changes.deleted != null && changes.deleted!.isNotEmpty) {
      await TransactionLocalStorageService.deleteTransactions(changes.deleted!);
      totalChanges += changes.deleted!.length;
      print('❌ [TRANSACTION SYNC] ${changes.deleted!.length} transactions supprimées');
    }

    print('🔄 [TRANSACTION SYNC] Diff sync: $totalChanges changements traités');
    
    // Notifier les services esclaves seulement s'il y a eu des changements
    if (totalChanges > 0) {
      PaymentSyncListenerService.instance.notifyTransactionSync(true);
    } else {
      PaymentSyncListenerService.instance.notifyTransactionSync(false);
    }
  }

  /// Crée une requête de synchronisation basée sur le cache local
  static TransactionSyncRequest createSyncRequest({
    TransactionSyncFilters? filters,
    bool isInitializing = false,
  }) {
    final checksums = TransactionLocalStorageService.getAllChecksums();
    
    if (checksums.isEmpty || isInitializing) {
      return TransactionSyncRequest(
        isInitializing: true,
        filters: filters,
      );
    }

    final globalChecksum = TransactionLocalStorageService.calculateGlobalChecksum(checksums);
    final itemsChecksums = checksums.map((c) => c.toJson()).toList();

    return TransactionSyncRequest(
      isInitializing: false,
      globalChecksum: globalChecksum,
      itemsChecksums: itemsChecksums,
      filters: filters,
    );
  }

  /// Détermine le type de synchronisation nécessaire
  static String determineSyncType({
    bool forceFullSync = false,
    bool hasLocalData = true,
  }) {
    if (forceFullSync || !hasLocalData) {
      return 'full';
    }
    return 'differential';
  }

  /// Valide la cohérence des données après synchronisation
  static bool validateSyncIntegrity(TransactionSyncResponse response) {
    try {
      // Vérifier que la réponse est valide
      if (response.syncType.isEmpty) {
        print('❌ [TRANSACTION SYNC] Type de sync manquant');
        return false;
      }

      // Pour les sync complètes, vérifier les items
      if (response.isFullSync) {
        if (response.items == null) {
          print('❌ [TRANSACTION SYNC] Items manquants pour full sync');
          return false;
        }
        
        // Vérifier que chaque transaction a un ID et un checksum
        for (final item in response.items!) {
          if (item['id'] == null || item['checksum'] == null) {
            print('❌ [TRANSACTION SYNC] Transaction avec ID ou checksum manquant');
            return false;
          }
        }
      }

      // Pour les sync différentielles, vérifier les changements
      if (response.syncType == 'differential') {
        if (response.changes != null) {
          final changes = response.changes!;
          
          // Vérifier les ajouts
          if (changes.added != null) {
            for (final item in changes.added!) {
              if (item['id'] == null || item['checksum'] == null) {
                print('❌ [TRANSACTION SYNC] Transaction ajoutée avec ID ou checksum manquant');
                return false;
              }
            }
          }

          // Vérifier les mises à jour
          if (changes.updated != null) {
            for (final item in changes.updated!) {
              if (item['id'] == null || item['checksum'] == null) {
                print('❌ [TRANSACTION SYNC] Transaction mise à jour avec ID ou checksum manquant');
                return false;
              }
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('❌ [TRANSACTION SYNC] Erreur lors de la validation: $e');
      return false;
    }
  }

  /// Nettoie les données obsolètes
  static Future<void> cleanupObsoleteData({int maxAge = 30}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: maxAge));
      final checksums = TransactionLocalStorageService.getAllChecksums();
      
      final obsoleteIds = checksums
          .where((c) => c.lastUpdated.isBefore(cutoffDate))
          .map((c) => c.transactionId)
          .toList();

      if (obsoleteIds.isNotEmpty) {
        await TransactionLocalStorageService.deleteTransactions(obsoleteIds);
        print('🧹 [TRANSACTION SYNC] ${obsoleteIds.length} transactions obsolètes supprimées');
      }
    } catch (e) {
      print('❌ [TRANSACTION SYNC] Erreur lors du nettoyage: $e');
    }
  }

  /// Obtient un résumé des statistiques de synchronisation
  static Map<String, dynamic> getSyncSummary() {
    final cacheStats = TransactionLocalStorageService.getCacheStats();
    final checksums = TransactionLocalStorageService.getAllChecksums();
    
    return {
      'total_transactions': cacheStats['transactions_count'],
      'total_checksums': cacheStats['checksums_count'],
      'global_checksum': checksums.isNotEmpty 
          ? TransactionLocalStorageService.calculateGlobalChecksum(checksums)
          : null,
      'last_sync': cacheStats['last_updated'],
      'is_cache_healthy': cacheStats['transactions_count'] == cacheStats['checksums_count'],
    };
  }
}