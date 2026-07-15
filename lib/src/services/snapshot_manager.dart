import 'dart:io';
import '../models/vm_instance.dart';

class SnapshotManager {
  Future<List<String>> listSnapshots(VmInstance vm) async {
    final result = await Process.run('qemu-img', [
      'snapshot',
      '-l',
      vm.overlayPath,
    ]);
    
    if (result.exitCode != 0) return [];
    
    final output = result.stdout.toString();
    final snapshots = <String>[];
    
    for (final line in output.split('\n')) {
      if (line.contains('ID') || line.trim().isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        snapshots.add(parts.first);
      }
    }
    
    return snapshots;
  }

  Future<bool> createSnapshot(VmInstance vm, String name) async {
    final result = await Process.run('qemu-img', [
      'snapshot',
      '-c',
      name,
      vm.overlayPath,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> restoreSnapshot(VmInstance vm, String name) async {
    if (vm.state == VmState.running) {
      return false; // VM must be stopped
    }
    
    final result = await Process.run('qemu-img', [
      'snapshot',
      '-a',
      name,
      vm.overlayPath,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> deleteSnapshot(VmInstance vm, String name) async {
    final result = await Process.run('qemu-img', [
      'snapshot',
      '-d',
      name,
      vm.overlayPath,
    ]);
    return result.exitCode == 0;
  }

  Future<bool> createBranch(VmInstance vm, String branchName) async {
    final result = await Process.run('qemu-img', [
      'create',
      '-f',
      'qcow2',
      '-b',
      vm.overlayPath,
      '/tmp/${vm.id}-$branchName.qcow2',
    ]);
    return result.exitCode == 0;
  }
}