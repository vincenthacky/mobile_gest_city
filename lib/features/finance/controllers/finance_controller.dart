import 'dart:io';
import 'package:flutter/material.dart';
import '../models/wallet_model.dart';
import '../models/payment_breakdown_model.dart';
import '../models/monthly_contributions_model.dart';

enum FinanceLoadingStatus { initial, loading, success, error }

class FinanceController extends ChangeNotifier {
  FinanceLoadingStatus _walletStatus = FinanceLoadingStatus.initial;
  FinanceLoadingStatus _paymentStatus = FinanceLoadingStatus.initial;
  FinanceLoadingStatus _contributionStatus = FinanceLoadingStatus.initial;

  WalletModel? _walletData;
  PaymentBreakdownModel? _paymentBreakdownData;
  MonthlyContributionsModel? _contributionsData;

  String? _errorMessage;

  // Getters
  FinanceLoadingStatus get walletStatus => _walletStatus;
  FinanceLoadingStatus get paymentStatus => _paymentStatus;
  FinanceLoadingStatus get contributionStatus => _contributionStatus;

  WalletModel? get walletData => _walletData;
  PaymentBreakdownModel? get paymentBreakdownData => _paymentBreakdownData;
  MonthlyContributionsModel? get contributionsData => _contributionsData;

  String? get errorMessage => _errorMessage;

  bool get isLoadingWallet => _walletStatus == FinanceLoadingStatus.loading;
  bool get isLoadingPayments => _paymentStatus == FinanceLoadingStatus.loading;
  bool get isLoadingContributions => _contributionStatus == FinanceLoadingStatus.loading;

  // Méthodes pour charger les données (statiques pour l'instant)
  Future<void> loadWalletData() async {
    _walletStatus = FinanceLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      // Simulation d'un délai réseau
      await Future.delayed(const Duration(milliseconds: 800));

      // Données mockées pour le wallet
      _walletData = WalletModel(
        totalBalance: 450000,
        pendingAmount: 25000,
        availableBalance: 425000,
        monthlyTarget: 50000,
        currentMonthContribution: 35000,
        recentTransactions: [
          TransactionModel(
            id: '1',
            type: 'contribution',
            amount: 25000,
            description: 'Cotisation mensuelle novembre',
            status: 'completed',
            date: DateTime.now().subtract(const Duration(days: 2)),
            reference: 'COT-2024-11-001',
            paymentMethod: 'Orange Money',
          ),
          TransactionModel(
            id: '2',
            type: 'payment',
            amount: -15000,
            description: 'Frais de gestion',
            status: 'completed',
            date: DateTime.now().subtract(const Duration(days: 5)),
            reference: 'FEE-2024-11-002',
            paymentMethod: 'Wallet',
          ),
          TransactionModel(
            id: '3',
            type: 'contribution',
            amount: 30000,
            description: 'Cotisation mensuelle octobre',
            status: 'completed',
            date: DateTime.now().subtract(const Duration(days: 32)),
            reference: 'COT-2024-10-001',
            paymentMethod: 'MTN Mobile Money',
          ),
        ],
        paymentMethods: [
          PaymentMethodModel(
            id: '1',
            type: 'mobile_money',
            name: 'Orange Money',
            last4: '1234',
            isDefault: true,
            isActive: true,
          ),
          PaymentMethodModel(
            id: '2',
            type: 'mobile_money',
            name: 'MTN Mobile Money',
            last4: '5678',
            isDefault: false,
            isActive: true,
          ),
        ],
      );

      _walletStatus = FinanceLoadingStatus.success;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des données du portefeuille';
      _walletStatus = FinanceLoadingStatus.error;
    }

