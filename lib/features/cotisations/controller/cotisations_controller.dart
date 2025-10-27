import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/contribution_model.dart';
import '../data_source/cotisations_data_source.dart';

enum CotisationsStatus { initial, loading, loaded, loadingMore, error }

enum CotisationFilter { all, ongoing, finished, paid, notPaid, pending }

class CotisationsController extends ChangeNotifier {
  final CotisationsDataSource _dataSource = CotisationsDataSource();
  
  CotisationsStatus _status = CotisationsStatus.initial;
  List<ContributionModel> _contributions = [];
  String? _errorMessage;
  String _searchQuery = '';
  CotisationFilter _selectedFilter = CotisationFilter.all;
  
  // Pagination
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasMoreData = true;
  
  // Getters
  CotisationsStatus get status => _status;
  List<ContributionModel> get contributions => _contributions;
  String? get errorMessage => _errorMessage;
  String get searchQuery => _searchQuery;
  CotisationFilter get selectedFilter => _selectedFilter;
  bool get isLoading => _status == CotisationsStatus.loading;
  bool get isLoadingMore => _status == CotisationsStatus.loadingMore;
  bool get hasError => _status == CotisationsStatus.error;
  bool get hasMoreData => _hasMoreData;

  // Icônes et couleurs cycliques pour les cotisations
  final List<IconData> _icons = [
    Icons.school,
    Icons.celebration,
    Icons.group,
    Icons.mosque,
    Icons.water_drop,
  ];
  
  final List<Color> _colors = [
    const Color(0xFF3B82F6),
    const Color(0xFF8B5CF6),
    const Color(0xFFEC4899),
    const Color(0xFF10B981),
    const Color(0xFF06B6D4),
  ];

  IconData getIconForIndex(int index) => _icons[index % _icons.length];
  Color getColorForIndex(int index) => _colors[index % _colors.length];

  Future<void> loadContributions({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMoreData = true;
      _contributions.clear();
    }
    
    _setStatus(CotisationsStatus.loading);
    _clearError();

    try {
      final response = await _dataSource.getContributions(
        perPage: 10,
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _getApiStatusFromFilter(),
        alreadyPaid: _getAlreadyPaidFromFilter(),
      );

      if (refresh) {
        _contributions = response.data;
      } else {
        _contributions.addAll(response.data);
      }
      
      if (response.pagination != null) {
        _totalPages = response.pagination!.lastPage;
        _hasMoreData = _currentPage < _totalPages;
      }
      
      _setStatus(CotisationsStatus.loaded);
    } catch (e) {
      _setError(e.toString());
      _setStatus(CotisationsStatus.error);
    }
  }

  Future<void> loadMoreContributions() async {
    if (!_hasMoreData || _status == CotisationsStatus.loadingMore) return;
    
    _setStatus(CotisationsStatus.loadingMore);
    _currentPage++;

    try {
      final response = await _dataSource.getContributions(
        perPage: 10,
        page: _currentPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        status: _getApiStatusFromFilter(),
        alreadyPaid: _getAlreadyPaidFromFilter(),
      );

      _contributions.addAll(response.data);
      
      if (response.pagination != null) {
        _hasMoreData = _currentPage < response.pagination!.lastPage;
      }
      
      _setStatus(CotisationsStatus.loaded);
    } catch (e) {
      _currentPage--; // Revenir à la page précédente en cas d'erreur
      _setError(e.toString());
      _setStatus(CotisationsStatus.error);
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      loadContributions(refresh: true);
    });
  }

  Timer? _debounceTimer;

  void updateFilter(CotisationFilter filter) {
    if (_selectedFilter != filter) {
      _selectedFilter = filter;
      loadContributions(refresh: true);
    }
  }

  String? _getApiStatusFromFilter() {
    switch (_selectedFilter) {
      case CotisationFilter.ongoing:
        return 'pending';
      case CotisationFilter.finished:
        return 'finished';
      default:
        return null;
    }
  }

  String? _getAlreadyPaidFromFilter() {
    switch (_selectedFilter) {
      case CotisationFilter.paid:
        return 'paid';
      case CotisationFilter.notPaid:
        return 'not_paid';
      case CotisationFilter.pending:
        return 'pending';
      default:
        return null;
    }
  }

  void _setStatus(CotisationsStatus status) {
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

  double getProgressPercentage(ContributionModel contribution) {
    if (contribution.amount == 0) return 0.0;
    return (contribution.amountReachedTotal / contribution.amount).clamp(0.0, 1.0);
  }

  String formatAmount(int amount) {
    return '${amount.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]} ')} FCFA';
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}