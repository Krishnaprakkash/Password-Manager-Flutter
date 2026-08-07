import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/sodium_provider.dart';
import '../vault/services/vault_setup_service.dart';
import '../vault/services/unlock_service.dart';
import '../../core/crypto/secure_cache_service.dart';

class SetupMasterPasswordScreen extends ConsumerStatefulWidget {
  const SetupMasterPasswordScreen({super.key});

  @override
  ConsumerState<SetupMasterPasswordScreen> createState() =>
      _SetupMasterPasswordScreenState();
}

class _SetupMasterPasswordScreenState
    extends ConsumerState<SetupMasterPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _handleSetup() async {
    if (_passwordController.text.length < 12) {
      setState(() => _error = 'Master password must be at least 12 characters.');
      return;
    }
    if (_passwordController.text != _confirmController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final crypto = await ref.read(cryptoServiceProvider.future);
      final setupService = VaultSetupService(crypto);
      await setupService.setupNewUser(_passwordController.text);

      final unlockService = UnlockService(crypto);
      final result = await unlockService.unlock(_passwordController.text);

      await SecureCacheService().cacheSession(
        identityKeyPair: result.identityKeyPair,
        vaultKey: result.vaultKey,
        vaultId: result.vaultId,
      );

      if (!mounted) return;
      Navigator.of(context)
          .pushReplacementNamed('/setup-pin', arguments: result);
    } catch (e) {
      setState(() => _error = 'Setup failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
              const Text('Create Master Password',
                  style: TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              const Text(
                'This encrypts your vault. It is never sent to the server.\n'
                'If you forget it, your data cannot be recovered.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Master Password'),
                obscureText: true,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
                obscureText: true,
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
                      onPressed: _handleSetup,
                      child: const Text('Create Vault'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}