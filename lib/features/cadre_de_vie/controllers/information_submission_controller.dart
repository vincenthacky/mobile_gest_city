import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/image_optimizer.dart';
import '../data_sources/information_data_source.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/unified_sync_service.dart';

enum InformationSubmissionStatus { initial, loading, success, error }

enum InformationType { security, drugs, suspiciousPerson, noisePollution, infrastructure, other }
enum PriorityLevel { low, medium, high }

class InformationSubmissionController extends ChangeNotifier {
  final InformationDataSource _informationDataSource = InformationDataSource();
  final ImagePicker _imagePicker = ImagePicker();
  final ConnectivityService _connectivityService = ConnectivityService();
  final UnifiedSyncService _unifiedSyncService = UnifiedSyncService();
  
  InformationSubmissionStatus _status = InformationSubmissionStatus.initial;
  String? _errorMessage;
  List<File> _selectedImages = [];
  bool _isOptimizing = false;

  InformationSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  bool get isLoading => _status == InformationSubmissionStatus.loading;
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

  String _mapInformationTypeToApi(InformationType type) {
    switch (type) {
      case InformationType.security:
        return 'security';
      case InformationType.drugs:
        return 'drugs';
      case InformationType.suspiciousPerson:
        return 'suspicious_person';
      case InformationType.noisePollution:
        return 'noise_pollution';
      case InformationType.infrastructure:
        return 'infrastructure';
      case InformationType.other:
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

  Future<bool> createInformation({
    required String title,
    required String description,
    required InformationType reportType,
    required String place,
    required PriorityLevel priority,
    required bool isAnonymous,
  }) async {
    _setStatus(InformationSubmissionStatus.loading);
    _clearError();

    try {
      // Vérifier la connectivité
      if (_connectivityService.isConnected) {
        // Connexion disponible - tenter l'envoi direct
        final response = await _informationDataSource.createInformation(
          title: title,
          description: description,
          reportType: _mapInformationTypeToApi(reportType),
          place: place,
          priority: _mapPriorityToApi(priority),
          anonymous: isAnonymous,
          images: _selectedImages,
        );
        
        if (response.success) {
          _setStatus(InformationSubmissionStatus.success);
          _selectedImages.clear();
          return true;
        } else {
          _setError(response.message);
          _setStatus(InformationSubmissionStatus.error);
          return false;
        }
      } else {
        // Pas de connexion - sauvegarder en local
        debugPrint('📵 [CADRE_VIE] Pas de connexion - sauvegarde en local');
        
        // Copier les images dans un dossier temporaire pour les garder
        final imagePaths = <String>[];
        for (final image in _selectedImages) {
          imagePaths.add(image.path);
        }
        
        // Sauvegarder l'information en attente
        final pendingId = await _unifiedSyncService.addPendingCadreDeVie(
          title: title,
          description: description,
          place: place,
          type: _mapInformationTypeToApi(reportType),
          priority: _mapPriorityToApi(priority),
          imagePaths: imagePaths,
        );
        
        debugPrint('💾 [CADRE_VIE] Information "$title" sauvegardée en local avec ID: $pendingId');
        
        _setStatus(InformationSubmissionStatus.success);
        _selectedImages.clear();
        return true;
      }
    } catch (e) {
      debugPrint('❌ [CADRE_VIE] Erreur lors de la création: $e');
      _setError(e.toString());
      _setStatus(InformationSubmissionStatus.error);
      return false;
    }
  }

  void _setStatus(InformationSubmissionStatus status) {
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
    _status = InformationSubmissionStatus.initial;
    _clearError();
    notifyListeners();
  }
}