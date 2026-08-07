import 'package:flutter/material.dart';
import '../services/unlock_service.dart';

class VaultScreen extends StatelessWidget {
  const VaultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final result =
        ModalRoute.of(context)!.settings.arguments as UnlockResult?;

    return Scaffold(
      appBar: AppBar(title: const Text('Vault')),
      body: Center(
        child: result == null
            ? const Text('No unlock result received')
            : Text('Vault unlocked.\nVault ID: ${result.vaultId}'),
      ),
    );
  }
}