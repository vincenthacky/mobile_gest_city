import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/admin_payment_model.dart';

/// Service de stockage local pour les paiements admin
/// Suit le même pattern que ContributionLocalStorageService
class AdminPaymentsLocalStorageService {
  static const String _paymentsBoxName = 'admin_payments_cache';
  static const String _paymentsKey = 'all_payments';
  static const String _paginationKey = 'pagination';
  static const String _lastSyncKey = 'last_sync';

  static Box? _paymentsBox;

  /// Initialise le service de stockage
  static Future<void> initialize() async {
    try {
      _paymentsBox = await Hive.openBox(_paymentsBoxName);
      debugPrint('✅ [ADMIN PAYMENTS STORAGE] Cache initialisé');
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur initialisation: $e');
      rethrow;
    }
  }

  /// Sauvegarde la liste complète des paiements
  static Future<void> savePayments(List<AdminPaymentItem> payments,
      {PaymentPagination? pagination}) async {
    if (_paymentsBox == null) await initialize();

    try {
      final paymentsJson =
          jsonEncode(payments.map((p) => p.toJson()).toList());

      await _paymentsBox!.put(_paymentsKey, paymentsJson);

      if (pagination != null) {
        final paginationJson = jsonEncode(pagination.toJson());
        await _paymentsBox!.put(_paginationKey, paginationJson);
      }

      await _paymentsBox!.put(_lastSyncKey, DateTime.now().toIso8601String());

      debugPrint(
          '✅ [ADMIN PAYMENTS STORAGE] ${payments.length} paiements sauvegardés');
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur sauvegarde: $e');
      rethrow;
    }
  }

  /// Récupère les paiements du cache
  static List<AdminPaymentItem>? getPayments() {
    if (_paymentsBox == null) return null;

    try {
      final paymentsJson = _paymentsBox!.get(_paymentsKey);
      if (paymentsJson == null) {
        debugPrint('ℹ️ [ADMIN PAYMENTS STORAGE] Aucun cache trouvé');
        return null;
      }

      final List<dynamic> jsonList = jsonDecode(paymentsJson);
      final payments = jsonList
          .map((item) => AdminPaymentItem.fromJson(item as Map<String, dynamic>))
          .toList();

      debugPrint(
          '✅ [ADMIN PAYMENTS STORAGE] ${payments.length} paiements récupérés du cache');
      return payments;
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur récupération: $e');
      return null;
    }
  }

  /// Récupère la pagination du cache
  static PaymentPagination? getPagination() {
    if (_paymentsBox == null) return null;

    try {
      final paginationJson = _paymentsBox!.get(_paginationKey);
      if (paginationJson == null) return null;

      final Map<String, dynamic> json = jsonDecode(paginationJson);
      return PaymentPagination.fromJson(json);
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur récupération pagination: $e');
      return null;
    }
  }

  /// Ajoute des paiements à la liste existante (pour pagination infinie)
  static Future<void> addMorePayments(List<AdminPaymentItem> newPayments,
      {PaymentPagination? pagination}) async {
    if (_paymentsBox == null) await initialize();

    try {
      // Récupérer les paiements existants
      final existing = getPayments() ?? [];

      // Ajouter les nouveaux paiements
      final allPayments = [...existing, ...newPayments];

      // Sauvegarder la liste complète
      await savePayments(allPayments, pagination: pagination);

      debugPrint(
          '✅ [ADMIN PAYMENTS STORAGE] ${newPayments.length} paiements ajoutés (total: ${allPayments.length})');
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur ajout paiements: $e');
      rethrow;
    }
  }

  /// Met à jour un paiement spécifique dans le cache
  static Future<void> updatePayment(AdminPaymentItem updatedPayment) async {
    if (_paymentsBox == null) await initialize();

    try {
      final payments = getPayments();
      if (payments == null) {
        debugPrint('⚠️ [ADMIN PAYMENTS STORAGE] Aucun cache à mettre à jour');
        return;
      }

      final index = payments.indexWhere((p) => p.id == updatedPayment.id);
      if (index != -1) {
        payments[index] = updatedPayment;
        await savePayments(payments);
        debugPrint('✅ [ADMIN PAYMENTS STORAGE] Paiement ${updatedPayment.id} mis à jour');
      } else {
        debugPrint('⚠️ [ADMIN PAYMENTS STORAGE] Paiement non trouvé dans le cache');
      }
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur mise à jour: $e');
      rethrow;
    }
  }

  /// Supprime un paiement du cache
  static Future<void> removePayment(String paymentId) async {
    if (_paymentsBox == null) await initialize();

    try {
      final payments = getPayments();
      if (payments == null) return;

      final filteredPayments = payments.where((p) => p.id != paymentId).toList();
      await savePayments(filteredPayments);

      debugPrint('✅ [ADMIN PAYMENTS STORAGE] Paiement $paymentId supprimé');
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur suppression: $e');
      rethrow;
    }
  }

  /// Récupère la date de la dernière synchronisation
  static DateTime? getLastSyncDate() {
    if (_paymentsBox == null) return null;

    try {
      final lastSyncStr = _paymentsBox!.get(_lastSyncKey);
      if (lastSyncStr == null) return null;

      return DateTime.parse(lastSyncStr);
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur récupération last sync: $e');
      return null;
    }
  }

  /// Vérifie si le cache est expiré (plus de 5 minutes)
  static bool isCacheExpired() {
    final lastSync = getLastSyncDate();
    if (lastSync == null) return true;

    final difference = DateTime.now().difference(lastSync);
    return difference.inMinutes > 5;
  }

  /// Vide complètement le cache
  static Future<void> clearCache() async {
    if (_paymentsBox == null) await initialize();

    try {
      await _paymentsBox!.clear();
      debugPrint('✅ [ADMIN PAYMENTS STORAGE] Cache vidé complètement');
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS STORAGE] Erreur vidage cache: $e');
      rethrow;
    }
  }

  /// Obtient les statistiques du cache
  static Map<String, dynamic> getCacheStats() {
    final payments = getPayments();
    final pagination = getPagination();
    final lastSync = getLastSyncDate();

    return {
      'payments_count': payments?.length ?? 0,
      'total_in_api': pagination?.total ?? 0,
      'current_page': pagination?.currentPage ?? 0,
      'last_page': pagination?.lastPage ?? 0,
      'last_sync': lastSync?.toIso8601String() ?? 'Jamais',
      'is_expired': isCacheExpired(),
    };
  }

  /// Affiche les statistiques du cache dans les logs
  static void logCacheStats() {
    final stats = getCacheStats();
    debugPrint('📊 [ADMIN PAYMENTS STORAGE] Statistiques du cache:');
    debugPrint('   Paiements en cache: ${stats['payments_count']}');
    debugPrint('   Total dans l\'API: ${stats['total_in_api']}');
    debugPrint('   Page actuelle: ${stats['current_page']}/${stats['last_page']}');
    debugPrint('   Dernière sync: ${stats['last_sync']}');
    debugPrint('   Cache expiré: ${stats['is_expired']}');
  }
}
