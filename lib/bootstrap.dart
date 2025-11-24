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
import 'core/services/app_lock_service.dart';
import 'core/services/security_settings_service.dart';
import 'core/widgets/biometric_lock_overlay.dart';
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
import 'core/services/unified_sync_service.dart';
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
  
  // ⚡ OPTIMISATION: Charger .env en parallèle avec l'initialisation DB
  final envFuture = dotenv.load(fileName: ".env");
  final dbFuture = DatabaseInitializer.initialize();
  
  await Future.wait([envFuture, dbFuture]);
  
  // ⚡ OPTIMISATION: Initialiser seulement les services critiques au démarrage
  await _initializeCriticalServices();
  
  // ⚡ OPTIMISATION: Lazy loading pour les autres services
  _initializeNonCriticalServices();
  
  final router = AppRouter.createRouter();
  DioClient.setRouter(router);
  
  runApp(GestCityApp(router: router));
}

/// Initialise uniquement les services critiques pour l'authentification
Future<void> _initializeCriticalServices() async {
  // Service de base pour les transactions (nécessaire pour auth)
  await TransactionLocalStorageService.initialize();
  
  // 🎯 VIDAGE DU MAÎTRE UNIQUEMENT (force resynchronisation complète)
  await _clearMasterCacheOnly();
}

/// Initialise les services non-critiques en arrière-plan (lazy loading)
void _initializeNonCriticalServices() {
  // Lancer l'initialisation en arrière-plan sans bloquer l'UI
  Future.microtask(() async {
    try {
      await Future.wait([
        FinanceTotalsLocalStorageService.initialize(),
        PaymentStatisticsLocalStorageService.initialize(),
        PaymentOverviewLocalStorageService.initialize(),
        ContributionLocalStorageService.initialize(),
        CashMovementsLocalStorageService.initialize(),
      ]);
      debugPrint('✅ [BOOTSTRAP] Services non-critiques initialisés en arrière-plan');
    } catch (e) {
      debugPrint('⚠️ [BOOTSTRAP] Erreur initialisation services non-critiques: $e');
    }
  });
}

class GestCityApp extends StatefulWidget {
  final GoRouter router;
  
  const GestCityApp({super.key, required this.router});

  @override
  State<GestCityApp> createState() => GestCityAppState();
}

class GestCityAppState extends State<GestCityApp> with WidgetsBindingObserver {
  late AuthController _authController;
  late ConnectivityService _connectivityService;
  late ContributionController _contributionController;
  late CashMovementsController _cashMovementsController;
  late PaymentBreakdownController _paymentBreakdownController;
  late UnifiedSyncService _unifiedSyncService;
  
  // Variables pour la gestion du lifecycle simplifié
  bool _appWasInBackground = false;

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
    _unifiedSyncService = UnifiedSyncService();
    
    debugPrint('🎯 [BOOTSTRAP] Contrôleurs finance et services projets initialisés - écoute du maître active');
    
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
        ChangeNotifierProvider.value(
          value: _unifiedSyncService,
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
        builder: (context, child) {
          return ValueListenableBuilder<bool>(
            valueListenable: AppLockService.isLocked,
            builder: (context, isLocked, routerChild) {
              return Stack(
                children: [
                  // Application principale
                  child ?? const SizedBox.shrink(),
                  
                  // Overlay biométrique (comme WhatsApp)
                  if (isLocked)
                    const BiometricLockOverlay(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
        // App mise en arrière-plan → vérifier si lock nécessaire
        _appWasInBackground = true;
        _handleAppPause();
        break;
        
      case AppLifecycleState.resumed:
        // App revenue en premier plan → le lock overlay gère automatiquement l'authentification
        if (_appWasInBackground) {
          _appWasInBackground = false;
          debugPrint('🔓 [LIFECYCLE] App revenue - overlay biométrique actif si nécessaire');
        }
        break;
        
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        break;
    }
  }

  /// Gère la mise en arrière-plan (WhatsApp-like)
  Future<void> _handleAppPause() async {
    final isAuthenticated = _authController.status == AuthStatus.authenticated;
    
    if (!isAuthenticated) {
      debugPrint('🔒 [LIFECYCLE] User non authentifié - pas de lock');
      return;
    }
    
    // Vérifier les préférences utilisateur
    try {
      final shouldLock = await SecuritySettingsService.shouldActivateAppLock();
      
      if (shouldLock) {
        AppLockService.lock();
        debugPrint('🔒 [LIFECYCLE] App en arrière-plan - lock overlay activé');
      } else {
        debugPrint('🔒 [LIFECYCLE] User n\'a pas activé de sécurité - pas de lock (comme WhatsApp)');
      }
    } catch (e) {
      debugPrint('🔒 [LIFECYCLE] Erreur vérification préférences: $e');
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivityService.stopMonitoring();
    _contributionController.dispose();
    _cashMovementsController.dispose();
    _paymentBreakdownController.dispose();
    _unifiedSyncService.dispose();
    super.dispose();
  }
}