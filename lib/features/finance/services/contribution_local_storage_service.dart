import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../models/contribution_model.dart';
import '../models/unpaid_months_model.dart';
import '../models/payment_proofs_model.dart';
import '../models/payment_list_model.dart';
import '../models/payment_periods_model.dart';
import '../models/contribution_cache_models.dart';

class ContributionLocalStorageService {
  static const String _contributionBoxName = 'contribution_data_cache';
  static const String _unpaidMonthsBoxName = 'unpaid_months_cache';
  static const String _paymentProofsBoxName = 'payment_proofs_cache';
  static const String _allPaymentsBoxName = 'all_payments_cache';
  static const String _paymentPeriodsBoxName = 'payment_periods_cache';
  
  static Box<ContributionDataCache>? _contributionBox;
  static Box<UnpaidMonthsCache>? _unpaidMonthsBox;
  static Box<PaymentProofsCache>? _paymentProofsBox;
  static Box<AllPaymentsCache>? _allPaymentsBox;
  static Box<PaymentPeriodsCache>? _paymentPeriodsBox;

  /// Initialise tous les services de cache des cotisations
  static Future<void> initialize() async {
    try {
      _contributionBox = await Hive.openBox<ContributionDataCache>(_contributionBoxName);
      _unpaidMonthsBox = await Hive.openBox<UnpaidMonthsCache>(_unpaidMonthsBoxName);
      _paymentProofsBox = await Hive.openBox<PaymentProofsCache>(_paymentProofsBoxName);
      _allPaymentsBox = await Hive.openBox<AllPaymentsCache>(_allPaymentsBoxName);
      _paymentPeriodsBox = await Hive.openBox<PaymentPeriodsCache>(_paymentPeriodsBoxName);
      
      debugPrint('✅ [CONTRIBUTION CACHE] Services initialisés avec succès');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  // ============ CONTRIBUTION DATA ============

  /// Sauvegarde les données de contribution
  static Future<void> saveContributionData(ContributionData data) async {
    if (_contributionBox == null) await initialize();

    try {
      final contributionJson = jsonEncode(_contributionDataToJson(data));
      
      final cache = ContributionDataCache.create(
        contributionJson: contributionJson,
        cachedAt: DateTime.now(),
      );

      await _contributionBox!.put('contribution', cache);
      debugPrint('✅ [CONTRIBUTION CACHE] Données de contribution sauvegardées');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur sauvegarde contribution: $e');
      rethrow;
    }
  }

  /// Récupère les données de contribution depuis le cache
  static ContributionData? getContributionData() {
    if (_contributionBox == null) return null;

    try {
      final cached = _contributionBox!.get('contribution');
      
      if (cached != null) {
        final json = jsonDecode(cached.contributionJson) as Map<String, dynamic>;
        debugPrint('✅ [CONTRIBUTION CACHE] Données contribution récupérées du cache');
        return _contributionDataFromJson(json);
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur récupération contribution: $e');
      return null;
    }
  }

  // ============ UNPAID MONTHS ============

  /// Sauvegarde les mois impayés
  static Future<void> saveUnpaidMonths(List<UnpaidMonth> months) async {
    if (_unpaidMonthsBox == null) await initialize();

    try {
      final monthsJson = jsonEncode(months.map((m) => _unpaidMonthToJson(m)).toList());
      
      final cache = UnpaidMonthsCache.create(
        unpaidMonthsJson: monthsJson,
        cachedAt: DateTime.now(),
      );

      await _unpaidMonthsBox!.put('unpaid_months', cache);
      debugPrint('✅ [CONTRIBUTION CACHE] ${months.length} mois impayés sauvegardés');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur sauvegarde mois impayés: $e');
      rethrow;
    }
  }

  /// Récupère les mois impayés depuis le cache
  static List<UnpaidMonth>? getUnpaidMonths() {
    if (_unpaidMonthsBox == null) return null;

    try {
      final cached = _unpaidMonthsBox!.get('unpaid_months');
      
      if (cached != null) {
        final json = jsonDecode(cached.unpaidMonthsJson) as List<dynamic>;
        final months = json.map((m) => _unpaidMonthFromJson(m as Map<String, dynamic>)).toList();
        debugPrint('✅ [CONTRIBUTION CACHE] ${months.length} mois impayés récupérés du cache');
        return months;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur récupération mois impayés: $e');
      return null;
    }
  }

  // ============ PAYMENT PROOFS ============

  /// Sauvegarde les preuves de paiement (validés ou en attente)
  static Future<void> savePaymentProofs(
    String userId,
    String proofType, // 'validated' ou 'pending'
    List<PaymentProof> proofs,
  ) async {
    if (_paymentProofsBox == null) await initialize();

    try {
      final proofsJson = jsonEncode(proofs.map((p) => _paymentProofToJson(p)).toList());
      
      final cache = PaymentProofsCache.create(
        proofType: proofType,
        userId: userId,
        paymentProofsJson: proofsJson,
        cachedAt: DateTime.now(),
      );

      final cacheKey = '${userId}_$proofType';
      await _paymentProofsBox!.put(cacheKey, cache);
      debugPrint('✅ [CONTRIBUTION CACHE] ${proofs.length} preuves $proofType sauvegardées pour $userId');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur sauvegarde preuves $proofType: $e');
      rethrow;
    }
  }

  /// Récupère les preuves de paiement depuis le cache
  static List<PaymentProof>? getPaymentProofs(String userId, String proofType) {
    if (_paymentProofsBox == null) return null;

    try {
      final cacheKey = '${userId}_$proofType';
      final cached = _paymentProofsBox!.get(cacheKey);
      
      if (cached != null) {
        final json = jsonDecode(cached.paymentProofsJson) as List<dynamic>;
        final proofs = json.map((p) => _paymentProofFromJson(p as Map<String, dynamic>)).toList();
        debugPrint('✅ [CONTRIBUTION CACHE] ${proofs.length} preuves $proofType récupérées pour $userId');
        return proofs;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur récupération preuves $proofType: $e');
      return null;
    }
  }

  // ============ ALL PAYMENTS ============

  /// Sauvegarde tous les paiements d'un utilisateur
  static Future<void> saveAllPayments(String userId, List<PaymentItem> payments) async {
    if (_allPaymentsBox == null) await initialize();

    try {
      final paymentsJson = jsonEncode(payments.map((p) => _paymentItemToJson(p)).toList());
      
      final cache = AllPaymentsCache.create(
        userId: userId,
        paymentsJson: paymentsJson,
        cachedAt: DateTime.now(),
      );

      await _allPaymentsBox!.put(userId, cache);
      debugPrint('✅ [CONTRIBUTION CACHE] ${payments.length} paiements sauvegardés pour $userId');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur sauvegarde tous paiements: $e');
      rethrow;
    }
  }

  /// Récupère tous les paiements d'un utilisateur depuis le cache
  static List<PaymentItem>? getAllPayments(String userId) {
    if (_allPaymentsBox == null) return null;

    try {
      final cached = _allPaymentsBox!.get(userId);
      
      if (cached != null) {
        final json = jsonDecode(cached.paymentsJson) as List<dynamic>;
        final payments = json.map((p) => _paymentItemFromJson(p as Map<String, dynamic>)).toList();
        debugPrint('✅ [CONTRIBUTION CACHE] ${payments.length} paiements récupérés pour $userId');
        return payments;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur récupération tous paiements: $e');
      return null;
    }
  }

  // ============ PAYMENT PERIODS ============

  /// Sauvegarde les périodes de paiement
  static Future<void> savePaymentPeriods(List<PaymentPeriod> periods) async {
    if (_paymentPeriodsBox == null) await initialize();

    try {
      final periodsJson = jsonEncode(periods.map((p) => _paymentPeriodToJson(p)).toList());
      
      final cache = PaymentPeriodsCache.create(
        periodsJson: periodsJson,
        cachedAt: DateTime.now(),
      );

      await _paymentPeriodsBox!.put('payment_periods', cache);
      debugPrint('✅ [CONTRIBUTION CACHE] ${periods.length} périodes de paiement sauvegardées');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur sauvegarde périodes: $e');
      rethrow;
    }
  }

  /// Récupère les périodes de paiement depuis le cache
  static List<PaymentPeriod>? getPaymentPeriods() {
    if (_paymentPeriodsBox == null) return null;

    try {
      final cached = _paymentPeriodsBox!.get('payment_periods');
      
      if (cached != null) {
        final json = jsonDecode(cached.periodsJson) as List<dynamic>;
        final periods = json.map((p) => _paymentPeriodFromJson(p as Map<String, dynamic>)).toList();
        debugPrint('✅ [CONTRIBUTION CACHE] ${periods.length} périodes récupérées du cache');
        return periods;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur récupération périodes: $e');
      return null;
    }
  }

  // ============ UTILITAIRES ============

  /// Vérifie si on a des données en cache
  static bool hasContributionData() {
    return _contributionBox?.containsKey('contribution') ?? false;
  }

  static bool hasUnpaidMonths() {
    return _unpaidMonthsBox?.containsKey('unpaid_months') ?? false;
  }

  static bool hasPaymentProofs(String userId, String proofType) {
    final cacheKey = '${userId}_$proofType';
    return _paymentProofsBox?.containsKey(cacheKey) ?? false;
  }

  static bool hasAllPayments(String userId) {
    return _allPaymentsBox?.containsKey(userId) ?? false;
  }

  static bool hasPaymentPeriods() {
    return _paymentPeriodsBox?.containsKey('payment_periods') ?? false;
  }

  /// Vide tous les caches
  static Future<void> clearAllCaches() async {
    try {
      await _contributionBox?.clear();
      await _unpaidMonthsBox?.clear();
      await _paymentProofsBox?.clear();
      await _allPaymentsBox?.clear();
      await _paymentPeriodsBox?.clear();
      debugPrint('🗑️ [CONTRIBUTION CACHE] Tous les caches vidés');
    } catch (e) {
      debugPrint('❌ [CONTRIBUTION CACHE] Erreur vidage caches: $e');
    }
  }

  /// Obtient les statistiques des caches
  static Map<String, dynamic> getCacheStats() {
    return {
      'contribution_cached': hasContributionData(),
      'unpaid_months_cached': hasUnpaidMonths(),
      'payment_proofs_entries': _paymentProofsBox?.length ?? 0,
      'all_payments_entries': _allPaymentsBox?.length ?? 0,
      'payment_periods_cached': hasPaymentPeriods(),
    };
  }

  // ============ MÉTHODES PRIVÉES DE CONVERSION ============

  static Map<String, dynamic> _contributionDataToJson(ContributionData data) {
    return {
      'id': data.id,
      'name': data.name,
      'description': data.description,
      'amount_by_person': data.amountByPerson,
      'deadline_day': data.deadlineDay,
      'created_at': data.createdAt.toIso8601String(),
      'updated_at': data.updatedAt.toIso8601String(),
      'total_amount_payment_collected_current_period': data.totalAmountPaymentCollectedCurrentPeriod,
      'total_expected_amount_this_month': data.totalExpectedAmountThisMonth,
      'current_period': data.currentPeriod,
    };
  }

  static ContributionData _contributionDataFromJson(Map<String, dynamic> json) {
    return ContributionData.fromJson(json);
  }

  static Map<String, dynamic> _unpaidMonthToJson(UnpaidMonth month) {
    return {
      'period': month.period,
      'year': month.year,
      'month': month.month,
    };
  }

  static UnpaidMonth _unpaidMonthFromJson(Map<String, dynamic> json) {
    return UnpaidMonth.fromJson(json);
  }

  static Map<String, dynamic> _paymentProofToJson(PaymentProof proof) {
    return {
      'id': proof.id,
      'comment': proof.comment,
      'status': proof.status,
      'created_at': proof.createdAt.toIso8601String(),
      'file_url': proof.fileUrl,
    };
  }

  static PaymentProof _paymentProofFromJson(Map<String, dynamic> json) {
    return PaymentProof.fromJson(json);
  }

  static Map<String, dynamic> _paymentItemToJson(PaymentItem item) {
    return {
      'id': item.id,
      'contribution_id': item.contributionId,
      'amount_paid': item.amountPaid,
      'payment_date': item.paymentDate,
      'payment_method': item.paymentMethod,
      'status': item.status,
      'processed_by': item.processedBy,
      'processed_at': item.processedAt,
      'payment_year': item.paymentYear,
      'payment_month': item.paymentMonth,
      'period': item.period,
      'created_at': item.createdAt,
      'user': {
        'id': item.user.id,
        'name': item.user.name,
        'phone': item.user.phone,
        'email': item.user.email,
      },
    };
  }

  static PaymentItem _paymentItemFromJson(Map<String, dynamic> json) {
    return PaymentItem.fromJson(json);
  }

  static Map<String, dynamic> _paymentPeriodToJson(PaymentPeriod period) {
    return {
      'year': period.year,
      'month': period.month,
      'period': period.period,
      'is_selected': period.isSelected,
    };
  }

  static PaymentPeriod _paymentPeriodFromJson(Map<String, dynamic> json) {
    return PaymentPeriod.fromJson(json);
  }
}