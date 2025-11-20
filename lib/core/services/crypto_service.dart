import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'dart:math';

class CryptoService {
  static const int _keySize = 2048;

  /// Génère une paire de clés RSA
  static Future<KeyPair> generateRSAKeyPair() async {
    final keyGen = RSAKeyGenerator();
    final secureRandom = FortunaRandom();
    
    // Initialiser le générateur aléatoire
    final seedSource = Random.secure();
    final seeds = <int>[];
    for (int i = 0; i < 32; i++) {
      seeds.add(seedSource.nextInt(255));
    }
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    
    keyGen.init(ParametersWithRandom(
      RSAKeyGeneratorParameters(BigInt.parse('65537'), _keySize, 64),
      secureRandom,
    ));
    
    final pair = keyGen.generateKeyPair();
    return KeyPair(pair.publicKey as RSAPublicKey, pair.privateKey as RSAPrivateKey);
  }

  /// Convertit une clé publique RSA en format PEM simplifié
  static String publicKeyToPem(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!.toRadixString(16);
    final exponent = publicKey.exponent!.toRadixString(16);
    
    final keyData = {
      'modulus': modulus,
      'exponent': exponent,
    };
    
    final jsonString = jsonEncode(keyData);
    final encodedKey = base64.encode(utf8.encode(jsonString));
    
    return '-----BEGIN PUBLIC KEY-----\n${_formatBase64(encodedKey)}\n-----END PUBLIC KEY-----';
  }

  /// Convertit une clé privée RSA en format PEM simplifié
  static String privateKeyToPem(RSAPrivateKey privateKey) {
    final modulus = privateKey.modulus!.toRadixString(16);
    final privateExponent = privateKey.privateExponent!.toRadixString(16);
    final p = privateKey.p!.toRadixString(16);
    final q = privateKey.q!.toRadixString(16);
    
    final keyData = {
      'modulus': modulus,
      'privateExponent': privateExponent,
      'p': p,
      'q': q,
    };
    
    final jsonString = jsonEncode(keyData);
    final encodedKey = base64.encode(utf8.encode(jsonString));
    
    return '-----BEGIN PRIVATE KEY-----\n${_formatBase64(encodedKey)}\n-----END PRIVATE KEY-----';
  }

  /// Signe des données avec une clé privée RSA
  static String signData(String data, RSAPrivateKey privateKey) {
    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    
    final signature = signer.generateSignature(Uint8List.fromList(utf8.encode(data)));
    return base64.encode(signature.bytes);
  }

  /// Parse une clé publique depuis le format PEM simplifié
  static RSAPublicKey parsePublicKeyFromPem(String pem) {
    final stripped = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
    
    final decodedKey = utf8.decode(base64.decode(stripped));
    final keyData = jsonDecode(decodedKey) as Map<String, dynamic>;
    
    final modulus = BigInt.parse(keyData['modulus'], radix: 16);
    final exponent = BigInt.parse(keyData['exponent'], radix: 16);
    
    return RSAPublicKey(modulus, exponent);
  }

  /// Parse une clé privée depuis le format PEM simplifié
  static RSAPrivateKey parsePrivateKeyFromPem(String pem) {
    final stripped = pem
        .replaceAll('-----BEGIN PRIVATE KEY-----', '')
        .replaceAll('-----END PRIVATE KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
    
    final decodedKey = utf8.decode(base64.decode(stripped));
    final keyData = jsonDecode(decodedKey) as Map<String, dynamic>;
    
    final modulus = BigInt.parse(keyData['modulus'], radix: 16);
    final privateExponent = BigInt.parse(keyData['privateExponent'], radix: 16);
    final p = BigInt.parse(keyData['p'], radix: 16);
    final q = BigInt.parse(keyData['q'], radix: 16);
    
    return RSAPrivateKey(modulus, BigInt.parse('65537'), privateExponent, p, q);
  }

  /// Formate une chaîne base64 avec des retours à la ligne
  static String _formatBase64(String base64) {
    final regex = RegExp(r'.{1,64}');
    return regex.allMatches(base64).map((match) => match.group(0)).join('\n');
  }
}

/// Classe pour stocker une paire de clés
class KeyPair {
  final RSAPublicKey publicKey;
  final RSAPrivateKey privateKey;

  KeyPair(this.publicKey, this.privateKey);
}