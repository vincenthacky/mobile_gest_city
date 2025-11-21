import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'core/utils/app_router.dart';
import 'core/controller/home_controller.dart';
import 'core/database/database_initializer.dart';
import 'features/finance/services/transaction_local_storage_service.dart';
import 'features/finance/services/finance_totals_local_storage_service.dart';
import 'features/finance/services/payment_statistics_local_storage_service.dart';
import 'features/finance/services/payment_overview_local_storage_service.dart';
import 'features/finance/services/contribution_local_storage_service.dart';
import 'features/finance/services/cash_movements_local_storage_service.dart';
import 'features/authentication/controller/auth_controller.dart';
import 'features/authentication/controller/register_controller.dart';
import 'features/projets/controllers/project_controller.dart';
import 'features/signalement/controllers/signalement_controller.dart';
import 'features/signalement/controllers/report_controller.dart';
import 'features/signalement/controllers/sync_report_controller.dart';
import 'features/finance/controllers/finance_controller.dart';
import 'features/finance/controllers/sync_transaction_controller.dart';
import 'features/cadre_de_vie/controllers/information_controller.dart';
import 'features/cadre_de_vie/controllers/information_submission_controller.dart';
import 'features/cadre_de_vie/controllers/sync_information_controller.dart';
import 'features/finance/controllers/contribution_controller.dart';
import 'features/finance/controllers/cash_movements_controller.dart';
import 'features/finance/controllers/payment_breakdown_controller.dart';
import 'core/services/connectivity_service.dart';
// import 'features/cotisations/controller/cotisations_controller.dart';
// import 'features/cotisations/controller/payment_proof_controller.dart';

/// 🎯 FONCTION DE VIDAGE DU MAÎTRE UNIQUEMENT (force resynchronisation)
Future<void> _clearMasterCacheOnly() async {
  try {
    debugPrint('🎯 [DEBUG] Vidage du cache MAÎTRE uniquement...');
    
    // Obtenir stats avant vidage
    final statsBefore = TransactionLocalStorageService.getCacheStats();
    debugPrint('📊 Stats AVANT vidage: ${statsBefore['checksums_count']} checksums, ${statsBefore['transactions_count']} transactions');
    
    // Vider seulement le cache du maître (TransactionLocalStorageService)
    await TransactionLocalStorageService.clearCache();
    debugPrint('✅ Cache du MAÎTRE vidé - resynchronisation forcée');
    
    // Vérifier que le vidage a fonctionné
    final statsAfter = TransactionLocalStorageService.getCacheStats();
    debugPrint('📊 Stats APRÈS vidage: ${statsAfter['checksums_count']} checksums, ${statsAfter['transactions_count']} transactions');
    
    debugPrint('ℹ️ [INFO] Les esclaves gardent leur cache - sync en cascade déclenchée');
  } catch (e) {
    debugPrint('❌ [DEBUG] Erreur lors du vidage du cache maître: $e');
    // Afficher plus de détails sur l'erreur
    debugPrint('🔍 [DEBUG] Détails erreur: $e');
  }
}

/// 🚨 FONCTION DE VIDAGE COMPLET DU CACHE FINANCE (pour debug uniquement)
/// À commenter après les tests
Future<void> _clearAllFinanceCache() async {
  try {
    debugPrint('🗑️ [DEBUG] Vidage complet du cache finance...');
    
    // Vider tous les caches de finance (avec try-catch pour chaque service)
    try {
      await TransactionLocalStorageService.clearCache();
      debugPrint('✅ TransactionLocalStorageService cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur TransactionLocalStorageService: $e');
    }
    
    try {
      await FinanceTotalsLocalStorageService.clearCachedTotals();
      debugPrint('✅ FinanceTotalsLocalStorageService cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur FinanceTotalsLocalStorageService: $e');
    }
    
    try {
      await PaymentStatisticsLocalStorageService.clearCache();
      debugPrint('✅ PaymentStatisticsLocalStorageService cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur PaymentStatisticsLocalStorageService: $e');
    }
    
    try {
      await PaymentOverviewLocalStorageService.clearCache();
      debugPrint('✅ PaymentOverviewLocalStorageService cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur PaymentOverviewLocalStorageService: $e');
    }
    
    try {
      await ContributionLocalStorageService.clearAllCaches();
      debugPrint('✅ ContributionLocalStorageService cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur ContributionLocalStorageService: $e');
    }
    
    try {
      await CashMovementsLocalStorageService.clearAllCache();
      debugPrint('✅ CashMovementsLocalStorageService cache vidé');
    } catch (e) {
      debugPrint('❌ Erreur CashMovementsLocalStorageService: $e');
    }
    
    debugPrint('✅ [DEBUG] Cache finance vidé complètement - simulation nouveau téléphone');
  } catch (e) {
    debugPrint('❌ [DEBUG] Erreur lors du vidage du cache: $e');
  }
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
  // Initialiser la base de données Hive
  await DatabaseInitializer.initialize();
  
  // Initialiser le stockage local des transactions (nécessaire avant le vidage)
  await TransactionLocalStorageService.initialize();
  
  // 🚨 VIDAGE COMPLET DU CACHE FINANCE (pour debug - à commenter après test)
  // ⚠️  COMMENTER/DÉCOMMENTER LA LIGNE CI-DESSOUS POUR TESTER NOUVEAU TÉLÉPHONE
  // await _clearAllFinanceCache(); // ❌ COMMENTÉ - vidage désactivé
  
  // 🎯 VIDAGE DU MAÎTRE UNIQUEMENT (force resynchronisation complète)
  await _clearMasterCacheOnly();
  
  // Initialiser le stockage local des totaux financiers
  await FinanceTotalsLocalStorageService.initialize();
  
  // Initialiser les services de cache des paiements
  await PaymentStatisticsLocalStorageService.initialize();
  await PaymentOverviewLocalStorageService.initialize();
  
  // Initialiser les services de cache des cotisations
  await ContributionLocalStorageService.initialize();
  
  // Initialiser le service de cache des mouvements de caisse
  await CashMovementsLocalStorageService.initialize();
  
  final router = AppRouter.createRouter();
  DioClient.setRouter(router);
  
  runApp(GestCityApp(router: router));
}

