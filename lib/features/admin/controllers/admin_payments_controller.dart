import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../data_source/admin_payments_data_source.dart';
import '../models/admin_payment_model.dart';
import '../services/admin_payments_local_storage_service.dart';

/// Status de chargement des paiements admin
enum AdminPaymentsStatus { initial, loading, loaded, error }

/// Contrôleur pour la gestion des paiements admin
/// Suit le pattern de ContributionController et CashMovementsController
class AdminPaymentsController extends ChangeNotifier {
  final AdminPaymentsDataSource _dataSource = AdminPaymentsDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();

  // État
  AdminPaymentsStatus _status = AdminPaymentsStatus.initial;
  List<AdminPaymentItem> _payments = [];
  PaymentPagination? _pagination;
  String? _errorMessage;

  // Filtres actifs
  String? _statusFilter;
  String? _orderFilter = 'newest'; // Par défaut: plus récents en premier

  // État de chargement de pagination
  bool _isLoadingMore = false;

  // Getters
  AdminPaymentsStatus get status => _status;
  List<AdminPaymentItem> get payments => _payments;
  PaymentPagination? get pagination => _pagination;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AdminPaymentsStatus.loading;
  bool get hasData => _payments.isNotEmpty;
  bool get isLoadingMore => _isLoadingMore;
  String? get currentStatusFilter => _statusFilter;
  String? get currentOrderFilter => _orderFilter;

  // Getters de filtres calculés
  bool get hasNextPage => _pagination?.hasNextPage ?? false;
  int get currentPage => _pagination?.currentPage ?? 0;
  int get totalPages => _pagination?.lastPage ?? 0;
  int get totalItems => _pagination?.total ?? 0;

  /// Initialise le contrôleur
  void initialize() {
    debugPrint('🎯 [ADMIN PAYMENTS CONTROLLER] Initialisation...');
    AdminPaymentsLocalStorageService.initialize();
  }

  /// Charge les paiements (cache-first, puis sync si connecté)
  Future<void> loadPayments({
    String? status,
    String? order,
    bool forceRefresh = false,
  }) async {
    debugPrint('🔄 [ADMIN PAYMENTS CONTROLLER] Loading payments...');
    debugPrint('   Status filter: $status, Order: $order, ForceRefresh: $forceRefresh');

    // Mettre à jour les filtres
    _statusFilter = status;
    _orderFilter = order ?? 'newest';

    _setStatus(AdminPaymentsStatus.loading);
    _clearError();

    try {
      // 1. Charger depuis le cache (instant, même hors ligne)
      if (!forceRefresh) {
        await _loadFromCache();
      }

      // 2. Synchroniser avec l'API si connecté
      if (_connectivityService.isConnected) {
        await _syncWithAPI();
      } else {
        debugPrint('📱 [ADMIN PAYMENTS CONTROLLER] Pas de connexion, affichage du cache');
      }

      _setStatus(AdminPaymentsStatus.loaded);
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur: $e');
      _setError(e.toString());
      _setStatus(AdminPaymentsStatus.error);
    }
  }

  /// Charge les paiements depuis le cache
  Future<void> _loadFromCache() async {
    try {
      final cachedPayments = AdminPaymentsLocalStorageService.getPayments();
      final cachedPagination = AdminPaymentsLocalStorageService.getPagination();

      if (cachedPayments != null) {
        _payments = cachedPayments;
        _pagination = cachedPagination;

        // Appliquer les filtres localement (WhatsApp pattern)
        _applyLocalFilters();

        debugPrint(
            '✅ [ADMIN PAYMENTS CONTROLLER] ${_payments.length} paiements chargés du cache');
        notifyListeners();
      } else {
        debugPrint('ℹ️ [ADMIN PAYMENTS CONTROLLER] Aucun cache disponible');
        _payments = [];
        _pagination = null;
      }
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur lecture cache: $e');
    }
  }

