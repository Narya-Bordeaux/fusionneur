// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fusionneur/fusionneur_app.dart';
import 'package:fusionneur/app_initializer.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Phase d'init centralisée
  await AppInitializer.init();

  // Lancer l'app
  runApp(
    const ProviderScope(
      child: FusionneurApp(),
    ),
  );
}
