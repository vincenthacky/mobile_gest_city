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

class _QrScanPageState extends State<QrScanPage> {
  MobileScannerController? controller;
  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  void _initializeScanner() {
    controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal, // Changé pour Android
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
      formats: [BarcodeFormat.qrCode], // Uniquement QR codes
    );

    print('🎥 Scanner QR initialisé');
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> _handleBarcode(BarcodeCapture barcodes) async {
    print('📷 Callback appelé - Barcodes détectés: ${barcodes.barcodes.length}');

    // Protection contre le traitement multiple
    if (isProcessing) {
      print('⏸️ Déjà en cours de traitement, ignoré');
      return;
    }

    final barcode = barcodes.barcodes.firstOrNull;
    if (barcode == null) {
      print('❌ Aucun barcode valide');
      return;
    }

    if (barcode.rawValue == null || barcode.rawValue!.isEmpty) {
      print('❌ Barcode vide');
      return;
    }

    print('✅ QR Code détecté: ${barcode.rawValue}');

    // Verrouiller immédiatement
    isProcessing = true;

    // Arrêter le scanner
    print('⏹️ Arrêt du scanner...');
    await controller?.stop();
    print('⏹️ Scanner arrêté');

    if (!mounted) return;

    final code = barcode.rawValue!;
    await _processQrCode(code);
  }

  Future<void> _processQrCode(String code) async {
    print('🔍 Traitement du code: $code');
    final authController = Provider.of<AuthController>(context, listen: false);

    try {
      // Parser le QR code
      String villaNumber = code;
      try {
        final qrData = json.decode(code);
        if (qrData is Map<String, dynamic> && qrData.containsKey('villa_number')) {
          villaNumber = qrData['villa_number'];
        }
      } catch (e) {
        villaNumber = code;
      }

      // Vérifier le code villa
      final response = await authController.verifyVilla(villaNumber);

      if (!mounted) return;

      if (response != null && response['success'] == true) {
        final villaId = response['data']['villa_id'];

        _showSuccessSnackbar();

        // Navigation après un court délai
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/register?villa_id=$villaId');
        }
      } else {
        _showErrorSnackbar('Code QR invalide');
        await _resetScanner();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackbar('Erreur de vérification');
        await _resetScanner();
      }
    }
  }

  Future<void> _resetScanner() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      isProcessing = false;
      await controller?.start();
    }
  }

  void _showSuccessSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Code QR scanné avec succès',
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(milliseconds: 1500),
      ),
    );
  }

  void _showErrorSnackbar(String message) {
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

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final scanAreaSize = screenHeight * 0.3;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.go('/onboarding/choice'),
                    icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
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

            // Zone de scan
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      // Scanner
                      if (controller != null)
                        MobileScanner(
                          controller: controller!,
                          onDetect: _handleBarcode,
                        ),

                      // Overlay (ignorePointer pour ne pas bloquer)
                      IgnorePointer(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                          child: Center(
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
                                  // Coins
                                  ..._buildCorners(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Instruction
                      IgnorePointer(
                        child: Positioned(
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
                                color: Colors.black.withValues(alpha: 0.7),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Titre et description
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

            // Illustration
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
    );
  }

  List<Widget> _buildCorners() {
    return [
      _buildCorner(Alignment.topLeft, true, false, false, false),
      _buildCorner(Alignment.topRight, false, true, false, false),
      _buildCorner(Alignment.bottomLeft, false, false, true, false),
      _buildCorner(Alignment.bottomRight, false, false, false, true),
    ];
  }

  Widget _buildCorner(
    Alignment alignment,
    bool topLeft,
    bool topRight,
    bool bottomLeft,
    bool bottomRight,
  ) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          border: Border(
            top: (topLeft || topRight)
                ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
                : BorderSide.none,
            bottom: (bottomLeft || bottomRight)
                ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
                : BorderSide.none,
            left: (topLeft || bottomLeft)
                ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
                : BorderSide.none,
            right: (topRight || bottomRight)
                ? const BorderSide(color: Color(0xFF3B82F6), width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }
}
