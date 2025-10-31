import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';

enum ActivityType { mariage, naissance, deces, reunion, fete, travaux, visite, autre }

class AjouterActivitePage extends StatefulWidget {
  const AjouterActivitePage({super.key});

  @override
  State<AjouterActivitePage> createState() => _AjouterActivitePageState();
}

class _AjouterActivitePageState extends State<AjouterActivitePage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _lieuController = TextEditingController();
  
  ActivityType _selectedType = ActivityType.autre;
  DateTime? _dateEvenement;
  bool _isPublic = true;
  List<File> _selectedPhotos = [];

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

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _lieuController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF10B981),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF1F2937),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateEvenement = picked;
      });
    }
  }

  void _addPhoto() {
    showDialog(
      context: context,
      builder: (context) => _PhotoDialog(
        onPhotoAdded: (fileName) {
          // Simulation d'ajout de photo
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Photo "$fileName" ajoutée'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }

  void _submitActivity() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activité ajoutée avec succès !'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
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
                  const Text(
                    '✨ Nouvelle activité',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                      fontFamily: 'Poppins',
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
                            controller: _titreController,
                            label: 'Titre de l\'activité',
                            hint: 'Ex: Mariage de Marie et Jean',
                            icon: Icons.title,
                            validator: (value) => value?.isEmpty ?? true ? 'Le titre est requis' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _descriptionController,
                            label: 'Description',
                            hint: 'Décrivez l\'activité en détail...',
                            icon: Icons.article,
                            maxLines: 4,
                            validator: (value) => value?.isEmpty ?? true ? 'La description est requise' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _lieuController,
                            label: 'Lieu (optionnel)',
                            hint: 'Ex: Rue des Roses, n°15',
                            icon: Icons.location_on,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Type d\'activité',
                        Icons.category,
                        [
                          _buildTypeSelector(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Date et visibilité',
                        Icons.calendar_today,
                        [
                          _buildDateField(),
                          const SizedBox(height: 16),
                          _buildVisibilitySwitch(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Photos (optionnel)',
                        Icons.photo_camera,
                        [
                          _buildPhotoSection(),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitActivity,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Partager l\'activité',
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
          'Choisissez le type d\'activité',
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

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date de l\'événement (optionnel)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => _selectDate(context),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF6B7280), size: 20),
                const SizedBox(width: 12),
                Text(
                  _dateEvenement != null
                      ? '${_dateEvenement!.day.toString().padLeft(2, '0')}/${_dateEvenement!.month.toString().padLeft(2, '0')}/${_dateEvenement!.year}'
                      : 'Sélectionner une date',
                  style: TextStyle(
                    fontSize: 16,
                    color: _dateEvenement != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    fontFamily: 'Nunito',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.arrow_forward_ios, color: Color(0xFF6B7280), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVisibilitySwitch() {
    return Row(
      children: [
        Icon(
          _isPublic ? Icons.public : Icons.lock,
          color: _isPublic ? const Color(0xFF10B981) : const Color(0xFF6B7280),
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isPublic ? 'Activité publique' : 'Activité privée',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                  fontFamily: 'Poppins',
                ),
              ),
              Text(
                _isPublic
                    ? 'Visible par tous les membres de la cité'
                    : 'Visible uniquement par vous',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                  fontFamily: 'Nunito',
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: _isPublic,
          onChanged: (value) => setState(() => _isPublic = value),
          activeColor: const Color(0xFF10B981),
        ),
      ],
    );
  }

  Widget _buildPhotoSection() {
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
        GestureDetector(
          onTap: _addPhoto,
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
                  Icons.add_photo_alternate,
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
                  'Cliquez pour sélectionner vos photos',
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
        if (_selectedPhotos.isNotEmpty) ...[
          const SizedBox(height: 16),
          SizedBox(
            height: 80,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedPhotos.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 80,
                  height: 80,
                  margin: EdgeInsets.only(
                    right: index < _selectedPhotos.length - 1 ? 12 : 0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    size: 32,
                    color: Color(0xFF6B7280),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PhotoDialog extends StatefulWidget {
  final Function(String) onPhotoAdded;

  const _PhotoDialog({required this.onPhotoAdded});

  @override
  State<_PhotoDialog> createState() => _PhotoDialogState();
}

class _PhotoDialogState extends State<_PhotoDialog> {
  final _fileNameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ajouter une photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _fileNameController,
              decoration: InputDecoration(
                hintText: 'Nom de la photo (ex: mariage_marie_jean.jpg)',
                hintStyle: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontFamily: 'Nunito',
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF10B981), width: 2),
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: const TextStyle(fontFamily: 'Nunito'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Annuler',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontFamily: 'Nunito',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (_fileNameController.text.isNotEmpty) {
                        widget.onPhotoAdded(_fileNameController.text);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Ajouter',
                      style: TextStyle(fontFamily: 'Nunito'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}