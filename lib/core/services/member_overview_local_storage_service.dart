import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/member_overview_model.dart';

class MemberOverviewLocalStorageService {
  static const String _boxName = 'member_overview_cache';
  static const String _overviewKey = 'current_overview';
  static Box? _box;
  
  /// Initialise Hive et ouvre la box pour les données overview
  static Future<Box> get instance async {
    if (_box != null && _box!.isOpen) return _box!;
    
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    
    print('✅ [OVERVIEW] Box créée pour les données member overview');
    
    return _box!;
  }

  /// Ferme la base de données
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Sauvegarde les données overview en cache
  static Future<void> saveMemberOverview(MemberOverviewModel overview) async {
    final box = await instance;
    
    try {
      await box.put(_overviewKey, jsonEncode(overview.toJson()));
      print('✅ [OVERVIEW] Données overview sauvegardées en cache');
    } catch (e) {
      print('❌ [OVERVIEW] Erreur sauvegarde overview: $e');
      throw Exception('Erreur lors de la sauvegarde des données overview: $e');
    }
  }

  /// Récupère les données overview depuis le cache
  static Future<MemberOverviewModel?> getMemberOverview() async {
    final box = await instance;
    
    try {
      final overviewJson = box.get(_overviewKey);
      
      if (overviewJson != null) {
        final overviewData = jsonDecode(overviewJson) as Map<String, dynamic>;
        
        // Reconstituer le modèle avec la date de dernière mise à jour
        final overview = MemberOverviewModel(
          villaInscrit: overviewData['villas_with_users_count'] ?? 0,
          projetEnCours: overviewData['accepted_projects_count'] ?? 0,
          vigilance: overviewData['incident_reports_count'] ?? 0,
          solde: overviewData['wallet_balance'] ?? 0,
          pendingPaymentsCount: overviewData['pending_payments_count'] ?? 0,
          walletDetails: WalletDetails.fromJson(overviewData['wallet_details'] ?? {}),
          lastUpdated: DateTime.fromMillisecondsSinceEpoch(
            overviewData['last_updated'] ?? DateTime.now().millisecondsSinceEpoch
          ),
        );
        
        print('📂 [OVERVIEW] Données overview récupérées du cache');
        return overview;
      }
      
      print('📭 [OVERVIEW] Aucune donnée overview en cache');
      return null;
      
    } catch (e) {
      print('❌ [OVERVIEW] Erreur récupération overview: $e');
      return null;
    }
  }

  /// Vérifie si on a des données overview en cache
  static Future<bool> hasCachedOverview() async {
    final box = await instance;
    return box.containsKey(_overviewKey);
  }

  /// Vérifie si les données en cache sont récentes (moins de 30 minutes)
  static Future<bool> isCacheRecent() async {
    final overview = await getMemberOverview();
    return overview?.isRecent ?? false;
  }

  /// Supprime les données overview du cache
  static Future<void> clearCache() async {
    final box = await instance;
    
    try {
      await box.delete(_overviewKey);
      print('🗑️ [OVERVIEW] Cache overview nettoyé');
    } catch (e) {
      print('❌ [OVERVIEW] Erreur nettoyage cache overview: $e');
      throw Exception('Erreur lors du nettoyage du cache overview: $e');
    }
  }

  /// Obtient les statistiques de stockage
  static Future<Map<String, dynamic>> getStorageStats() async {
    try {
      final box = await instance;
      final hasData = await hasCachedOverview();
      final isRecent = await isCacheRecent();
      final overview = await getMemberOverview();
      
      return {
        'has_cached_data': hasData,
        'is_cache_recent': isRecent,
        'cache_size': box.length,
        'last_updated': overview?.lastUpdated.toIso8601String(),
        'box_name': _boxName,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'has_cached_data': false,
        'is_cache_recent': false,
      };
    }
  }

  /// Force la mise à jour du timestamp de cache
  static Future<void> updateCacheTimestamp() async {
    final overview = await getMemberOverview();
    if (overview != null) {
      final updatedOverview = overview.copyWith(lastUpdated: DateTime.now());
      await saveMemberOverview(updatedOverview);
    }
  }
}