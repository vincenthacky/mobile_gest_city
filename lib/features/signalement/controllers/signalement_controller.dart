import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/image_optimizer.dart';
import '../data_sources/signalement_data_source.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/unified_sync_service.dart';
import 'sync_report_controller.dart';

enum SignalementSubmissionStatus { initial, loading, success, error }

enum SignalementType { security, drugs, suspiciousPerson, noisePollution, infrastructure, other }
enum PriorityLevel { low, medium, high }

class SignalementController extends ChangeNotifier {
  final SignalementDataSource _signalementDataSource = SignalementDataSource();
  final ImagePicker _imagePicker = ImagePicker();
  final ConnectivityService _connectivityService = ConnectivityService();
  final UnifiedSyncService _unifiedSyncService = UnifiedSyncService();
  
  // Contrôleur de synchronisation pour mettre à jour le cache après création
  SyncReportController? _syncReportController;
  
  SignalementSubmissionStatus _status = SignalementSubmissionStatus.initial;
  String? _errorMessage;
  List<File> _selectedImages = [];
  bool _isOptimizing = false;

  SignalementSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  bool get isLoading => _status == SignalementSubmissionStatus.loading;
  bool get hasImages => _selectedImages.isNotEmpty;
  bool get isOptimizing => _isOptimizing;

  Future<void> pickImages() async {
    try {
      final List<XFile> picked = await _imagePicker.pickMultiImage();
      if (picked.isEmpty) return;

      _isOptimizing = true;
      notifyListeners();

      final optimized = await ImageOptimizer.optimizeAll(
        picked.map((x) => File(x.path)).toList(),
      );
      _selectedImages.addAll(optimized);
    } catch (e) {
      _setError('Erreur lors de la sélection des images: $e');
    } finally {
      _isOptimizing = false;
      notifyListeners();
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (picked == null) return;

      _isOptimizing = true;
      notifyListeners();

      final optimized = await ImageOptimizer.optimize(File(picked.path));
      _selectedImages.add(optimized);
    } catch (e) {
      _setError('Erreur lors de la prise de photo: $e');
    } finally {
      _isOptimizing = false;
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < _selectedImages.length) {
      _selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  void clearImages() {
    _selectedImages.clear();
    notifyListeners();
  }

  String _mapSignalementTypeToApi(SignalementType type) {
    switch (type) {
      case SignalementType.security:
        return 'security';
      case SignalementType.drugs:
        return 'drugs';
      case SignalementType.suspiciousPerson:
        return 'suspicious_person';
      case SignalementType.noisePollution:
        return 'noise_pollution';
      case SignalementType.infrastructure:
        return 'infrastructure';
      case SignalementType.other:
        return 'other';
    }
  }

  String _mapPriorityToApi(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.low:
        return 'low';
      case PriorityLevel.medium:
        return 'medium';
      case PriorityLevel.high:
        return 'high';
    }
  }

  Future<bool> createSignalement({
    required String title,
    required String description,
    required SignalementType reportType,
    required String place,
    required PriorityLevel priority,
    required bool isAnonymous,
  }) async {
    _setStatus(SignalementSubmissionStatus.loading);
    _clearError();

    try {
      // Vérifier la connectivité
      if (_connectivityService.isConnected) {
        // Connexion disponible - tenter l'envoi direct
        final response = await _signalementDataSource.createSignalement(
          title: title,
          description: description,
          reportType: _mapSignalementTypeToApi(reportType),
          place: place,
          priority: _mapPriorityToApi(priority),
          anonymous: isAnonymous,
          images: _selectedImages,
        );
        
        if (response.success) {
          _setStatus(SignalementSubmissionStatus.success);
          _selectedImages.clear();
          
          // ✅ SYNCHRONISER les données après création pour maintenir la cohérence (comme le module Projet)
          try {
            if (_syncReportController != null) {
              await _syncReportController!.syncReports(showNotifications: false);
              debugPrint('✅ [SIGNALEMENT] Synchronisation post-création réussie');
            } else {
              debugPrint('⚠️ [SIGNALEMENT] Pas de contrôleur de sync disponible');
            }
          } catch (e) {
            debugPrint('⚠️ [SIGNALEMENT] Erreur sync post-création: $e');
            // Ne pas faire échouer la création pour autant
          }
          
          return true;
        } else {
          _setError(response.message);
          _setStatus(SignalementSubmissionStatus.error);
          return false;
        }
      } else {
        // Pas de connexion - sauvegarder en local
        debugPrint('📵 [SIGNALEMENT] Pas de connexion - sauvegarde en local');
        
        // Copier les images dans un dossier temporaire pour les garder
        final imagePaths = <String>[];
        for (final image in _selectedImages) {
          imagePaths.add(image.path);
        }
        
        // Sauvegarder le signalement en attente
        final pendingId = await _unifiedSyncService.addPendingSignalement(
          title: title,
          description: description,
          place: place,
          type: _mapSignalementTypeToApi(reportType),
          priority: _mapPriorityToApi(priority),
          isAnonymous: isAnonymous,
          imagePaths: imagePaths,
        );
        
        debugPrint('💾 [SIGNALEMENT] Signalement "$title" sauvegardé en local avec ID: $pendingId');
        
        _setStatus(SignalementSubmissionStatus.success);
        _selectedImages.clear();
        return true;
      }
    } catch (e) {
      debugPrint('❌ [SIGNALEMENT] Erreur lors de la création: $e');
      _setError(e.toString());
      _setStatus(SignalementSubmissionStatus.error);
      return false;
    }
  }

  void _setStatus(SignalementSubmissionStatus status) {
    _status = status;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  void resetStatus() {
    _status = SignalementSubmissionStatus.initial;
    _clearError();
    notifyListeners();
  }

  /// Injecte le contrôleur de synchronisation pour permettre la mise à jour du cache après création
  void setSyncController(SyncReportController syncController) {
    _syncReportController = syncController;
  }
}