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
  
  // 🚨 VIDAGE COMPLET DU CACHE FINANCE (pour debug - à commenter après test)
  // ⚠️  COMMENTER/DÉCOMMENTER LA LIGNE CI-DESSOUS POUR TESTER NOUVEAU TÉLÉPHONE
  // await _clearAllFinanceCache(); // ❌ COMMENTÉ - vidage désactivé
  
  // Initialiser le stockage local des transactions
  await TransactionLocalStorageService.initialize();
  
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

class _GestCityAppState extends State<GestCityApp> {
  late AuthController _authController;
  late ConnectivityService _connectivityService;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _connectivityService = ConnectivityService();
    
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
        ChangeNotifierProvider(
          create: (_) => ContributionController(),
        ),
        ChangeNotifierProvider(
          create: (_) => CashMovementsController(),
        ),
        ChangeNotifierProvider(
          create: (_) => PaymentBreakdownController(),
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
  void dispose() {
    _connectivityService.stopMonitoring();
    super.dispose();
  }
}