import 'package:flutter/material.dart';
import '../data_source/contribution_data_source.dart';
import '../models/payment_overview_model.dart';
import '../models/payment_statistics_model.dart';

enum PaymentBreakdownStatus { initial, loading, loaded, error }

class PaymentBreakdownController extends ChangeNotifier {
  final ContributionDataSource _dataSource = ContributionDataSource();
  
  PaymentBreakdownStatus _status = PaymentBreakdownStatus.initial;
  List<PaymentOverviewUser> _paymentOverview = [];
  PaymentStatisticsData? _paymentStatistics;
  Map<int, PaymentStatisticsData> _annualStatistics = {};
  String? _errorMessage;
  
  // État pour la sélection
  String _selectedSegment = '1-6';
  int? _selectedMonth;

  // Getters
  PaymentBreakdownStatus get status => _status;
  List<PaymentOverviewUser> get paymentOverview => _paymentOverview;
  PaymentStatisticsData? get paymentStatistics => _paymentStatistics;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _status == PaymentBreakdownStatus.loading;
  bool get hasData => _paymentOverview.isNotEmpty;
  String get selectedSegment => _selectedSegment;
  int? get selectedMonth => _selectedMonth;
  int get annualStatisticsCount => _annualStatistics.length;

  // Getters pour les données calculées
  List<String> get monthNames => [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  List<int> get segmentMonths {
    final startMonth = (_selectedSegment == '1-6') ? 1 : 7;
    return List.generate(6, (index) => startMonth + index);
  }

  // Listes pour la compatibilité avec SummaryCard
  List<int> get montantVentileRef {
    if (_selectedMonth != null && _paymentStatistics != null) {
      // Mode mois sélectionné
      List<int> amounts = List.filled(12, 0);
      amounts[_selectedMonth! - 1] = _paymentStatistics!.montantRecuInt;
      return amounts;
    } else {
      // Mode annuel - utiliser toutes les statistiques
      return List.generate(12, (index) {
        final month = index + 1;
        return _annualStatistics[month]?.montantRecuInt ?? 0;
      });
    }
  }

  List<int> get montantRecuParMois {
    if (_annualStatistics.isEmpty) {
      debugPrint('DEBUG: Utilisation des données de fallback pour montantRecuParMois');
      return _getFallbackMontantRecu();
    }
    final result = List.generate(12, (index) {
      final month = index + 1;
      final amount = _annualStatistics[month]?.montantRecuInt ?? 0;
      return amount;
    });
    debugPrint('DEBUG: montantRecuParMois depuis API: $result');
    return result;
  }

  List<int> get montantReelParMois {
    if (_annualStatistics.isEmpty) {
      return _getFallbackMontantReel();
    }
    return List.generate(12, (index) {
      final month = index + 1;
      return _annualStatistics[month]?.montantReelInt ?? 0;
    });
  }

  List<int> get montantRemboursementParMois {
    if (_annualStatistics.isEmpty) {
      return _getFallbackMontantRemboursement();
    }
    return List.generate(12, (index) {
      final month = index + 1;
      return _annualStatistics[month]?.montantRemboursementInt ?? 0;
    });
  }

  List<int> get montantAvanceParMois {
    if (_annualStatistics.isEmpty) {
      return _getFallbackMontantAvance();
    }
    return List.generate(12, (index) {
      final month = index + 1;
      return _annualStatistics[month]?.montantAvanceInt ?? 0;
    });
  }
  
  // Données de fallback pour les montants
  List<int> _getFallbackMontantRecu() {
    return [90000, 200000, 70000, 120000, 160000, 0, 220000, 40000, 120000, 260000, 60000, 0];
  }
  
  List<int> _getFallbackMontantReel() {
    return [80000, 120000, 70000, 100000, 130000, 0, 110000, 40000, 100000, 150000, 60000, 0];
  }
  
  List<int> _getFallbackMontantRemboursement() {
    return [10000, 50000, 0, 20000, 30000, 0, 60000, 0, 20000, 60000, 0, 0];
  }
  
  List<int> _getFallbackMontantAvance() {
    return [0, 30000, 0, 0, 0, 0, 50000, 0, 0, 50000, 0, 0];
  }

  // Méthodes pour gérer la sélection
  void updateSelectedSegment(String segment) {
    _selectedSegment = segment;
    _selectedMonth = null; // Reset month selection
    notifyListeners();
  }

  void updateSelectedMonth(int? month) {
    _selectedMonth = month;
    notifyListeners();
    
    // Charger les statistiques pour le mois sélectionné
    if (month != null) {
      _loadPaymentStatistics(DateTime.now().year, month);
    }
  }

  // Charger les données
  Future<void> loadPaymentBreakdownData() async {
    _setStatus(PaymentBreakdownStatus.loading);
    _clearError();
    
    try {
      // Charger l'aperçu des paiements
      final overviewResponse = await _dataSource.getPaymentOverview();
      
      if (overviewResponse.success) {
        _paymentOverview = overviewResponse.data;
        _setStatus(PaymentBreakdownStatus.loaded);
        
        // Charger les statistiques pour tous les mois de l'année
        final now = DateTime.now();
        await _loadAnnualStatistics(now.year);
        
        // Charger les statistiques pour le mois actuel par défaut
        await _loadPaymentStatistics(now.year, now.month);
      } else {
        _setError(overviewResponse.message);
        _setStatus(PaymentBreakdownStatus.error);
      }
    } catch (e) {
      _setError(e.toString());
      _setStatus(PaymentBreakdownStatus.error);
    }
  }

  Future<void> _loadPaymentStatistics(int year, int month) async {
    try {
      final statsResponse = await _dataSource.getPaymentStatistics(
        year: year,
        month: month,
      );
      
      if (statsResponse.success) {
        _paymentStatistics = statsResponse.data;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques: $e');
      // Ne pas faire échouer toute l'opération si les stats échouent
    }
  }

  Future<void> refreshData() async {
    await loadPaymentBreakdownData();
  }

  void _setStatus(PaymentBreakdownStatus status) {
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
    _paymentOverview = [];
    _paymentStatistics = null;
    _annualStatistics = {};
    _errorMessage = null;
    _status = PaymentBreakdownStatus.initial;
    _selectedSegment = '1-6';
    _selectedMonth = null;
    notifyListeners();
  }
  
  Future<void> _loadAnnualStatistics(int year) async {
    try {
      debugPrint('DEBUG: Chargement des statistiques annuelles pour $year');
      // Charger les statistiques pour tous les mois de l'année
      for (int month = 1; month <= 12; month++) {
        final statsResponse = await _dataSource.getPaymentStatistics(
          year: year,
          month: month,
        );
        
        debugPrint('DEBUG: Mois $month - Success: ${statsResponse.success}, Data: ${statsResponse.data}');
        
        if (statsResponse.success) {
          _annualStatistics[month] = statsResponse.data;
          debugPrint('DEBUG: Statistiques mois $month chargées - Montant réel: ${statsResponse.data.montantReel}');
        } else {
          debugPrint('DEBUG: Échec du chargement pour le mois $month');
        }
      }
      debugPrint('DEBUG: Statistiques annuelles chargées: ${_annualStatistics.length} mois');
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors du chargement des statistiques annuelles: $e');
    }
  }
  
  // Méthode publique pour s'assurer que toutes les statistiques annuelles sont chargées
  Future<void> ensureAnnualStatisticsLoaded() async {
    final currentYear = DateTime.now().year;
    
    // Si moins de 12 mois chargés, recharger toutes les statistiques
    if (_annualStatistics.length < 12) {
      debugPrint('DEBUG: Rechargement des statistiques annuelles (${_annualStatistics.length}/12 actuellement)');
      await _loadAnnualStatistics(currentYear);
      
      // Attendre maximum 30 secondes
      int attempts = 0;
      while (_annualStatistics.length < 12 && attempts < 300) {
        await Future.delayed(const Duration(milliseconds: 100));
        attempts++;
      }
      
      debugPrint('DEBUG: Statistiques finales chargées: ${_annualStatistics.length}/12');
    }
  }

  // Méthode utilitaire pour obtenir les membres au format compatible
  List<Map<String, dynamic>> get membersForTable {
    if (_paymentOverview.isEmpty) {
      debugPrint('DEBUG Controller: Aucune donnée dans _paymentOverview, utilisation des données de fallback');
      return _getFallbackMembers();
    }
    
    debugPrint('DEBUG Controller: ${_paymentOverview.length} membres dans _paymentOverview');
    
    return _paymentOverview.map((user) {
      final payments = List.generate(12, (index) {
        final monthNumber = index + 1;
        final status = user.getDisplayStatusForMonth(monthNumber);
        return status;
      });
      
      debugPrint('DEBUG Controller: Utilisateur ${user.fullName}, payments: $payments');
      
      return {
        'name': user.fullName,
        'payments': payments,
      };
    }).toList();
  }
  
  // Données de fallback pour les tests et quand les APIs échouent
  List<Map<String, dynamic>> _getFallbackMembers() {
    return [
      {
        'name': 'Marie DUPONT',
        'payments': ['paid', 'paid', 'unpaid', 'paid', 'paid', 'future', 'paid', 'paid', 'paid', 'paid', 'paid', 'future']
      },
      {
        'name': 'Paul MARTIN', 
        'payments': ['paid', 'paid', 'paid', 'paid', 'unpaid', 'future', 'paid', 'paid', 'paid', 'paid', 'unpaid', 'future']
      },
      {
        'name': 'Jean KOUASSI',
        'payments': ['unpaid', 'paid', 'paid', 'paid', 'paid', 'future', 'paid', 'paid', 'paid', 'paid', 'paid', 'future']
      },
      {
        'name': 'Sophie BROU',
        'payments': ['paid', 'unpaid', 'paid', 'unpaid', 'paid', 'future', 'paid', 'unpaid', 'paid', 'unpaid', 'paid', 'future']
      },
      {
        'name': 'Thomas YAO',
        'payments': ['paid', 'paid', 'paid', 'paid', 'paid', 'future', 'paid', 'paid', 'paid', 'paid', 'paid', 'future']
      },
    ];
  }
}