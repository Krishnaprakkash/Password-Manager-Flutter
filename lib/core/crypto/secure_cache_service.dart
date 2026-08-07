import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sodium/sodium_sumo.dart';
import 'dart:typed_data';

class SecureCacheService {
  final _storage = const FlutterSecureStorage();
  static const _kPrivateKey = 'cached_private_key';
  static const _kPublicKey = 'cached_public_key';
  static const _kVaultKey = 'cached_vault_key';
  static const _kVaultId = 'cached_vault_id';
  static const _kPinHash = 'pin_hash';
  static const _kAttempts = 'pin_attempts';

  Future<void> cacheSession({
    required KeyPair identityKeyPair,
    required SecureKey vaultKey,
    required String vaultId,
  }) async {
    await _storage.write(
        key: _kPrivateKey,
        value: base64Encode(identityKeyPair.secretKey.extractBytes()));
    await _storage.write(
        key: _kPublicKey, value: base64Encode(identityKeyPair.publicKey));
    await _storage.write(
        key: _kVaultKey, value: base64Encode(vaultKey.extractBytes()));
    await _storage.write(key: _kVaultId, value: vaultId);
  }

  Future<bool> hasCachedSession() async =>
      (await _storage.read(key: _kPrivateKey)) != null;

  Future<({KeyPair identityKeyPair, SecureKey vaultKey, String vaultId})?>
      readCachedSession(SodiumSumo sodium) async {
    final priv = await _storage.read(key: _kPrivateKey);
    final pub = await _storage.read(key: _kPublicKey);
    final vk = await _storage.read(key: _kVaultKey);
    final vaultId = await _storage.read(key: _kVaultId);
    if (priv == null || pub == null || vk == null || vaultId == null) {
      return null;
    }
    return (
      identityKeyPair: KeyPair(
        publicKey: base64Decode(pub),
        secretKey: SecureKey.fromList(sodium, base64Decode(priv)),
      ),
      vaultKey: SecureKey.fromList(sodium, base64Decode(vk)),
      vaultId: vaultId,
    );
  }

  Future<void> setPin(String pin, SodiumSumo sodium) async {
    final hash = sodium.crypto.genericHash
        .call(message: Uint8List.fromList(pin.codeUnits));
    await _storage.write(key: _kPinHash, value: base64Encode(hash));
    await _storage.write(key: _kAttempts, value: '0');
  }

  Future<bool> verifyPin(String pin, SodiumSumo sodium) async {
    final stored = await _storage.read(key: _kPinHash);
    if (stored == null) return false;
    final hash = sodium.crypto.genericHash
        .call(message: Uint8List.fromList(pin.codeUnits));
    final match = base64Encode(hash) == stored;

    if (match) {
      await _storage.write(key: _kAttempts, value: '0');
      return true;
    }

    final attempts = int.parse(await _storage.read(key: _kAttempts) ?? '0') + 1;
    if (attempts >= 5) {
      await clearSession();
      return false;
    }
    await _storage.write(key: _kAttempts, value: attempts.toString());
    return false;
  }

  Future<int> remainingAttempts() async {
    final attempts = int.parse(await _storage.read(key: _kAttempts) ?? '0');
    return 5 - attempts;
  }

  Future<bool> hasPin() async => (await _storage.read(key: _kPinHash)) != null;

  Future<void> clearSession() async => _storage.deleteAll();
}