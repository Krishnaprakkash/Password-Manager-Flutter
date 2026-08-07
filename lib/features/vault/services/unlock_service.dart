import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sodium/sodium_sumo.dart';
import '../../../core/crypto/crypto_service.dart';

class UnlockResult {
  final KeyPair identityKeyPair;
  final SecureKey vaultKey;
  final String vaultId;
  UnlockResult(this.identityKeyPair, this.vaultKey, this.vaultId);
}

class UnlockService {
  final CryptoService crypto;
  final SupabaseClient client = Supabase.instance.client;

  UnlockService(this.crypto);

  Future<UnlockResult> unlock(String masterPassword) async {
    final userId = client.auth.currentUser!.id;

    final keysRow = await client
        .from('user_keys')
        .select()
        .eq('user_id', userId)
        .single();

    final salt = base64Decode(keysRow['kdf_salt']);
    final masterKey = crypto.deriveMasterKey(masterPassword, salt);

    final privateKey = crypto.unwrapPrivateKey(
      base64Decode(keysRow['wrapped_private_key']),
      base64Decode(keysRow['private_key_nonce']),
      masterKey,
    );

    final publicKey = base64Decode(keysRow['public_key']);
    final identityKeyPair = KeyPair(
      publicKey: publicKey,
      secretKey: privateKey,
    );

    final memberRow = await client
        .from('vault_members')
        .select()
        .eq('user_id', userId)
        .single();

    final vaultKey = crypto.unsealVaultKey(
      base64Decode(memberRow['wrapped_vault_key']),
      identityKeyPair,
    );

    return UnlockResult(
      identityKeyPair,
      vaultKey,
      memberRow['vault_id'] as String,
    );
  }
}