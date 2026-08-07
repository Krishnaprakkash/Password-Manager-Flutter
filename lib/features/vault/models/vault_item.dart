class VaultItem {
  final String id;
  final String vaultId;
  final String ciphertext;
  final String nonce;
  final DateTime updatedAt;

  VaultItem({
    required this.id,
    required this.vaultId,
    required this.ciphertext,
    required this.nonce,
    required this.updatedAt,
  });

  factory VaultItem.fromRow(Map<String, dynamic> row) => VaultItem(
        id: row['id'] as String,
        vaultId: row['vault_id'] as String,
        ciphertext: row['ciphertext'] as String,
        nonce: row['nonce'] as String,
        updatedAt: DateTime.parse(row['updated_at'] as String),
      );
}