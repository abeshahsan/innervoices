import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pointycastle/export.dart';

class BackupEncryptionService {
  /// Gets the encryption key from environment variables.
  /// This key is consistent across all app installations.
  Uint8List _getKey() {
    final base64Key = dotenv.env['BACKUP_ENCRYPTION_KEY'];
    if (base64Key == null || base64Key.isEmpty) {
      throw Exception(
        'BACKUP_ENCRYPTION_KEY not found in .env file. '
        'Please ensure the .env file exists and contains the key.',
      );
    }
    return base64Decode(base64Key);
  }

  Future<Uint8List> encrypt(Uint8List data) async {
    final key = _getKey();
    final iv = _secureRandomBytes(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final encrypted = cipher.process(data);
    return Uint8List.fromList(iv + encrypted);
  }

  Future<Uint8List> decrypt(Uint8List encryptedData) async {
    final key = _getKey();
    final iv = encryptedData.sublist(0, 12);
    final cipherText = encryptedData.sublist(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(false, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    return cipher.process(cipherText);
  }

  Uint8List _secureRandomBytes(int length) {
    final random = SecureRandom('Fortuna')
      ..seed(
        KeyParameter(
          Uint8List.fromList(
            List.generate(
              32,
              (_) => DateTime.now().millisecondsSinceEpoch & 0xff,
            ),
          ),
        ),
      );

    return random.nextBytes(length);
  }
}
