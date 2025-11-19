import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service qui écoute les changements de synchronisation des transactions
/// et déclenche la synchronisation des données de paiement en cascade
class PaymentSyncListenerService {
  static PaymentSyncListenerService? _instance;
  static PaymentSyncListenerService get instance => _instance ??= PaymentSyncListenerService._();
  
  PaymentSyncListenerService._();

  final StreamController<bool> _transactionSyncController = StreamController<bool>.broadcast();
  final StreamController<bool> _paymentSyncTriggerController = StreamController<bool>.broadcast();

  /// Stream qui écoute les changements de synchronisation des transactions
  Stream<bool> get transactionSyncStream => _transactionSyncController.stream;

  /// Stream qui déclenche la synchronisation des paiements
  Stream<bool> get paymentSyncTriggerStream => _paymentSyncTriggerController.stream;

  /// Méthode appelée par TransactionSyncService quand il y a une synchronisation
  void notifyTransactionSync(bool hasUpdates) {
    debugPrint('🔄 [PAYMENT SYNC LISTENER] Transaction sync notifié: hasUpdates=$hasUpdates');
    _transactionSyncController.add(hasUpdates);
    
    // Si il y a des mises à jour, déclencher la sync des paiements
    if (hasUpdates) {
      debugPrint('🚀 [PAYMENT SYNC LISTENER] Déclenchement sync paiements');
      debugPrint('📊 [PAYMENT SYNC LISTENER] Nombre d\'écouteurs actifs: ${_paymentSyncTriggerController.hasListener ? 'Oui' : 'Non'}');
      _paymentSyncTriggerController.add(true);
      debugPrint('✅ [PAYMENT SYNC LISTENER] Signal envoyé aux écouteurs');
    }
  }

  /// Nettoie les streams
  void dispose() {
    _transactionSyncController.close();
    _paymentSyncTriggerController.close();
  }
}