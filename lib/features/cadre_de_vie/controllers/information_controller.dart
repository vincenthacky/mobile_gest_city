import 'package:flutter/material.dart';
import '../data_sources/information_data_source.dart';
import '../models/information_model.dart';

enum InformationLoadingStatus { initial, loading, success, error }

class InformationController extends ChangeNotifier {
  final InformationDataSource _informationDataSource = InformationDataSource();

  InformationLoadingStatus _loadingStatus = InformationLoadingStatus.initial;
  List<InformationModel> _informations = [];
  Map<String, dynamic>? _pagination;
  String? _loadingErrorMessage;

  InformationLoadingStatus get loadingStatus => _loadingStatus;
  List<InformationModel> get informations => List.unmodifiable(_informations);
  Map<String, dynamic>? get pagination => _pagination;
  String? get loadingErrorMessage => _loadingErrorMessage;
  bool get isLoadingInformations => _loadingStatus == InformationLoadingStatus.loading;

  Future<void> fetchInformations({
    String? status,
    String? priority,
    String? reportType,
    int perPage = 15,
    int page = 1,
    bool append = false,
  }) async {
    if (!append) {
      _setLoadingStatus(InformationLoadingStatus.loading);
      _clearLoadingError();
    }

    try {
      final response = await _informationDataSource.getInformation(
        status: status,
        priority: priority,
        reportType: reportType,
        perPage: perPage,
        page: page,
      );

      if (response['success'] == true) {
        final informationsData = response['data'] as List<dynamic>;
        final newInformations = informationsData.map((json) => InformationModel.fromJson(json as Map<String, dynamic>)).toList();
        
        if (append) {
          _informations.addAll(newInformations);
        } else {
          _informations = newInformations;
        }
        
        _pagination = response['pagination'] as Map<String, dynamic>?;
        _setLoadingStatus(InformationLoadingStatus.success);
      } else {
        _setLoadingError(response['message'] ?? 'Erreur lors de la récupération des informations');
        _setLoadingStatus(InformationLoadingStatus.error);
      }
    } catch (e) {
      _setLoadingError(e.toString());
      _setLoadingStatus(InformationLoadingStatus.error);
    }
  }

  void _setLoadingStatus(InformationLoadingStatus status) {
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

  List<InformationModel> getFilteredInformations({
    String? searchQuery,
  }) {
    var filteredInformations = _informations;

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredInformations = filteredInformations.where((information) {
        return information.title.toLowerCase().contains(searchQuery.toLowerCase()) ||
               information.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
               (information.place?.toLowerCase().contains(searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return filteredInformations;
  }

  Future<void> refreshInformations() async {
    await fetchInformations();
  }
}