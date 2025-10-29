import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../controller/projects_controller.dart';

class AjouterProjetPage extends StatefulWidget {
  const AjouterProjetPage({super.key});

  @override
  State<AjouterProjetPage> createState() => _AjouterProjetPageState();
}

class _AjouterProjetPageState extends State<AjouterProjetPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _dateDebut;
  DateTime? _dateCloture;
  IconData _selectedIcon = Icons.lightbulb;
  Color _selectedColor = const Color(0xFF3B82F6);
  bool _isLoading = false;

  final List<IconData> _icons = [
    Icons.lightbulb,
    Icons.fence,
    Icons.cleaning_services,
    Icons.water_drop,
    Icons.park,
    Icons.construction,
    Icons.nature,
    Icons.directions_car,
    Icons.sports_soccer,
    Icons.local_hospital,
  ];

  final List<Color> _colors = [
    const Color(0xFF3B82F6),
    const Color(0xFF10B981),
    const Color(0xFFF59E0B),
    const Color(0xFF06B6D4),
    const Color(0xFFEC4899),
    const Color(0xFF8B5CF6),
    const Color(0xFFEF4444),
    const Color(0xFF84CC16),
  ];

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF374151)),
          onPressed: () => context.go('/projets'),
        ),
        title: const Text(
          'Ajouter un projet',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Titre
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Titre du projet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _titreController,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Construction d\'une aire de jeux',
                                    prefixIcon: const Icon(
                                      Icons.title,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF3F4F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer un titre';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Description
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 4,
                                  decoration: InputDecoration(
                                    hintText: 'Décrivez votre projet en détail...',
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 60),
                                      child: Icon(
                                        Icons.description,
                                        color: Color(0xFF9CA3AF),
                                      ),
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xFFF3F4F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Veuillez entrer une description';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Budget
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Budget estimé (optionnel)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _budgetController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  ],
                                  decoration: InputDecoration(
                                    hintText: 'Ex: 50000',
                                    prefixIcon: const Icon(
                                      Icons.attach_money,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                    suffixText: 'FCFA',
                                    filled: true,
                                    fillColor: const Color(0xFFF3F4F6),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFE5E7EB),
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: const BorderSide(
                                        color: Color(0xFF3B82F6),
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final budget = double.tryParse(value);
                                      if (budget == null || budget < 0) {
                                        return 'Veuillez entrer un budget valide';
                                      }
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Date de début
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date de début du vote',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context, true),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _dateDebut != null
                                              ? '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year}'
                                              : 'Sélectionner une date',
                                          style: TextStyle(
                                            color: _dateDebut != null
                                                ? const Color(0xFF374151)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Date de clôture
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Date de clôture du vote',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _selectDate(context, false),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF3F4F6),
                                      border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today,
                                          color: Color(0xFF9CA3AF),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          _dateCloture != null
                                              ? '${_dateCloture!.day}/${_dateCloture!.month}/${_dateCloture!.year}'
                                              : 'Sélectionner une date',
                                          style: TextStyle(
                                            color: _dateCloture != null
                                                ? const Color(0xFF374151)
                                                : const Color(0xFF9CA3AF),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Sélection d'icône
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Icône du projet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _icons.map((icon) {
                                      final isSelected = icon == _selectedIcon;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedIcon = icon;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _selectedColor.withValues(alpha: 0.1)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? _selectedColor
                                                  : const Color(0xFFE5E7EB),
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Icon(
                                            icon,
                                            color: isSelected
                                                ? _selectedColor
                                                : const Color(0xFF6B7280),
                                            size: 24,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Sélection de couleur
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Couleur du projet',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Wrap(
                                    spacing: 12,
                                    runSpacing: 12,
                                    children: _colors.map((color) {
                                      final isSelected = color == _selectedColor;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedColor = color;
                                          });
                                        },
                                        child: Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: color,
                                            borderRadius: BorderRadius.circular(8),
                                            border: isSelected
                                                ? Border.all(
                                                    color: color,
                                                    width: 3,
                                                  )
                                                : null,
                                            boxShadow: isSelected
                                                ? [
                                                    BoxShadow(
                                                      color: color.withValues(alpha: 0.3),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ]
                                                : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 20,
                                                )
                                              : null,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createProject,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Créer le projet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF3B82F6),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF374151),
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
        } else {
          _dateCloture = picked;
        }
      });
    }
  }

  String _getIconName(IconData icon) {
    final iconMap = {
      Icons.lightbulb: 'lightbulb',
      Icons.fence: 'fence',
      Icons.cleaning_services: 'cleaning_services',
      Icons.water_drop: 'water_drop',
      Icons.park: 'park',
      Icons.construction: 'build',
      Icons.nature: 'nature',
      Icons.directions_car: 'directions_car',
      Icons.sports_soccer: 'sports_soccer',
      Icons.local_hospital: 'local_hospital',
    };
    return iconMap[icon] ?? 'lightbulb';
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_dateDebut == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de début'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    
    if (_dateCloture == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une date de clôture'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }
    
    if (_dateCloture!.isBefore(_dateDebut!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La date de clôture doit être après la date de début'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final projectsController = context.read<ProjectsController>();
      
      // Préparer les données
      final budget = _budgetController.text.isNotEmpty 
          ? double.tryParse(_budgetController.text)
          : null;
          
      await projectsController.createProject(
        title: _titreController.text.trim(),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
        voteStartDate: _dateDebut!,
        voteEndDate: _dateCloture!,
        budget: budget,
        icon: _getIconName(_selectedIcon),
        color: _colorToHex(_selectedColor),
      );

      // Succès
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Projet créé avec succès !'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        context.go('/projets');
      }
    } catch (e) {
      // Erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création : ${e.toString()}'),
            backgroundColor: const Color(0xFFEF4444),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}