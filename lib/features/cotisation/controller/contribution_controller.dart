import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/contribution_model.dart';

enum ContributionStatus { initial, loading, loaded, error }

class ContributionController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  
  ContributionStatus _status = ContributionStatus.initial;
  ContributionData? _contributionData;
  String? _errorMessage;

  ContributionStatus get status => _status;
  ContributionData? get contributionData => _contributionData;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == ContributionStatus.loading;
  bool get hasData => _contributionData != null;

  Future<void> loadContribution() async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      final response = await _dataSource.getContribution();
      
      if (response.success) {
        _contributionData = response.data;
        _setStatus(ContributionStatus.loaded);
      } else {
        _setError(response.message);
        _setStatus(ContributionStatus.error);
      }
    } catch (e) {
      _setError(e.toString());
      _setStatus(ContributionStatus.error);
    }
  }

  Future<void> refreshContribution() async {
    _setStatus(ContributionStatus.loading);
    _clearError();
    
    try {
      final response = await _dataSource.getContribution();
      
      if (response.success) {
        _contributionData = response.data;
        _setStatus(ContributionStatus.loaded);
      } else {
        _setError(response.message);
        _setStatus(ContributionStatus.error);
      }
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
    _errorMessage = null;
    _status = ContributionStatus.initial;
    notifyListeners();
  }
}