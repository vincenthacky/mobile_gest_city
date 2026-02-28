import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/signalement_controller.dart';

class AjouterSignalementPage extends StatefulWidget {
  const AjouterSignalementPage({super.key});

  @override
  State<AjouterSignalementPage> createState() => _AjouterSignalementPageState();
}

class _AjouterSignalementPageState extends State<AjouterSignalementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  
  SignalementType _selectedType = SignalementType.other;
  PriorityLevel _selectedPriority = PriorityLevel.medium;
  bool _isAnonymous = false;
  late SignalementController _signalementController;

  @override
  void initState() {
    super.initState();
    _signalementController = Provider.of<SignalementController>(context, listen: false);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  void _addImages() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _ImagePickerBottomSheet(
        onImageSelected: () {
          setState(() {});
        },
      ),
    );
  }

  void _submitSignalement() async {
    if (_formKey.currentState!.validate()) {
      if (_placeController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La localisation est obligatoire'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final success = await _signalementController.createSignalement(
        title: _titleController.text,
        description: _descriptionController.text,
        reportType: _selectedType,
        place: _placeController.text,
        priority: _selectedPriority,
        isAnonymous: _isAnonymous,
      );

      if (!mounted) return;
      
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isAnonymous 
                ? 'Signalement anonyme envoyé avec succès !'
                : 'Signalement envoyé avec succès !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        context.go('/signalements');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_signalementController.errorMessage ?? 'Erreur lors de l\'envoi'),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.shade200,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/signalements'),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nouveau signalement',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2937),
                        fontFamily: 'Poppins',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection(
                        'Informations générales',
                        Icons.info_outline,
                        [
                          _buildTextField(
                            controller: _titleController,
                            label: 'Titre du signalement',
                            hint: 'Ex: Enfants fumant de la drogue',
                            icon: Icons.title,
                            validator: (value) => value?.isEmpty ?? true ? 'Le titre est requis' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description détaillée',
                            hint: 'Décrivez le problème en détail...\nQuand ? Où ? Qui ? Que s\'est-il passé ?',
                            icon: Icons.description,
                            maxLines: 4,
                            validator: (value) => value?.isEmpty ?? true ? 'La description est requise' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _placeController,
                            label: 'Localisation *',
                            hint: 'Ex: Derrière résidence A, bloc 3',
                            icon: Icons.location_on,
                            validator: (value) => value?.isEmpty ?? true ? 'La localisation est requise' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Type de problème',
                        Icons.report_problem,
                        [
                          _buildTypeSelector(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Priorité et options',
                        Icons.priority_high,
                        [
                          _buildPrioritySelector(),
                          const SizedBox(height: 16),
                          _buildAnonymousSwitch(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Preuves visuelles',
                        Icons.photo_camera,
                        [
                          _buildImagesSection(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Consumer<SignalementController>(
                        builder: (context, controller, child) {
                          if (controller.isOptimizing) {
                            return _buildSection(
                              'Optimisation en cours…',
                              Icons.image,
                              [
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Préparation des images…',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF6B7280),
                                          fontFamily: 'Nunito',
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }
                          if (controller.hasImages) {
                            return _buildSection(
                              'Images sélectionnées (${controller.selectedImages.length})',
                              Icons.image,
                              [_buildSelectedImagesSection()],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _signalementController.isLoading ? null : _submitSignalement,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Consumer<SignalementController>(
                                builder: (context, controller, child) {
                                  if (controller.isLoading) {
                                    return const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    );
                                  }
                                  return const Icon(Icons.send, size: 20);
                                },
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Envoyer le signalement',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'Poppins',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: Color(0xFF9CA3AF),
              fontFamily: 'Nunito',
            ),
            prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(fontFamily: 'Nunito'),
        ),
      ],
    );
  }

  Widget _buildTypeSelector() {
    final Map<SignalementType, String> typeLabels = {
      SignalementType.security: 'Sécurité',
      SignalementType.drugs: 'Drogue',
      SignalementType.suspiciousPerson: 'Personne suspecte',
      SignalementType.noisePollution: 'Nuisance sonore',
      SignalementType.infrastructure: 'Infrastructure',
      SignalementType.other: 'Autre',
    };

    final Map<SignalementType, IconData> typeIcons = {
      SignalementType.security: Icons.security,
      SignalementType.drugs: Icons.medical_services,
      SignalementType.suspiciousPerson: Icons.person_search,
      SignalementType.noisePollution: Icons.volume_up,
      SignalementType.infrastructure: Icons.construction,
      SignalementType.other: Icons.report,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sélectionnez le type de problème',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: typeLabels.entries.map((entry) {
            final isSelected = entry.key == _selectedType;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFE5E7EB),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedType = entry.key;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        typeIcons[entry.key]!,
                        color: isSelected
                            ? const Color(0xFFEF4444)
                            : const Color(0xFF6B7280),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFFEF4444)
                                : const Color(0xFF1F2937),
                            fontFamily: 'Nunito',
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    final Map<PriorityLevel, String> priorityLabels = {
      PriorityLevel.low: 'Faible',
      PriorityLevel.medium: 'Moyen',
      PriorityLevel.high: 'Élevé',
    };

    final Map<PriorityLevel, Color> priorityColors = {
      PriorityLevel.low: const Color(0xFF10B981),
      PriorityLevel.medium: const Color(0xFFF59E0B),
      PriorityLevel.high: const Color(0xFFEF4444),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Niveau de priorité',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: priorityLabels.entries.map((entry) {
            final isSelected = entry.key == _selectedPriority;
            return Expanded(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedPriority = entry.key;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? priorityColors[entry.key]!.withValues(alpha: 0.1)
                          : const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? priorityColors[entry.key]!
                            : const Color(0xFFE5E7EB),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      entry.value,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? priorityColors[entry.key]!
                            : const Color(0xFF374151),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAnonymousSwitch() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _isAnonymous 
                  ? const Color(0xFF10B981).withValues(alpha: 0.1)
                  : const Color(0xFF6B7280).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.visibility_off,
              color: _isAnonymous ? const Color(0xFF10B981) : const Color(0xFF6B7280),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signalement anonyme',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Nunito',
                  ),
                ),
                Text(
                  'Votre identité ne sera pas révélée',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAnonymous,
            onChanged: (value) {
              setState(() {
                _isAnonymous = value;
              });
            },
            activeThumbColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Photos et preuves',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '(optionnel)',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _addImages,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                style: BorderStyle.solid,
              ),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.cloud_upload,
                  color: Color(0xFF6B7280),
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Ajouter des photos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cliquez pour sélectionner vos preuves',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedImagesSection() {
    return Consumer<SignalementController>(
      builder: (context, controller, child) {
        if (controller.selectedImages.isEmpty) {
          return const SizedBox.shrink();
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: controller.selectedImages.length,
          itemBuilder: (context, index) {
            final image = controller.selectedImages[index];
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                    ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => controller.removeImage(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEF4444),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ImagePickerBottomSheet extends StatelessWidget {
  final VoidCallback onImageSelected;

  const _ImagePickerBottomSheet({required this.onImageSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ajouter des preuves',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildOptionTile(
                  context,
                  icon: Icons.photo_library,
                  title: 'Galerie',
                  onTap: () async {
                    Navigator.pop(context);
                    await Provider.of<SignalementController>(context, listen: false).pickImages();
                    onImageSelected();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildOptionTile(
                  context,
                  icon: Icons.camera_alt,
                  title: 'Caméra',
                  onTap: () async {
                    Navigator.pop(context);
                    await Provider.of<SignalementController>(context, listen: false).pickImageFromCamera();
                    onImageSelected();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFEF4444),
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF374151),
                fontFamily: 'Nunito',
              ),
            ),
          ],
        ),
      ),
    );
  }
}