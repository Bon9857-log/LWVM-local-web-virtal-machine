import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vm_instance.dart';
import '../../models/snapshot.dart';
import '../../services/snapshot_manager.dart';
import '../../services/offline_mode.dart';

class SnapshotsScreen extends ConsumerStatefulWidget {
  final VmInstance vm;

  const SnapshotsScreen({super.key, required this.vm});

  @override
  ConsumerState<SnapshotsScreen> createState() => _SnapshotsScreenState();
}

class _SnapshotsScreenState extends ConsumerState<SnapshotsScreen> {
  late Future<List<Snapshot>> _snapshotsFuture;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshSnapshots();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _refreshSnapshots() {
    setState(() {
      _snapshotsFuture = SnapshotManager().listSnapshotsWithDetails(widget.vm);
    });
  }

  void _createSnapshot() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final description = _descriptionController.text.trim();
    final success = await SnapshotManager().createSnapshotWithMetadata(
      widget.vm,
      name,
      description,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      _refreshSnapshots();
    }
  }

  void _restoreSnapshot(Snapshot snapshot) async {
    if (widget.vm.state == VmState.running) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stop VM before restoring snapshot')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restore Snapshot'),
        content: Text('Restore "${snapshot.name}"? Current state will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SnapshotManager().restoreSnapshot(widget.vm, snapshot.name);
      _refreshSnapshots();
    }
  }

  void _deleteSnapshot(Snapshot snapshot) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Snapshot'),
        content: Text('Delete "${snapshot.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await SnapshotManager().deleteSnapshot(widget.vm, snapshot.name);
      _refreshSnapshots();
    }
  }

  void _branchFromSnapshot(Snapshot snapshot) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameController.text = 'branch-${widget.vm.id}-${snapshot.name}';
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Branch'),
        content: TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'New VM Name',
            hintText: 'Enter branch name',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final branchName = _nameController.text.trim();
      await SnapshotManager().createBranch(widget.vm, branchName, snapshot.name);
      if (mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  void _showCreateDialog() {
    _nameController.clear();
    _descriptionController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Snapshot'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Snapshot Name',
                hintText: 'e.g., clean-install',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'Describe this snapshot',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: _createSnapshot,
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRunning = widget.vm.state == VmState.running;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Snapshots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Offline Package Mirror'),
                content: FutureBuilder<String>(
                  future: OfflineModeService().getPackageMirrorUrl(),
                  builder: (context, snapshot) {
                    return Text(
                      'When offline mode is enabled, use this URL in guest:\n'
                      '${snapshot.data ?? 'http://10.0.2.2:9999/packages'}\n\n'
                      'For apt: Add to sources.list:',
                    );
                  },
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Snapshot>>(
        future: _snapshotsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final snapshots = snapshot.data ?? [];

          if (snapshots.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'No snapshots yet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a snapshot to save this VM state',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshots.length,
            itemBuilder: (context, index) {
              final snap = snapshots[index];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.save),
                  title: Text(snap.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (snap.description.isNotEmpty) Text(snap.description),
                      Text(
                        snap.timestamp.toLocal().toString().split('.').first,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.call_split),
                        tooltip: 'Create Branch',
                        onPressed: isRunning
                            ? null
                            : () {
                                _nameController.text = 'branch-${snap.name}';
                                _branchFromSnapshot(snap);
                              },
                      ),
                      IconButton(
                        icon: const Icon(Icons.restore),
                        tooltip: 'Restore',
                        onPressed: isRunning ? null : () => _restoreSnapshot(snap),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        tooltip: 'Delete',
                        onPressed: () => _deleteSnapshot(snap),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateDialog,
        icon: const Icon(Icons.add),
        label: const Text('Create Snapshot'),
      ),
    );
  }
}