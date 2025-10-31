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
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

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
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _slideController.reset();
      _slideController.forward();
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _skipToChoice,
                    child: Text(
                      'Passer',
                      style: GoogleFonts.nunito(
                        fontSize: 16,
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
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                  _slideController.reset();
                  _slideController.forward();
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: OnboardingSlideWidget(slide: _slides[index]),
                    ),
                  );
                },
              ),
            ),
            
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  height: 8.0,
                  width: _currentPage == index ? 24.0 : 8.0,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? const Color(0xFF3B82F6)
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.0),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Next button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                    shadowColor: Colors.black.withValues(alpha: 0.08),
                  ),
                  child: Text(
                    _currentPage == _slides.length - 1 ? 'Commencer' : 'Suivant',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
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

class OnboardingSlideWidget extends StatelessWidget {
  final OnboardingSlide slide;

  const OnboardingSlideWidget({
    super.key,
    required this.slide,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          SizedBox(
            height: 350,
            width: double.infinity,
            child: Image.asset(
              slide.image,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFFF9FAFB),
                  child: Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 48),
          
          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Subtitle
          Text(
            slide.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}