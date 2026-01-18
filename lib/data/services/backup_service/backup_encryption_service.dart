import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pointycastle/export.dart';

class BackupEncryptionService {
  static const _keyName = 'inner_voices_backup_key';
  final _storage = const FlutterSecureStorage();

  Future<Uint8List> _getOrCreateKey() async {
    final existing = await _storage.read(key: _keyName);
    if (existing != null) {
      return base64Decode(existing);
    }

    final key = _secureRandomBytes(32); // 256-bit
    await _storage.write(key: _keyName, value: base64Encode(key));
    return key;
  }

  Future<Uint8List> encrypt(Uint8List data) async {
    final key = await _getOrCreateKey();
    final iv = _secureRandomBytes(12);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(true, AEADParameters(KeyParameter(key), 128, iv, Uint8List(0)));

    final encrypted = cipher.process(data);
    return Uint8List.fromList(iv + encrypted);
  }

  Future<Uint8List> decrypt(Uint8List encryptedData) async {
    final key = await _getOrCreateKey();
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
