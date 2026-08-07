import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/sodium_provider.dart';
import '../../core/crypto/secure_cache_service.dart';
import '../vault/services/unlock_service.dart';

class PinUnlockScreen extends ConsumerStatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  ConsumerState<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends ConsumerState<PinUnlockScreen> {
  final _pinController = TextEditingController();
  String? _error;

  Future<void> _handleVerify() async {
    final sodium = await ref.read(sodiumProvider.future);
    final cache = SecureCacheService();
    final ok = await cache.verifyPin(_pinController.text, sodium);

    if (!mounted) return;

    if (ok) {
      final session = await cache.readCachedSession(sodium);
      if (session == null) {
        if (!mounted) return;
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      final result = UnlockResult(
        session.identityKeyPair,
        session.vaultKey,
        session.vaultId,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/vault', arguments: result);
      return;
    }

    final stillHasSession = await cache.hasCachedSession();
    if (!stillHasSession) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    final remaining = await cache.remainingAttempts();
    setState(() => _error = 'Incorrect PIN. $remaining attempts left.');
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
              const Text('Enter PIN', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: 'PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                onSubmitted: (_) => _handleVerify(),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleVerify,
                child: const Text('Unlock'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}