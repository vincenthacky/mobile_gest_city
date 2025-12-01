import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/app_lock_service.dart';
import '../services/biometric_auth_service.dart';
import '../services/security_settings_service.dart';
import '../utils/app_router.dart';
import '../../features/authentification/controller/auth_controller.dart';

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
  
  // Contrôleur pour la saisie du PIN directement sur l'overlay
  final TextEditingController _pinController = TextEditingController();

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
      // Pour la biométrie, attendre que l'overlay soit complètement affiché
      // avant de lancer l'authentification (Samsung nécessite délai)
      if (_lockType == LockType.biometric) {
        // Délai pour laisser l'overlay se stabiliser avant biométrie
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) {
          _authenticateUser();
        }
      }
    }
  }

  Future<void> _authenticateUser() async {
    if (AppLockService.isAuthInProgress) return;
    
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    
    AppLockService.startAuthentication();
    
    // 🚀 OPTIMISÉ: Timeout étendu pour empreintes écran Android
    final timeout = Duration(seconds: 60); // Plus long pour empreintes intégrées
    final timeoutFuture = Future.delayed(timeout, () => throw TimeoutException('Authentification timeout', timeout));

    try {
      // 🚀 OPTIMISÉ: Utiliser Future.any pour gérer le timeout
      final authFuture = _performAuthentication();
      final result = await Future.any([authFuture, timeoutFuture]);
      final success = result;

      if (success) {
        // Succès → Retirer l'overlay ET changer le statut auth
        AppLockService.unlock();
        _pinController.clear();
        
        // CRUCIAL : Dire à AuthController que l'authentification est réussie
        // Utiliser le contexte principal de l'app via navigatorKey
        final mainContext = navigatorKey.currentContext;
        if (mainContext != null && mainContext.mounted) {
          try {
            final authController = Provider.of<AuthController>(mainContext, listen: false);
            authController.setStatus(AuthStatus.authenticated);
            debugPrint('🔐 [OVERLAY] Statut auth changé vers AUTHENTICATED');
          } catch (e) {
            debugPrint('❌ [OVERLAY] Erreur changement statut: $e');
          }
        } else {
          debugPrint('❌ [OVERLAY] Context principal non disponible');
        }
      } else {
        // Échec → Afficher l'erreur
        setState(() {
          _hasError = true;
        });
        AppLockService.isAuthenticating.value = false;
      }
    } on TimeoutException catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Délai d\'authentification dépassé. Veuillez réessayer.';
      });
      AppLockService.isAuthenticating.value = false;
      debugPrint('⏰ [OVERLAY] Timeout authentification: ${e.message}');
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Erreur d\'authentification: $e';
      });
      AppLockService.isAuthenticating.value = false;
      debugPrint('❌ [OVERLAY] Erreur: $e');
    }
  }

  /// 🚀 OPTIMISÉ: Logique d'authentification séparée avec gestion d'erreurs améliorée
  Future<bool> _performAuthentication() async {
    try {
      if (_lockType == LockType.biometric) {
        // Diagnostic préalable pour optimiser l'authentification
        final diagnostic = await BiometricAuthService.diagnosticBiometrics();
        debugPrint('🔍 [OVERLAY] Diagnostic biométrie: $diagnostic');
        
        // Authentification biométrique optimisée pour tous types d'empreintes
        final result = await BiometricAuthService.authenticate(
          localizedReason: 'Déverrouiller Gest City pour accéder à vos données',
          useErrorDialogs: true, // CRUCIAL: afficher les dialogues système
          stickyAuth: true, // Maintient l'authentification active
        );
        if (!result.isSuccess) {
          _errorMessage = result.message;
        }
        return result.isSuccess;
      } else if (_lockType == LockType.pin) {
        // Authentification PIN via champ de saisie sur l'overlay
        final pin = _pinController.text.trim();
        debugPrint('🔐 [OVERLAY] Tentative authentification PIN - longueur: ${pin.length}');
        
        if (pin.isEmpty) {
          _errorMessage = 'Veuillez entrer votre code PIN';
          setState(() {
            _hasError = true;
          });
          return false;
        }
        
        if (pin.length != 4) {
          _errorMessage = 'Le code PIN doit contenir 4 chiffres';
          setState(() {
            _hasError = true;
          });
          return false;
        }
        
        final isValid = await SecuritySettingsService.verifyPin(pin);
        debugPrint('🔐 [OVERLAY] Vérification PIN résultat: $isValid');
        if (!isValid) {
          _errorMessage = 'Code PIN incorrect';
          _pinController.clear(); // Effacer le champ en cas d'erreur
        }
        return isValid;
      } else {
        // Aucun lock défini → débloquer directement
        return true;
      }
    } catch (e) {
      debugPrint('❌ [OVERLAY] Erreur _performAuthentication: $e');
      _errorMessage = 'Erreur lors de l\'authentification';
      return false;
    }
  }



  String _getInstructionText() {
    switch (_lockType) {
      case LockType.biometric:
        return 'Utilisez votre empreinte/Face ID pour déverrouiller l\'application';
      case LockType.pin:
        return 'Entrez votre code PIN pour déverrouiller l\'application';
      case LockType.none:
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
        return 'Déverrouiller';
    }
  }

  void _showOptionsDialog() {
    // Utiliser le navigator global pour éviter l'erreur de contexte sans Navigator
    final ctx = navigatorKey.currentContext ?? context;
    showDialog(
      context: ctx,
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
            onPressed: () async {
              Navigator.of(context).pop();
              // Déconnexion complète en cas de problème persistant
              final mainContext = navigatorKey.currentContext;
              if (mainContext != null && mainContext.mounted) {
                try {
                  final authController = Provider.of<AuthController>(mainContext, listen: false);
                  await authController.forceLogout();
                  debugPrint('🔐 [OVERLAY] Déconnexion forcée suite à problème auth');
                } catch (e) {
                  debugPrint('❌ [OVERLAY] Erreur déconnexion forcée: $e');
                }
              }
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
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final containerSize = isSmallScreen ? screenSize.width * 0.25 : screenSize.width * 0.3;
    final iconSize = containerSize * 0.6;

    // Utiliser Material au lieu de MaterialApp pour éviter de bloquer les dialogues système
    return Material(
      color: const Color(0xFF1F2937), // Fond sombre comme WhatsApp
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenSize.width * 0.06, // Responsive horizontal padding
              vertical: screenSize.height * 0.02,  // Responsive vertical padding
            ),
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenSize.height - (MediaQuery.of(context).padding.top + MediaQuery.of(context).padding.bottom + (screenSize.height * 0.04)),
                ),
                child: IntrinsicHeight(
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
              
              SizedBox(height: isSmallScreen ? screenSize.height * 0.03 : screenSize.height * 0.04),

              // Titre de l'application
              Text(
                'Gest City',
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 26 : 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? screenSize.height * 0.015 : screenSize.height * 0.02),

              // Instructions adaptées au type de lock
              Text(
                _getInstructionText(),
                style: GoogleFonts.nunito(
                  fontSize: isSmallScreen ? 14 : 18,
                  color: const Color(0xFFC0C7D0),
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: isSmallScreen ? screenSize.height * 0.04 : screenSize.height * 0.06),

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
                        SizedBox(height: isSmallScreen ? 16 : 24),
                        Text(
                          'Authentification en cours...',
                          style: GoogleFonts.nunito(
                            fontSize: isSmallScreen ? 14 : 16,
                            color: const Color(0xFFC0C7D0),
                          ),
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      // Icône principale adaptée au type de lock
                      Container(
                        height: isSmallScreen ? 60 : 80,
                        width: isSmallScreen ? 60 : 80,
                        decoration: const BoxDecoration(
                          color: Color(0xFF3B82F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getLockIcon(),
                          size: isSmallScreen ? 30 : 40,
                          color: Colors.white,
                        ),
                      ),
                      
                      SizedBox(height: isSmallScreen ? 16 : 24),
                      
                      // Si lock par PIN, afficher directement un champ de saisie
                      if (_lockType == LockType.pin) ...[
                        Material(
                          color: Colors.transparent,
                          child: TextField(
                            controller: _pinController,
                            decoration: InputDecoration(
                              hintText: 'Code PIN (4 chiffres)',
                              hintStyle: GoogleFonts.nunito(
                                color: const Color(0xFF9CA3AF),
                              ),
                              border: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              enabledBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24),
                              ),
                              focusedBorder: const OutlineInputBorder(
                                borderSide: BorderSide(color: Color(0xFF3B82F6)),
                              ),
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.1),
                            ),
                            style: GoogleFonts.nunito(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 8,
                            ),
                            keyboardType: TextInputType.number,
                            maxLength: 4,
                            obscureText: true,
                            textAlign: TextAlign.center,
                            onSubmitted: (value) {
                              if (value.length == 4) {
                                _authenticateUser();
                              }
                            },
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 12 : 16),
                      ],
                      
                      // Bouton principal (texte et icône selon le type de lock)
                      ElevatedButton(
                        onPressed: _authenticateUser,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 24 : 32, 
                            vertical: isSmallScreen ? 12 : 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getLockIcon(),
                              size: isSmallScreen ? 16 : 20,
                            ),
                            SizedBox(width: isSmallScreen ? 6 : 8),
                            Text(
                              _getButtonText(),
                              style: GoogleFonts.nunito(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Message d'erreur si applicable
                      if (_hasError) ...[
                        SizedBox(height: isSmallScreen ? 12 : 16),
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            _errorMessage.isNotEmpty ? _errorMessage : 'Erreur d\'authentification',
                            style: GoogleFonts.nunito(
                              fontSize: isSmallScreen ? 12 : 14,
                              color: Colors.red.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 6 : 8),
                        TextButton(
                          onPressed: _showOptionsDialog,
                          child: Text(
                            'Problème d\'authentification ?',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
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
            ),
          ),
        ),
      ),
    );
  }
}