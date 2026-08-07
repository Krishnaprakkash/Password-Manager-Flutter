import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/sodium_provider.dart';
import '../../core/crypto/secure_cache_service.dart';
import '../vault/services/unlock_service.dart';

class PinSetupScreen extends ConsumerStatefulWidget {
  const PinSetupScreen({super.key});

  @override
  ConsumerState<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends ConsumerState<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;

  Future<void> _handleSetPin() async {
    final pin = _pinController.text;
    if (pin.length != 4 || int.tryParse(pin) == null) {
      setState(() => _error = 'PIN must be exactly 4 digits.');
      return;
    }
    if (pin != _confirmController.text) {
      setState(() => _error = 'PINs do not match.');
      return;
    }

    final sodium = await ref.read(sodiumProvider.future);
    await SecureCacheService().setPin(pin, sodium);

    if (!mounted) return;
    final result =
        ModalRoute.of(context)!.settings.arguments as UnlockResult;
    Navigator.of(context).pushReplacementNamed('/vault', arguments: result);
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
              const Text('Set a 4-Digit PIN', style: TextStyle(fontSize: 22)),
              const SizedBox(height: 8),
              const Text(
                'Used for quick unlock on this device only.',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _pinController,
                decoration: const InputDecoration(labelText: 'PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              TextField(
                controller: _confirmController,
                decoration: const InputDecoration(labelText: 'Confirm PIN'),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _handleSetPin,
                child: const Text('Set PIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}