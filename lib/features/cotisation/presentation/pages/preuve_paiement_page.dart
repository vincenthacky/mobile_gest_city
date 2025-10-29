import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import '../../data_source/contribution_data_source.dart';
import '../../models/payment_proof_model.dart';

class PreuvePaiementPage extends StatefulWidget {
  final String? cotisationTitle;
  final int? montant;
  final int? cotisationId;

  const PreuvePaiementPage({
    super.key,
    this.cotisationTitle,
    this.montant,
    this.cotisationId,
  });

  @override
  State<PreuvePaiementPage> createState() => _PreuvePaiementPageState();
}

class _PreuvePaiementPageState extends State<PreuvePaiementPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _commentController = TextEditingController();
  String _selectedPaymentMethod = 'Orange Money';
  List<XFile> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  final ContributionDataSource _dataSource = ContributionDataSource();
  bool _isLoading = false;

  final List<String> _paymentMethods = [
    'Orange Money',
    'MTN Money',
    'Wave',
    'Moov Money',
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF6B7280),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Preuve de paiement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info cotisation
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.cotisationTitle ?? 'Cotisation Mensuelle',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Montant : ${widget.montant ?? 5000} FCFA',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Moyen de paiement
                      const Text(
                        'Moyen de paiement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          value: _selectedPaymentMethod,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(16),
                            prefixIcon: Icon(
                              Icons.payment,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          items: _paymentMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Text(method),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedPaymentMethod = value!;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Numéro de téléphone
                      const Text(
                        'Numéro de téléphone',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Ex: +225 0123456789',
                          prefixIcon: const Icon(
                            Icons.phone,
                            color: Color(0xFF6B7280),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre numéro de téléphone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      // Commentaire
                      const Text(
                        'Commentaire (optionnel)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _commentController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Ajouter un commentaire...',
                          prefixIcon: const Icon(
                            Icons.comment,
                            color: Color(0xFF6B7280),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
                          ),
                          contentPadding: const EdgeInsets.all(16),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Section téléchargement
                      const Text(
                        'Preuve de paiement',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Zone de téléchargement
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFD1D5DB),
                            style: BorderStyle.solid,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFF1F2937),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Télécharger les preuves de paiement',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: _pickImageFromCamera,
                                    icon: const Icon(Icons.camera_alt, size: 18),
                                    label: const Text('Prendre photo'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF4F46E5),
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: _pickImageFromGallery,
                                    icon: const Icon(Icons.photo_library, size: 18),
                                    label: const Text('Galerie'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFF4F46E5),
                                      side: const BorderSide(color: Color(0xFF4F46E5)),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Images sélectionnées
                      if (_selectedImages.isNotEmpty) ...[
                        const Text(
                          'Fichiers sélectionnés',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedImages.asMap().entries.map((entry) {
                            int index = entry.key;
                            XFile image = entry.value;
                            String imageName = image.name;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFF10B981)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Color(0xFF10B981),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    imageName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: () => _removeImage(index),
                                    child: const Icon(
                                      Icons.close,
                                      size: 14,
                                      color: Color(0xFF10B981),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            // Bouton envoyer
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: (_selectedImages.isNotEmpty && !_isLoading) ? _submitProof : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1F2937),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFFE5E7EB),
                    disabledForegroundColor: const Color(0xFF9CA3AF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Envoyer',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      if (Platform.isIOS) {
        try {
          final XFile? photo = await _picker.pickImage(
            source: ImageSource.camera,
            imageQuality: 85,
          );
          
          if (photo != null) {
            setState(() {
              _selectedImages.add(photo);
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Photo ajoutée avec succès !'),
                  backgroundColor: Color(0xFF10B981),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
          return;
        } catch (e) {
          // Si le picker échoue, continuer avec la vérification des permissions
        }
      }
      
      // Vérifier les permissions pour Android ou iOS en cas d'échec du picker direct
      PermissionStatus cameraStatus = await Permission.camera.status;
      
      if (cameraStatus.isDenied) {
        cameraStatus = await Permission.camera.request();
      }
      
      if (cameraStatus.isGranted) {
        final XFile? photo = await _picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 85,
        );
        
        if (photo != null) {
          setState(() {
            _selectedImages.add(photo);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Photo ajoutée avec succès !'),
                backgroundColor: Color(0xFF10B981),
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (cameraStatus.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog('caméra');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission caméra requise pour prendre une photo'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la prise de photo'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      if (Platform.isIOS) {
        try {
          final List<XFile> images = await _picker.pickMultiImage(
            imageQuality: 85,
          );
          
          if (images.isNotEmpty) {
            setState(() {
              _selectedImages.addAll(images);
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${images.length} image(s) ajoutée(s) depuis la galerie !'),
                  backgroundColor: const Color(0xFF10B981),
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          }
          return;
        } catch (e) {
          // Si le picker échoue, continuer avec la vérification des permissions
        }
      }
      
      // Vérifier les permissions pour Android ou iOS en cas d'échec du picker direct
      Permission storagePermission;
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        if (androidInfo.version.sdkInt <= 32) {
          storagePermission = Permission.storage;
        } else {
          storagePermission = Permission.photos;
        }
      } else {
        storagePermission = Permission.photos;
      }
      
      PermissionStatus storageStatus = await storagePermission.status;
      
      if (storageStatus.isDenied) {
        storageStatus = await storagePermission.request();
      }
      
      if (storageStatus.isGranted || storageStatus.isLimited) {
        final List<XFile> images = await _picker.pickMultiImage(
          imageQuality: 85,
        );
        
        if (images.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(images);
          });
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${images.length} image(s) ajoutée(s) depuis la galerie !'),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      } else if (storageStatus.isPermanentlyDenied) {
        if (mounted) {
          _showPermissionDialog('galerie');
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Permission galerie requise pour sélectionner des images'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la sélection d\'images'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _showPermissionDialog(String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission requise'),
          content: Text(
            'L\'accès à la $permissionType est nécessaire pour ajouter des preuves de paiement. '
            'Veuillez autoriser l\'accès dans les paramètres de l\'application.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                openAppSettings();
              },
              child: const Text('Paramètres'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitProof() async {
    if (_formKey.currentState!.validate() && _selectedImages.isNotEmpty) {
      setState(() {
        _isLoading = true;
      });

      try {
        // Convertir le nom du moyen de paiement en enum
        final provider = PaymentProviderExtension.fromDisplayName(_selectedPaymentMethod);
        
        // Créer la requête avec le premier fichier sélectionné
        final request = PaymentProofRequest(
          comment: _commentController.text.trim(),
          phone: _phoneController.text.trim(),
          provider: provider,
          file: File(_selectedImages.first.path),
        );
        
        // Soumettre la preuve de paiement
        final response = await _dataSource.submitPaymentProof(request);
        
        if (!mounted) return;
        
        // Vérifier le succès de la réponse
        if (response.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : 'Preuve de paiement envoyée avec succès !'),
              backgroundColor: const Color(0xFF10B981),
              duration: const Duration(seconds: 3),
            ),
          );
          
          // Retourner à la page précédente avec succès
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message.isNotEmpty ? response.message : 'Erreur lors de l\'envoi de la preuve de paiement'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        
        String errorMessage = 'Erreur lors de l\'envoi de la preuve de paiement';
        if (e.toString().contains('DioException')) {
          errorMessage = e.toString().replaceAll('DioException: ', '');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }
}