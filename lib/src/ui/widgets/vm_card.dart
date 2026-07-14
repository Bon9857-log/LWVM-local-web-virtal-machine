import 'package:flutter/material.dart';
import '../../models/vm_instance.dart';
import 'state_badge.dart';

class VmCard extends StatelessWidget {
  final VmInstance vm;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onRestart;
  final VoidCallback onDelete;
  final VoidCallback onSettings;
  final VoidCallback onTap;

  const VmCard({
    super.key,
    required this.vm,
    required this.onStart,
    required this.onStop,
    required this.onRestart,
    required this.onDelete,
    required this.onSettings,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = vm.state == VmState.running;
    final isStarting = vm.state == VmState.starting;
    final isStopping = vm.state == VmState.stopping;

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  StateBadge(state: vm.state),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      vm.id,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'start':
                          onStart();
                          break;
                        case 'stop':
                          onStop();
                          break;
                        case 'restart':
                          onRestart();
                          break;
                        case 'settings':
                          onSettings();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      if (!isRunning && !isStarting)
                        const PopupMenuItem(value: 'start', child: Text('Start')),
                      if (isRunning && !isStopping)
                        const PopupMenuItem(value: 'stop', child: Text('Stop')),
                      if (isRunning || isStopping)
                        const PopupMenuItem(value: 'restart', child: Text('Restart')),
                      const PopupMenuItem(value: 'settings', child: Text('Settings')),
                      const PopupMenuDivider(),
                      const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    Icons.desktop_windows,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${vm.config.ram}MB RAM • ${vm.config.cpus} CPU • ${vm.config.diskSize}GB Disk',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                'OS: ${vm.config.guestOS.name}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}