import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../controller/auth_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  @override
  void dispose() {
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final screenWidth = mediaQuery.size.width;
    final isSmallScreen = screenHeight < 700;
    final isVerySmallScreen = screenHeight < 600;
    final keyboardVisible = mediaQuery.viewInsets.bottom > 0;
    
    // Responsive padding
    final horizontalPadding = screenWidth < 400 ? 16.0 : 32.0;
    final verticalPadding = isSmallScreen ? 16.0 : 32.0;
    
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Consumer<AuthController>(
          builder: (context, authController, child) {
            if (authController.isAuthenticated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.go('/home');
              });
            }

            return Column(
              children: [
                // Header avec bouton retour
                Container(
                  height: isVerySmallScreen ? 56 : 64,
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go('/onboarding/choice'),
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Color(0xFF6B7280),
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFFF3F4F6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Contenu principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: horizontalPadding,
                      vertical: verticalPadding,
                    ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: screenHeight - mediaQuery.padding.top - mediaQuery.padding.bottom - (verticalPadding * 2),
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: keyboardVisible ? MainAxisAlignment.start : MainAxisAlignment.center,
                          children: [
                            if (keyboardVisible) const SizedBox(height: 20),
                            Container(
                              height: isVerySmallScreen ? 60 : (isSmallScreen ? 70 : 80),
                              width: isVerySmallScreen ? 60 : (isSmallScreen ? 70 : 80),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.lock,
                                size: isVerySmallScreen ? 36 : (isSmallScreen ? 42 : 48),
                                color: const Color(0xFF3B82F6),
                              ),
                            ),
                            SizedBox(height: isVerySmallScreen ? 16 : (isSmallScreen ? 24 : 32)),
                            Text(
                              'Connexion',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 24 : (isSmallScreen ? 26 : 28),
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Content de vous revoir !',
                              style: TextStyle(
                                fontSize: isVerySmallScreen ? 14 : 16,
                                color: const Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isVerySmallScreen ? 24 : (isSmallScreen ? 32 : 48)),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Téléphone ou Email',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _phoneOrEmailController,
                                        decoration: InputDecoration(
                                          hintText: 'exemple@email.com ou +33123456789',
                                          prefixIcon: const Icon(
                                            Icons.alternate_email,
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
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Veuillez entrer votre téléphone ou email';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isVerySmallScreen ? 16 : 24),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Mot de passe',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF374151),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        decoration: InputDecoration(
                                          hintText: 'Entrez votre mot de passe',
                                          prefixIcon: const Icon(
                                            Icons.lock,
                                            color: Color(0xFF9CA3AF),
                                          ),
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off
                                                  : Icons.visibility,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword = !_obscurePassword;
                                              });
                                            },
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
                                            return 'Veuillez entrer votre mot de passe';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isVerySmallScreen ? 16 : 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Flexible(
                                        child: Row(
                                          children: [
                                            SizedBox(
                                              height: 16,
                                              width: 16,
                                              child: Checkbox(
                                                value: _rememberMe,
                                                onChanged: (value) {
                                                  setState(() {
                                                    _rememberMe = value ?? false;
                                                  });
                                                },
                                                activeColor: const Color(0xFF3B82F6),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                'Se souvenir de moi',
                                                style: TextStyle(
                                                  fontSize: isVerySmallScreen ? 12 : 14,
                                                  color: const Color(0xFF374151),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          context.go('/forgot-password');
                                        },
                                        style: TextButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: Text(
                                          'Oublié mot de passe ?',
                                          style: TextStyle(
                                            fontSize: isVerySmallScreen ? 12 : 14,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF3B82F6),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isVerySmallScreen ? 20 : (isSmallScreen ? 24 : 32)),
                                  if (authController.errorMessage != null)
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      decoration: BoxDecoration(
                                        color: Colors.red.shade50,
                                        border: Border.all(color: Colors.red.shade200),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade600),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              authController.errorMessage!,
                                              style: TextStyle(color: Colors.red.shade600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: authController.isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF3B82F6),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: authController.isLoading
                                          ? const SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor: AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                              ),
                                            )
                                          : const Text(
                                              'Connexion',
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
                          ],
                        ),
                      ),
                      if (!keyboardVisible || !isSmallScreen)
                        Padding(
                          padding: EdgeInsets.only(
                            top: isVerySmallScreen ? 16 : 24,
                            bottom: 16,
                          ),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Pas encore de compte ? ',
                                style: TextStyle(
                                  fontSize: isVerySmallScreen ? 12 : 14,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go('/register');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                child: Text(
                                  'S\'inscrire',
                                  style: TextStyle(
                                    fontSize: isVerySmallScreen ? 12 : 14,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authController = context.read<AuthController>();
      authController.clearError();
      
      final success = await authController.login(
        _phoneOrEmailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        context.go('/home');
      }
    }
  }
}