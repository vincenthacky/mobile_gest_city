import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeController extends ChangeNotifier {
  final ContributionDataSource _contributionDataSource = ContributionDataSource();
  
  HomeStatus _status = HomeStatus.initial;
  ContributionModel? _defaultContribution;
  List<ContributionModel> _contributions = [];
  String? _errorMessage;

  HomeStatus get status => _status;
  ContributionModel? get defaultContribution => _defaultContribution;
  List<ContributionModel> get contributions => _contributions;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == HomeStatus.loading;
  bool get hasError => _status == HomeStatus.error;
  bool get isLoaded => _status == HomeStatus.loaded;

  Future<void> loadHomeData() async {
    _setStatus(HomeStatus.loading);
    _clearError();

    try {
      // Load both default contribution and contributions list
      final defaultContributionResponse = await _contributionDataSource.getDefaultContribution();
      final contributionsResponse = await _contributionDataSource.getContributions(perPage: 3);

      _defaultContribution = defaultContributionResponse.data;
      _contributions = contributionsResponse.data;
      
      _setStatus(HomeStatus.loaded);
    } catch (e) {
      _setError(e.toString());
      _setStatus(HomeStatus.error);
    }
  }

  Future<void> refreshHomeData() async {
    await loadHomeData();
  }

  void _setStatus(HomeStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  double getProgressPercentage() {
    if (_defaultContribution == null) return 0.0;
    if (_defaultContribution!.amount == 0) return 0.0;
    
    return (_defaultContribution!.amountReachedTotal / _defaultContribution!.amount)
        .clamp(0.0, 1.0);
  }

  String formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }
}