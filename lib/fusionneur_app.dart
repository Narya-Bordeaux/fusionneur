// lib/fusionneur_app.dart
//
// Widget racine de l'application Flutter.

import 'package:flutter/material.dart';
import 'package:fusionneur/pages/home/home_page.dart';

class FusionneurApp extends StatelessWidget {
  const FusionneurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fusionneur',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
