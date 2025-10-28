import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';

enum SignalementType { securite, drogue, suspect, nuisance, infrastructure, autre }
enum PriorityLevel { faible, moyen, eleve, urgent }

class AjouterSignalementPage extends StatefulWidget {
  const AjouterSignalementPage({super.key});

  @override
  State<AjouterSignalementPage> createState() => _AjouterSignalementPageState();
}

class _AjouterSignalementPageState extends State<AjouterSignalementPage> {
  final _formKey = GlobalKey<FormState>();
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  SignalementType _selectedType = SignalementType.autre;
  PriorityLevel _selectedPriority = PriorityLevel.moyen;
  bool _isAnonymous = false;
  List<File> _selectedPhotos = [];
  File? _selectedVideo;

  final Map<SignalementType, String> _typeLabels = {
    SignalementType.securite: 'Sécurité',
    SignalementType.drogue: 'Drogue',
    SignalementType.suspect: 'Personne suspecte',
    SignalementType.nuisance: 'Nuisance sonore',
    SignalementType.infrastructure: 'Infrastructure',
    SignalementType.autre: 'Autre',
  };

  final Map<SignalementType, IconData> _typeIcons = {
    SignalementType.securite: Icons.security,
    SignalementType.drogue: Icons.medical_services,
    SignalementType.suspect: Icons.person_search,
    SignalementType.nuisance: Icons.volume_up,
    SignalementType.infrastructure: Icons.construction,
    SignalementType.autre: Icons.report,
  };

  final Map<PriorityLevel, String> _priorityLabels = {
    PriorityLevel.faible: 'Faible',
    PriorityLevel.moyen: 'Moyen',
    PriorityLevel.eleve: 'Élevé',
    PriorityLevel.urgent: 'Urgent',
  };

  final Map<PriorityLevel, Color> _priorityColors = {
    PriorityLevel.faible: const Color(0xFF10B981),
    PriorityLevel.moyen: const Color(0xFFF59E0B),
    PriorityLevel.eleve: const Color(0xFFEF4444),
    PriorityLevel.urgent: const Color(0xFF7C2D12),
  };

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
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
          onPressed: () => context.go('/signalements'),
        ),
        title: const Text(
          'Nouveau signalement',
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
                      Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _typeIcons[_selectedType]!,
                          size: 48,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Signaler un problème',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Aidez à améliorer la sécurité de votre quartier',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF6B7280),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            // Titre
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Titre du signalement',
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
                                    hintText: 'Ex: Enfants fumant de la drogue',
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
                            
                            // Type de signalement
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Type de problème',
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
                                  child: Column(
                                    children: _typeLabels.entries.map((entry) {
                                      final isSelected = entry.key == _selectedType;
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 8),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _selectedType = entry.key;
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                  ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                                                  : Colors.white,
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFF3B82F6)
                                                    : const Color(0xFFE5E7EB),
                                                width: isSelected ? 2 : 1,
                                              ),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _typeIcons[entry.key]!,
                                                  color: isSelected
                                                      ? const Color(0xFF3B82F6)
                                                      : const Color(0xFF6B7280),
                                                  size: 20,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  entry.value,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                    color: isSelected
                                                        ? const Color(0xFF3B82F6)
                                                        : const Color(0xFF374151),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Description
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Description détaillée',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  maxLines: 5,
                                  decoration: InputDecoration(
                                    hintText: 'Décrivez le problème en détail...\nQuand ? Où ? Qui ? Que s\'est-il passé ?',
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(bottom: 80),
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
                            
                            // Localisation
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Localisation (optionnel)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _locationController,
                                  decoration: InputDecoration(
                                    hintText: 'Ex: Derrière résidence A, bloc 3',
                                    prefixIcon: const Icon(
                                      Icons.location_on,
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
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Niveau de priorité
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Niveau de priorité',
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
                                    children: _priorityLabels.entries.map((entry) {
                                      final isSelected = entry.key == _selectedPriority;
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedPriority = entry.key;
                                          });
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? _priorityColors[entry.key]!.withValues(alpha: 0.1)
                                                : Colors.white,
                                            border: Border.all(
                                              color: isSelected
                                                  ? _priorityColors[entry.key]!
                                                  : const Color(0xFFE5E7EB),
                                              width: isSelected ? 2 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            entry.value,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                              color: isSelected
                                                  ? _priorityColors[entry.key]!
                                                  : const Color(0xFF374151),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Photos et vidéos
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Photos et vidéos (optionnel)',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF3F4F6),
                                    border: Border.all(
                                      color: const Color(0xFFE5E7EB),
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              onPressed: _pickPhotos,
                                              icon: const Icon(Icons.photo_camera, size: 18),
                                              label: const Text('Ajouter photos'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF3B82F6),
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
                                            child: ElevatedButton.icon(
                                              onPressed: _pickVideo,
                                              icon: const Icon(Icons.videocam, size: 18),
                                              label: const Text('Ajouter vidéo'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(0xFF10B981),
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      
                                      // Affichage des médias sélectionnés
                                      if (_selectedPhotos.isNotEmpty || _selectedVideo != null) ...[
                                        const SizedBox(height: 16),
                                        if (_selectedPhotos.isNotEmpty) ...[
                                          Text(
                                            '${_selectedPhotos.length} photo(s) sélectionnée(s)',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        if (_selectedVideo != null) ...[
                                          const Text(
                                            'Vidéo sélectionnée',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xFF374151),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                        ],
                                        if (_selectedPhotos.isNotEmpty || _selectedVideo != null)
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _selectedPhotos.clear();
                                                _selectedVideo = null;
                                              });
                                            },
                                            child: const Text(
                                              'Supprimer tout',
                                              style: TextStyle(
                                                color: Color(0xFFEF4444),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Signalement anonyme
                            Row(
                              children: [
                                SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: Checkbox(
                                    value: _isAnonymous,
                                    onChanged: (value) {
                                      setState(() {
                                        _isAnonymous = value ?? false;
                                      });
                                    },
                                    activeColor: const Color(0xFF3B82F6),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Signalement anonyme',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color(0xFF374151),
                                    ),
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
                  onPressed: _submitSignalement,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Envoyer le signalement',
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

  void _pickPhotos() {
    // TODO: Implémenter la sélection de photos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de sélection de photos à implémenter'),
        backgroundColor: Color(0xFF3B82F6),
      ),
    );
  }

  void _pickVideo() {
    // TODO: Implémenter la sélection de vidéo
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité de sélection de vidéo à implémenter'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  void _submitSignalement() {
    if (_formKey.currentState!.validate()) {
      // TODO: Envoyer le signalement
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAnonymous 
                ? 'Signalement anonyme envoyé avec succès !'
                : 'Signalement envoyé avec succès !',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
      
      context.go('/signalements');
    }
  }
}