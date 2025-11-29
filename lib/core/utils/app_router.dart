import 'package:flutter/material.dart';
import 'package:gest_city/features/admin/presentation/pages/admin_dashboard.dart';
import 'package:gest_city/features/admin/presentation/pages/payments_page.dart';
import 'package:gest_city/features/admin/presentation/pages/qr_scan_admin_page.dart';
import 'package:gest_city/features/admin/presentation/pages/qr_validate_payment_page.dart';
import 'package:gest_city/features/admin/models/admin_payment_model.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/authentication/controller/auth_controller.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../../features/authentication/presentation/pages/onboarding_page.dart';
import '../../features/authentication/presentation/pages/onboarding_choice_page.dart';
import '../../features/authentication/presentation/pages/qr_scan_page.dart'
    as auth_qr;
import '../../features/authentication/presentation/pages/biometric_auth_page.dart';
import '../pages/home_page.dart';
import '../../features/finance/presentation/pages/finance_page.dart';
import '../../features/projets/presentation/pages/projets_page.dart';
import '../../features/projets/presentation/pages/create_project_page.dart';
import '../pages/unified_sync_page.dart';
import '../../features/signalement/presentation/pages/signalements_page.dart';
import '../../features/signalement/presentation/pages/ajouter_signalement_page.dart';
import '../../features/cadre_de_vie/presentation/pages/cadre_de_vie_page.dart';
import '../../features/compte/presentation/pages/compte_page.dart';
import '../widgets/main_layout.dart';

class AppRouter {
  static final _routerRefreshNotifier = RouterRefreshNotifier();

  static GoRouter createRouter() {
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      redirect: (context, state) {
        final authController = context.read<AuthController>();
        final currentPath = state.matchedLocation;
        final status = authController.status;

        // Initialiser le notifier pour qu'il écoute les changements
        _routerRefreshNotifier.ensureInitialized(context);

        debugPrint('🌐 [ROUTER] Path: $currentPath, Status: $status');

        // Ne pas rediriger pendant le chargement ou depuis splash
        if (status == AuthStatus.loading ||
            status == AuthStatus.initial ||
            currentPath == '/') {
          return null;
        }

        final isOnAuthPages =
            currentPath == '/login' ||
            currentPath == '/register' ||
            currentPath == '/forgot-password' ||
            currentPath == '/qr-scan';
        final isOnOnboardingPages =
            currentPath == '/onboarding' || currentPath == '/onboarding/choice';
        final isOnBiometricAuth = currentPath == '/biometric-auth';

        // Redirection selon le statut déterminé par la méthode suprême
        switch (status) {
          case AuthStatus.authenticated:
            // User authentifié → home SEULEMENT depuis pages d'auth/onboarding
            if (isOnAuthPages || isOnOnboardingPages || isOnBiometricAuth) {
              return '/home';
            }
            // Si déjà dans l'app (home, signalements, etc.) → laisser naviguer
            break;

          case AuthStatus.biometricRequired:
            // Device auth trouvé, biométrie requise
            // ANCIEN: Navigation vers /biometric-auth
            // NOUVEAU: L'overlay biométrique gère cela directement
            if (!isOnBiometricAuth) {
              return '/biometric-auth';
            }
            break;

          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            // Aucune auth → onboarding (sauf si sur pages d'auth)
            if (!isOnOnboardingPages && !isOnAuthPages) {
              return '/onboarding';
            }
            break;

          case AuthStatus.initial:
          case AuthStatus.loading:
            // Ne pas rediriger
            break;
        }

        return null;
      },
      refreshListenable: _routerRefreshNotifier,
      routes: [
        GoRoute(
          path: '/onboarding',
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),
        GoRoute(
          path: '/onboarding/choice',
          name: 'onboarding-choice',
          builder: (context, state) => const OnboardingChoicePage(),
        ),
        GoRoute(
          path: '/qr-scan',
          name: 'qr-scan',
          builder: (context, state) => const auth_qr.QrScanPage(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) {
            final villaId = state.uri.queryParameters['villa_id'];
            return RegisterPage(villaId: villaId);
          },
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        GoRoute(
          path: '/biometric-auth',
          name: 'biometric-auth',
          builder: (context, state) => const BiometricAuthPage(),
        ),
        // Routes admin sans navbar
        GoRoute(
          path: '/admin/scan-qr',
          name: 'admin-scan-qr',
          builder: (context, state) => const QRScanAdminPage(),
        ),
        GoRoute(
          path: '/admin/qr-validate',
          name: 'admin-qr-validate',
          builder: (context, state) {
            final userData = state.extra as QRUserData;
            return QRValidatePaymentPage(userData: userData);
          },
        ),
        ShellRoute(
          builder: (context, state, child) =>
              MainLayout(currentPath: state.matchedLocation, child: child),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/finance',
              name: 'finance',
              builder: (context, state) => const FinancePage(),
            ),
            GoRoute(
              path: '/projets',
              name: 'projets',
              builder: (context, state) => const ProjetsPage(),
            ),
            GoRoute(
              path: '/projets/ajouter',
              name: 'ajouter-projet',
              builder: (context, state) => const CreateProjectPage(),
            ),
            GoRoute(
              path: '/signalements',
              name: 'signalements',
              builder: (context, state) => const SignalementsPage(),
            ),
            GoRoute(
              path: '/signalements/ajouter',
              name: 'ajouter-signalement',
              builder: (context, state) => const AjouterSignalementPage(),
            ),
            GoRoute(
              path: '/cadre-de-vie',
              name: 'cadre-de-vie',
              builder: (context, state) => const CadreDeViePage(),
            ),
            GoRoute(
              path: '/compte',
              name: 'compte',
              builder: (context, state) => const ComptePage(),
            ),
            GoRoute(
              path: '/pending-sync',
              name: 'pending-sync',
              builder: (context, state) => const UnifiedSyncPage(),
            ),
            GoRoute(
              path: '/admin',
              name: 'admin',
              builder: (context, state) => const AdminDashboard(),
            ),
            GoRoute(
              path: '/admin/payments',
              name: 'admin-payments',
              builder: (context, state) => const PaymentsPage(),
            ),
          ],
        ),
        GoRoute(
          path: '/',
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),
      ],
      errorBuilder: (context, state) => Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(
                'Page non trouvée',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'La page "${state.matchedLocation}" n\'existe pas.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.go('/home'),
                child: const Text('Retour à l\'accueil'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RouterRefreshNotifier extends ChangeNotifier {
  AuthController? _authController;
  bool _isInitialized = false;

  void _initialize(BuildContext context) {
    if (!_isInitialized) {
      _authController = Provider.of<AuthController>(context, listen: false);
      _authController!.addListener(notifyListeners);
      _isInitialized = true;
      debugPrint('🌐 [ROUTER NOTIFIER] Initialisé et écoute AuthController');
    }
  }

  /// Méthode appelée par AppRouter pour s'initialiser si besoin
  void ensureInitialized(BuildContext context) {
    _initialize(context);
  }

  @override
  void dispose() {
    _authController?.removeListener(notifyListeners);
    super.dispose();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
