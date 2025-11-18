import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/payment_overview_model.dart';
import '../models/payment_cache_models.dart';

class PaymentOverviewLocalStorageService {
  static const String _boxName = 'payment_overview_cache';
  static Box<PaymentOverviewCache>? _box;

  /// Initialise le service de cache de l'aperçu
  static Future<void> initialize() async {
    try {
      _box = await Hive.openBox<PaymentOverviewCache>(_boxName);
      debugPrint('✅ [OVERVIEW CACHE] Service initialisé avec succès');
    } catch (e) {
      debugPrint('❌ [OVERVIEW CACHE] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Sauvegarde l'aperçu des paiements
  static Future<void> savePaymentOverview(List<PaymentOverviewUser> overview) async {
    if (_box == null) await initialize();

    try {
      final overviewJson = jsonEncode(overview.map((user) => _userToJson(user)).toList());
      
      final cache = PaymentOverviewCache.create(
        overviewJson: overviewJson,
        cachedAt: DateTime.now(),
      );

      await _box!.put('overview', cache);
      debugPrint('✅ [OVERVIEW CACHE] Aperçu des paiements sauvegardé (${overview.length} utilisateurs)');
    } catch (e) {
      debugPrint('❌ [OVERVIEW CACHE] Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// Récupère l'aperçu des paiements depuis le cache
  static List<PaymentOverviewUser>? getPaymentOverview() {
    if (_box == null) return null;

    try {
      final cached = _box!.get('overview');
      
      if (cached != null) {
        final json = jsonDecode(cached.overviewJson) as List<dynamic>;
        final overview = json.map((userJson) => _userFromJson(userJson as Map<String, dynamic>)).toList();
        debugPrint('✅ [OVERVIEW CACHE] Aperçu récupéré du cache (${overview.length} utilisateurs)');
        return overview;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [OVERVIEW CACHE] Erreur récupération: $e');
      return null;
    }
  }

  /// Vérifie si on a un aperçu en cache
  static bool hasPaymentOverview() {
    if (_box == null) return false;
    return _box!.containsKey('overview');
  }

  /// Vide le cache
  static Future<void> clearCache() async {
    if (_box == null) return;
    await _box!.clear();
    debugPrint('🗑️ [OVERVIEW CACHE] Cache vidé');
  }

  /// Obtient les statistiques du cache
  static Map<String, dynamic> getCacheStats() {
    if (_box == null) return {'has_data': false};

    final cached = _box!.get('overview');
    return {
      'has_data': cached != null,
      'cached_at': cached?.cachedAt,
    };
  }

  // ============ MÉTHODES PRIVÉES ============

  // Conversion PaymentOverviewUser vers JSON simple
  static Map<String, dynamic> _userToJson(PaymentOverviewUser user) {
    return {
      'id': user.id,
      'full_name': user.fullName,
      'email': user.email,
      'phone': user.phone,
      'payments': user.payments.map((payment) => {
        'month_number': payment.monthNumber,
        'status': payment.status,
      }).toList(),
    };
  }

  // Conversion JSON vers PaymentOverviewUser
  static PaymentOverviewUser _userFromJson(Map<String, dynamic> json) {
    return PaymentOverviewUser.fromJson(json);
  }
}