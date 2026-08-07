import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/crypto/crypto_service.dart';
import 'package:uuid/uuid.dart';

class VaultSetupService {
  final CryptoService crypto;
  final SupabaseClient client = Supabase.instance.client;

  VaultSetupService(this.crypto);

  /// Call this only when fetchUserKeys() returned null.
  Future<void> setupNewUser(String masterPassword) async {
    final userId = client.auth.currentUser!.id;

    // 1. Derive master key
    final salt = crypto.generateSalt();
    final masterKey = crypto.deriveMasterKey(masterPassword, salt);

    // 2. Generate identity keypair
    final identityKeyPair = crypto.generateIdentityKeyPair();

    // 3. Wrap private key with master key
    final wrapped =
        crypto.wrapPrivateKey(identityKeyPair.secretKey, masterKey);

    // 4. Upload user_keys row
    await client.from('user_keys').insert({
      'user_id': userId,
      'public_key': base64Encode(identityKeyPair.publicKey),
      'wrapped_private_key': base64Encode(wrapped.ciphertext),
      'private_key_nonce': base64Encode(wrapped.nonce),
      'kdf_salt': base64Encode(salt),
    });

    // 5. Create vault
    final vaultId = const Uuid().v4();
    await client.from('vaults').insert({'id': vaultId});

    // 6. Generate Vault Key, seal to own public key
    final vaultKey = crypto.generateVaultKey();
    final sealed =
        crypto.sealVaultKey(vaultKey, identityKeyPair.publicKey);

    // 7. Add self as vault member
    await client.from('vault_members').insert({
      'vault_id': vaultId,
      'user_id': userId,
      'wrapped_vault_key': base64Encode(sealed),
    });
  }
}