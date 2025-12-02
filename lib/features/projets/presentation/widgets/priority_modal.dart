import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../controllers/project_controller.dart';

class PriorityModal extends StatefulWidget {
  final List<ProjectModel> projects;
  final Function(List<String>)? onPrioritySubmitted;

  const PriorityModal({
    super.key,
    required this.projects,
    this.onPrioritySubmitted,
  });

  @override
  State<PriorityModal> createState() => _PriorityModalState();
}

class _PriorityModalState extends State<PriorityModal>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  List<ProjectModel> _orderedProjects = [];

  @override
  void initState() {
    super.initState();
    _orderedProjects = List.from(widget.projects);
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _closeModal() {
    _animationController.reverse().then((_) {
      Navigator.of(context).pop();
    });
  }

  Future<void> _saveOrder() async {
    print('💾 Modal - _saveOrder() appelée');
    final projectController = context.read<ProjectController>();
    
    // Les IDs sont des UUIDs (strings), pas des entiers
    final projectIds = _orderedProjects.map((p) => p.id).toList();
    
    print('💾 Modal - Projets ordonnés:');
    for (int i = 0; i < _orderedProjects.length; i++) {
      print('💾   ${i + 1}. ${_orderedProjects[i].title} (ID: ${_orderedProjects[i].id})');
    }
    print('💾 Modal - IDs envoyés: $projectIds');
    
    final success = await projectController.prioritizeProjects(projectIds);
    print('💾 Modal - Résultat: $success');
    
    if (success) {
      // Succès - optionnellement appeler le callback
      widget.onPrioritySubmitted?.call(_orderedProjects.map((p) => p.id).toList());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Priorités des projets mises à jour avec succès'),
            backgroundColor: Color(0xFF34c759),
          ),
        );
        _closeModal();
      }
    } else {
      // Erreur
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(projectController.prioritizationErrorMessage ?? 'Erreur lors de la mise à jour des priorités'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Stack(
            children: [
              // Background avec gesture pour fermer
              GestureDetector(
                onTap: _closeModal,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 1.2,
                      colors: [
                        Colors.black.withValues(alpha: 0.15 * _fadeAnimation.value),
                        Colors.black.withValues(alpha: 0.35 * _fadeAnimation.value),
                        Colors.black.withValues(alpha: 0.55 * _fadeAnimation.value),
                      ],
                    ),
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8 * _fadeAnimation.value, sigmaY: 8 * _fadeAnimation.value),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
              // Modal au centre sans GestureDetector qui interfère
              Center(
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: _buildModal(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModal() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isSmallScreen = screenSize.width < 400;
    
    return Container(
      width: isTablet 
          ? screenSize.width * 0.7 
          : (isSmallScreen ? screenSize.width * 0.95 : screenSize.width * 0.9),
      constraints: BoxConstraints(
        maxWidth: isTablet ? 600 : 500,
        minWidth: 300,
        maxHeight: screenSize.height * (isTablet ? 0.7 : 0.8),
        minHeight: 300,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.25),
                      Colors.white.withValues(alpha: 0.15),
                      Colors.white.withValues(alpha: 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.8),
                      blurRadius: 8,
                      offset: const Offset(-2, -2),
                      spreadRadius: 0,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 15,
                      offset: const Offset(2, 2),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    Flexible(child: _buildProjectsList()),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final horizontalPadding = isSmallScreen ? 20.0 : 30.0;
    
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 25, horizontalPadding, 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF1F2937).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              'Ordre de priorité des projets',
              style: TextStyle(
                color: const Color(0xFF1F2937),
                fontSize: MediaQuery.of(context).size.width < 400 ? 18 : 22,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: _closeModal,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF1F2937).withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF1F2937).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFF1F2937),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsList() {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.shortestSide >= 600;
    final isSmallScreen = screenSize.width < 400;
    final horizontalPadding = isSmallScreen ? 15.0 : (isTablet ? 35.0 : 30.0);
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: screenSize.height * (isTablet ? 0.45 : 0.4),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(horizontalPadding, 10, horizontalPadding - 10, 10),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          itemCount: _orderedProjects.length,
          proxyDecorator: (child, index, animation) {
            return AnimatedBuilder(
              animation: animation,
              builder: (BuildContext context, Widget? child) {
                final double animValue = Curves.easeInOut.transform(animation.value);
                final double elevation = lerpDouble(0, 6, animValue)!;
                final double scale = lerpDouble(1, 1.02, animValue)!;
                return Transform.scale(
                  scale: scale,
                  child: Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(10),
                    child: child,
                  ),
                );
              },
              child: child,
            );
          },
          itemBuilder: (context, index) {
            final project = _orderedProjects[index];
            return _buildProjectItem(project, index + 1, key: ValueKey(project.id));
          },
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _orderedProjects.removeAt(oldIndex);
              _orderedProjects.insert(newIndex, item);
            });
          },
        ),
      ),
    );
  }

  Widget _buildProjectItem(ProjectModel project, int priority, {required Key key}) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final itemHeight = isSmallScreen ? 60.0 : 65.0;
    final index = _orderedProjects.indexWhere((p) => p.id == project.id);
    
    return ReorderableDragStartListener(
      key: key,
      index: index,
      child: Container(
        margin: EdgeInsets.only(bottom: isSmallScreen ? 8 : 10),
        height: itemHeight,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.3),
              Colors.white.withValues(alpha: 0.15),
            ],
          ),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: MediaQuery.of(context).size.width < 400 ? 10 : 12, 
            vertical: 8
          ),
          child: Row(
            children: [
              // Numéro de priorité
              Container(
                width: MediaQuery.of(context).size.width < 400 ? 22 : 24,
                height: MediaQuery.of(context).size.width < 400 ? 22 : 24,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF007bff),
                      Color(0xFF0056b3),
                    ],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF007bff).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '$priority',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Contenu du projet
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      project.title,
                      style: TextStyle(
                        color: const Color(0xFF1F2937),
                        fontSize: MediaQuery.of(context).size.width < 400 ? 13 : 14,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: MediaQuery.of(context).size.width < 400 ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: MediaQuery.of(context).size.width < 400 ? 2 : 3),
                    Flexible(
                      child: Text(
                        project.shortDescription,
                        style: TextStyle(
                          color: const Color(0xFF6B7280),
                          fontSize: MediaQuery.of(context).size.width < 400 ? 10 : 11,
                          fontFamily: 'Nunito',
                        ),
                        maxLines: MediaQuery.of(context).size.width < 400 ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              // Icône drag - maintenant cliquable pour glisser immédiatement
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B7280).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.drag_handle,
                  color: const Color(0xFF6B7280),
                  size: MediaQuery.of(context).size.width < 400 ? 18 : 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 400;
    final horizontalPadding = isSmallScreen ? 20.0 : 30.0;
    
    return Container(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 15, horizontalPadding, isSmallScreen ? 20 : 25),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF1F2937).withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: MediaQuery.of(context).size.width < 400 
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCancelButton(),
              const SizedBox(height: 10),
              _buildSaveButton(),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _buildCancelButton(),
              const SizedBox(width: 12),
              _buildSaveButton(),
        ],
      ),
    );
  }

  Widget _buildCancelButton() {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    
    return GestureDetector(
      onTap: _closeModal,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 20 : 24, 
          vertical: isSmallScreen ? 12 : 10
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1F2937).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          'Annuler',
          style: TextStyle(
            color: const Color(0xFF1F2937),
            fontSize: isSmallScreen ? 14 : 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    final isSmallScreen = MediaQuery.of(context).size.width < 400;
    
    return Consumer<ProjectController>(
      builder: (context, projectController, child) {
        return GestureDetector(
          onTap: projectController.isPrioritizing ? null : () {
            print('💾 Modal - Bouton Enregistrer cliqué !');
            _saveOrder();
          },
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 20 : 24, 
              vertical: isSmallScreen ? 12 : 10
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: projectController.isPrioritizing
                    ? [
                        const Color(0xFF6B7280),
                        const Color(0xFF4B5563),
                      ]
                    : [
                        const Color(0xFF34c759),
                        const Color(0xFF2fb34d),
                      ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (projectController.isPrioritizing 
                      ? const Color(0xFF6B7280) 
                      : const Color(0xFF34c759)).withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: projectController.isPrioritizing
                ? SizedBox(
                    width: isSmallScreen ? 18 : 20,
                    height: isSmallScreen ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Enregistrer',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isSmallScreen ? 14 : 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                    textAlign: TextAlign.center,
                  ),
          ),
        );
      },
    );
  }
}