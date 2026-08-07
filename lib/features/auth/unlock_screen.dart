import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/sodium_provider.dart';
import '../vault/services/unlock_service.dart';
import '../../core/crypto/secure_cache_service.dart';

class UnlockScreen extends ConsumerStatefulWidget {
  const UnlockScreen({super.key});

  @override
  ConsumerState<UnlockScreen> createState() => _UnlockScreenState();
}

class _UnlockScreenState extends ConsumerState<UnlockScreen> {
  final _passwordController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleUnlock() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final crypto = await ref.read(cryptoServiceProvider.future);
      final unlockService = UnlockService(crypto);
      final result = await unlockService.unlock(_passwordController.text);

      final cache = SecureCacheService();
      await cache.cacheSession(
        identityKeyPair: result.identityKeyPair,
        vaultKey: result.vaultKey,
        vaultId: result.vaultId,
      );

      if (!mounted) return;
      if (await cache.hasPin()) {
        Navigator.of(context).pushReplacementNamed('/vault', arguments: result);
      } else {
        Navigator.of(context)
            .pushReplacementNamed('/setup-pin', arguments: result);
      }
    } catch (e) {
      setState(() => _error = 'Incorrect password.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unlock Vault', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Master Password'),
                obscureText: true,
                onSubmitted: (_) => _handleUnlock(),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              _loading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _handleUnlock,
                      child: const Text('Unlock'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}