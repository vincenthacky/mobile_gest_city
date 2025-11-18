import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/cash_movement_model.dart';
import '../models/cash_movements_response_model.dart';
import '../models/cash_movements_cache_models.dart';

class CashMovementsLocalStorageService {
  static const String _boxName = 'cash_movements_cache';
  static Box<CashMovementsCache>? _box;

  /// Initialise le service de cache des mouvements de caisse
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<CashMovementsCache>(_boxName);
      debugPrint('✅ [CASH MOVEMENTS CACHE] Service initialisé avec succès');
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS CACHE] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Sauvegarde les mouvements de caisse
  static Future<void> saveCashMovements(
    List<CashMovement> movements,
    Pagination? pagination, {
    String? filter,
  }) async {
    if (_box == null) await initialize();

    try {
      final movementsJson = jsonEncode(movements.map((m) => _movementToJson(m)).toList());
      final paginationJson = pagination != null ? jsonEncode(_paginationToJson(pagination)) : '{}';
      
      final cache = CashMovementsCache.create(
        movementsJson: movementsJson,
        paginationJson: paginationJson,
        filter: filter,
        cachedAt: DateTime.now(),
      );

      final cacheKey = _getCacheKey(filter);
      await _box!.put(cacheKey, cache);
      debugPrint('✅ [CASH MOVEMENTS CACHE] ${movements.length} mouvements sauvegardés (filter: $filter)');
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS CACHE] Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// Récupère les mouvements de caisse depuis le cache
  static CashMovementsData? getCashMovements({String? filter}) {
    if (_box == null) return null;

    try {
      final cacheKey = _getCacheKey(filter);
      final cached = _box!.get(cacheKey);
      
      if (cached != null) {
        final movementsJson = jsonDecode(cached.movementsJson) as List<dynamic>;
        final paginationJson = jsonDecode(cached.paginationJson) as Map<String, dynamic>;
        
        final movements = movementsJson.map((m) => _movementFromJson(m as Map<String, dynamic>)).toList();
        final pagination = paginationJson.isNotEmpty ? _paginationFromJson(paginationJson) : null;
        
        debugPrint('✅ [CASH MOVEMENTS CACHE] ${movements.length} mouvements récupérés (filter: $filter)');
        return CashMovementsData(cashMovements: movements, pagination: pagination);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS CACHE] Erreur récupération: $e');
      return null;
    }
  }

  /// Ajoute des mouvements à un cache existant (pagination)
  static Future<void> addMoreCashMovements(
    List<CashMovement> newMovements,
    Pagination? newPagination, {
    String? filter,
  }) async {
    if (_box == null) await initialize();

    try {
      final existingData = getCashMovements(filter: filter);
      if (existingData != null) {
        // Fusionner les mouvements existants avec les nouveaux
        final allMovements = [...existingData.cashMovements, ...newMovements];
        await saveCashMovements(allMovements, newPagination, filter: filter);
        debugPrint('✅ [CASH MOVEMENTS CACHE] ${newMovements.length} mouvements ajoutés (total: ${allMovements.length})');
      } else {
        // Si pas de cache existant, sauvegarder directement
        await saveCashMovements(newMovements, newPagination, filter: filter);
      }
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS CACHE] Erreur ajout mouvements: $e');
      rethrow;
    }
  }

  /// Vérifie si on a des mouvements en cache
  static bool hasCashMovements({String? filter}) {
    if (_box == null) return false;
    final cacheKey = _getCacheKey(filter);
    return _box!.containsKey(cacheKey);
  }

  /// Vide le cache pour un filtre donné
  static Future<void> clearCacheForFilter({String? filter}) async {
    if (_box == null) return;
    
    try {
      final cacheKey = _getCacheKey(filter);
      await _box!.delete(cacheKey);
      debugPrint('🗑️ [CASH MOVEMENTS CACHE] Cache vidé pour filtre: $filter');
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS CACHE] Erreur vidage cache: $e');
    }
  }

  /// Vide tout le cache
  static Future<void> clearAllCache() async {
    if (_box == null) return;
    
    try {
      await _box!.clear();
      debugPrint('🗑️ [CASH MOVEMENTS CACHE] Tout le cache vidé');
    } catch (e) {
      debugPrint('❌ [CASH MOVEMENTS CACHE] Erreur vidage total: $e');
    }
  }

  /// Obtient les statistiques du cache
  static Map<String, dynamic> getCacheStats() {
    if (_box == null) return {'total_entries': 0};

    final entries = _box!.values.toList();
    return {
      'total_entries': entries.length,
      'cache_keys': _box!.keys.toList(),
      'last_cached': entries.isNotEmpty
          ? entries.map((e) => e.cachedAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  // ============ MÉTHODES PRIVÉES ============

  static String _getCacheKey(String? filter) {
    return filter ?? 'all';
  }

  static Map<String, dynamic> _movementToJson(CashMovement movement) {
    return {
      'id': movement.id,
      'contribution_id': movement.contributionId,
      'amount': movement.amount,
      'date': movement.date.toIso8601String(),
      'kind': movement.kind,
      'method': movement.method,
      'status': movement.status,
      'project_id': movement.projectId,
      'user': movement.user?.toJson(),
      'project': movement.project?.toJson(),
    };
  }

  static CashMovement _movementFromJson(Map<String, dynamic> json) {
    return CashMovement.fromJson(json);
  }

  static Map<String, dynamic> _paginationToJson(Pagination pagination) {
    return {
      'current_page': pagination.currentPage,
      'last_page': pagination.lastPage,
      'per_page': pagination.perPage,
      'total': pagination.total,
    };
  }

  static Pagination _paginationFromJson(Map<String, dynamic> json) {
    return Pagination.fromJson(json);
  }
}

// Classe helper pour retourner les données
class CashMovementsData {
  final List<CashMovement> cashMovements;
  final Pagination? pagination;

  CashMovementsData({
    required this.cashMovements,
    this.pagination,
  });
}