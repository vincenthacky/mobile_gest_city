import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controller/auth_controller.dart';
import '../../../../core/services/biometric_auth_service.dart';

/// Page d'authentification biométrique (comme WhatsApp)
/// Affichée quand l'app revient en premier plan et que des secrets sont stockés
class BiometricAuthPage extends StatefulWidget {
  const BiometricAuthPage({super.key});

  @override
  State<BiometricAuthPage> createState() => _BiometricAuthPageState();
}

class _BiometricAuthPageState extends State<BiometricAuthPage> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Demander immédiatement la biométrie à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  Future<void> _authenticateUser() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final authController = Provider.of<AuthController>(context, listen: false);
      final success = await authController.processBiometricAuthentication();

      if (!mounted) return;

      if (success) {
        // Authentification réussie → redirection manuelle immédiate
        debugPrint('🔐 [BIOMETRIC PAGE] Authentification réussie - fin session sécurité');
        
        // ANCIEN SYSTÈME: Communiquer avec Bootstrap - plus nécessaire avec overlay system
        
        if (mounted) {
          context.go('/home');
        }
      } else {
        // Authentification échouée
        _showAuthFailedDialog(BiometricAuthResult.failed);
      }
    } catch (e) {
      debugPrint('❌ Erreur authentification biométrique: $e');
      if (mounted) {
        _showAuthFailedDialog(BiometricAuthResult.failed);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showAuthFailedDialog(BiometricAuthResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Authentification échouée',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.message,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: const Color(0xFF374151),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Que souhaitez-vous faire ?',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _authenticateUser(); // Réessayer
            },
            child: Text(
              'Réessayer',
              style: GoogleFonts.nunito(
                color: const Color(0xFF3B82F6),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final router = GoRouter.of(context);
              final authController = Provider.of<AuthController>(context, listen: false);
              
              navigator.pop();
              // Reset complet et retour à l'onboarding
              await authController.logout();
              if (mounted) {
                router.go('/onboarding');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Réinitialiser',
              style: GoogleFonts.nunito(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final containerSize = isSmallScreen ? screenSize.width * 0.25 : screenSize.width * 0.3;
    final iconSize = containerSize * 0.6;

    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de l'app
              Container(
                height: containerSize,
                width: containerSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.account_balance,
                  size: iconSize,
                  color: const Color(0xFF3B82F6),
                ),
              ),
              
              SizedBox(height: screenSize.height * 0.04),

              // Titre
              Text(
                'Gest City',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 28 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenSize.height * 0.02),

              // Instructions
              Text(
                'Veuillez vous authentifier pour accéder à votre compte',
                style: GoogleFonts.nunito(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: const Color(0xFFC0C7D0),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenSize.height * 0.06),

              // Icône biométrique
              if (!_isLoading) ...[
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.fingerprint,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bouton réessayer
                ElevatedButton(
                  onPressed: _authenticateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    'Authentifier',
                    style: GoogleFonts.nunito(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ] else ...[
                // Loading indicator
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  'Authentification en cours...',
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: const Color(0xFFC0C7D0),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}