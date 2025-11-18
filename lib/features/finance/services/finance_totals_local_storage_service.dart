import 'package:hive_flutter/hive_flutter.dart';
import '../models/cash_totals_model.dart';

class FinanceTotalsLocalStorageService {
  static const String _boxName = 'finance_totals';
  static Box<Map>? _box;

  /// Initialise le stockage local pour les totaux financiers
  static Future<void> initialize() async {
    if (_box != null && _box!.isOpen) return;
    
    try {
      _box = await Hive.openBox<Map>(_boxName);
      print('✅ [FINANCE_TOTALS] Box initialisée avec succès');
    } catch (e) {
      print('❌ [FINANCE_TOTALS] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Sauvegarde les totaux financiers en local
  static Future<void> saveTotals(CashTotals totals) async {
    try {
      await initialize();
      
      final totalsMap = {
        'balance': totals.balance,
        'totalReceipts': totals.totalReceipts,
        'totalExpenses': totals.totalExpenses,
        'cachedAt': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _box!.put('current_totals', totalsMap);
      print('💾 [FINANCE_TOTALS] Totaux sauvegardés: Solde=${totals.balance}, Recettes=${totals.totalReceipts}, Dépenses=${totals.totalExpenses}');
    } catch (e) {
      print('❌ [FINANCE_TOTALS] Erreur lors de la sauvegarde: $e');
    }
  }

  /// Récupère les totaux financiers depuis le cache local
  static Future<CashTotals?> getCachedTotals() async {
    try {
      await initialize();
      
      final totalsMap = _box!.get('current_totals');
      if (totalsMap == null) {
        print('📂 [FINANCE_TOTALS] Aucun total en cache');
        return null;
      }
      
      final totals = CashTotals(
        balance: totalsMap['balance'] ?? 0,
        totalReceipts: totalsMap['totalReceipts'] ?? 0,
        totalExpenses: totalsMap['totalExpenses'] ?? 0,
      );
      
      final cachedAt = DateTime.fromMillisecondsSinceEpoch(totalsMap['cachedAt'] ?? 0);
      print('📂 [FINANCE_TOTALS] Totaux récupérés du cache (mis en cache le ${cachedAt.toString()}): Solde=${totals.balance}, Recettes=${totals.totalReceipts}, Dépenses=${totals.totalExpenses}');
      
      return totals;
    } catch (e) {
      print('❌ [FINANCE_TOTALS] Erreur lors de la récupération: $e');
      return null;
    }
  }

  /// Vérifie si on a des totaux en cache
  static Future<bool> hasCachedTotals() async {
    try {
      await initialize();
      return _box!.containsKey('current_totals');
    } catch (e) {
      print('❌ [FINANCE_TOTALS] Erreur lors de la vérification: $e');
      return false;
    }
  }

  /// Supprime les totaux du cache
  static Future<void> clearCachedTotals() async {
    try {
      await initialize();
      await _box!.delete('current_totals');
      print('🗑️ [FINANCE_TOTALS] Totaux supprimés du cache');
    } catch (e) {
      print('❌ [FINANCE_TOTALS] Erreur lors de la suppression: $e');
    }
  }

  /// Ferme le stockage local
  static Future<void> close() async {
    try {
      await _box?.close();
      _box = null;
      print('✅ [FINANCE_TOTALS] Stockage fermé');
    } catch (e) {
      print('❌ [FINANCE_TOTALS] Erreur lors de la fermeture: $e');
    }
  }
}