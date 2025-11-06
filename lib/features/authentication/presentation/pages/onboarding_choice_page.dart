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
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    
    // Better responsive breakpoints
    final isVerySmallScreen = screenHeight < 650 || screenWidth < 350;
    final isSmallScreen = screenHeight < 700 && !isVerySmallScreen;
    final isMediumScreen = screenHeight >= 700 && screenHeight < 850;
    
    // Responsive values
    final imageHeight = isVerySmallScreen 
        ? screenHeight * 0.25 
        : isSmallScreen 
            ? screenHeight * 0.3 
            : screenHeight * 0.35;
    
    final horizontalPadding = screenWidth < 350 
        ? screenWidth * 0.04 
        : screenWidth * 0.06;
    
    // Button dimensions
    final buttonVerticalPadding = isVerySmallScreen ? 12.0 : isSmallScreen ? 16.0 : 18.0;
    final buttonFontSize = isVerySmallScreen ? 13.0 : isSmallScreen ? 14.0 : 16.0;
    final iconSize = isVerySmallScreen ? 16.0 : isSmallScreen ? 18.0 : 20.0;
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.all(horizontalPadding),
            child: Column(
              children: [
                // Back button
                Row(
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
                
                SizedBox(height: isVerySmallScreen 
                    ? screenSize.height * 0.015 
                    : screenSize.height * 0.025),
                
                // Image
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
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
                
                SizedBox(height: isVerySmallScreen 
                    ? screenSize.height * 0.04 
                    : screenSize.height * 0.06),
                
                // Title
                Text(
                  'Rejoins ta communauté !',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: isVerySmallScreen ? 20 : isSmallScreen ? 24 : 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                    height: 1.2,
                  ),
                ),
                
                SizedBox(height: isVerySmallScreen 
                    ? screenSize.height * 0.015 
                    : screenSize.height * 0.02),
                
                // Subtitle
                Text(
                  'Choisis comment tu veux accéder à ton espace communautaire',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: isVerySmallScreen ? 13 : isSmallScreen ? 14 : 16,
                    color: Colors.grey[600],
                    height: 1.5,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                
                const Spacer(),
                
                // Login button
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
                              borderRadius: BorderRadius.circular(isVerySmallScreen ? 20 : 24),
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
                
                SizedBox(height: isVerySmallScreen ? 12 : 16),
                
                // Register button
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
                        borderRadius: BorderRadius.circular(isVerySmallScreen ? 20 : 24),
                      ),
                      elevation: 0,
                      shadowColor: Colors.black.withValues(alpha: 0.08),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_add,
                          size: iconSize,
                        ),
                        SizedBox(width: isVerySmallScreen ? 6 : 8),
                        Text(
                          'Je découvre la cité',
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
                
                SizedBox(height: isVerySmallScreen 
                    ? screenSize.height * 0.025 
                    : screenSize.height * 0.04),
                
                // Terms and conditions
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 8.0 : 0.0,
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
                
                SizedBox(height: isVerySmallScreen 
                    ? screenSize.height * 0.02 
                    : screenSize.height * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }
}