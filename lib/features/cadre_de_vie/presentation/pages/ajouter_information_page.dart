import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/information_submission_controller.dart';

enum ActivityType { mariage, naissance, deces, reunion, fete, travaux, visite, autre }

class AjouterInformationPage extends StatefulWidget {
  const AjouterInformationPage({super.key});

  @override
  State<AjouterInformationPage> createState() => _AjouterInformationPageState();
}

class _AjouterInformationPageState extends State<AjouterInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _placeController = TextEditingController();
  
  ActivityType _selectedType = ActivityType.autre;
  PriorityLevel _selectedPriority = PriorityLevel.medium;
  bool _isAnonymous = false; // Toujours false pour le cadre de vie

  final Map<ActivityType, String> _typeLabels = {
    ActivityType.mariage: 'Mariage',
    ActivityType.naissance: 'Naissance', 
    ActivityType.deces: 'Décès',
    ActivityType.reunion: 'Réunion',
    ActivityType.fete: 'Fête',
    ActivityType.travaux: 'Travaux',
    ActivityType.visite: 'Visite',
    ActivityType.autre: 'Autre',
  };

  final Map<ActivityType, IconData> _typeIcons = {
    ActivityType.mariage: Icons.favorite,
    ActivityType.naissance: Icons.child_care,
    ActivityType.deces: Icons.local_florist,
    ActivityType.reunion: Icons.groups,
    ActivityType.fete: Icons.celebration,
    ActivityType.travaux: Icons.construction,
    ActivityType.visite: Icons.visibility,
    ActivityType.autre: Icons.event,
  };

  final Map<ActivityType, Color> _typeColors = {
    ActivityType.mariage: const Color(0xFFEC4899),
    ActivityType.naissance: const Color(0xFF10B981),
    ActivityType.deces: const Color(0xFF6B7280),
    ActivityType.reunion: const Color(0xFF3B82F6),
    ActivityType.fete: const Color(0xFFF59E0B),
    ActivityType.travaux: const Color(0xFFEF4444),
    ActivityType.visite: const Color(0xFF8B5CF6),
    ActivityType.autre: const Color(0xFF6B7280),
  };

  final Map<PriorityLevel, String> _priorityLabels = {
    PriorityLevel.low: 'Faible',
    PriorityLevel.medium: 'Moyenne',
    PriorityLevel.high: 'Élevée',
  };

  final Map<PriorityLevel, Color> _priorityColors = {
    PriorityLevel.low: const Color(0xFF10B981),
    PriorityLevel.medium: const Color(0xFFF59E0B),
    PriorityLevel.high: const Color(0xFFEF4444),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Nouvelle information',
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
              child: Consumer<InformationSubmissionController>(
                builder: (context, controller, child) {
                  return SingleChildScrollView(
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
                                label: 'Titre de l\'information',
                                hint: 'Ex: Travaux sur la rue principale',
                                icon: Icons.title,
                                validator: (value) => value?.isEmpty ?? true ? 'Le titre est requis' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _descriptionController,
                                label: 'Description',
                                hint: 'Décrivez l\'information en détail...',
                                icon: Icons.article,
                                maxLines: 4,
                                validator: (value) => value?.isEmpty ?? true ? 'La description est requise' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _placeController,
                                label: 'Lieu',
                                hint: 'Ex: Rue des Roses, n°15',
                                icon: Icons.location_on,
                                validator: (value) => value?.isEmpty ?? true ? 'Le lieu est requis' : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildSection(
                            'Type d\'information',
                            Icons.category,
                            [
                              _buildTypeSelector(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildSection(
                            'Priorité',
                            Icons.flag,
                            [
                              _buildPrioritySelector(),
                            ],
                          ),
                          const SizedBox(height: 24),
                          
                          _buildSection(
                            'Photos (optionnel)',
                            Icons.photo_camera,
                            [
                              _buildPhotoSection(controller),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          if (controller.errorMessage != null) ...[
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade600),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      controller.errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                        fontFamily: 'Nunito',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: controller.isLoading ? null : _submitForm,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: controller.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.send, size: 20),
                                        SizedBox(width: 8),
                                        Text(
                                          'Publier l\'information',
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
                  );
                },
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
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF10B981),
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
              borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez le type d\'information',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ActivityType.values.map((type) {
            final isSelected = _selectedType == type;
            final color = _typeColors[type]!;
            
            return GestureDetector(
              onTap: () => setState(() => _selectedType = type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? color : const Color(0xFFE5E7EB),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _typeIcons[type],
                      size: 18,
                      color: isSelected ? color : const Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _typeLabels[type]!,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? color : const Color(0xFF374151),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choisissez le niveau de priorité',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: PriorityLevel.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            final color = _priorityColors[priority]!;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedPriority = priority),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? color.withValues(alpha: 0.1) : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? color : const Color(0xFFE5E7EB),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _priorityLabels[priority]!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? color : const Color(0xFF374151),
                      fontFamily: 'Nunito',
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

  Widget _buildPhotoSection(InformationSubmissionController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ajouter des photos',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: controller.pickImages,
                child: Container(
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
                        Icons.add_photo_alternate,
                        color: Color(0xFF6B7280),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Galerie',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          fontFamily: 'Nunito',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sélectionner depuis la galerie',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: controller.pickImageFromCamera,
                child: Container(
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
                        Icons.camera_alt,
                        color: Color(0xFF6B7280),
                        size: 32,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Caméra',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                          fontFamily: 'Nunito',
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Prendre une photo',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B7280),
                          fontFamily: 'Nunito',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (controller.isOptimizing) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF10B981),
                  ),
                ),
                SizedBox(width: 10),
                Text(
                  'Optimisation de l\'image en cours…',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF10B981),
                    fontFamily: 'Nunito',
                  ),
                ),
              ],
            ),
          ),
        ],
        if (controller.hasImages && !controller.isOptimizing) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.selectedImages.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  height: 80,
                  margin: EdgeInsets.only(
                    right: index < controller.selectedImages.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: FileImage(controller.selectedImages[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => controller.removeImage(index),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
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
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }


  InformationType _mapActivityTypeToInformationType(ActivityType activityType) {
    switch (activityType) {
      case ActivityType.mariage:
      case ActivityType.naissance:
      case ActivityType.deces:
      case ActivityType.fete:
      case ActivityType.reunion:
      case ActivityType.visite:
        return InformationType.other;
      case ActivityType.travaux:
        return InformationType.infrastructure;
      case ActivityType.autre:
        return InformationType.other;
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    final controller = context.read<InformationSubmissionController>();
    
    final success = await controller.createInformation(
      title: _titleController.text,
      description: _descriptionController.text,
      reportType: _mapActivityTypeToInformationType(_selectedType),
      place: _placeController.text,
      priority: _selectedPriority,
      isAnonymous: _isAnonymous,
    );

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Information publiée avec succès'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        Navigator.pop(context);
      }
    }
  }
}