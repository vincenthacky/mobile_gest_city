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

  /// Convertit une clé publique RSA en format PEM standard X.509
  static String publicKeyToPem(RSAPublicKey publicKey) {
    // Créer la structure ASN.1 pour une clé publique RSA
    // RSAPublicKey ::= SEQUENCE {
    //     modulus           INTEGER,  -- n
    //     publicExponent    INTEGER   -- e
    // }
    
    final modulusBytes = _bigIntToBytes(publicKey.modulus!);
    final exponentBytes = _bigIntToBytes(publicKey.exponent!);
    
    // Construire la séquence ASN.1 RSAPublicKey
    final rsaPublicKeySeq = <int>[];
    rsaPublicKeySeq.addAll(_encodeAsn1Integer(modulusBytes));
    rsaPublicKeySeq.addAll(_encodeAsn1Integer(exponentBytes));
    final rsaPublicKeyDer = _encodeAsn1Sequence(rsaPublicKeySeq);
    
    // Créer l'AlgorithmIdentifier pour RSA
    // AlgorithmIdentifier ::= SEQUENCE {
    //     algorithm               OBJECT IDENTIFIER,
    //     parameters              ANY DEFINED BY algorithm OPTIONAL
    // }
    final rsaOid = [0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86, 0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00];
    
    // Encoder la clé publique comme BIT STRING
    final publicKeyBitString = _encodeAsn1BitString(rsaPublicKeyDer);
    
    // Construire la structure SubjectPublicKeyInfo
    // SubjectPublicKeyInfo ::= SEQUENCE {
    //     algorithm         AlgorithmIdentifier,
    //     subjectPublicKey  BIT STRING
    // }
    final spkiSeq = <int>[];
    spkiSeq.addAll(rsaOid);
    spkiSeq.addAll(publicKeyBitString);
    final spkiDer = _encodeAsn1Sequence(spkiSeq);
    
    // Encoder en base64 et formater en PEM
    final base64Encoded = base64.encode(spkiDer);
    return '-----BEGIN PUBLIC KEY-----\n${_formatBase64(base64Encoded)}\n-----END PUBLIC KEY-----';
  }
  
  /// Convertit un BigInt en bytes (format big-endian)
  static Uint8List _bigIntToBytes(BigInt value) {
    final hex = value.toRadixString(16);
    final paddedHex = hex.length % 2 == 0 ? hex : '0$hex';
    final bytes = <int>[];
    for (int i = 0; i < paddedHex.length; i += 2) {
      bytes.add(int.parse(paddedHex.substring(i, i + 2), radix: 16));
    }
    // Ajouter un byte 0x00 si le premier bit est 1 (pour éviter les nombres négatifs)
    if (bytes.isNotEmpty && bytes[0] & 0x80 != 0) {
      bytes.insert(0, 0x00);
    }
    return Uint8List.fromList(bytes);
  }
  
  /// Encode un INTEGER ASN.1
  static List<int> _encodeAsn1Integer(Uint8List bytes) {
    final result = <int>[0x02]; // INTEGER tag
    result.addAll(_encodeLength(bytes.length));
    result.addAll(bytes);
    return result;
  }
  
  /// Encode une SEQUENCE ASN.1
  static List<int> _encodeAsn1Sequence(List<int> content) {
    final result = <int>[0x30]; // SEQUENCE tag
    result.addAll(_encodeLength(content.length));
    result.addAll(content);
    return result;
  }
  
  /// Encode un BIT STRING ASN.1
  static List<int> _encodeAsn1BitString(List<int> bytes) {
    final result = <int>[0x03]; // BIT STRING tag
    result.addAll(_encodeLength(bytes.length + 1));
    result.add(0x00); // Nombre de bits inutilisés
    result.addAll(bytes);
    return result;
  }
  
  /// Encode la longueur au format ASN.1 DER
  static List<int> _encodeLength(int length) {
    if (length < 0x80) {
      return [length];
    } else {
      final bytes = <int>[];
      int temp = length;
      while (temp > 0) {
        bytes.insert(0, temp & 0xFF);
        temp >>= 8;
      }
      return [0x80 | bytes.length, ...bytes];
    }
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

  /// Parse une clé publique depuis le format PEM standard X.509
  static RSAPublicKey parsePublicKeyFromPem(String pem) {
    final stripped = pem
        .replaceAll('-----BEGIN PUBLIC KEY-----', '')
        .replaceAll('-----END PUBLIC KEY-----', '')
        .replaceAll('\n', '')
        .replaceAll('\r', '');
    
    try {
      // Essayer de parser le nouveau format PEM standard
      final derBytes = base64.decode(stripped);
      return _parseX509PublicKey(derBytes);
    } catch (e) {
      // Fallback : essayer l'ancien format JSON pour compatibilité
      try {
        final decodedKey = utf8.decode(base64.decode(stripped));
        final keyData = jsonDecode(decodedKey) as Map<String, dynamic>;
        
        final modulus = BigInt.parse(keyData['modulus'], radix: 16);
        final exponent = BigInt.parse(keyData['exponent'], radix: 16);
        
        return RSAPublicKey(modulus, exponent);
      } catch (e2) {
        throw Exception('Format de clé publique non supporté: $e');
      }
    }
  }
  
  /// Parse une clé publique au format X.509 DER
  static RSAPublicKey _parseX509PublicKey(Uint8List derBytes) {
    // Parser basique ASN.1 pour extraire modulus et exponent
    // Cette implémentation suppose un format standard SubjectPublicKeyInfo
    
    // Sauter l'en-tête SubjectPublicKeyInfo et AlgorithmIdentifier
    // Pour simplifier, on cherche la séquence RSA directement
    int offset = 0;
    
    // Chercher la séquence principale (tag 0x30)
    while (offset < derBytes.length && derBytes[offset] != 0x30) {
      offset++;
    }
    
    if (offset >= derBytes.length) {
      throw Exception('Format DER invalide');
    }
    
    // Sauter les métadonnées et aller à la clé RSA
    offset = _findRsaSequence(derBytes, offset);
    
    // Parser la séquence RSA (modulus, exponent)
    final (modulus, exponent) = _parseRsaSequence(derBytes, offset);
    
    return RSAPublicKey(modulus, exponent);
  }
  
  static int _findRsaSequence(Uint8List bytes, int start) {
    // Implémentation simplifiée : chercher la séquence contenant modulus/exponent
    // Cette fonction cherche le BIT STRING qui contient la séquence RSA
    int offset = start;
    
    while (offset < bytes.length - 1) {
      if (bytes[offset] == 0x03) { // BIT STRING tag
        // Sauter le tag et la longueur
        offset++;
        final length = _parseAsn1Length(bytes, offset);
        offset += _getLengthBytes(bytes, offset);
        offset++; // Sauter le byte "unused bits"
        
        // Maintenant on devrait être sur la séquence RSA
        if (offset < bytes.length && bytes[offset] == 0x30) {
          return offset;
        }
      }
      offset++;
    }
    
    throw Exception('Séquence RSA non trouvée dans le DER');
  }
  
  static (BigInt, BigInt) _parseRsaSequence(Uint8List bytes, int start) {
    int offset = start;
    
    // Vérifier que c'est une séquence
    if (bytes[offset] != 0x30) {
      throw Exception('Séquence RSA attendue');
    }
    
    offset++; // Sauter le tag SEQUENCE
    offset += _getLengthBytes(bytes, offset); // Sauter la longueur
    
    // Parser le modulus (premier INTEGER)
    if (bytes[offset] != 0x02) {
      throw Exception('INTEGER attendu pour modulus');
    }
    
    offset++; // Sauter le tag INTEGER
    final modulusLength = _parseAsn1Length(bytes, offset);
    offset += _getLengthBytes(bytes, offset);
    
    final modulusBytes = bytes.sublist(offset, offset + modulusLength);
    final modulus = _bytesToBigInt(modulusBytes);
    offset += modulusLength;
    
    // Parser l'exponent (deuxième INTEGER)
    if (bytes[offset] != 0x02) {
      throw Exception('INTEGER attendu pour exponent');
    }
    
    offset++; // Sauter le tag INTEGER
    final exponentLength = _parseAsn1Length(bytes, offset);
    offset += _getLengthBytes(bytes, offset);
    
    final exponentBytes = bytes.sublist(offset, offset + exponentLength);
    final exponent = _bytesToBigInt(exponentBytes);
    
    return (modulus, exponent);
  }
  
  static int _parseAsn1Length(Uint8List bytes, int offset) {
    final firstByte = bytes[offset];
    
    if (firstByte & 0x80 == 0) {
      // Forme courte
      return firstByte;
    } else {
      // Forme longue
      final lengthBytes = firstByte & 0x7F;
      int length = 0;
      
      for (int i = 1; i <= lengthBytes; i++) {
        length = (length << 8) | bytes[offset + i];
      }
      
      return length;
    }
  }
  
  static int _getLengthBytes(Uint8List bytes, int offset) {
    final firstByte = bytes[offset];
    
    if (firstByte & 0x80 == 0) {
      return 1; // Forme courte
    } else {
      return 1 + (firstByte & 0x7F); // 1 + nombre de bytes de longueur
    }
  }
  
  static BigInt _bytesToBigInt(Uint8List bytes) {
    // Supprimer le byte 0x00 de padding s'il existe
    final cleanBytes = bytes[0] == 0x00 && bytes.length > 1 
        ? bytes.sublist(1) 
        : bytes;
    
    final hex = cleanBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
    return BigInt.parse(hex, radix: 16);
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
    
    // Utiliser le constructeur sans exposant public (pointycastle v3+)
    return RSAPrivateKey(modulus, privateExponent, p, q);
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