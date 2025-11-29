import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../controllers/admin_payments_controller.dart';

class QRScanAdminPage extends StatefulWidget {
  const QRScanAdminPage({super.key});

  @override
  State<QRScanAdminPage> createState() => _QRScanAdminPageState();
}

class _QRScanAdminPageState extends State<QRScanAdminPage>
    with TickerProviderStateMixin {
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

        // Traiter le QR code scanné
        _processQRCode(barcode.rawValue!);
        break;
      }
    }
  }

  void _processQRCode(String code) async {
    try {
      // Parser le QR code pour extraire villa_number
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

      if (!mounted) return;

      // Appeler l'API pour vérifier le QR code
      final controller = Provider.of<AdminPaymentsController>(context, listen: false);
      final response = await controller.verifyQRCode(villaNumber);

      if (!mounted) return;

      if (response != null && response.success) {
        // Succès - afficher message et naviguer
        _showSuccessMessage();

        // Attendre un peu puis naviguer vers la page de validation
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            context.push('/admin/qr-validate', extra: response.data);
          }
        });
      } else {
        // QR code invalide ou utilisateur non trouvé
        _showErrorMessage('QR code incorrect ou utilisateur non trouvé.');
        _resetScanning();
      }
    } catch (e) {
      // Erreur lors du traitement
      if (mounted) {
        _showErrorMessage('Erreur lors du scan: ${e.toString()}');
        _resetScanning();
      }
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'QR code scanné avec succès !',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFEF4444),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
    final scanAreaSize = screenHeight * 0.35;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Stack(
            children: [
              // Scanner plein écran
              MobileScanner(controller: cameraController, onDetect: _onDetect),

              // Overlay avec zone de scan
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                ),
                child: Column(
                  children: [
                    // Header avec bouton retour
                    Container(
                      height: 64,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Scanner QR Code',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Zone de scan centrale
                    Center(
                      child: Container(
                        width: scanAreaSize,
                        height: scanAreaSize,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFF4F46E5),
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Stack(
                          children: [
                            // Animation de scan
                            AnimatedBuilder(
                              animation: _scanAnimation,
                              builder: (context, child) {
                                return Positioned(
                                  top: scanAreaSize * _scanAnimation.value - 2,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 2,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF4F46E5),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF4F46E5,
                                          ).withValues(alpha: 0.6),
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
                                  corner = const _ScanCorner(isTopLeft: true);
                                  break;
                                case 1: // Top-right
                                  alignment = Alignment.topRight;
                                  corner = const _ScanCorner(isTopRight: true);
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

                              return Align(alignment: alignment, child: corner);
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Instructions
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF4F46E5).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: const Color(0xFF4F46E5),
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Scannez le QR de l\'utilisateur',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Positionnez le QR code dans le cadre\nLe scan se fera automatiquement',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Contrôles en bas
                    Container(
                      padding: const EdgeInsets.all(24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Bouton flash
                          IconButton(
                            onPressed: () => cameraController.toggleTorch(),
                            icon: const Icon(Icons.flash_on),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),

                          // Bouton retourner caméra
                          IconButton(
                            onPressed: () => cameraController.switchCamera(),
                            icon: const Icon(Icons.cameraswitch),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
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
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        border: Border(
          top: (isTopLeft || isTopRight)
              ? const BorderSide(color: Color(0xFF4F46E5), width: 5)
              : BorderSide.none,
          bottom: (isBottomLeft || isBottomRight)
              ? const BorderSide(color: Color(0xFF4F46E5), width: 5)
              : BorderSide.none,
          left: (isTopLeft || isBottomLeft)
              ? const BorderSide(color: Color(0xFF4F46E5), width: 5)
              : BorderSide.none,
          right: (isTopRight || isBottomRight)
              ? const BorderSide(color: Color(0xFF4F46E5), width: 5)
              : BorderSide.none,
        ),
      ),
    );
  }
}
