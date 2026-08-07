import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/decrypted_vault_item.dart';
import '../repositories/vault_items_repository.dart';
import '../services/unlock_service.dart';
import '../../../core/crypto/sodium_provider.dart';

class VaultScreen extends ConsumerStatefulWidget {
  const VaultScreen({super.key});

  @override
  ConsumerState<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends ConsumerState<VaultScreen> {
  List<DecryptedVaultItem> _items = [];
  List<DecryptedVaultItem> _filtered = [];
  bool _loading = true;
  String? _error;
  UnlockResult? _unlock;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_unlock == null) {
      _unlock = ModalRoute.of(context)!.settings.arguments as UnlockResult?;
      if (_unlock == null) {
        setState(() {
          _error = 'No unlock result received';
          _loading = false;
        });
      } else {
        _load(_unlock!);
      }
    }
  }

  Future<void> _load(UnlockResult unlock) async {
    try {
      final crypto = await ref.read(cryptoServiceProvider.future);
      final repo = VaultItemsRepository(Supabase.instance.client, crypto);
      final encrypted = await repo.fetchEncryptedItems(unlock.vaultId);
      final items = repo.decryptAll(encrypted, unlock.vaultKey);
      items.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      setState(() {
        _items = items;
        _filtered = items;
        _loading = false;
      });
    } catch (e, st) {
      debugPrint('Vault load error: $e\n$st');
      setState(() {
        _error = 'Failed to load vault items';
        _loading = false;
      });
    }
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = query.isEmpty
          ? _items
          : _items.where((i) => i.matches(query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Search title, username, notes',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: _onSearch,
                      ),
                    ),
                    Expanded(
                      child: _filtered.isEmpty
                          ? const Center(child: Text('No items'))
                          : ListView.builder(
                              itemCount: _filtered.length,
                              itemBuilder: (context, i) {
                                final item = _filtered[i];
                                return ListTile(
                                  title: Text(item.title),
                                  subtitle: Text(item.username),
                                  onTap: () {
                                    // TODO next: /view-item route
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final saved = await Navigator.of(context).pushNamed(
            '/add-item',
            arguments: _unlock,
          );
          if (saved == true && _unlock != null) _load(_unlock!);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}