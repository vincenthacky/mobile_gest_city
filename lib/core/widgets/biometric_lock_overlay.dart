import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_lock_service.dart';
import '../services/biometric_auth_service.dart';

/// Overlay de verrouillage biométrique (comme WhatsApp)
/// S'affiche au-dessus de l'application quand elle est verrouillée
class BiometricLockOverlay extends StatefulWidget {
  const BiometricLockOverlay({super.key});

  @override
  State<BiometricLockOverlay> createState() => _BiometricLockOverlayState();
}

class _BiometricLockOverlayState extends State<BiometricLockOverlay> {
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    // Lancer l'authentification automatiquement à l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticateUser();
    });
  }

  Future<void> _authenticateUser() async {
    if (AppLockService.isAuthInProgress) return;
    
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    
    AppLockService.startAuthentication();

    try {
      final result = await BiometricAuthService.authenticate(
        localizedReason: 'Déverrouiller Gest City pour accéder à vos données',
        useErrorDialogs: false, // Gérer nous-mêmes les erreurs
        stickyAuth: true, // Garder actif jusqu'à succès/annulation
      );

      if (result.isSuccess) {
        // Succès → Retirer l'overlay (plus besoin de communiquer avec Bootstrap)
        AppLockService.unlock();
      } else {
        // Échec → Afficher l'erreur et permettre de réessayer
        setState(() {
          _hasError = true;
          _errorMessage = result.message;
        });
        AppLockService.isAuthenticating.value = false;
      }
    } catch (e) {
      // Erreur inattendue
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur d\'authentification: $e';
      });
      AppLockService.isAuthenticating.value = false;
      debugPrint('❌ [BIOMETRIC OVERLAY] Erreur: $e');
    }
  }

  void _showOptionsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF374151),
        title: Text(
          'Authentification requise',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _errorMessage,
              style: GoogleFonts.nunito(
                fontSize: 16,
                color: const Color(0xFFC0C7D0),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Que souhaitez-vous faire ?',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _authenticateUser();
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
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implémenter la déconnexion complète si nécessaire
              // authController.forceLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(
              'Déconnecter',
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

    return Container(
      color: const Color(0xFF1F2937), // Fond sombre comme WhatsApp
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de l'application
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

              // Titre de l'application
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
                'Déverrouillez votre application pour accéder à vos données',
                style: GoogleFonts.nunito(
                  fontSize: isSmallScreen ? 16 : 18,
                  color: const Color(0xFFC0C7D0),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: screenSize.height * 0.06),

              // État de l'authentification
              ValueListenableBuilder<bool>(
                valueListenable: AppLockService.isAuthenticating,
                builder: (context, isAuth, child) {
                  if (isAuth) {
                    return Column(
                      children: [
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
                    );
                  }

                  return Column(
                    children: [
                      // Icône biométrique
                      Container(
                        height: 80,
                        width: 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Bouton principal
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
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fingerprint),
                            const SizedBox(width: 8),
                            Text(
                              'Déverrouiller',
                              style: GoogleFonts.nunito(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Bouton d'options si erreur
                      if (_hasError) ...[
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _showOptionsDialog,
                          child: Text(
                            'Problème d\'authentification ?',
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              color: Colors.red.shade300,
                            ),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}