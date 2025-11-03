import 'package:flutter/material.dart';
import '../data_sources/report_data_source.dart';
import '../models/report_model.dart';

enum ReportLoadingStatus { initial, loading, success, error }

class ReportController extends ChangeNotifier {
  final ReportDataSource _reportDataSource = ReportDataSource();

  // Pour la récupération des signalements
  ReportLoadingStatus _loadingStatus = ReportLoadingStatus.initial;
  List<ReportModel> _reports = [];
  Map<String, dynamic>? _pagination;
  String? _loadingErrorMessage;

  // Getters
  ReportLoadingStatus get loadingStatus => _loadingStatus;
  List<ReportModel> get reports => List.unmodifiable(_reports);
  Map<String, dynamic>? get pagination => _pagination;
  String? get loadingErrorMessage => _loadingErrorMessage;
  bool get isLoadingReports => _loadingStatus == ReportLoadingStatus.loading;

  // Méthodes pour récupérer les signalements
  Future<void> fetchReports({
    String? status,
    String? priority,
    String? reportType,
    int perPage = 15,
    int page = 1,
    bool append = false,
  }) async {
    if (!append) {
      _setLoadingStatus(ReportLoadingStatus.loading);
      _clearLoadingError();
    }

    try {
      final response = await _reportDataSource.getReports(
        status: status,
        priority: priority,
        reportType: reportType,
        perPage: perPage,
        page: page,
      );

      if (response['success'] == true) {
        final reportsData = response['data'] as List<dynamic>;
        final newReports = reportsData.map((json) => ReportModel.fromJson(json as Map<String, dynamic>)).toList();
        
        if (append) {
          _reports.addAll(newReports);
        } else {
          _reports = newReports;
        }
        
        _pagination = response['pagination'] as Map<String, dynamic>?;
        _setLoadingStatus(ReportLoadingStatus.success);
      } else {
        _setLoadingError(response['message'] ?? 'Erreur lors de la récupération des signalements');
        _setLoadingStatus(ReportLoadingStatus.error);
      }
    } catch (e) {
      _setLoadingError(e.toString());
      _setLoadingStatus(ReportLoadingStatus.error);
    }
  }

  // Méthodes utilitaires pour le chargement
  void _setLoadingStatus(ReportLoadingStatus status) {
    _loadingStatus = status;
    notifyListeners();
  }

  void _setLoadingError(String error) {
    _loadingErrorMessage = error;
    notifyListeners();
  }

  void _clearLoadingError() {
    _loadingErrorMessage = null;
    notifyListeners();
  }

  // Méthode pour filtrer les signalements localement (pour la recherche)
  List<ReportModel> getFilteredReports({
    String? searchQuery,
  }) {
    var filteredReports = _reports;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredReports = filteredReports.where((report) {
        return report.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
               report.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (report.place?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filteredReports;
  }

  // Méthode pour rafraîchir les signalements
  Future<void> refreshReports() async {
    await fetchReports();
  }
}