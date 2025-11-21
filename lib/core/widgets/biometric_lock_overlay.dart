import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/app_lock_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/security_settings_service.dart';

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
  LockType _lockType = LockType.none;

  @override
  void initState() {
    super.initState();
    // Déterminer le type de lock et lancer l'authentification
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAndAuthenticate();
    });
  }

  Future<void> _initializeAndAuthenticate() async {
    // Déterminer le type de verrouillage préféré
    _lockType = await SecuritySettingsService.getPreferredLockType();
    debugPrint('🔐 [OVERLAY] Type de lock déterminé: $_lockType');
    
    if (mounted) {
      setState(() {});
      _authenticateUser();
    }
  }

  Future<void> _authenticateUser() async {
    if (AppLockService.isAuthInProgress) return;
    
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    
    AppLockService.startAuthentication();

    try {
      bool success = false;

      if (_lockType == LockType.biometric) {
        // Authentification biométrique
        final result = await BiometricAuthService.authenticate(
          localizedReason: 'Déverrouiller Gest City pour accéder à vos données',
          useErrorDialogs: false,
          stickyAuth: true,
        );
        success = result.isSuccess;
        if (!success) {
          _errorMessage = result.message;
        }
      } else if (_lockType == LockType.pin) {
        // Authentification PIN
        final pin = await _showPinDialog();
        if (pin != null) {
          success = await _verifyPin(pin);
          if (!success) {
            _errorMessage = 'Code PIN incorrect';
          }
        } else {
          _errorMessage = 'Code PIN requis';
        }
      } else {
        // Aucun lock défini → débloquer directement
        success = true;
      }

      if (success) {
        // Succès → Retirer l'overlay
        AppLockService.unlock();
      } else {
        // Échec → Afficher l'erreur
        setState(() {
          _hasError = true;
        });
        AppLockService.isAuthenticating.value = false;
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur d\'authentification: $e';
      });
      AppLockService.isAuthenticating.value = false;
      debugPrint('❌ [OVERLAY] Erreur: $e');
    }
  }

  Future<String?> _showPinDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Code PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez votre code PIN pour déverrouiller l\'application'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Code PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onSubmitted: (value) => Navigator.of(context).pop(value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );
  }

  Future<bool> _verifyPin(String enteredPin) async {
    final prefs = await SecuritySettingsService.getPreferences();
    return prefs.appPin == enteredPin;
  }

  String _getInstructionText() {
    switch (_lockType) {
      case LockType.biometric:
        return 'Utilisez votre empreinte/Face ID pour déverrouiller l\'application';
      case LockType.pin:
        return 'Entrez votre code PIN pour déverrouiller l\'application';
      case LockType.none:
      default:
        return 'Déverrouillez votre application pour accéder à vos données';
    }
  }

  IconData _getLockIcon() {
    switch (_lockType) {
      case LockType.biometric:
        return Icons.fingerprint;
      case LockType.pin:
        return Icons.pin;
      case LockType.none:
      default:
        return Icons.lock;
    }
  }

  String _getButtonText() {
    switch (_lockType) {
      case LockType.biometric:
        return 'Utiliser biométrie';
      case LockType.pin:
        return 'Entrer le code';
      case LockType.none:
      default:
        return 'Déverrouiller';
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

              // Instructions adaptées au type de lock
              Text(
                _getInstructionText(),
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