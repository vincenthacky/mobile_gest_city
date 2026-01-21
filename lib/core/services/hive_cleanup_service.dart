import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Services de stockage local de tous les modules
import '../../features/finance/services/transaction_local_storage_service.dart';
import '../../features/finance/services/finance_totals_local_storage_service.dart';
import '../../features/finance/services/payment_statistics_local_storage_service.dart';
import '../../features/finance/services/contribution_local_storage_service.dart';
import '../../features/finance/services/cash_movements_local_storage_service.dart';
import '../../features/finance/services/payment_overview_local_storage_service.dart';
import '../../features/cadre_de_vie/services/information_local_storage_service.dart';
import '../../features/admin/services/admin_payments_local_storage_service.dart';
import '../../features/projets/services/local_storage_service.dart';
import '../../features/signalement/services/report_local_storage_service.dart';
import 'member_overview_local_storage_service.dart';

/// Service central pour nettoyer toutes les données Hive locales
/// Utilisé lors de la déconnexion pour éviter la pollution des données
/// entre différents comptes utilisateur
class HiveCleanupService {
  
  /// Nettoie toutes les données Hive de tous les modules
  /// ✅ Garantit un environnement propre pour la prochaine connexion
  static Future<void> clearAllLocalData() async {
    debugPrint('🧹 [CLEANUP] Début du nettoyage TOTAL de toutes les données Hive...');
    
    try {
      // ÉTAPE 1: Fermer proprement tous les services et leurs boxes
      debugPrint('🔒 [CLEANUP] Fermeture de tous les services de stockage...');
      await _closeAllServices();
      
      // ÉTAPE 2: Nettoyer via les services (méthode sûre)
      final List<Future<void>> cleanupTasks = [];
      
      // 1. Module Finance - Transactions
      cleanupTasks.add(_cleanupWithLog(
        'Transactions Finance',
        () => TransactionLocalStorageService.clearCache(),
      ));
      
      // 2. Module Finance - Totaux
      cleanupTasks.add(_cleanupWithLog(
        'Totaux Finance', 
        () => FinanceTotalsLocalStorageService.clearCachedTotals(),
      ));
      
      // 3. Module Finance - Statistiques paiements
      cleanupTasks.add(_cleanupWithLog(
        'Statistiques Paiements',
        () => PaymentStatisticsLocalStorageService.clearCache(),
      ));
      
      // 4. Module Finance - Contributions
      cleanupTasks.add(_cleanupWithLog(
        'Contributions',
        () => ContributionLocalStorageService.clearAllCaches(),
      ));
      
      // 5. Module Finance - Mouvements de caisse
      cleanupTasks.add(_cleanupWithLog(
        'Mouvements Caisse',
        () => CashMovementsLocalStorageService.clearAllCache(),
      ));
      
      // 6. Module Finance - Vue d'ensemble paiements
      cleanupTasks.add(_cleanupWithLog(
        'Vue Paiements',
        () => PaymentOverviewLocalStorageService.clearCache(),
      ));
      
      // 7. Module Cadre de Vie - Informations
      cleanupTasks.add(_cleanupWithLog(
        'Informations Cadre de Vie - Checksums',
        () => InformationLocalStorageService.clearAllChecksums(),
      ));
      
      cleanupTasks.add(_cleanupWithLog(
        'Informations Cadre de Vie - Cache',
        () => InformationLocalStorageService.clearCachedInformations(),
      ));
      
      // 8. Module Admin - Paiements admin
      cleanupTasks.add(_cleanupWithLog(
        'Paiements Admin',
        () => AdminPaymentsLocalStorageService.clearCache(),
      ));
      
      // 9. Module Projets
      cleanupTasks.add(_cleanupWithLog(
        'Projets',
        () => LocalStorageService.clearAllProjectData(),
      ));
      
      // 10. Module Signalement
      cleanupTasks.add(_cleanupWithLog(
        'Signalements - Checksums',
        () => ReportLocalStorageService.clearAllChecksums(),
      ));
      
      cleanupTasks.add(_cleanupWithLog(
        'Signalements - Cache',
        () => ReportLocalStorageService.clearCachedReports(),
      ));
      
      // 11. Module Core - Overview Member
      cleanupTasks.add(_cleanupWithLog(
        'Overview Member',
        () => MemberOverviewLocalStorageService.clearCache(),
      ));
      
      // Exécuter tous les nettoyages en parallèle pour optimiser les performances
      await Future.wait(cleanupTasks);
      
      // ÉTAPE 3: Nettoyage agressif - supprimer physiquement toutes les boxes Hive
      debugPrint('💥 [CLEANUP] Suppression physique de toutes les boxes Hive...');
      await _deleteAllHiveBoxes();
      
      debugPrint('✅ [CLEANUP] Nettoyage COMPLET de toutes les données Hive terminé avec succès');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [CLEANUP] Erreur durant le nettoyage des données Hive: $e');
      debugPrint('📍 [CLEANUP] StackTrace: $stackTrace');
      
      // En cas d'erreur, tenter un nettoyage d'urgence
      debugPrint('🚨 [CLEANUP] Tentative de nettoyage d\'urgence...');
      try {
        await _emergencyCleanup();
      } catch (emergencyError) {
        debugPrint('💀 [CLEANUP] Échec du nettoyage d\'urgence: $emergencyError');
      }
    }
  }
  
