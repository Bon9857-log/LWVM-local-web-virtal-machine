import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/vm_instance.dart';
import '../../providers/providers.dart';
import '../widgets/vm_card.dart';
import '../widgets/widgets.dart';
import 'create_vm_wizard.dart';
import 'vm_detail_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _isGridView = true;

  void _showCreateVmWizard() async {
    final result = await Navigator.of(context).push<VmConfig>(
      MaterialPageRoute(builder: (context) => const CreateVmWizard()),
    );
    if (result != null && mounted) {
      ref.read(vmListProvider.notifier).state = [
        ...ref.read(vmListProvider),
        VmInstance(
          id: 'vm-${DateTime.now().millisecondsSinceEpoch}',
          config: result,
          overlayPath: '/tmp/vm-overlay.qcow2',
          dataDiskPath: '/tmp/vm-data.qcow2',
        ),
      ];
    }
  }

  void _startVm(VmInstance vm) {}
  void _stopVm(VmInstance vm) {}
  void _restartVm(VmInstance vm) {}
  void _deleteVm(VmInstance vm) {
    ref.read(vmListProvider.notifier).state = 
        ref.read(vmListProvider).where((v) => v.id != vm.id).toList();
  }

  void _openVmDetail(VmInstance vm) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => VmDetailScreen(vm: vm)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vmList = ref.watch(vmListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('LWVM'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: vmList.isEmpty
          ? Center(
              child: Text(
                'No VMs created yet\nTap + to create one',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            )
          : _isGridView
              ? _buildGridView(vmList)
              : _buildListView(vmList),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateVmWizard,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildGridView(List<VmInstance> vmList) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900
            ? 3
            : constraints.maxWidth > 600
                ? 2
                : 1;
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: vmList.length,
          itemBuilder: (context, index) {
            final vm = vmList[index];
            return VmCard(
              vm: vm,
              onStart: () => _startVm(vm),
              onStop: () => _stopVm(vm),
              onRestart: () => _restartVm(vm),
              onDelete: () => _deleteVm(vm),
              onSettings: () => _openVmDetail(vm),
              onTap: () => _openVmDetail(vm),
            );
          },
        );
      },
    );
  }

  Widget _buildListView(List<VmInstance> vmList) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vmList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final vm = vmList[index];
        return VmCard(
          vm: vm,
          onStart: () => _startVm(vm),
          onStop: () => _stopVm(vm),
          onRestart: () => _restartVm(vm),
          onDelete: () => _deleteVm(vm),
          onSettings: () => _openVmDetail(vm),
          onTap: () => _openVmDetail(vm),
        );
      },
    );
  }
}