  /// Synchronise avec l'API
  Future<void> _syncWithAPI() async {
    try {
      debugPrint('🌐 [ADMIN PAYMENTS CONTROLLER] Synchronisation API...');

      final response = await _dataSource.getPayments(
        status: _statusFilter,
        order: _orderFilter,
        perPage: 20,
        page: 1,
      );

      if (response.success) {
        _payments = response.data;
        _pagination = response.pagination;

        // Sauvegarder dans le cache
        await AdminPaymentsLocalStorageService.savePayments(
          _payments,
          pagination: _pagination,
        );

        debugPrint(
            '✅ [ADMIN PAYMENTS CONTROLLER] ${_payments.length} paiements synchronisés');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur sync API: $e');
      // Ne pas throw - on garde le cache en cas d'erreur réseau
    }
  }

  /// Applique les filtres localement (évite les appels API multiples)
  void _applyLocalFilters() {
    if (_statusFilter == null || _statusFilter!.isEmpty) {
      // Pas de filtre - afficher tout
      return;
    }

    // Filtrer par statut
    _payments = _payments.where((payment) {
      return payment.status == _statusFilter;
    }).toList();

    debugPrint('🔍 [ADMIN PAYMENTS CONTROLLER] Filtre appliqué: ${_payments.length} résultats');
  }

  /// Charge plus de paiements (pagination infinie)
  Future<void> loadMorePayments() async {
    if (!hasNextPage || _isLoadingMore) {
      debugPrint('⚠️ [ADMIN PAYMENTS CONTROLLER] Pas de page suivante ou déjà en chargement');
      return;
    }

    if (!_connectivityService.isConnected) {
      debugPrint('📱 [ADMIN PAYMENTS CONTROLLER] Pas de connexion pour charger plus');
      return;
    }

    _isLoadingMore = true;
    notifyListeners();

    try {
      final nextPage = currentPage + 1;
      debugPrint('📄 [ADMIN PAYMENTS CONTROLLER] Chargement page $nextPage...');

      final response = await _dataSource.getPayments(
        status: _statusFilter,
        order: _orderFilter,
        perPage: 20,
        page: nextPage,
      );

      if (response.success) {
        // Ajouter les nouveaux paiements à la liste existante
        _payments.addAll(response.data);
        _pagination = response.pagination;

        // Mettre à jour le cache
        await AdminPaymentsLocalStorageService.addMorePayments(
          response.data,
          pagination: _pagination,
        );

        debugPrint(
            '✅ [ADMIN PAYMENTS CONTROLLER] ${response.data.length} paiements ajoutés (total: ${_payments.length})');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur chargement page: $e');
      _setError('Erreur lors du chargement des paiements supplémentaires');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Rafraîchit les données (pull-to-refresh)
  Future<void> refreshPayments() async {
    debugPrint('🔄 [ADMIN PAYMENTS CONTROLLER] Rafraîchissement...');
    await loadPayments(
      status: _statusFilter,
      order: _orderFilter,
      forceRefresh: true,
    );
  }

  /// Change le filtre de statut
  Future<void> changeStatusFilter(String? status) async {
    if (_statusFilter == status) {
      debugPrint('ℹ️ [ADMIN PAYMENTS CONTROLLER] Filtre déjà appliqué');
      return;
    }

    debugPrint('🔍 [ADMIN PAYMENTS CONTROLLER] Changement de filtre: $status');
    _statusFilter = status;

    // Recharger avec le nouveau filtre
    await loadPayments(status: status, order: _orderFilter);
  }

  /// Change l'ordre de tri
  Future<void> changeOrder(String order) async {
    if (_orderFilter == order) {
      debugPrint('ℹ️ [ADMIN PAYMENTS CONTROLLER] Ordre déjà appliqué');
      return;
    }

    debugPrint('🔄 [ADMIN PAYMENTS CONTROLLER] Changement d\'ordre: $order');
    _orderFilter = order;

    // Recharger avec le nouvel ordre
    await loadPayments(status: _statusFilter, order: order);
  }

  /// Valide un paiement
  Future<bool> approvePayment(String paymentId, {String? notes}) async {
    try {
      debugPrint('✅ [ADMIN PAYMENTS CONTROLLER] Validation du paiement: $paymentId');

      // Récupérer le paiement existant pour conserver les infos utilisateur
      final existingPaymentIndex = _payments.indexWhere((p) => p.id == paymentId);
      final existingPayment = existingPaymentIndex != -1 ? _payments[existingPaymentIndex] : null;

      final response = await _dataSource.approvePayment(
        paymentId: paymentId,
        notes: notes,
      );

      if (response.success && response.payment != null) {
        // Fusionner les données: garder les infos user de l'existant, mettre à jour le statut
        AdminPaymentItem updatedPayment = response.payment!;

        if (existingPayment != null) {
          // Créer un nouveau paiement avec les infos user conservées
          updatedPayment = AdminPaymentItem(
            id: updatedPayment.id,
            checksum: updatedPayment.checksum,
            contributionId: updatedPayment.contributionId,
            amountPaid: updatedPayment.amountPaid,
            paymentDate: updatedPayment.paymentDate,
            paymentMethod: updatedPayment.paymentMethod,
            status: updatedPayment.status,
            processedBy: updatedPayment.processedBy,
            processedAt: updatedPayment.processedAt,
            paymentYear: updatedPayment.paymentYear,
            paymentMonth: updatedPayment.paymentMonth,
            period: updatedPayment.period,
            createdAt: updatedPayment.createdAt,
            // Conserver les infos user de l'existant
            userAnonymity: existingPayment.userAnonymity,
            userId: existingPayment.userId,
            userFullName: existingPayment.userFullName,
            userEmail: existingPayment.userEmail,
            userPhone: existingPayment.userPhone,
            userImageUrl: existingPayment.userImageUrl,
            villaId: existingPayment.villaId,
            villaNumber: existingPayment.villaNumber,
            villaCode: existingPayment.villaCode,
            proofs: updatedPayment.proofs,
          );
        }

        // Mettre à jour le paiement dans la liste locale
        if (existingPaymentIndex != -1) {
          _payments[existingPaymentIndex] = updatedPayment;

          // Mettre à jour le cache
          await AdminPaymentsLocalStorageService.updatePayment(updatedPayment);

          notifyListeners();
        }

        debugPrint('✅ [ADMIN PAYMENTS CONTROLLER] Paiement validé avec succès');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur validation: $e');
      _setError('Erreur lors de la validation du paiement');
      return false;
    }
  }

  /// Rejette un paiement
  Future<bool> rejectPayment(String paymentId, String reason) async {
    try {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Rejet du paiement: $paymentId');

      // Récupérer le paiement existant pour conserver les infos utilisateur
      final existingPaymentIndex = _payments.indexWhere((p) => p.id == paymentId);
      final existingPayment = existingPaymentIndex != -1 ? _payments[existingPaymentIndex] : null;

      final response = await _dataSource.rejectPayment(
        paymentId: paymentId,
        reason: reason,
      );

      if (response.success && response.payment != null) {
        // Fusionner les données: garder les infos user de l'existant, mettre à jour le statut
        AdminPaymentItem updatedPayment = response.payment!;

        if (existingPayment != null) {
          // Créer un nouveau paiement avec les infos user conservées
          updatedPayment = AdminPaymentItem(
            id: updatedPayment.id,
            checksum: updatedPayment.checksum,
            contributionId: updatedPayment.contributionId,
            amountPaid: updatedPayment.amountPaid,
            paymentDate: updatedPayment.paymentDate,
            paymentMethod: updatedPayment.paymentMethod,
            status: updatedPayment.status,
            processedBy: updatedPayment.processedBy,
            processedAt: updatedPayment.processedAt,
            paymentYear: updatedPayment.paymentYear,
            paymentMonth: updatedPayment.paymentMonth,
            period: updatedPayment.period,
            createdAt: updatedPayment.createdAt,
            // Conserver les infos user de l'existant
            userAnonymity: existingPayment.userAnonymity,
            userId: existingPayment.userId,
            userFullName: existingPayment.userFullName,
            userEmail: existingPayment.userEmail,
            userPhone: existingPayment.userPhone,
            userImageUrl: existingPayment.userImageUrl,
            villaId: existingPayment.villaId,
            villaNumber: existingPayment.villaNumber,
            villaCode: existingPayment.villaCode,
            proofs: updatedPayment.proofs,
          );
        }

        // Mettre à jour le paiement dans la liste locale
        if (existingPaymentIndex != -1) {
          _payments[existingPaymentIndex] = updatedPayment;

          // Mettre à jour le cache
          await AdminPaymentsLocalStorageService.updatePayment(updatedPayment);

          notifyListeners();
        }

        debugPrint('✅ [ADMIN PAYMENTS CONTROLLER] Paiement rejeté avec succès');
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur rejet: $e');
      _setError('Erreur lors du rejet du paiement');
      return false;
    }
  }

  /// Vérifie un QR code et récupère les informations utilisateur
  Future<QRCodeVerificationResponse?> verifyQRCode(String villaNumber) async {
    try {
      debugPrint('📱 [ADMIN PAYMENTS CONTROLLER] Vérification QR code: $villaNumber');

      final response = await _dataSource.verifyQRCode(villaNumber);

      if (response.success) {
        debugPrint('✅ [ADMIN PAYMENTS CONTROLLER] QR code vérifié avec succès');
        return response;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur vérification QR: $e');
      _setError('Erreur lors de la vérification du QR code');
      return null;
    }
  }

  /// Valide les paiements d'un utilisateur pour des périodes spécifiques
  Future<PaymentValidationResponse?> validateUserPayments({
    required String userId,
    required List<Map<String, dynamic>> periods,
  }) async {
    try {
      debugPrint('📱 [ADMIN PAYMENTS CONTROLLER] Validation paiements user: $userId');
      debugPrint('   Périodes: $periods');

      final response = await _dataSource.validateUserPayments(
        userId: userId,
        periods: periods,
      );

      if (response.success) {
        debugPrint('✅ [ADMIN PAYMENTS CONTROLLER] Paiements validés avec succès');

        // Rafraîchir la liste
        await refreshPayments();

        return response;
      }

      return null;
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur validation paiements: $e');
      _setError('Erreur lors de la validation des paiements');
      return null;
    }
  }

  /// Valide un paiement via QR code
  Future<bool> validateQRPayment({
    required String userId,
    required List<String> validatedMonths,
    String? notes,
  }) async {
    try {
      debugPrint(
          '📱 [ADMIN PAYMENTS CONTROLLER] Validation QR pour user: $userId');
      debugPrint('   Mois validés: $validatedMonths');

      final response = await _dataSource.validateQRPayment(
        userId: userId,
        validatedMonths: validatedMonths,
        notes: notes,
      );

      if (response.success) {
        debugPrint('✅ [ADMIN PAYMENTS CONTROLLER] Paiement QR validé');

        // Rafraîchir la liste
        await refreshPayments();

        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Erreur validation QR: $e');
      _setError('Erreur lors de la validation du paiement QR');
      return false;
    }
  }

  /// Affiche les statistiques du cache
  void logCacheStats() {
    AdminPaymentsLocalStorageService.logCacheStats();
  }

  // Helpers privés
  void _setStatus(AdminPaymentsStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint('❌ [ADMIN PAYMENTS CONTROLLER] Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    debugPrint('🔴 [ADMIN PAYMENTS CONTROLLER] Dispose');
    super.dispose();
  }
}