  /// Exécute une tâche de nettoyage avec logging détaillé
  static Future<void> _cleanupWithLog(String moduleName, Future<void> Function() cleanupTask) async {
    try {
      debugPrint('🔄 [CLEANUP] Nettoyage: $moduleName...');
      await cleanupTask();
      debugPrint('✅ [CLEANUP] $moduleName nettoyé avec succès');
    } catch (e) {
      debugPrint('⚠️ [CLEANUP] Erreur lors du nettoyage de $moduleName: $e');
      // Continuer même si un module échoue
    }
  }
  
  /// Nettoie uniquement les données d'un module spécifique
  /// Utile pour le développement et les tests
  static Future<void> clearModuleData(String moduleName) async {
    debugPrint('🧹 [CLEANUP] Nettoyage du module: $moduleName');
    
    switch (moduleName.toLowerCase()) {
      case 'finance':
        await _cleanupFinanceModule();
        break;
      case 'projets':
        await LocalStorageService.clearAllProjectData();
        break;
      case 'signalement':
        await ReportLocalStorageService.clearAllChecksums();
        await ReportLocalStorageService.clearCachedReports();
        break;
      case 'cadre_de_vie':
        await InformationLocalStorageService.clearAllChecksums();
        await InformationLocalStorageService.clearCachedInformations();
        break;
      case 'admin':
        await AdminPaymentsLocalStorageService.clearCache();
        break;
      default:
        debugPrint('⚠️ [CLEANUP] Module non reconnu: $moduleName');
    }
  }
  
  /// Nettoie tous les services du module Finance
  static Future<void> _cleanupFinanceModule() async {
    await Future.wait([
      TransactionLocalStorageService.clearCache(),
      FinanceTotalsLocalStorageService.clearCachedTotals(),
      PaymentStatisticsLocalStorageService.clearCache(),
      ContributionLocalStorageService.clearAllCaches(),
      CashMovementsLocalStorageService.clearAllCache(),
      PaymentOverviewLocalStorageService.clearCache(),
    ]);
  }
  
  /// Obtient les statistiques de stockage de tous les modules
  /// Utile pour le debugging et la maintenance
  static Future<Map<String, dynamic>> getStorageStats() async {
    final stats = <String, dynamic>{};
    
    try {
      // Collecter les stats de chaque module si les méthodes existent
      // Note: Toutes les méthodes getStorageStats ne sont pas implémentées partout
      
      stats['finance_transactions'] = 'N/A';
      stats['finance_totals'] = 'N/A'; 
      stats['contributions'] = 'N/A';
      stats['cash_movements'] = 'N/A';
      stats['cadre_de_vie'] = 'N/A';
      stats['admin_payments'] = 'N/A';
      stats['projets'] = 'N/A';
      
      // Modules avec stats disponibles
      try {
        stats['signalement'] = await ReportLocalStorageService.getStorageStats();
      } catch (e) {
        stats['signalement'] = 'Error: $e';
      }
      
      debugPrint('📊 [CLEANUP] Statistiques de stockage collectées');
      
    } catch (e) {
      debugPrint('❌ [CLEANUP] Erreur lors de la collecte des statistiques: $e');
    }
    
    return stats;
  }

