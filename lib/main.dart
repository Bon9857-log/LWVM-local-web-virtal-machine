import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: LwvmApp()));
}

class LwvmApp extends StatelessWidget {
  const LwvmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LWVM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('LWVM - ChromeOS VM Platform', style: TextStyle(fontSize: 24)),
        ),
      ),
    );
  }
}