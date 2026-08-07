import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/supabase_config.dart';
import 'app/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/setup_master_password_screen.dart';
import 'features/auth/unlock_screen.dart';
import 'features/auth/pin_setup_screen.dart';
import 'features/auth/pin_unlock_screen.dart';
import 'features/vault/screens/vault_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupabaseConfig.url,
    publishableKey: SupabaseConfig.publishableKey,
  );
  runApp(const ProviderScope(child: PasswordVaultApp()));
}

class PasswordVaultApp extends StatelessWidget {
  const PasswordVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/setup-master-password': (context) =>
            const SetupMasterPasswordScreen(),
        '/unlock': (context) => const UnlockScreen(),
        '/setup-pin': (context) => const PinSetupScreen(),
        '/pin-unlock': (context) => const PinUnlockScreen(),
        '/vault': (context) => const VaultScreen(),
      },
    );
  }
}