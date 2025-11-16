import 'dart:convert';
import 'package:crypto/crypto.dart';

class ReportChecksumService {
  /// Calcule le checksum d'un signalement individuel à partir de son contenu JSON
  static String calculateItemChecksum(Map<String, dynamic> item) {
    final jsonString = jsonEncode(item);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  /// Calcule le checksum global à partir d'une liste de checksums individuels
  static String calculateGlobalChecksum(List<Map<String, dynamic>> checksums) {
    final jsonString = jsonEncode(checksums);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  /// Calcule le checksum global à partir d'une liste de strings de checksums
  /// CONFORME à la logique JavaScript (SANS tri pour préserver l'ordre)
  static String calculateGlobalChecksumFromStrings(List<String> checksums) {
    // NE PAS trier - garder l'ordre naturel comme en JavaScript
    final jsonString = jsonEncode(checksums);
    return sha256.convert(utf8.encode(jsonString)).toString();
  }

  /// Calcule le checksum d'un signalement à partir du ReportModel
  static String calculateReportChecksum(Map<String, dynamic> reportJson) {
    // Créer une copie pour éviter de modifier l'original
    final Map<String, dynamic> cleanReport = Map<String, dynamic>.from(reportJson);
    
    // Supprimer les champs qui ne doivent pas affecter le checksum
    cleanReport.remove('created_at');
    cleanReport.remove('updated_at');
    
    // Trier les clés pour assurer un ordre constant
    final sortedKeys = cleanReport.keys.toList()..sort();
    final Map<String, dynamic> sortedReport = {};
    for (final key in sortedKeys) {
      sortedReport[key] = cleanReport[key];
    }
    
    return calculateItemChecksum(sortedReport);
  }

  /// Vérifie si deux checksums sont identiques
  static bool areChecksumsEqual(String checksum1, String checksum2) {
    return checksum1 == checksum2;
  }

  /// Génère un hash simple pour les tests ou debug
  static String generateSimpleHash(String input) {
    return sha256.convert(utf8.encode(input)).toString().substring(0, 8);
  }

  /// Valide qu'un checksum a le format SHA256 attendu
  static bool isValidChecksum(String checksum) {
    return RegExp(r'^[a-f0-9]{64}$').hasMatch(checksum);
  }
}