  /// Ferme proprement tous les services de stockage et leurs boxes
  static Future<void> _closeAllServices() async {
    final List<Future<void>> closeTasks = [];

    try {
      // Fermer tous les services qui ont une méthode close
      closeTasks.add(_closeServiceSafely('Report Storage', () => ReportLocalStorageService.close()));
      closeTasks.add(_closeServiceSafely('Information Storage', () => InformationLocalStorageService.close()));
      closeTasks.add(_closeServiceSafely('Finance Totals Storage', () => FinanceTotalsLocalStorageService.close()));
      closeTasks.add(_closeServiceSafely('Project Storage', () => LocalStorageService.close()));
      closeTasks.add(_closeServiceSafely('Overview Member Storage', () => MemberOverviewLocalStorageService.close()));
      closeTasks.add(_closeServiceSafely('Transaction Storage', () => TransactionLocalStorageService.close()));

      await Future.wait(closeTasks);
      debugPrint('✅ [CLEANUP] Tous les services fermés avec succès');

    } catch (e) {
      debugPrint('⚠️ [CLEANUP] Erreur lors de la fermeture des services: $e');
    }
  }

  /// Ferme un service de stockage de manière sécurisée
  static Future<void> _closeServiceSafely(String serviceName, Future<void> Function() closeTask) async {
    try {
      await closeTask();
      debugPrint('✅ [CLEANUP] $serviceName fermé');
    } catch (e) {
      debugPrint('⚠️ [CLEANUP] Erreur fermeture $serviceName: $e');
    }
  }

  /// Supprime physiquement toutes les boxes Hive connues
  static Future<void> _deleteAllHiveBoxes() async {
    final List<String> knownBoxes = [
      // Finance
      'transaction_checksums',
      'cached_transactions', 
      'finance_totals',
      'payment_statistics',
      'contribution_checksums',
      'cached_contributions',
      'cash_movements_checksums',
      'cached_cash_movements', 
      'payment_overview',
      
      // Cadre de vie
      'information_checksums',
      'cached_informations',
      
      // Admin
      'admin_payments',
      
      // Projets
      'project_checksums',
      'cached_projects',
      
      // Signalements
      'report_checksums',
      'cached_reports',
      
      // Core - Overview Member
      'member_overview_cache',
    ];
    
    int deletedCount = 0;
    for (final boxName in knownBoxes) {
      try {
        await Hive.deleteBoxFromDisk(boxName);
        deletedCount++;
        debugPrint('🗑️ [CLEANUP] Box supprimée: $boxName');
      } catch (e) {
        debugPrint('⚠️ [CLEANUP] Impossible de supprimer la box $boxName: $e');
      }
    }
    
    debugPrint('💥 [CLEANUP] $deletedCount/${knownBoxes.length} boxes supprimées physiquement');
  }

  /// Nettoyage d'urgence en cas d'échec du nettoyage principal
  static Future<void> _emergencyCleanup() async {
    debugPrint('🚨 [EMERGENCY-CLEANUP] Début du nettoyage d\'urgence...');
    
    try {
      // Fermer toutes les boxes ouvertes de force
      await Hive.close();
      debugPrint('🔒 [EMERGENCY-CLEANUP] Toutes les boxes Hive fermées de force');
      
      // Tenter de supprimer toutes les boxes connues
      await _deleteAllHiveBoxes();
      
      debugPrint('✅ [EMERGENCY-CLEANUP] Nettoyage d\'urgence terminé');
      
    } catch (e) {
      debugPrint('💀 [EMERGENCY-CLEANUP] Échec critique: $e');
      rethrow;
    }
  }
  
  /// Force la réinitialisation complète de Hive après des changements d'adapters
  /// Résout les problèmes "Box has already been closed"
  static Future<void> forceHiveReinitialization() async {
    debugPrint('🔄 [FORCE-REINIT] Début de la réinitialisation forcée de Hive...');
    
    try {
      // ÉTAPE 1: Fermer tout Hive
      await Hive.close();
      debugPrint('🔒 [FORCE-REINIT] Hive fermé complètement');
      
      // ÉTAPE 2: Supprimer toutes les données
      await Hive.deleteFromDisk();
      debugPrint('🗑️ [FORCE-REINIT] Toutes les données Hive supprimées');
      
      // ÉTAPE 3: Forcer une pause pour laisser le système nettoyer
      await Future.delayed(Duration(milliseconds: 500));
      
      // ÉTAPE 4: Réinitialiser Hive
      await Hive.initFlutter();
      debugPrint('🆕 [FORCE-REINIT] Hive réinitialisé');
      
      debugPrint('✅ [FORCE-REINIT] Réinitialisation forcée terminée - Redémarrez l\'application');
      
    } catch (e) {
      debugPrint('❌ [FORCE-REINIT] Erreur lors de la réinitialisation: $e');
      rethrow;
    }
  }
}