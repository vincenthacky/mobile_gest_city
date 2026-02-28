import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';

/// Optimise les images avant upload :
/// - Convertit tout en JPEG (HEIC, PNG, WebP…)
/// - Supprime les métadonnées EXIF
/// - Corrige automatiquement l'orientation EXIF
/// - Redimensionne intelligemment (max 1920px côté)
/// - Compresse à qualité 85 (sweet spot qualité/taille)
/// - Ne recompresse pas les JPEG déjà < 800 KB
class ImageOptimizer {
  // Qualité cible : sweet spot recommandé (texte lisible, photo nette)
  static const int _quality = 85;

  // Dimension maximale en pixels (largeur ou hauteur)
  static const int _maxDimension = 1920;

  // Seuil en dessous duquel on ne recompresse pas (si déjà JPEG)
  static const int _skipThresholdBytes = 800 * 1024; // 800 KB

  /// Optimise une seule image et retourne un [File] JPEG prêt pour l'upload.
  ///
  /// Règles :
  /// - HEIC/HEIF → toujours converti (jamais accepté par les backends)
  /// - > 800 KB → redimensionné + compressé
  /// - JPEG déjà ≤ 800 KB → retourné tel quel (pas de dégradation inutile)
  static Future<File> optimize(File file) async {
    try {
      final fileSize = await file.length();
      final ext = file.path.split('.').last.toLowerCase();
      final isHeic = ext == 'heic' || ext == 'heif';
      final isJpeg = ext == 'jpg' || ext == 'jpeg';

      // Cas : JPEG léger — on évite la recompression inutile
      if (isJpeg && !isHeic && fileSize < _skipThresholdBytes) {
        debugPrint(
          '📸 [ImageOptimizer] Skip ${fileSize ~/ 1024} KB JPEG (déjà optimal)',
        );
        return file;
      }

      return await _compress(file, fileSize);
    } catch (e) {
      debugPrint('⚠️ [ImageOptimizer] Erreur optimisation "${file.path}": $e');
      // Fallback : retourner le fichier original plutôt qu'échouer
      return file;
    }
  }

  static Future<File> _compress(File file, int originalSize) async {
    final tempDir = await getTemporaryDirectory();
    final ts = DateTime.now().millisecondsSinceEpoch;
    final targetPath = '${tempDir.path}/opt_$ts.jpg';

    // flutter_image_compress :
    // - minWidth/minHeight = dimension cible max (pas d'upscale si image plus petite)
    // - format = CompressFormat.jpeg → conversion forcée (HEIC, PNG, etc.)
    // - keepExif = false → supprime toutes les métadonnées
    // - autoCorrectionAngle = true → corrige l'orientation EXIF
    final XFile? result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      minWidth: _maxDimension,
      minHeight: _maxDimension,
      quality: _quality,
      format: CompressFormat.jpeg,
      keepExif: false,
      autoCorrectionAngle: true,
    );

    if (result == null) {
      debugPrint(
        '⚠️ [ImageOptimizer] Compression nulle, fichier original conservé',
      );
      return file;
    }

    final optimized = File(result.path);
    final optimizedSize = await optimized.length();
    final savedPct = ((1 - optimizedSize / originalSize) * 100).toStringAsFixed(0);
    debugPrint(
      '✅ [ImageOptimizer] ${originalSize ~/ 1024} KB → ${optimizedSize ~/ 1024} KB ($savedPct% économisé)',
    );

    return optimized;
  }

  /// Optimise plusieurs images en parallèle.
  static Future<List<File>> optimizeAll(List<File> files) async {
    return Future.wait(files.map(optimize));
  }
}
