import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../authentification/controller/auth_controller.dart';
import '../../../../core/services/security_settings_service.dart';

class ComptePage extends StatefulWidget {
  const ComptePage({super.key});

  @override
  State<ComptePage> createState() => _ComptePageState();
}

class _ComptePageState extends State<ComptePage> {
  SecurityPreferences? _securityPrefs;

  @override
  void initState() {
    super.initState();
    _loadSecurityPreferences();
  }

  Future<void> _loadSecurityPreferences() async {
    final prefs = await SecuritySettingsService.getPreferences();
    if (mounted) {
      setState(() {
        _securityPrefs = prefs;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthController>(
      builder: (context, authController, child) {
        final user = authController.user;
        
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 24, 16, 96),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Mon Compte',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      IconButton(
                        onPressed: () => _showLogoutDialog(context, authController),
                        icon: const Icon(
                          Icons.logout,
                          color: Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // Profil utilisateur
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          backgroundImage: user?.imageUrl != null 
                              ? NetworkImage(user!.imageUrl!) 
                              : null,
                          child: user?.imageUrl == null
                              ? Text(
                                  user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                                  style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4F46E5),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user?.fullName ?? 'Utilisateur',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            user?.role ?? 'Membre',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Informations personnelles
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Informations personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow('Téléphone', user?.phone ?? ''),
                        _buildInfoRow('Villa ID', user?.villaId.toString() ?? ''),
                        _buildInfoRow('Rôle', user?.role ?? ''),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Options du compte
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Paramètres',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildSettingItem(
                          Icons.edit,
                          'Modifier le profil',
                          () {},
                        ),
                        _buildSettingItem(
                          Icons.lock,
                          'Changer le mot de passe',
                          () {},
                        ),
                        // _buildSettingItem(
                        //   Icons.notifications,
                        //   'Notifications',
                        //   () {},
                        // ),
                        // _buildSettingItem(
                        //   Icons.help,
                        //   'Aide et support',
                        //   () {},
                        // ),
                        // _buildSettingItem(
                        //   Icons.privacy_tip,
                        //   'Confidentialité',
                        //   () {},
                        // ),
                        
                        // Section sécurité (comme WhatsApp)
                        if (_securityPrefs != null) ...[
                          const Divider(height: 32, color: Color(0xFFE5E7EB)),
                          
                          // Titre section sécurité
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Sécurité de l\'application',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF374151),
                              ),
                            ),
                          ),
                          
                          // Toggle biométrique (si disponible)
                          if (_securityPrefs!.biometricAvailable)
                            _buildSecurityToggle(
                              Icons.fingerprint,
                              'Verrouillage par empreinte/Face ID',
                              'Utiliser la biométrie pour déverrouiller l\'app',
                              _securityPrefs!.biometricEnabled,
                              (value) => _toggleBiometric(value),
                            ),
                          
                          // Toggle PIN (toujours disponible - choix alternatif)
                          _buildSecurityToggle(
                            Icons.pin,
                            'Verrouillage par code PIN',
                            _securityPrefs!.biometricAvailable 
                              ? 'Alternative à la biométrie - utiliser un code PIN'
                              : 'Utiliser un code PIN pour déverrouiller l\'app',
                            _securityPrefs!.pinEnabled,
                            (value) => _togglePin(value),
                          ),
                          
                          // Option de modification du PIN si activé
                          if (_securityPrefs!.pinEnabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 8, left: 36),
                              child: InkWell(
                                onTap: _changePinCode,
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.edit,
                                      color: Color(0xFF3B82F6),
                                      size: 16,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Modifier le code PIN',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF3B82F6),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          
                          // Note importante sur exclusivité
                          if (_securityPrefs!.biometricAvailable)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF3B82F6),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Vous ne pouvez activer qu\'un seul type de verrouillage à la fois',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: const Color(0xFF3B82F6),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          
                          // Info sécurité si aucun activé
                          if (!_securityPrefs!.biometricEnabled && !_securityPrefs!.pinEnabled)
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF6B7280),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Sans verrouillage, votre app s\'ouvre avec le déverrouillage de votre téléphone',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ],
                    ),
                  ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? 'Non renseigné',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1F2937),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityToggle(
    IconData icon,
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF6B7280),
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFF3B82F6),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingItem(IconData icon, String title, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: const Color(0xFF6B7280),
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1F2937),
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _toggleBiometric(bool enabled) async {
    try {
      if (enabled) {
        // Si on active biométrie, désactiver PIN (mutuellement exclusif)
        if (_securityPrefs!.pinEnabled) {
          await SecuritySettingsService.setPinPreference(false);
        }
      }
      
      await SecuritySettingsService.setBiometricPreference(enabled);
      await _loadSecurityPreferences(); // Recharger les préférences
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled 
                ? 'Verrouillage biométrique activé (PIN désactivé)'
                : 'Verrouillage biométrique désactivé',
            ),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _togglePin(bool enabled) async {
    if (enabled) {
      // Si on active PIN, désactiver biométrie (mutuellement exclusif)
      if (_securityPrefs!.biometricEnabled) {
        final confirmDisableBiometric = await _showConfirmDialog(
          'Désactiver la biométrie',
          'Activer le code PIN va désactiver le verrouillage biométrique. Continuer ?'
        );
        if (!confirmDisableBiometric) return;
        
        await SecuritySettingsService.setBiometricPreference(false);
      }
      
      // Demander de créer un PIN avec confirmation
      final pin = await _showPinSetupDialog();
      if (pin != null && pin.isNotEmpty) {
        await SecuritySettingsService.setPinPreference(true, pin: pin);
        await _loadSecurityPreferences();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_securityPrefs!.biometricAvailable 
                ? 'Code PIN activé (biométrie désactivée)'
                : 'Code PIN activé'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        }
      }
    } else {
      // Désactiver le PIN
      final confirmDisable = await _showConfirmDialog(
        'Désactiver le code PIN',
        'Êtes-vous sûr de vouloir désactiver le verrouillage par code PIN ?'
      );
      
      if (confirmDisable) {
        await SecuritySettingsService.setPinPreference(false);
        await _loadSecurityPreferences();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code PIN désactivé'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    }
  }

  /// Modifier le code PIN existant
  /// - Vérifie d'abord l'ancien PIN
  /// - Puis demande un nouveau PIN (avec confirmation, via _showPinSetupDialog)
  Future<void> _changePinCode() async {
    try {
      // S'assurer d'avoir les dernières préférences
      final prefs = _securityPrefs ?? await SecuritySettingsService.getPreferences();

      // Si aucun PIN enregistré (cas anormal), on redirige vers la création classique
      if (!(prefs.pinEnabled) || prefs.appPin == null) {
        final newPin = await _showPinSetupDialog();
        if (newPin != null && newPin.isNotEmpty) {
          await SecuritySettingsService.setPinPreference(true, pin: newPin);
          await _loadSecurityPreferences();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Code PIN défini avec succès'),
                backgroundColor: Color(0xFF10B981),
              ),
            );
          }
        }
        return;
      }

      String currentPin = '';

      // Demander le PIN actuel
      if (!mounted) return;
      final enteredCurrentPin = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('Code PIN actuel'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Entrez votre code PIN actuel pour continuer'),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Code PIN actuel (4 chiffres)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
                obscureText: true,
                onChanged: (value) => currentPin = value,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (currentPin.length == 4) {
                  Navigator.of(context).pop(currentPin);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Le code PIN doit contenir exactement 4 chiffres'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Continuer'),
            ),
          ],
        ),
      );

      if (enteredCurrentPin == null) return; // Annulé

      // Vérifier le PIN actuel
      if (enteredCurrentPin != prefs.appPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code PIN actuel incorrect'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // PIN actuel correct → demander un nouveau PIN (avec confirmation)
      final newPin = await _showPinSetupDialog();
      if (newPin != null && newPin.isNotEmpty) {
        await SecuritySettingsService.setPinPreference(true, pin: newPin);
        await _loadSecurityPreferences();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Code PIN modifié avec succès'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showPinSetupDialog() async {
    String pin1 = '';
    String pin2 = '';
    
    // Première saisie
    final firstPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Créer un code PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez un code PIN à 4 chiffres pour sécuriser votre application'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Code PIN (4 chiffres)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onChanged: (value) => pin1 = value,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pin1.length == 4) {
                Navigator.of(context).pop(pin1);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le code PIN doit contenir exactement 4 chiffres'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Suivant'),
          ),
        ],
      ),
    );
    
    if (firstPin == null) return null;
    
    // Confirmation du PIN
    if (!mounted) return null;
    final confirmPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirmer le code PIN'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Confirmez votre code PIN pour valider'),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Confirmer le code PIN',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              onChanged: (value) => pin2 = value,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (pin2.length == 4) {
                Navigator.of(context).pop(pin2);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Le code PIN doit contenir exactement 4 chiffres'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );
    
    if (confirmPin == null) return null;
    
    // Vérifier que les deux PINs correspondent
    if (firstPin == confirmPin) {
      return firstPin;
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les codes PIN ne correspondent pas. Recommencez.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showLogoutDialog(BuildContext context, AuthController authController) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              authController.logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}