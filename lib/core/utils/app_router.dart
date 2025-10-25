import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/authentication/controller/auth_controller.dart';
import '../../features/authentication/presentation/pages/splash_page.dart';
import '../../features/authentication/presentation/pages/login_page.dart';
import '../../features/authentication/presentation/pages/register_page.dart';
import '../../features/authentication/presentation/pages/forgot_password_page.dart';
import '../pages/home_page.dart';
import '../../features/compte/presentation/pages/compte_page.dart';
import '../../features/cotisations/presentation/pages/cotisations_page.dart';
import '../../features/projets/presentation/pages/projets_page.dart';
import '../widgets/main_layout.dart';

class AppRouter {
  static GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/',
      redirect: (context, state) {
        final authController = context.read<AuthController>();
        final isAuthenticated = authController.isAuthenticated;
        final isLoading = authController.status == AuthStatus.initial || 
                         authController.status == AuthStatus.loading;

        // Pendant le chargement, ne pas rediriger
        if (isLoading) {
          return null;
        }

        final isGoingToLogin = state.matchedLocation == '/login';
        final isGoingToRegister = state.matchedLocation == '/register';
        final isGoingToForgotPassword = state.matchedLocation == '/forgot-password';

        // Si pas authentifié et pas sur login/register/forgot-password, rediriger vers login
        if (!isAuthenticated && !isGoingToLogin && !isGoingToRegister && !isGoingToForgotPassword) {
          return '/login';
        }

        // Si authentifié et sur login/register/forgot-password, rediriger vers home
        if (isAuthenticated && (isGoingToLogin || isGoingToRegister || isGoingToForgotPassword)) {
          return '/home';
        }

        return null;
      },
      refreshListenable: RouterRefreshNotifier(),
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (context, state) => const RegisterPage(),
        ),
        GoRoute(
          path: '/forgot-password',
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordPage(),
        ),
        ShellRoute(
          builder: (context, state, child) => MainLayout(
            currentPath: state.matchedLocation,
            child: child,
          ),
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/cotisations',
              name: 'cotisations',
              builder: (context, state) => const CotisationsPage(),
            ),
            GoRoute(
              path: '/projets',
              name: 'projets',
              builder: (context, state) => const ProjetsPage(),
            ),
            GoRoute(
              path: '/compte',
              name: 'compte',
              builder: (context, state) => const ComptePage(),
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
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
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
  RouterRefreshNotifier() {
    _init();
  }

  late AuthController _authController;

  void _init() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentContext != null) {
        _authController = Provider.of<AuthController>(
          navigatorKey.currentContext!,
          listen: false,
        );
        _authController.addListener(notifyListeners);
      }
    });
  }

  @override
  void dispose() {
    _authController.removeListener(notifyListeners);
    super.dispose();
  }
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();