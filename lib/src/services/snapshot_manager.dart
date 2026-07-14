import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as p;
import '../models/vm_instance.dart';
import '../models/snapshot.dart';

class SnapshotManager {
  Future<List<Snapshot>> listSnapshotsWithDetails(VmInstance vm) async {
    final result = await Process.run('qemu-img', [
      'snapshot',
      '-l',
      vm.overlayPath,
    ]);

    if (result.exitCode != 0) return [];

    final output = result.stdout.toString();
    final snapshots = <Snapshot>[];

    for (final line in output.split('\n')) {
      if (line.contains('ID') || line.trim().isEmpty) continue;
      final parts = line.split(RegExp(r'\s+'));
      if (parts.isNotEmpty) {
        final name = parts.length > 3 ? parts[3] : parts[1];
        final id = parts.length > 3 ? parts[1] : parts[0];
        DateTime timestamp = DateTime.now();
        String description = '';
        
        final metaDir = await _getSnapshotMetaDir(vm);
        final metaFile = File(p.join(metaDir.path, '$name.json'));
        if (await metaFile.exists()) {
          try {
            final meta = jsonDecode(await metaFile.readAsString()) as Map<String, dynamic>;
            if (meta['timestamp'] != null) {
              timestamp = DateTime.parse(meta['timestamp'] as String);
            }
            description = meta['description'] as String? ?? '';
          } catch (_) {}
        }

        final snap = Snapshot.fromJson({
          'id': id,
          'name': name,
          'timestamp': timestamp.toIso8601String(),
          'description': description,
        });
        snapshots.add(snap);
      }
    }

    return snapshots;
  }

  Future<bool> createSnapshotWithMetadata(
    VmInstance vm,
    String name,
    String description,
  ) async {
    final result = await Process.run('qemu-img', [
      'snapshot',
      '-c',
      name,
      vm.overlayPath,
    ]);
    
    if (result.exitCode != 0) return false;

    final metaDir = await _getSnapshotMetaDir(vm);
    await Directory(metaDir.path).create(recursive: true);
    
    final metaFile = File(p.join(metaDir.path, '$name.json'));
    await metaFile.writeAsString(jsonEncode({
      'name': name,
      'description': description,
      'timestamp': DateTime.now().toIso8601String(),
    }));
    
    return true;
  }

  Future<Directory> _getSnapshotMetaDir(VmInstance vm) async {
    final home = await _getHomeDir();
    return Directory(p.join(home, '.lwvm', 'vms', vm.id, 'snapshots'));
  }

  static Future<String> _getHomeDir() async {
    var home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) {
      home = Platform.environment['USERPROFILE'];
    }
    return home ?? '.';
  }

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
    
    if (result.exitCode != 0) return false;
    
    // Clean up metadata file
    try {
      final metaDir = await _getSnapshotMetaDir(vm);
      final metaFile = File(p.join(metaDir.path, '$name.json'));
      if (await metaFile.exists()) {
        await metaFile.delete();
      }
    } catch (_) {
      // Ignore metadata cleanup errors
    }
    
    return true;
  }

  Future<bool> createBranch(VmInstance vm, String branchName, String snapshotName) async {
    final metaDir = await _getSnapshotMetaDir(vm);
    final snapshotMetaFile = File(p.join(metaDir.path, '$snapshotName.json'));
    
    if (await snapshotMetaFile.exists()) {
      final meta = jsonDecode(await snapshotMetaFile.readAsString()) as Map<String, dynamic>;
      // Could use metadata for branch description, etc.
    }

    final home = await _getHomeDir();
    final branchVmDir = Directory(p.join(home, '.lwvm', 'vms', branchName));
    await branchVmDir.create(recursive: true);
    
    final branchOverlayPath = p.join(branchVmDir.path, 'overlay.qcow2');
    
    final result = await Process.run('qemu-img', [
      'create',
      '-f',
      'qcow2',
      '-b',
      vm.overlayPath,
      branchOverlayPath,
    ]);
    return result.exitCode == 0;
  }
}