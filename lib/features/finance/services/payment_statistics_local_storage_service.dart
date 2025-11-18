import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/payment_statistics_model.dart';
import '../models/payment_cache_models.dart';

class PaymentStatisticsLocalStorageService {
  static const String _boxName = 'payment_statistics_cache';
  static Box<PaymentStatisticsCache>? _box;

  /// Initialise le service de cache des statistiques
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<PaymentStatisticsCache>(_boxName);
      debugPrint('✅ [STATS CACHE] Service initialisé avec succès');
    } catch (e) {
      debugPrint('❌ [STATS CACHE] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Sauvegarde les statistiques d'un mois
  static Future<void> saveMonthStatistics(
    int year,
    int month,
    PaymentStatisticsData statistics,
  ) async {
    if (_box == null) await initialize();

    try {
      final monthKey = _getMonthKey(year, month);
      final statisticsJson = jsonEncode(_statisticsToJson(statistics));
      
      final cache = PaymentStatisticsCache.create(
        monthKey: monthKey,
        statisticsJson: statisticsJson,
        cachedAt: DateTime.now(),
      );

      await _box!.put(monthKey, cache);
      debugPrint('✅ [STATS CACHE] Statistiques $monthKey sauvegardées');
    } catch (e) {
      debugPrint('❌ [STATS CACHE] Erreur sauvegarde $year-$month: $e');
      rethrow;
    }
  }

  /// Récupère les statistiques d'un mois depuis le cache
  static PaymentStatisticsData? getMonthStatistics(int year, int month) {
    if (_box == null) return null;

    try {
      final monthKey = _getMonthKey(year, month);
      final cached = _box!.get(monthKey);
      
      if (cached != null) {
        final json = jsonDecode(cached.statisticsJson) as Map<String, dynamic>;
        debugPrint('✅ [STATS CACHE] Statistiques $monthKey récupérées du cache');
        return _statisticsFromJson(json);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [STATS CACHE] Erreur récupération $year-$month: $e');
      return null;
    }
  }

  /// Sauvegarde toutes les statistiques d'une année
  static Future<void> saveYearStatistics(
    int year,
    Map<int, PaymentStatisticsData> monthlyStats,
  ) async {
    if (_box == null) await initialize();

    try {
      final cacheEntries = <String, PaymentStatisticsCache>{};
      final now = DateTime.now();

      for (final entry in monthlyStats.entries) {
        final monthKey = _getMonthKey(year, entry.key);
        final statisticsJson = jsonEncode(_statisticsToJson(entry.value));
        
        cacheEntries[monthKey] = PaymentStatisticsCache.create(
          monthKey: monthKey,
          statisticsJson: statisticsJson,
          cachedAt: now,
        );
      }

      await _box!.putAll(cacheEntries);
      debugPrint('✅ [STATS CACHE] ${monthlyStats.length} mois sauvegardés pour $year');
    } catch (e) {
      debugPrint('❌ [STATS CACHE] Erreur sauvegarde année $year: $e');
      rethrow;
    }
  }

  /// Récupère toutes les statistiques d'une année
  static Map<int, PaymentStatisticsData> getYearStatistics(int year) {
    if (_box == null) return {};

    try {
      final yearStats = <int, PaymentStatisticsData>{};
      
      for (int month = 1; month <= 12; month++) {
        final stats = getMonthStatistics(year, month);
        if (stats != null) {
          yearStats[month] = stats;
        }
      }

      debugPrint('📂 [STATS CACHE] ${yearStats.length}/12 mois récupérés pour $year');
      return yearStats;
    } catch (e) {
      debugPrint('❌ [STATS CACHE] Erreur récupération année $year: $e');
      return {};
    }
  }

  /// Vérifie si toutes les statistiques d'une année sont en cache
  static bool hasCompleteYearStatistics(int year) {
    if (_box == null) return false;
    
    for (int month = 1; month <= 12; month++) {
      final monthKey = _getMonthKey(year, month);
      if (!_box!.containsKey(monthKey)) {
        return false;
      }
    }
    return true;
  }

  /// Vide tout le cache
  static Future<void> clearCache() async {
    if (_box == null) return;
    await _box!.clear();
    debugPrint('🗑️ [STATS CACHE] Cache complètement vidé');
  }

  /// Obtient les statistiques du cache
  static Map<String, dynamic> getCacheStats() {
    if (_box == null) return {'total_entries': 0};

    final entries = _box!.values.toList();
    return {
      'total_entries': entries.length,
      'last_cached': entries.isNotEmpty
          ? entries.map((e) => e.cachedAt).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }

  // ============ MÉTHODES PRIVÉES ============

  static String _getMonthKey(int year, int month) {
    return '$year-${month.toString().padLeft(2, '0')}';
  }

  // Conversion PaymentStatisticsData vers JSON simple
  static Map<String, dynamic> _statisticsToJson(PaymentStatisticsData stats) {
    return {
      'period': {
        'year': stats.period.year,
        'month': stats.period.month,
        'label': stats.period.label,
      },
      'payments_made_in_month': {
        'total_amount': stats.paymentsMadeInMonth.totalAmount,
        'count': stats.paymentsMadeInMonth.count,
        'breakdown': {
          'for_current_month': {
            'amount': stats.paymentsMadeInMonth.breakdown.forCurrentMonth.amount,
            'count': stats.paymentsMadeInMonth.breakdown.forCurrentMonth.count,
          },
          'catch_up': {
            'amount': stats.paymentsMadeInMonth.breakdown.catchUp.amount,
            'count': stats.paymentsMadeInMonth.breakdown.catchUp.count,
          },
          'advance': {
            'amount': stats.paymentsMadeInMonth.breakdown.advance.amount,
            'count': stats.paymentsMadeInMonth.breakdown.advance.count,
          },
        },
      },
      'payments_for_month': {
        'total_amount': stats.paymentsForMonth.totalAmount,
        'count': stats.paymentsForMonth.count,
      },
    };
  }

  // Conversion JSON vers PaymentStatisticsData
  static PaymentStatisticsData _statisticsFromJson(Map<String, dynamic> json) {
    return PaymentStatisticsData.fromJson(json);
  }
}