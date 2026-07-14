import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/providers.dart';
import '../../models/vm_config.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _registryController = TextEditingController(text: 'ghcr.io/org/lwvm-images');
  bool _offlineMode = false;
  bool _telemetryOptIn = false;
  String _logLevel = 'info';

  int _defaultRam = 2048;
  int _defaultCpus = 2;
  int _defaultDisk = 20;

  @override
  void dispose() {
    _registryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection('Registry', [
            TextFormField(
              controller: _registryController,
              decoration: const InputDecoration(
                labelText: 'Registry URL',
                hintText: 'ghcr.io/org/lwvm-images',
              ),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Default VM Resources', [
            Text('RAM: ${_formatRam(_defaultRam)}', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _defaultRam.toDouble(),
              min: 512,
              max: 4096,
              divisions: 15,
              label: _formatRam(_defaultRam),
              onChanged: (v) => setState(() => _defaultRam = v.round()),
            ),
            Text('CPUs: $_defaultCpus', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _defaultCpus.toDouble(),
              min: 1,
              max: 4,
              divisions: 3,
              label: '$_defaultCpus',
              onChanged: (v) => setState(() => _defaultCpus = v.round()),
            ),
            Text('Disk: ${_defaultDisk}GB', style: Theme.of(context).textTheme.bodyMedium),
            Slider(
              value: _defaultDisk.toDouble(),
              min: 10,
              max: 100,
              divisions: 18,
              label: '$_defaultDisk GB',
              onChanged: (v) => setState(() => _defaultDisk = v.round()),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('General', [
            SwitchListTile(
              title: const Text('Offline Mode'),
              value: _offlineMode,
              onChanged: (v) => setState(() => _offlineMode = v),
            ),
            SwitchListTile(
              title: const Text('Telemetry Opt-in'),
              value: _telemetryOptIn,
              onChanged: (v) => setState(() => _telemetryOptIn = v),
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Cache Management', [
            FutureBuilder<int>(
              future: _getCacheSize(),
              builder: (context, snapshot) {
                final size = snapshot.data ?? 0;
                return ListTile(
                  title: const Text('Image Cache Size'),
                  subtitle: Text('${(size / 1024 / 1024).toStringAsFixed(1)} MB'),
                  trailing: TextButton(onPressed: _clearCache, child: const Text('Clear')),
                );
              },
            ),
          ]),
          const SizedBox(height: 24),
          _buildSection('Advanced', [
            DropdownButtonFormField<String>(
              value: _logLevel,
              decoration: const InputDecoration(labelText: 'Log Level'),
              items: const [
                DropdownMenuItem(value: 'debug', child: Text('Debug')),
                DropdownMenuItem(value: 'info', child: Text('Info')),
                DropdownMenuItem(value: 'warning', child: Text('Warning')),
                DropdownMenuItem(value: 'error', child: Text('Error')),
              ],
              onChanged: (v) => setState(() => _logLevel = v ?? 'info'),
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: '/usr/bin',
              decoration: const InputDecoration(labelText: 'QEMU Binary Path'),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  String _formatRam(int mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }

  Future<int> _getCacheSize() async => 0;
  void _clearCache() {}
}