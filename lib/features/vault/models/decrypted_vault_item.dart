class DecryptedVaultItem {
  final String id;
  final String title;
  final String username;
  final String password;
  final String notes;

  DecryptedVaultItem({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    required this.notes,
  });

  bool matches(String query) {
    final q = query.toLowerCase();
    return title.toLowerCase().contains(q) ||
        username.toLowerCase().contains(q) ||
        notes.toLowerCase().contains(q);
  }
}