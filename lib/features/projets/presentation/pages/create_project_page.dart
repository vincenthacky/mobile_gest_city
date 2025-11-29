import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../controllers/project_controller.dart';
import '../../models/project_model.dart';

class CreateProjectPage extends StatefulWidget {
  final ProjectModel? project;

  const CreateProjectPage({
    super.key,
    this.project,
  });

  @override
  State<CreateProjectPage> createState() => _CreateProjectPageState();
}

class _CreateProjectPageState extends State<CreateProjectPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _shortDescriptionController = TextEditingController();
  final _longDescriptionController = TextEditingController();
  final _estimatedAmountController = TextEditingController();
  final _providerNameController = TextEditingController();
  final _providerAmountController = TextEditingController();
  
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime? _deadlineDate;
  ImplementationType _implementationType = ImplementationType.withoutProvider;
  List<String> _attachments = [];
  late ProjectController _projectController;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    _projectController = Provider.of<ProjectController>(context, listen: false);
    if (_isEditing) {
      _populateFields();
    }
  }

  void _populateFields() {
    final project = widget.project!;
    _titleController.text = project.title;
    _shortDescriptionController.text = project.shortDescription;
    _longDescriptionController.text = project.longDescription;
    _estimatedAmountController.text = project.estimatedAmount.toString();
    _startDate = project.startDate;
    _endDate = project.endDate;
    _deadlineDate = project.deadlineDate;
    _implementationType = project.implementationType;
    _providerNameController.text = project.providerName ?? '';
    _providerAmountController.text = project.providerAmount?.toString() ?? '';
    _attachments = List.from(project.attachments);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _longDescriptionController.dispose();
    _estimatedAmountController.dispose();
    _providerNameController.dispose();
    _providerAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, String type) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
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
        switch (type) {
          case 'start':
            _startDate = picked;
            break;
          case 'end':
            _endDate = picked;
            break;
          case 'deadline':
            _deadlineDate = picked;
            break;
        }
      });
    }
  }

  void _addAttachment() {
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

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  void _submitProject() async {
    if (_formKey.currentState!.validate()) {
      if (_deadlineDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La date butoir est obligatoire'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }

      final success = await _projectController.createProject(
        title: _titleController.text,
        briefDescription: _shortDescriptionController.text,
        detailedDescription: _longDescriptionController.text,
        estimatedBudget: _estimatedAmountController.text,
        startDate: _startDate?.toIso8601String() ?? '',
        estimatedCompletionDate: _endDate?.toIso8601String() ?? '',
        dateLapses: _deadlineDate!.toIso8601String(),
        withCallForTenders: _implementationType == ImplementationType.withTender,
        withServiceProvider: _implementationType == ImplementationType.knownProvider,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditing ? 'Projet modifié avec succès !' : 'Projet soumis à la communauté !'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_projectController.errorMessage ?? 'Erreur lors de la soumission'),
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
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _isEditing ? 'Modifier le projet' : 'Nouveau projet',
                      style: const TextStyle(
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
                            label: 'Titre du projet',
                            hint: 'Ex: Aménagement du parc central',
                            icon: Icons.title,
                            validator: (value) => value?.isEmpty ?? true ? 'Le titre est requis' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _shortDescriptionController,
                            label: 'Description courte',
                            hint: 'Résumé visible sur la carte du projet',
                            icon: Icons.short_text,
                            maxLines: 2,
                            validator: (value) => value?.isEmpty ?? true ? 'La description courte est requise' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _longDescriptionController,
                            label: 'Description complète',
                            hint: 'Détails complets du projet',
                            icon: Icons.article,
                            maxLines: 4,
                            validator: (value) => value?.isEmpty ?? true ? 'La description complète est requise' : null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Dates du projet',
                        Icons.calendar_today,
                        [
                          _buildDateField(
                            'Date de début souhaitée',
                            _startDate,
                            () => _selectDate(context, 'start'),
                            Icons.play_arrow,
                          ),
                          const SizedBox(height: 16),
                          _buildDateField(
                            'Date de fin estimée',
                            _endDate,
                            () => _selectDate(context, 'end'),
                            Icons.stop,
                          ),
                          const SizedBox(height: 16),
                          _buildDateField(
                            'Date butoir (caduque)',
                            _deadlineDate,
                            () => _selectDate(context, 'deadline'),
                            Icons.warning,
                            isRequired: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Budget et mise en œuvre',
                        Icons.monetization_on,
                        [
                          _buildTextField(
                            controller: _estimatedAmountController,
                            label: 'Montant estimatif (FCFA)',
                            hint: 'Ex: 50000',
                            icon: Icons.monetization_on,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            validator: (value) => value?.isEmpty ?? true ? 'Le montant estimatif est requis' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildImplementationTypeSelector(),
                          if (_implementationType == ImplementationType.knownProvider) ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _providerAmountController,
                              label: 'Montant de prestation (FCFA)',
                              hint: 'Ex: 45000',
                              icon: Icons.monetization_on,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (value) => value?.isEmpty ?? true ? 'Le montant de prestation est requis' : null,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      _buildSection(
                        'Fichiers joints',
                        Icons.attach_file,
                        [
                          _buildAttachmentsSection(),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      Consumer<ProjectController>(
                        builder: (context, controller, child) {
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
                          onPressed: _projectController.isLoading ? null : _submitProject,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF3B82F6),
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
                              Consumer<ProjectController>(
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
                              Text(
                                _isEditing ? 'Mettre à jour le projet' : 'Soumettre à la communauté',
                                style: const TextStyle(
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
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF3B82F6),
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
              borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
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

  Widget _buildDateField(String label, DateTime? date, VoidCallback onTap, IconData icon, {bool isRequired = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
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
            if (isRequired) ...[
              const SizedBox(width: 4),
              const Text(
                '*',
                style: TextStyle(color: Color(0xFFEF4444), fontSize: 14),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: onTap,
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
                Icon(icon, color: const Color(0xFF6B7280), size: 20),
                const SizedBox(width: 12),
                Text(
                  date != null
                      ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                      : 'Sélectionner une date',
                  style: TextStyle(
                    fontSize: 16,
                    color: date != null ? const Color(0xFF1F2937) : const Color(0xFF9CA3AF),
                    fontFamily: 'Nunito',
                  ),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today, color: Color(0xFF6B7280), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImplementationTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Type de mise en œuvre',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: ImplementationType.values.map((type) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _implementationType == type
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFFE5E7EB),
                  width: _implementationType == type ? 2 : 1,
                ),
              ),
              child: RadioListTile<ImplementationType>(
                value: type,
                groupValue: _implementationType,
                onChanged: (value) {
                  setState(() {
                    _implementationType = value!;
                  });
                },
                title: Text(
                  _getImplementationTypeText(type),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                    fontFamily: 'Nunito',
                  ),
                ),
                activeColor: const Color(0xFF3B82F6),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getImplementationTypeText(ImplementationType type) {
    switch (type) {
      case ImplementationType.withTender:
        return 'Avec appel d\'offre';
      case ImplementationType.knownProvider:
        return 'Prestataire connu';
      case ImplementationType.withoutProvider:
        return 'Sans prestataire';
    }
  }

  Widget _buildAttachmentsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Fichiers joints',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF374151),
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              '(plans, devis, images, etc.)',
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
          onTap: _addAttachment,
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
                  'Ajouter un fichier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF374151),
                    fontFamily: 'Nunito',
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Cliquez pour sélectionner vos fichiers',
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
        if (_attachments.isNotEmpty) ...[
          const SizedBox(height: 16),
          Column(
            children: _attachments.asMap().entries.map((entry) {
              int index = entry.key;
              String fileName = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file, color: Color(0xFF6B7280), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        fileName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1F2937),
                          fontFamily: 'Nunito',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _removeAttachment(index),
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSelectedImagesSection() {
    return Consumer<ProjectController>(
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
            'Ajouter des images',
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
                    await Provider.of<ProjectController>(context, listen: false).pickImages();
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
                    await Provider.of<ProjectController>(context, listen: false).pickImageFromCamera();
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
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF3B82F6),
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

class _AttachmentDialog extends StatefulWidget {
  final Function(String) onAttachmentAdded;

  const _AttachmentDialog({required this.onAttachmentAdded});

  @override
  State<_AttachmentDialog> createState() => _AttachmentDialogState();
}

class _AttachmentDialogState extends State<_AttachmentDialog> {
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
              'Ajouter un fichier',
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
                hintText: 'Nom du fichier (ex: plan_amenagement.pdf)',
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
                  borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
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
                        widget.onAttachmentAdded(_fileNameController.text);
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
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