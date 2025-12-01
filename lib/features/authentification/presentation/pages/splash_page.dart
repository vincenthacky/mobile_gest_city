import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controller/auth_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Décaler l'appel après la construction pour éviter setState pendant build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuth();
    });
  }

  Future<void> _checkAuth() async {
    debugPrint('🚀 [SPLASH] Appel méthode suprême...');
    final authController = context.read<AuthController>();
    
    // Appeler la méthode suprême unique
    await authController.initializeAppAuthentication();
    
    if (mounted) {
      debugPrint('🚀 [SPLASH] Initialisation terminée - statut: ${authController.status}');
      
      // Redirection manuelle selon le statut final
      switch (authController.status) {
        case AuthStatus.authenticated:
          debugPrint('🚀 [SPLASH] Redirection vers /home');
          context.go('/home');
          break;
          
        case AuthStatus.biometricRequired:
          debugPrint('🚀 [SPLASH] Redirection vers /biometric-auth');
          context.go('/biometric-auth');
          break;
          
        case AuthStatus.unauthenticated:
        case AuthStatus.error:
          debugPrint('🚀 [SPLASH] Redirection vers /onboarding');
          context.go('/onboarding');
          break;
          
        case AuthStatus.initial:
        case AuthStatus.loading:
          // Rester sur splash
          debugPrint('🚀 [SPLASH] Statut en attente - reste sur splash');
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final containerSize = isSmallScreen ? screenSize.width * 0.25 : screenSize.width * 0.3;
    final iconSize = containerSize * 0.53;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: containerSize,
              width: containerSize,
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.account_balance,
                size: iconSize,
                color: const Color(0xFF4F46E5),
              ),
            ),
            SizedBox(height: screenSize.height * 0.04),
            Text(
              'Gest City',
              style: TextStyle(
                fontSize: isSmallScreen ? 28 : 32,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1F2937),
              ),
            ),
            SizedBox(height: screenSize.height * 0.01),
            Text(
              'Gestion communautaire simplifiée',
              style: TextStyle(
                fontSize: isSmallScreen ? 14 : 16,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenSize.height * 0.06),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
            ),
          ],
        ),
      ),
    );
  }
}