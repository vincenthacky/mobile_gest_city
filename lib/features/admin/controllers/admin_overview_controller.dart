import 'package:flutter/material.dart';
import '../../../core/services/connectivity_service.dart';
import '../data_source/admin_overview_data_source.dart';
import '../models/admin_overview_model.dart';

enum AdminOverviewStatus { initial, loading, loaded, error }

class AdminOverviewController extends ChangeNotifier {
  final AdminOverviewDataSource _dataSource = AdminOverviewDataSource();
  final ConnectivityService _connectivityService = ConnectivityService();

  AdminOverviewStatus _status = AdminOverviewStatus.initial;
  AdminOverviewModel? _overview;
  String? _errorMessage;

  AdminOverviewStatus get status => _status;
  AdminOverviewModel? get overview => _overview;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == AdminOverviewStatus.loading;
  bool get hasData => _overview != null;

  Future<void> loadOverview({bool forceRefresh = false}) async {
    if (_status == AdminOverviewStatus.loading) return;

    debugPrint('🔄 [ADMIN OVERVIEW CONTROLLER] Loading overview...');

    _setStatus(AdminOverviewStatus.loading);
    _clearError();

    try {
      if (!_connectivityService.isConnected) {
        throw Exception('Pas de connexion Internet');
      }

      final overview = await _dataSource.getOverview();
      _overview = overview;

      debugPrint('✅ [ADMIN OVERVIEW CONTROLLER] Overview loaded successfully');
      debugPrint('   - Accepted projects: ${overview.acceptedProjectsCount}');
      debugPrint('   - Pending payments: ${overview.pendingPaymentsCount}');
      debugPrint('   - Villas with users: ${overview.villasWithUsersCount}');
      debugPrint('   - Wallet balance: ${overview.formattedWalletBalance}');

      _setStatus(AdminOverviewStatus.loaded);
    } catch (e) {
      debugPrint('❌ [ADMIN OVERVIEW CONTROLLER] Error: $e');
      _setError(e.toString());
      _setStatus(AdminOverviewStatus.error);
    }
  }

  Future<void> refreshOverview() async {
    debugPrint('🔄 [ADMIN OVERVIEW CONTROLLER] Refreshing overview...');
    await loadOverview(forceRefresh: true);
  }

  void _setStatus(AdminOverviewStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    debugPrint('❌ [ADMIN OVERVIEW CONTROLLER] Error: $error');
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  @override
  void dispose() {
    debugPrint('🔴 [ADMIN OVERVIEW CONTROLLER] Dispose');
    super.dispose();
  }
}
