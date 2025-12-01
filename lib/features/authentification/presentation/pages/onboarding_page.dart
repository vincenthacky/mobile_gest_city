import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController(
    // 🚀 OPTIMISÉ: Configurations pour fluidité
    viewportFraction: 1.0,
    keepPage: true,
  );
  int _currentPage = 0;
  bool _isAnimating = false; // Éviter les conflits d'animations
  
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // 🚀 OPTIMISÉ: Pre-cache des images pour fluidité
  final List<AssetImage> _preloadedImages = [];

  final List<OnboardingSlide> _slides = [
    OnboardingSlide(
      image: 'assets/images/personnes_salut.png',
      title: 'Bienvenue dans ta Cité !',
      subtitle: 'Découvre, partage et gère ta vie de quartier facilement.',
    ),
    OnboardingSlide(
      image: 'assets/images/Money_stress-amico.png',
      title: 'Cotise sans stress',
      subtitle: 'Suis tes paiements et reste à jour en toute simplicité.',
    ),
    OnboardingSlide(
      image: 'assets/images/Work-anniversary-pana.png',
      title: 'Reste informé',
      subtitle: 'Sois au courant de tous les événements et annonces.',
    ),
    OnboardingSlide(
      image: 'assets/images/Problem solving-amico.png',
      title: 'Signale les problèmes',
      subtitle: 'Aide à améliorer la cité en signalant ce qui ne va pas.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    
    // Animation simple et fluide
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // 🚀 OPTIMISÉ: Pre-charger les images quand le context est disponible
    if (_preloadedImages.isEmpty) {
      _preloadImages();
    }
  }

  /// 🚀 OPTIMISÉ: Pre-charge les images pour éviter les lag au swipe
  void _preloadImages() {
    for (final slide in _slides) {
      final assetImage = AssetImage(slide.image);
      _preloadedImages.add(assetImage);
      // Pre-cache l'image avec le context maintenant disponible
      precacheImage(assetImage, context);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_isAnimating) return; // 🚀 OPTIMISÉ: Éviter les animations multiples
    
    if (_currentPage < _slides.length - 1) {
      _isAnimating = true;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250), // 🚀 Plus rapide et fluide
        curve: Curves.easeOut,
      ).then((_) {
        _isAnimating = false;
      });
    } else {
      context.go('/onboarding/choice');
    }
  }

  void _skipToChoice() {
    context.go('/onboarding/choice');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipToChoice,
                    child: Text(
                      'Passer',
                      style: GoogleFonts.nunito(
                        fontSize: MediaQuery.of(context).size.height < 700 ? 14 : 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                // 🚀 OPTIMISÉ: Configuration pour fluidité maximale
                physics: const ClampingScrollPhysics(), // Meilleur contrôle
                pageSnapping: true,
                allowImplicitScrolling: false,
                onPageChanged: (index) {
                  if (!mounted) return;
                  setState(() {
                    _currentPage = index;
                    _isAnimating = false; // Reset du flag animation
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  // 🚀 OPTIMISÉ: Widget simple et performant avec image pre-cachée
                  return AnimatedOpacity(
                    opacity: 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: OnboardingSlideWidget(
                      slide: _slides[index],
                      preloadedImage: _preloadedImages.length > index ? _preloadedImages[index] : null,
                    ),
                  );
                },
              ),
            ),
            
            // 🚀 OPTIMISÉ: Page indicator plus fluide
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 200),
                  tween: Tween<double>(
                    begin: 0.0,
                    end: _currentPage == index ? 1.0 : 0.0,
                  ),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      height: 8.0,
                      width: 8.0 + (16.0 * value), // Interpolation fluide
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          Colors.grey[300],
                          const Color(0xFF3B82F6),
                          value,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Next button
            Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.06),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      vertical: MediaQuery.of(context).size.height < 700 ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Commencer' : 'Suivant',
                    style: GoogleFonts.poppins(
                      fontSize: MediaQuery.of(context).size.height < 700 ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
}

class OnboardingSlide {
  final String image;
  final String title;
  final String subtitle;

  OnboardingSlide({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}

// 🚀 OPTIMISÉ: Widget avec mise en cache et performance améliorée
class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;
  final AssetImage? preloadedImage;

  const OnboardingSlideWidget({
    super.key,
    required this.slide,
    this.preloadedImage,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.height < 700;
    final imageHeight = isSmallScreen ? screenSize.height * 0.35 : screenSize.height * 0.4;
    final horizontalPadding = screenSize.width * 0.06;
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 🚀 OPTIMISÉ: Image avec cache et loading amélioré
          SizedBox(
            height: imageHeight,
            width: double.infinity,
            child: preloadedImage != null
                ? Image(
                    image: preloadedImage!,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF9FAFB),
                        child: Icon(
                          Icons.image_not_supported,
                          size: isSmallScreen ? 60 : 80,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  )
                : Image.asset(
                    slide.image,
                    fit: BoxFit.contain,
                    cacheWidth: (screenSize.width * 0.8).round(),
                    cacheHeight: imageHeight.round(),
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF9FAFB),
                        child: Icon(
                          Icons.image_not_supported,
                          size: isSmallScreen ? 60 : 80,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
          ),
          
          SizedBox(height: isSmallScreen ? 32 : 48),
          
          // 🚀 OPTIMISÉ: Texte avec RepaintBoundary pour éviter les repaints
          RepaintBoundary(
            child: Column(
              children: [
                // Title
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),
                
                SizedBox(height: isSmallScreen ? 12 : 16),
                
                // Subtitle
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}