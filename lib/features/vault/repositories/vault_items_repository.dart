import 'dart:convert';
import 'package:sodium/sodium_sumo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vault_item.dart';
import '../models/decrypted_vault_item.dart';
import '../../../core/crypto/crypto_service.dart';

class VaultItemsRepository {
  final SupabaseClient _client;
  final CryptoService _crypto;

  VaultItemsRepository(this._client, this._crypto);

  Future<List<VaultItem>> fetchEncryptedItems(String vaultId) async {
    final rows = await _client
        .from('vault_items')
        .select()
        .eq('vault_id', vaultId);
    return (rows as List)
        .map((r) => VaultItem.fromRow(r as Map<String, dynamic>))
        .toList();
  }

  List<DecryptedVaultItem> decryptAll(
    List<VaultItem> items,
    SecureKey vaultKey,
  ) {
    final result = <DecryptedVaultItem>[];
    for (final item in items) {
      try {
        final ciphertext = base64Decode(item.ciphertext);
        final nonce = base64Decode(item.nonce);
        final plaintext = _crypto.decryptItem(ciphertext, nonce, vaultKey);
        final map = jsonDecode(plaintext) as Map<String, dynamic>;
        result.add(DecryptedVaultItem(
          id: item.id,
          title: map['t'] as String? ?? '',
          username: map['u'] as String? ?? '',
          password: map['p'] as String? ?? '',
          notes: map['n'] as String? ?? '',
        ));
      } catch (_) {
        continue;
      }
    }
    return result;
  }
}