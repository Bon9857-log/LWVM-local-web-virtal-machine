import 'package:flutter_test/flutter_test.dart';
import 'vm_config.dart';

void main() {
  group('VmConfigExtension', () {
    test('getDefaultPortForwards returns default mappings', () {
      const config = VmConfig();
      final defaults = config.getDefaultPortForwards();

      expect(defaults[22], equals(2222));
      expect(defaults[80], equals(8080));
      expect(defaults[443], equals(8443));
      expect(defaults[3389], equals(3389));
    });

    test('getAllPortForwards returns custom port forwards', () {
      const config = VmConfig(sshPort: '3333', customPortForwards: {8080: 8080});
      final forwards = config.getAllPortForwards();

      expect(forwards[22], equals(3333));
      expect(forwards[8080], equals(8080));
    });

    test('sharedFolderBackend defaults to webdav', () {
      const config = VmConfig();
      expect(config.sharedFolderBackend, equals(SharedFolderBackend.webdav));
    });

    test('sharedFolderBackend can be configured to virtiofs', () {
      const config = VmConfig(sharedFolderBackend: SharedFolderBackend.virtiofs);
      expect(config.sharedFolderBackend, equals(SharedFolderBackend.virtiofs));
    });
  });
}