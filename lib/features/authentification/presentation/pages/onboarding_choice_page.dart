import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingChoicePage extends StatefulWidget {
  const OnboardingChoicePage({super.key});

  @override
  State<OnboardingChoicePage> createState() => _OnboardingChoicePageState();
}

class _OnboardingChoicePageState extends State<OnboardingChoicePage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF0F8FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenHeight = constraints.maxHeight;
              final screenWidth = constraints.maxWidth;
              final isVerySmallScreen = screenHeight < 650;
              final isSmallScreen = screenHeight < 750;
              
              // Responsive dimensions basées sur la hauteur réelle disponible
              final horizontalPadding = screenWidth * 0.06; // 6% de la largeur
              final buttonFontSize = isVerySmallScreen ? 14.0 : isSmallScreen ? 16.0 : 18.0;
              final titleFontSize = isVerySmallScreen ? 20.0 : isSmallScreen ? 24.0 : 28.0;
              final subtitleFontSize = isVerySmallScreen ? 13.0 : isSmallScreen ? 14.0 : 16.0;
              final iconSize = isVerySmallScreen ? 18.0 : isSmallScreen ? 20.0 : 24.0;
              final buttonVerticalPadding = screenHeight * 0.02; // 2% de la hauteur

              return Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: Column(
                  children: [
                    // Back button area - hauteur fixe
                    SizedBox(
                      height: kToolbarHeight,
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.go('/onboarding'),
                            icon: const Icon(
                              Icons.arrow_back_ios,
                              color: Color(0xFF3B82F6),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              'Retour aux slides',
                              style: GoogleFonts.nunito(
                                fontSize: isVerySmallScreen ? 11 : isSmallScreen ? 12 : 14,
                                color: const Color(0xFF3B82F6),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Contenu principal - utilise tout l'espace restant
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: LayoutBuilder(
                          builder: (context, contentConstraints) {
                            final contentHeight = contentConstraints.maxHeight;
                            
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: contentHeight,
                                ),
                                child: IntrinsicHeight(
                                  child: Column(
                                    children: [
                                      // Image area - flexible mais avec une hauteur minimale
                                      Flexible(
                                        flex: 3,
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minHeight: contentHeight * 0.25,
                                            maxHeight: contentHeight * 0.4,
                                          ),
                                          width: double.infinity,
                                          padding: EdgeInsets.symmetric(vertical: contentHeight * 0.02),
                                          child: Image.asset(
                                            'assets/images/Fingerprint-cuate.png',
                                            fit: BoxFit.contain,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                color: const Color(0xFFF9FAFB),
                                                child: Icon(
                                                  Icons.fingerprint,
                                                  size: isVerySmallScreen ? 80 : isSmallScreen ? 100 : 120,
                                                  color: Colors.grey[400],
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                      
                                      // Texte - flexible
                                      Flexible(
                                        flex: 2,
                                        child: Container(
                                          constraints: BoxConstraints(
                                            minHeight: contentHeight * 0.15,
                                          ),
                                          padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: contentHeight * 0.01,
                                          ),
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              // Titre
                                              Text(
                                                'Rejoins ta communauté !',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.poppins(
                                                  fontSize: titleFontSize,
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF1F2937),
                                                  height: 1.2,
                                                ),
                                              ),
                                              
                                              SizedBox(height: contentHeight * 0.015),
                                              
                                              // Sous-titre
                                              Text(
                                                'Choisis comment tu veux accéder à ton espace communautaire',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.nunito(
                                                  fontSize: subtitleFontSize,
                                                  color: Colors.grey[600],
                                                  height: 1.5,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      
                                      // Spacer flexible pour pousser les boutons vers le bas
                                      const Spacer(flex: 1),
                                      
                                      // Boutons - hauteur fixe
                                      Container(
                                        constraints: BoxConstraints(
                                          minHeight: contentHeight * 0.25,
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            // Bouton de connexion avec animation
                                            AnimatedBuilder(
                                              animation: _pulseAnimation,
                                              builder: (context, child) {
                                                return Transform.scale(
                                                  scale: _pulseAnimation.value,
                                                  child: SizedBox(
                                                    width: double.infinity,
                                                    child: ElevatedButton(
                                                      onPressed: () => context.go('/login'),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: const Color(0xFF10B981),
                                                        foregroundColor: Colors.white,
                                                        padding: EdgeInsets.symmetric(
                                                          vertical: buttonVerticalPadding,
                                                        ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(
                                                            isVerySmallScreen ? 20 : 24
                                                          ),
                                                        ),
                                                        elevation: 0,
                                                        shadowColor: Colors.black.withValues(alpha: 0.08),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(
                                                            Icons.login,
                                                            size: iconSize,
                                                          ),
                                                          SizedBox(width: isVerySmallScreen ? 6 : 8),
                                                          Text(
                                                            'J\'ai déjà un compte',
                                                            style: GoogleFonts.poppins(
                                                              fontSize: buttonFontSize,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            
                                            SizedBox(height: screenHeight * 0.015),
                                            
                                            // Bouton d'inscription
                                            SizedBox(
                                              width: double.infinity,
                                              child: ElevatedButton(
                                                onPressed: () => context.go('/qr-scan'),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF3B82F6),
                                                  foregroundColor: Colors.white,
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: buttonVerticalPadding,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(
                                                      isVerySmallScreen ? 20 : 24
                                                    ),
                                                  ),
                                                  elevation: 0,
                                                  shadowColor: Colors.black.withValues(alpha: 0.08),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      Icons.qr_code_scanner,
                                                      size: iconSize,
                                                    ),
                                                    SizedBox(width: isVerySmallScreen ? 6 : 8),
                                                    Text(
                                                      'Scanner mon QR Code',
                                                      style: GoogleFonts.poppins(
                                                        fontSize: buttonFontSize,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            
                                            SizedBox(height: screenHeight * 0.03),
                                            
                                            // Conditions d'utilisation
                                            Padding(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: isVerySmallScreen ? 8.0 : 16.0,
                                              ),
                                              child: Text(
                                                'En continuant, tu acceptes nos conditions d\'utilisation et notre politique de confidentialité',
                                                textAlign: TextAlign.center,
                                                style: GoogleFonts.nunito(
                                                  fontSize: isVerySmallScreen ? 9 : isSmallScreen ? 10 : 12,
                                                  color: Colors.grey[500],
                                                  height: 1.4,
                                                  fontWeight: FontWeight.w400,
                                                ),
                                              ),
                                            ),
                                            
                                            // Espacement final
                                            SizedBox(height: screenHeight * 0.02),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}