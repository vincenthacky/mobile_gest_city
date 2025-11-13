import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

enum ConnectivityStatus { connected, disconnected, unknown }

class ConnectivityService extends ChangeNotifier {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  ConnectivityStatus _status = ConnectivityStatus.unknown;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isChecking = false;
  
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _internetChecker = InternetConnectionChecker();

  ConnectivityStatus get status => _status;
  bool get isConnected => _status == ConnectivityStatus.connected;

  /// Démarre le monitoring de la connexion
  void startMonitoring() {
    // Vérification initiale
    _checkConnectivity();
    
    // Écoute les changements de connectivité réseau
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _onConnectivityChanged(results);
      },
    );
  }

  /// Arrête le monitoring de la connexion
  void stopMonitoring() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = null;
  }

  /// Appelé quand l'état de connectivité change
  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // Si aucune connectivité réseau, on est déconnecté
    if (results.isEmpty || results.every((result) => result == ConnectivityResult.none)) {
      _updateStatus(ConnectivityStatus.disconnected);
      return;
    }
    
    // Si on a une connectivité réseau, vérifier l'accès internet
    _verifyInternetConnection();
  }

  /// Vérifie l'accès internet réel
  Future<void> _verifyInternetConnection() async {
    if (_isChecking) return;
    _isChecking = true;

    try {
      final hasInternet = await _internetChecker.hasConnection;
      
      if (hasInternet) {
        _updateStatus(ConnectivityStatus.connected);
      } else {
        _updateStatus(ConnectivityStatus.disconnected);
      }
    } catch (e) {
      _updateStatus(ConnectivityStatus.disconnected);
    } finally {
      _isChecking = false;
    }
  }

  /// Vérification initiale complète
  Future<void> _checkConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      _onConnectivityChanged(connectivityResults);
    } catch (e) {
      _updateStatus(ConnectivityStatus.disconnected);
    }
  }

  /// Met à jour le statut et notifie les listeners
  void _updateStatus(ConnectivityStatus newStatus) {
    if (_status != newStatus) {
      final wasConnected = _status == ConnectivityStatus.connected;
      final isNowConnected = newStatus == ConnectivityStatus.connected;
      
      _status = newStatus;
      
      debugPrint('🌐 [CONNECTIVITY] Statut: ${_status.name}');
      
      // Notifier tous les listeners du changement
      notifyListeners();
      
      // Si on vient de retrouver la connexion
      if (!wasConnected && isNowConnected) {
        debugPrint('🌐 [CONNECTIVITY] Connexion rétablie - sync automatique disponible');
      }
    }
  }

  /// Force une vérification immédiate
  Future<void> checkNow() async {
    await _checkConnectivity();
  }

  /// Dispose du service
  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}