    notifyListeners();
  }

  Future<void> loadPaymentBreakdown() async {
    _paymentStatus = FinanceLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 600));

      // Données mockées pour la ventilation des paiements
      _paymentBreakdownData = PaymentBreakdownModel(
        totalAmount: 150000,
        paidAmount: 85000,
        remainingAmount: 65000,
        status: 'partial',
        dueDate: DateTime.now().add(const Duration(days: 15)),
        items: [
          PaymentItemModel(
            id: '1',
            title: 'Cotisation mensuelle',
            description: 'Cotisation pour le mois de novembre 2024',
            amount: 50000,
            paidAmount: 50000,
            status: 'paid',
            dueDate: DateTime.now().subtract(const Duration(days: 5)),
            ventilations: [
              PaymentVentilationModel(
                id: '1',
                category: 'Fonds général',
                description: 'Contribution au fonds général de l\'association',
                amount: 30000,
                percentage: 60.0,
              ),
              PaymentVentilationModel(
                id: '2',
                category: 'Projets',
                description: 'Financement des projets communautaires',
                amount: 15000,
                percentage: 30.0,
              ),
              PaymentVentilationModel(
                id: '3',
                category: 'Frais administratifs',
                description: 'Frais de gestion et administration',
                amount: 5000,
                percentage: 10.0,
              ),
            ],
          ),
          PaymentItemModel(
            id: '2',
            title: 'Contribution spéciale',
            description: 'Contribution pour le projet d\'aménagement',
            amount: 75000,
            paidAmount: 25000,
            status: 'partial',
            dueDate: DateTime.now().add(const Duration(days: 10)),
            ventilations: [
              PaymentVentilationModel(
                id: '4',
                category: 'Matériaux',
                description: 'Achat de matériaux de construction',
                amount: 45000,
                percentage: 60.0,
              ),
              PaymentVentilationModel(
                id: '5',
                category: 'Main d\'œuvre',
                description: 'Coût de la main d\'œuvre',
                amount: 22500,
                percentage: 30.0,
              ),
              PaymentVentilationModel(
                id: '6',
                category: 'Supervision',
                description: 'Frais de supervision technique',
                amount: 7500,
                percentage: 10.0,
              ),
            ],
          ),
          PaymentItemModel(
            id: '3',
            title: 'Frais d\'adhésion',
            description: 'Frais d\'adhésion annuelle 2024',
            amount: 25000,
            paidAmount: 10000,
            status: 'partial',
            dueDate: DateTime.now().add(const Duration(days: 20)),
            ventilations: [
              PaymentVentilationModel(
                id: '7',
                category: 'Carnet de membre',
                description: 'Impression du carnet de membre',
                amount: 5000,
                percentage: 20.0,
              ),
              PaymentVentilationModel(
                id: '8',
                category: 'Frais de dossier',
                description: 'Traitement du dossier d\'adhésion',
                amount: 20000,
                percentage: 80.0,
              ),
            ],
          ),
        ],
      );

      _paymentStatus = FinanceLoadingStatus.success;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement de la ventilation des paiements';
      _paymentStatus = FinanceLoadingStatus.error;
    }

    notifyListeners();
  }

  Future<void> loadMonthlyContributions() async {
    _contributionStatus = FinanceLoadingStatus.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.delayed(const Duration(milliseconds: 700));

      // Données mockées pour les cotisations mensuelles
      _contributionsData = MonthlyContributionsModel(
        totalContributions: 2450000,
        averageMonthlyContribution: 42500,
        stats: ContributionStatsModel(
          totalMembers: 25,
          paidMembers: 18,
          partialMembers: 4,
          pendingMembers: 3,
          averageContribution: 42500,
          highestContribution: 75000,
          lowestContribution: 25000,
        ),
        periods: [
          ContributionPeriodModel(
            id: '1',
            year: '2024',
            month: 'Novembre',
            targetAmount: 1250000,
            collectedAmount: 950000,
            remainingAmount: 300000,
            status: 'active',
            startDate: DateTime(2024, 11, 1),
            endDate: DateTime(2024, 11, 30),
            memberContributions: [
              MemberContributionModel(
                memberId: '1',
                memberName: 'Jean Dupont',
                memberEmail: 'jean.dupont@email.com',
                expectedAmount: 50000,
                paidAmount: 50000,
                remainingAmount: 0,
                status: 'paid',
                lastPaymentDate: DateTime.now().subtract(const Duration(days: 5)),
                payments: [
                  ContributionPaymentModel(
                    id: '1',
                    amount: 50000,
                    paymentDate: DateTime.now().subtract(const Duration(days: 5)),
                    method: 'Orange Money',
                    reference: 'OM-2024-11-001',
                    status: 'completed',
                  ),
                ],
              ),
              MemberContributionModel(
                memberId: '2',
                memberName: 'Marie Martin',
                memberEmail: 'marie.martin@email.com',
                expectedAmount: 50000,
                paidAmount: 25000,
                remainingAmount: 25000,
                status: 'partial',
                lastPaymentDate: DateTime.now().subtract(const Duration(days: 10)),
                payments: [
                  ContributionPaymentModel(
                    id: '2',
                    amount: 25000,
                    paymentDate: DateTime.now().subtract(const Duration(days: 10)),
                    method: 'MTN Mobile Money',
                    reference: 'MTN-2024-11-002',
                    status: 'completed',
                  ),
                ],
              ),
              MemberContributionModel(
                memberId: '3',
                memberName: 'Paul Bernard',
                memberEmail: 'paul.bernard@email.com',
                expectedAmount: 50000,
                paidAmount: 0,
                remainingAmount: 50000,
                status: 'pending',
                lastPaymentDate: null,
                payments: [],
              ),
            ],
          ),
          ContributionPeriodModel(
            id: '2',
            year: '2024',
            month: 'Octobre',
            targetAmount: 1250000,
            collectedAmount: 1200000,
            remainingAmount: 50000,
            status: 'completed',
            startDate: DateTime(2024, 10, 1),
            endDate: DateTime(2024, 10, 31),
            memberContributions: [],
          ),
        ],
      );

      _contributionStatus = FinanceLoadingStatus.success;
    } catch (e) {
      _errorMessage = 'Erreur lors du chargement des cotisations mensuelles';
      _contributionStatus = FinanceLoadingStatus.error;
    }

    notifyListeners();
  }

  // Méthodes utilitaires
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void refreshAll() {
    loadWalletData();
    loadPaymentBreakdown();
    loadMonthlyContributions();
  }

  // Méthodes pour les actions (mockées pour l'instant)
  Future<bool> makePayment({
    required String itemId,
    required double amount,
    required String paymentMethod,
    File? receipt,
    String? notes,
  }) async {
    // Simulation d'un traitement de paiement
    await Future.delayed(const Duration(seconds: 2));
    
    // Recharger les données après le paiement
    loadPaymentBreakdown();
    loadWalletData();
    
    return true; // Succès simulé
  }

  Future<bool> makeContribution({
    required String periodId,
    required double amount,
    required String paymentMethod,
    File? receipt,
    String? notes,
  }) async {
    // Simulation d'un traitement de cotisation
    await Future.delayed(const Duration(seconds: 2));
    
    // Recharger les données après la cotisation
    loadMonthlyContributions();
    loadWalletData();
    
    return true; // Succès simulé
  }
}