class GestCityApp extends StatefulWidget {
  final GoRouter router;
  
  const GestCityApp({super.key, required this.router});

  @override
  State<GestCityApp> createState() => _GestCityAppState();
}

class _GestCityAppState extends State<GestCityApp> with WidgetsBindingObserver {
  late AuthController _authController;
  late ConnectivityService _connectivityService;
  late ContributionController _contributionController;
  late CashMovementsController _cashMovementsController;
  late PaymentBreakdownController _paymentBreakdownController;
  
  bool _appWasPaused = false;
  bool _isBiometricInProgress = false;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _connectivityService = ConnectivityService();
    
    // Ajouter l'observer pour le cycle de vie de l'app
    WidgetsBinding.instance.addObserver(this);
    
    // 🎯 Initialiser les contrôleurs finance IMMÉDIATEMENT pour écouter le maître
    _contributionController = ContributionController()..initialize();
    _cashMovementsController = CashMovementsController()..initialize();
    _paymentBreakdownController = PaymentBreakdownController()..initialize();
    
    debugPrint('🎯 [BOOTSTRAP] Contrôleurs finance initialisés - écoute du maître active');
    
    // Démarrer le monitoring de la connexion
    _connectivityService.startMonitoring();
    
    // Configurer le callback pour les erreurs 401
    DioClient.setUnauthorizedCallback(() {
      _authController.forceLogout();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(
          value: _authController,
        ),
        ChangeNotifierProvider.value(
          value: _connectivityService,
        ),
        ChangeNotifierProvider(
          create: (_) => RegisterController(),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ProjectController(),
        ),
        ChangeNotifierProvider(
          create: (_) => SignalementController(),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportController(),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncReportController(),
        ),
        ChangeNotifierProvider(
          create: (_) => FinanceController(),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncTransactionController(),
        ),
        ChangeNotifierProvider(
          create: (_) => InformationController(),
        ),
        ChangeNotifierProvider(
          create: (_) => SyncInformationController(),
        ),
        ChangeNotifierProvider(
          create: (_) => InformationSubmissionController(),
        ),
        ChangeNotifierProvider.value(
          value: _contributionController,
        ),
        ChangeNotifierProvider.value(
          value: _cashMovementsController,
        ),
        ChangeNotifierProvider.value(
          value: _paymentBreakdownController,
        ),
        // ChangeNotifierProvider(
        //   create: (_) => CotisationsController(),
        // ),
        // ChangeNotifierProvider(
        //   create: (_) => PaymentProofController(),
        // ),
      ],
      child: MaterialApp.router(
        title: 'Gest City',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
          ),
        ),
        routerConfig: widget.router,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App mise en arrière-plan (sauf si biométrie en cours)
        if (!_isBiometricInProgress) {
          _appWasPaused = true;
          debugPrint('📱 App mise en arrière-plan - biométrie requise au retour');
        } else {
          debugPrint('📱 App pause ignorée - biométrie en cours');
        }
        break;
        
      case AppLifecycleState.resumed:
        // App revenue en premier plan (seulement si vraiment mise en pause)
        if (_appWasPaused && !_isBiometricInProgress) {
          _appWasPaused = false;
          debugPrint('📱 App revenue en premier plan - vérification biométrique...');
          _handleAppResume();
        } else if (_isBiometricInProgress) {
          debugPrint('📱 App resume ignorée - biométrie en cours');
        }
        break;
        
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Gère le retour de l'app en premier plan (comme WhatsApp)
  Future<void> _handleAppResume() async {
    // Vérifier si l'utilisateur était authentifié avant la pause
    if (_authController.isAuthenticated) {
      
      try {
        // Marquer la biométrie comme en cours pour éviter la boucle
        _isBiometricInProgress = true;
        
        debugPrint('🔐 [LIFECYCLE] App revenue - demande biométrie immédiate...');
        
        // Déclencher la biométrie directement (comme WhatsApp)
        final success = await _authController.processBiometricAuthentication();
        
        if (!success) {
          debugPrint('❌ [LIFECYCLE] Biométrie échec - logout');
          // Le routeur gèrera la redirection automatiquement
        } else {
          debugPrint('✅ [LIFECYCLE] Biométrie réussie');
        }
        
      } catch (e) {
        debugPrint('❌ [LIFECYCLE] Erreur biométrie: $e');
        await _authController.logout();
      } finally {
        // Toujours remettre les flags à false à la fin
        _isBiometricInProgress = false;
        _appWasPaused = false;
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.stopMonitoring();
    _contributionController.dispose();
    _cashMovementsController.dispose();
    _paymentBreakdownController.dispose();
    super.dispose();
  }
}