import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../controller/auth_controller.dart';

class QrScanPage extends StatefulWidget {
  const QrScanPage({super.key});

  @override
  State<QrScanPage> createState() => _QrScanPageState();
}

class _QrScanPageState extends State<QrScanPage> with TickerProviderStateMixin {
  late MobileScannerController cameraController;
  late AnimationController _fadeController;
  late AnimationController _scanController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scanAnimation;

  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scanController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    _fadeController.forward();
    _scanController.repeat();
  }

  @override
  void dispose() {
    cameraController.dispose();
    _fadeController.dispose();
    _scanController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (!_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false;
        });

        // Simulation : après scan, naviguer vers register avec les données
        _showSuccessAndNavigate(barcode.rawValue!);
        break;
      }
    }
  }

  void _showSuccessAndNavigate(String code) async {
    final authController = Provider.of<AuthController>(context, listen: false);

    try {
      // Parser le QR code au nouveau format {"villa_code":"","villa_number":"Villa-360"}
      String villaNumber = code;
      try {
        final qrData = json.decode(code);
        if (qrData is Map<String, dynamic> &&
            qrData.containsKey('villa_number')) {
          villaNumber = qrData['villa_number'];
        }
      } catch (e) {
        // Si ce n'est pas du JSON, utiliser le code tel quel
        villaNumber = code;
      }

      // Appeler l'API pour vérifier le code villa avec le nouveau format
      final response = await authController.verifyVilla(villaNumber);

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        // Succès - naviguer vers register avec villa_id de la réponse API
        final villaId = response['data']['villa_id'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Code QR scanné avec succès ! 🎉',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
        );

        // Attendre un peu puis naviguer vers register avec villa_id
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (mounted) {
            context.go('/register?villa_id=$villaId');
          }
        });
      } else {
        // Échec - afficher message d'erreur
        _showErrorMessage('QR code incorrect.');
        _resetScanning();
      }
    } catch (e) {
      // Erreur - afficher message d'erreur
      if (mounted) {
        _showErrorMessage('QR code incorrect.');
        _resetScanning();
      }
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _resetScanning() {
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        setState(() {
          _isScanning = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final scanAreaSize = screenHeight * 0.3;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Header avec bouton retour
              Container(
                height: 64,
                padding: const EdgeInsets.symmetric(horizontal: 24),
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

              const SizedBox(height: 20),

              // Zone de scan avec caméra (en haut maintenant)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Stack(
                      children: [
                        // Caméra
                        MobileScanner(
                          controller: cameraController,
                          onDetect: _onDetect,
                        ),

                        // Overlay avec zone de scan
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: Stack(
                            children: [
                              // Zone transparente pour le scan
                              Center(
                                child: Container(
                                  width: scanAreaSize,
                                  height: scanAreaSize,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF3B82F6),
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Animation de scan
                                      AnimatedBuilder(
                                        animation: _scanAnimation,
                                        builder: (context, child) {
                                          return Positioned(
                                            top:
                                                scanAreaSize *
                                                    _scanAnimation.value -
                                                2,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 2,
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF3B82F6),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: const Color(
                                                      0xFF3B82F6,
                                                    ).withValues(alpha: 0.5),
                                                    blurRadius: 8,
                                                    spreadRadius: 2,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),

                                      // Coins de la zone de scan
                                      ...List.generate(4, (index) {
                                        late Alignment alignment;
                                        late Widget corner;

                                        switch (index) {
                                          case 0: // Top-left
                                            alignment = Alignment.topLeft;
                                            corner = const _ScanCorner(
                                              isTopLeft: true,
                                            );
                                            break;
                                          case 1: // Top-right
                                            alignment = Alignment.topRight;
                                            corner = const _ScanCorner(
                                              isTopRight: true,
                                            );
                                            break;
                                          case 2: // Bottom-left
                                            alignment = Alignment.bottomLeft;
                                            corner = const _ScanCorner(
                                              isBottomLeft: true,
                                            );
                                            break;
                                          case 3: // Bottom-right
                                            alignment = Alignment.bottomRight;
                                            corner = const _ScanCorner(
                                              isBottomRight: true,
                                            );
                                            break;
                                        }

                                        return Align(
                                          alignment: alignment,
                                          child: corner,
                                        );
                                      }),
                                    ],
                                  ),
                                ),
                              ),

                              // Instruction en bas
                              Positioned(
                                bottom: 40,
                                left: 0,
                                right: 0,
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.7,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Positionne le QR code dans le cadre',
                                      style: GoogleFonts.nunito(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w500,
                                      ),
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
                ),
              ),

              const SizedBox(height: 16),

              // Titre et description (juste en dessous du cadre)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      'Scanne ton code QR',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                        height: 1.2,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      'Scanne le code QR de ta villa pour rejoindre ta communauté',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 15,
                        color: const Color(0xFF6B7280),
                        height: 1.4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Illustration Storyset (agrandie intelligemment)
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Image.asset(
                    'assets/images/QR-Code-amico.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: const Color(0xFFF9FAFB),
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScanCorner extends StatelessWidget {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;

  const _ScanCorner({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border(
          top: (isTopLeft || isTopRight)
              ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
              : BorderSide.none,
          bottom: (isBottomLeft || isBottomRight)
              ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
              : BorderSide.none,
          left: (isTopLeft || isBottomLeft)
              ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
              : BorderSide.none,
          right: (isTopRight || isBottomRight)
              ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
              : BorderSide.none,
        ),
      ),
    );
  }
}
