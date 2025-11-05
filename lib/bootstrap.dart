import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'core/network/dio_client.dart';
import 'core/utils/app_router.dart';
import 'core/controller/home_controller.dart';
import 'features/authentication/controller/auth_controller.dart';
import 'features/authentication/controller/register_controller.dart';
import 'features/projets/controllers/project_controller.dart';
import 'features/signalement/controllers/signalement_controller.dart';
import 'features/signalement/controllers/report_controller.dart';
import 'features/finance/controllers/finance_controller.dart';
import 'features/cadre_de_vie/controllers/information_controller.dart';
import 'features/cadre_de_vie/controllers/information_submission_controller.dart';
import 'features/finance/controllers/contribution_controller.dart';
import 'features/finance/controllers/cash_movements_controller.dart';
import 'features/finance/controllers/payment_breakdown_controller.dart';
// import 'features/cotisations/controller/cotisations_controller.dart';
// import 'features/cotisations/controller/payment_proof_controller.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await dotenv.load(fileName: ".env");
  
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

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    
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
          create: (_) => FinanceController(),
        ),
        ChangeNotifierProvider(
          create: (_) => InformationController(),
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
}