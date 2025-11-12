import 'package:flutter/foundation.dart';
import '../../features/projets/services/local_storage_service.dart';

class DatabaseInitializer {
  static bool _isInitialized = false;

  /// Initialise la base de données Hive
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialiser Hive via LocalStorageService
      await LocalStorageService.instance;
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ Base de données Hive initialisée avec succès');
        
        // Afficher les statistiques en mode debug
        final stats = await LocalStorageService.getStorageStats();
        print('📊 Stats DB: ${stats['total_checksums']} checksums stockés');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de l\'initialisation de la base de données: $e');
      }
      rethrow;
    }
  }

  /// Ferme proprement la base de données
  static Future<void> close() async {
    if (_isInitialized) {
      await LocalStorageService.close();
      _isInitialized = false;
      
      if (kDebugMode) {
        print('🔒 Base de données fermée');
      }
    }
  }

  /// Vérifie si la base est initialisée
  static bool get isInitialized => _isInitialized;

  /// Nettoie complètement la base (utile pour debug/reset)
  static Future<void> reset() async {
    try {
      await LocalStorageService.clearAllChecksums();
      
      if (kDebugMode) {
        print('🗑️  Base de données Hive réinitialisée');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Erreur lors de la réinitialisation: $e');
      }
      rethrow;
    }
  }

  /// Obtient les informations sur la base de données
  static Future<Map<String, dynamic>> getDatabaseInfo() async {
    if (!_isInitialized) {
      return {'status': 'not_initialized'};
    }

    try {
      final stats = await LocalStorageService.getStorageStats();
      
      return {
        'status': 'initialized',
        'total_checksums': stats['total_checksums'],
        'recent_checksums': stats['recent_checksums'],
        'oldest_checksum': stats['oldest_checksum']?.toString(),
        'newest_checksum': stats['newest_checksum']?.toString(),
      };
    } catch (e) {
      return {
        'status': 'error',
        'error': e.toString(),
      };
    }
  }
}