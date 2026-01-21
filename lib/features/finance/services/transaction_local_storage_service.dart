import 'dart:convert';
import 'package:hive/hive.dart';
import '../models/transaction_sync_models.dart';

class TransactionLocalStorageService {
  static const String _checksumsBoxName = 'transaction_checksums';
  static const String _transactionsBoxName = 'cached_transactions';
  
  static Box<TransactionChecksum>? _checksumsBox;
  static Box<CachedTransaction>? _transactionsBox;

  /// Initialise les boxes Hive pour les transactions
  static Future<void> initialize() async {
    try {
      _checksumsBox = await Hive.openBox<TransactionChecksum>(_checksumsBoxName);
      _transactionsBox = await Hive.openBox<CachedTransaction>(_transactionsBoxName);

      print('✅ [TRANSACTION STORAGE] Boxes initialisées avec succès');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de l\'initialisation: $e');
      rethrow;
    }
  }

  /// Ferme les boxes et réinitialise les références
  /// Appelé lors de la déconnexion pour éviter "Box has already been closed"
  static Future<void> close() async {
    try {
      await _checksumsBox?.close();
      await _transactionsBox?.close();
      _checksumsBox = null;
      _transactionsBox = null;
      print('✅ [TRANSACTION STORAGE] Boxes fermées avec succès');
    } catch (e) {
      print('⚠️ [TRANSACTION STORAGE] Erreur lors de la fermeture: $e');
      // Réinitialiser quand même les références
      _checksumsBox = null;
      _transactionsBox = null;
    }
  }

  /// Vérifie si les boxes sont prêtes à l'utilisation
  static bool get _isReady =>
      _checksumsBox != null && _checksumsBox!.isOpen &&
      _transactionsBox != null && _transactionsBox!.isOpen;

  /// Sauvegarde les checksums des transactions
  static Future<void> saveChecksums(List<Map<String, dynamic>> transactions, String globalChecksum) async {
    if (!_isReady) {
      await initialize();
    }

    try {
      await _checksumsBox!.clear();
      
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final checksum = TransactionChecksum.create(
          transactionId: transaction['id'],
          checksum: transaction['checksum'],
          lastUpdated: DateTime.now(),
          receptionOrder: i,
        );
        
        await _checksumsBox!.put(transaction['id'], checksum);
      }

      print('✅ [TRANSACTION STORAGE] ${transactions.length} checksums sauvegardés');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de la sauvegarde des checksums: $e');
      rethrow;
    }
  }

  /// Récupère tous les checksums
  static List<TransactionChecksum> getAllChecksums() {
    if (!_isReady) return [];

    final checksums = _checksumsBox!.values.toList();
    checksums.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));
    return checksums;
  }

  /// Sauvegarde les transactions complètes
  static Future<void> saveTransactions(List<Map<String, dynamic>> transactions) async {
    if (!_isReady) {
      await initialize();
    }

    try {
      await _transactionsBox!.clear();
      
      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final cached = CachedTransaction.create(
          transactionId: transaction['id'],
          transactionJson: jsonEncode(transaction),
          cachedAt: DateTime.now(),
          receptionOrder: i,
        );
        
        await _transactionsBox!.put(transaction['id'], cached);
      }

      print('✅ [TRANSACTION STORAGE] ${transactions.length} transactions sauvegardées');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de la sauvegarde des transactions: $e');
      rethrow;
    }
  }

  /// Ajoute de nouvelles transactions au cache
  static Future<void> addTransactions(List<Map<String, dynamic>> transactions) async {
    if (!_isReady) {
      await initialize();
    }

    try {
      // Obtenir le prochain ordre de réception
      int nextOrder = _transactionsBox!.values.isEmpty 
          ? 0 
          : _transactionsBox!.values.map((t) => t.receptionOrder).reduce((a, b) => a > b ? a : b) + 1;

      for (int i = 0; i < transactions.length; i++) {
        final transaction = transactions[i];
        final transactionId = transaction['id'];
        
        // Ajouter transaction
        final cached = CachedTransaction.create(
          transactionId: transactionId,
          transactionJson: jsonEncode(transaction),
          cachedAt: DateTime.now(),
          receptionOrder: nextOrder + i,
        );
        await _transactionsBox!.put(transactionId, cached);

        // Ajouter checksum
        final checksum = TransactionChecksum.create(
          transactionId: transactionId,
          checksum: transaction['checksum'],
          lastUpdated: DateTime.now(),
          receptionOrder: nextOrder + i,
        );
        await _checksumsBox!.put(transactionId, checksum);
      }

      print('✅ [TRANSACTION STORAGE] ${transactions.length} nouvelles transactions ajoutées');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de l\'ajout: $e');
      rethrow;
    }
  }

  /// Met à jour des transactions existantes
  static Future<void> updateTransactions(List<Map<String, dynamic>> transactions) async {
    if (!_isReady) {
      await initialize();
    }

    try {
      for (final transaction in transactions) {
        final transactionId = transaction['id'];
        
        // Mettre à jour transaction
        final existing = _transactionsBox!.get(transactionId);
        if (existing != null) {
          existing.transactionJson = jsonEncode(transaction);
          existing.cachedAt = DateTime.now();
          await existing.save();

          // Mettre à jour checksum
          final existingChecksum = _checksumsBox!.get(transactionId);
          if (existingChecksum != null) {
            existingChecksum.checksum = transaction['checksum'];
            existingChecksum.lastUpdated = DateTime.now();
            await existingChecksum.save();
          }
        }
      }

      print('✅ [TRANSACTION STORAGE] ${transactions.length} transactions mises à jour');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de la mise à jour: $e');
      rethrow;
    }
  }

  /// Supprime des transactions
  static Future<void> deleteTransactions(List<String> transactionIds) async {
    if (!_isReady) {
      await initialize();
    }

    try {
      for (final transactionId in transactionIds) {
        await _transactionsBox!.delete(transactionId);
        await _checksumsBox!.delete(transactionId);
      }

      print('✅ [TRANSACTION STORAGE] ${transactionIds.length} transactions supprimées');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de la suppression: $e');
      rethrow;
    }
  }

  /// Récupère toutes les transactions du cache
  static List<Map<String, dynamic>> getAllTransactions() {
    if (!_isReady) return [];

    try {
      final transactions = _transactionsBox!.values.toList();
      transactions.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));

      return transactions.map((cached) {
        return jsonDecode(cached.transactionJson) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors de la récupération: $e');
      return [];
    }
  }

  /// Calcule le checksum global
  static String calculateGlobalChecksum(List<TransactionChecksum> checksums) {
    if (checksums.isEmpty) return '';
    
    final sortedChecksums = checksums.toList();
    sortedChecksums.sort((a, b) => a.receptionOrder.compareTo(b.receptionOrder));
    
    final concatenated = sortedChecksums.map((c) => c.checksum).join('');
    return concatenated.hashCode.toString();
  }

  /// Nettoie le cache
  static Future<void> clearCache() async {
    try {
      if (_checksumsBox != null && _checksumsBox!.isOpen) {
        await _checksumsBox!.clear();
      }
      if (_transactionsBox != null && _transactionsBox!.isOpen) {
        await _transactionsBox!.clear();
      }
      print('✅ [TRANSACTION STORAGE] Cache nettoyé');
    } catch (e) {
      print('❌ [TRANSACTION STORAGE] Erreur lors du nettoyage: $e');
    }
  }

  /// Statistiques du cache
  static Map<String, dynamic> getCacheStats() {
    if (!_isReady) {
      return {
        'checksums_count': 0,
        'transactions_count': 0,
        'last_updated': null,
      };
    }
    return {
      'checksums_count': _checksumsBox?.length ?? 0,
      'transactions_count': _transactionsBox?.length ?? 0,
      'last_updated': _checksumsBox?.values.isNotEmpty == true
          ? _checksumsBox!.values.map((c) => c.lastUpdated).reduce((a, b) => a.isAfter(b) ? a : b)
          : null,
    };
  }
}