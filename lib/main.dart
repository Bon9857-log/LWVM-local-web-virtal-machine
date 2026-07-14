import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/providers/providers.dart';
import 'src/ui/screens/screens.dart';

void main() {
  runApp(const ProviderScope(child: LwvmApp()));
}

class LwvmApp extends ConsumerWidget {
  const LwvmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LWVM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
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
=======
import 'src/ui/screens/screens.dart';
>>>>>>> 6f765f6 (feat: implement VM Management UI with Dashboard, Wizard, Detail, and Settings screens (#8))

void main() {
  runApp(const ProviderScope(child: LwvmApp()));
}

class LwvmApp extends ConsumerWidget {
  const LwvmApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'LWVM',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const DashboardScreen(),
    );
  }
}