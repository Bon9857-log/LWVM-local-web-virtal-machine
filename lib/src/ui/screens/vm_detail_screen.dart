import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vm_instance.dart';
import '../../models/vm_config.dart';
import '../widgets/vm_display.dart';
import '../widgets/shared_folder_picker.dart';

class VmDetailScreen extends ConsumerStatefulWidget {
  final VmInstance vm;

  const VmDetailScreen({super.key, required this.vm});

  @override
  ConsumerState<VmDetailScreen> createState() => _VmDetailScreenState();
}

class _VmDetailScreenState extends ConsumerState<VmDetailScreen> {
  late VmInstance _vm;

  @override
  void initState() {
    super.initState();
    _vm = widget.vm;
  }

  void _startVm() {}
  void _stopVm() {}
  void _restartVm() {}

  @override
  Widget build(BuildContext context) {
    final isRunning = _vm.state == VmState.running;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_vm.id),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Console'),
              Tab(text: 'Settings'),
              Tab(text: 'Snapshots'),
              Tab(text: 'Shared Folders'),
              Tab(text: 'Logs'),
            ],
          ),
          actions: [
            if (isRunning)
              IconButton(icon: const Icon(Icons.stop), onPressed: _stopVm)
            else
              IconButton(icon: const Icon(Icons.play_arrow), onPressed: _startVm),
            IconButton(icon: const Icon(Icons.restart_alt), onPressed: _restartVm),
          ],
        ),
body: TabBarView(
          children: [
            VmDisplay(isRunning: isRunning, vmId: _vm.id),
            _buildSettingsTab(isRunning),
            _buildSnapshotsTab(),
            _buildSharedFoldersTab(),
            _buildLogsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(bool isRunning) {
    final vm = _vm;
    final config = vm.config;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('VM Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Modified Resources'),
            subtitle: isRunning
                ? const Text('Stop VM to modify RAM/CPU')
                : const Text('Resource changes require VM restart'),
            value: false,
            onChanged: isRunning ? null : (v) {},
          ),
          ListTile(
            title: const Text('RAM'),
            subtitle: Text('${config.ram} MB'),
            enabled: !isRunning,
          ),
          ListTile(
            title: const Text('CPUs'),
            subtitle: Text('${config.cpus}'),
            enabled: !isRunning,
          ),
          ListTile(
            title: const Text('Disk Size'),
            subtitle: Text('${config.diskSize} GB'),
            enabled: !isRunning,
          ),
          ListTile(
            title: const Text('Graphics Backend'),
            subtitle: Text(config.graphics.name),
          ),
        ],
      ),
    );
  }

  Widget _buildSnapshotsTab() {
    final snapshots = <String>[];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (snapshots.isEmpty)
          Text('No snapshots', style: Theme.of(context).textTheme.bodyMedium),
        for (final snapshot in snapshots)
          ListTile(
            leading: const Icon(Icons.save),
            title: Text(snapshot),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: const Icon(Icons.restore), onPressed: () {}),
                IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
              ],
            ),
          ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add),
          label: const Text('Create Snapshot'),
        ),
      ],
    );
  }

  Widget _buildSharedFoldersTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SharedFolderPicker(
        initialFolders: const [],
        onChanged: (folders) {},
      ),
    );
  }

  Widget _buildLogsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 20,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Text(
            '[INFO] VM ${_vm.id} - QEMU log entry $index',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
          ),
        );
      },
    );
  }
}