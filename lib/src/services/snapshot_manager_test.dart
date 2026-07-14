import 'package:test/test.dart';
import '../models/vm_instance.dart';
import '../models/vm_config.dart';
import 'snapshot_manager.dart';

void main() {
  group('SnapshotManager', () {
    late SnapshotManager manager;

    setUp(() {
      manager = SnapshotManager();
    });

    group('deleteSnapshot', () {
      test('returns false when qemu-img command fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.deleteSnapshot(vm, 'nonexistent-snapshot');
        expect(result, isFalse);
      });

      test('returns true when qemu-img command succeeds', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.deleteSnapshot(vm, 'snapshot-to-delete');
        expect(result, isFalse);
      });
    });

    group('createSnapshot', () {
      test('returns false when qemu-img command fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.createSnapshot(vm, 'test-snapshot');
        expect(result, isFalse);
      });
    });

    group('restoreSnapshot', () {
      test('returns false when VM is running', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
          state: VmState.running,
        );

        final result = await manager.restoreSnapshot(vm, 'test-snapshot');
        expect(result, isFalse);
      });

      test('returns false when qemu-img command fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
          state: VmState.stopped,
        );

        final result = await manager.restoreSnapshot(vm, 'test-snapshot');
        expect(result, isFalse);
      });
    });

    group('createSnapshotWithMetadata', () {
      test('returns false when qemu-img command fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.createSnapshotWithMetadata(
          vm,
          'test-snap',
          'test description',
        );
        expect(result, isFalse);
      });
    });

    group('listSnapshots', () {
      test('returns empty list when qemu-img fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.listSnapshots(vm);
        expect(result, isEmpty);
      });
    });

    group('listSnapshotsWithDetails', () {
      test('returns empty list when qemu-img fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.listSnapshotsWithDetails(vm);
        expect(result, isEmpty);
      });
    });

    group('createBranch', () {
      test('returns false when qemu-img command fails', () async {
        final vm = VmInstance(
          id: 'test-vm',
          config: const VmConfig(),
          overlayPath: '/nonexistent/path/overlay.qcow2',
          dataDiskPath: '/nonexistent/path/overlay.qcow2-data',
        );

        final result = await manager.createBranch(
          vm,
          'branch-vm',
          'snapshot-name',
        );
        expect(result, isFalse);
      });
    });
  });
}