import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/providers/providers.dart';

void main() {
  runApp(const ProviderScope(child: lwvmApp()));
}

class lwvmApp extends ConsumerWidget {
  const lwvmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class lwvmApp extends ConsumerWidget {
  const lwvmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class lwvmApp extends ConsumerWidget {
  const lwvmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
=======

void main() {
  runApp(const ProviderScope(child: LwvmApp()));
}

class LwvmApp extends StatelessWidget {
  const LwvmApp({super.key});

  @override
  Widget build(BuildContext context) {
>>>>>>> 7612930 (feat: scaffold Flutter project with Android support + QEMU Android NDK build script (#1))
    return MaterialApp(
      title: 'LWVM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
<<<<<<< HEAD
          child: Text('LWVM - VM Platform'),
=======
          child: Text('LWVM - ChromeOS VM Platform', style: TextStyle(fontSize: 24)),
>>>>>>> 7612930 (feat: scaffold Flutter project with Android support + QEMU Android NDK build script (#1))
        ),
      ),
    );
  }
}