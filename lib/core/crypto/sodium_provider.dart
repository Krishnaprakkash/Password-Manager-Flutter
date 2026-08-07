import 'package:sodium/sodium_sumo.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'crypto_service.dart';

final sodiumProvider = FutureProvider<SodiumSumo>((ref) async {
  return await SodiumSumoInit.init();
});

final cryptoServiceProvider = FutureProvider<CryptoService>((ref) async {
  final sodium = await ref.watch(sodiumProvider.future);
  return CryptoService(sodium);
});