import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';
import '../models/unpaid_months_model.dart';

enum ContributionStatus { initial, loading, loaded, error }

class ContributionController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  
  ContributionStatus _status = ContributionStatus.initial;
  ContributionData? _contributionData;
  List<UnpaidMonth> _unpaidMonths = [];
  String? _errorMessage;

  ContributionStatus get status => _status;
  ContributionData? get contributionData => _contributionData;
  List<UnpaidMonth> get unpaidMonths => _unpaidMonths;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ContributionStatus.loading;
  bool get hasData => _contributionData != null;

  Future<void> loadContribution() async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      // Charger les données de contribution et les mois impayés en parallèle
      final contributionFuture = _dataSource.getContribution();
      final unpaidMonthsFuture = _dataSource.getUnpaidMonths();
      
      final results = await Future.wait([contributionFuture, unpaidMonthsFuture]);
      
      final contributionResponse = results[0] as ContributionResponse;
      final unpaidMonthsResponse = results[1] as UnpaidMonthsResponse;
      
      if (contributionResponse.success) {
        _contributionData = contributionResponse.data;
      } else {
        _setError(contributionResponse.message);
        _setStatus(ContributionStatus.error);
        return;
      }
      
      if (unpaidMonthsResponse.success) {
        _unpaidMonths = unpaidMonthsResponse.data;
      } else {
        // Ne pas faire échouer le chargement si les mois impayés échouent
        _unpaidMonths = [];
      }
      
      _setStatus(ContributionStatus.loaded);
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
    }
  }

  Future<void> refreshContribution() async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      // Rafraîchir les données de contribution et les mois impayés en parallèle
      final contributionFuture = _dataSource.getContribution();
      final unpaidMonthsFuture = _dataSource.getUnpaidMonths();
      
      final results = await Future.wait([contributionFuture, unpaidMonthsFuture]);
      
      final contributionResponse = results[0] as ContributionResponse;
      final unpaidMonthsResponse = results[1] as UnpaidMonthsResponse;
      
      if (contributionResponse.success) {
        _contributionData = contributionResponse.data;
      } else {
        _setError(contributionResponse.message);
        _setStatus(ContributionStatus.error);
        return;
      }
      
      if (unpaidMonthsResponse.success) {
        _unpaidMonths = unpaidMonthsResponse.data;
      } else {
        // Ne pas faire échouer le refresh si les mois impayés échouent
        _unpaidMonths = [];
      }
      
      _setStatus(ContributionStatus.loaded);
      
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
    }
  }

  void _setStatus(ContributionStatus status) {
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

  void clearData() {
    _contributionData = null;
    _unpaidMonths = [];
    _errorMessage = null;
    _status = ContributionStatus.initial;
    notifyListeners();
  }
}