import 'dart:typed_data';
import 'package:sodium/sodium_sumo.dart';

class CryptoService {
  final SodiumSumo sodium;
  CryptoService(this.sodium);

  // ---- 1. Master key derivation (Argon2id) ----
  SecureKey deriveMasterKey(String password, Uint8List salt) {
    return sodium.crypto.pwhash.call(
      outLen: sodium.crypto.secretBox.keyBytes,
      password: Int8List.fromList(password.codeUnits),
      salt: salt,
      opsLimit: sodium.crypto.pwhash.opsLimitModerate,
      memLimit: sodium.crypto.pwhash.memLimitModerate,
      alg: CryptoPwhashAlgorithm.argon2id13,
    );
  }

  Uint8List generateSalt() =>
      sodium.randombytes.buf(sodium.crypto.pwhash.saltBytes);

  // ---- 2. Identity keypair (X25519) ----
  KeyPair generateIdentityKeyPair() => sodium.crypto.box.keyPair();

  // ---- 3. Wrap / unwrap private key with master key ----
  ({Uint8List ciphertext, Uint8List nonce}) wrapPrivateKey(
      SecureKey privateKey, SecureKey masterKey) {
    final nonce =
        sodium.randombytes.buf(sodium.crypto.secretBox.nonceBytes);
    final ciphertext = sodium.crypto.secretBox.easy(
      message: privateKey.extractBytes(),
      nonce: nonce,
      key: masterKey,
    );
    return (ciphertext: ciphertext, nonce: nonce);
  }

  SecureKey unwrapPrivateKey(
      Uint8List ciphertext, Uint8List nonce, SecureKey masterKey) {
    final bytes = sodium.crypto.secretBox.openEasy(
      cipherText: ciphertext,
      nonce: nonce,
      key: masterKey,
    );
    return SecureKey.fromList(sodium, bytes);
  }

  // ---- 4. Seal / unseal Vault Key to a member's public key ----
  Uint8List sealVaultKey(SecureKey vaultKey, Uint8List recipientPublicKey) {
    return sodium.crypto.box.seal(
      message: vaultKey.extractBytes(),
      publicKey: recipientPublicKey,
    );
  }

  SecureKey unsealVaultKey(Uint8List sealedBox, KeyPair recipientKeyPair) {
    final bytes = sodium.crypto.box.sealOpen(
      cipherText: sealedBox,
      publicKey: recipientKeyPair.publicKey,
      secretKey: recipientKeyPair.secretKey,
    );
    return SecureKey.fromList(sodium, bytes);
  }

  SecureKey generateVaultKey() =>
      sodium.crypto.secretBox.keygen();

  // ---- 5. Encrypt / decrypt vault items ----
  ({Uint8List ciphertext, Uint8List nonce}) encryptItem(
      String plaintextJson, SecureKey vaultKey) {
    final nonce =
        sodium.randombytes.buf(sodium.crypto.secretBox.nonceBytes);
    final ciphertext = sodium.crypto.secretBox.easy(
      message: Uint8List.fromList(plaintextJson.codeUnits),
      nonce: nonce,
      key: vaultKey,
    );
    return (ciphertext: ciphertext, nonce: nonce);
  }

  String decryptItem(
      Uint8List ciphertext, Uint8List nonce, SecureKey vaultKey) {
    final bytes = sodium.crypto.secretBox.openEasy(
      cipherText: ciphertext,
      nonce: nonce,
      key: vaultKey,
    );
    return String.fromCharCodes(bytes);
  }
}