import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../data_sources/signalement_data_source.dart';

enum SignalementSubmissionStatus { initial, loading, success, error }

enum SignalementType { security, drugs, suspiciousPerson, noisePollution, infrastructure, other }
enum PriorityLevel { low, medium, high }

class SignalementController extends ChangeNotifier {
  final SignalementDataSource _signalementDataSource = SignalementDataSource();
  final ImagePicker _imagePicker = ImagePicker();
  
  SignalementSubmissionStatus _status = SignalementSubmissionStatus.initial;
  String? _errorMessage;
  List<File> _selectedImages = [];

  SignalementSubmissionStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<File> get selectedImages => List.unmodifiable(_selectedImages);
  bool get isLoading => _status == SignalementSubmissionStatus.loading;
  bool get hasImages => _selectedImages.isNotEmpty;

  Future<void> pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 80,
      );
      
      if (images.isNotEmpty) {
        _selectedImages.addAll(images.map((xfile) => File(xfile.path)));
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la sélection des images: $e');
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );
      
      if (image != null) {
        _selectedImages.add(File(image.path));
        notifyListeners();
      }
    } catch (e) {
      _setError('Erreur lors de la prise de photo: $e');
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
        return true;
      } else {
        _setError(response.message);
        _setStatus(SignalementSubmissionStatus.error);
        return false;
      }
    } catch (e) {
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
}