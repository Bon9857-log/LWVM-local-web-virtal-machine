import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import '../models/guest_os_image.dart';
import '../models/vm_config.dart';

class VmProvisioningService {
  static const String _metadataDir = '.lwvm/metadata';
  static const int _webdavPort = 9999;

  Future<String> generateCloudInitConfig(
    VmConfig config,
    String overlayPath,
    String dataDiskPath,
    String? sharedFolder,
  ) async {
    final overlayDir = p.dirname(overlayPath);
    final configPath = p.join(overlayDir, 'config-drive.iso');

    final cloudInitConfig = _buildCloudInit(config.guestOS, sharedFolder);

    if (Platform.isAndroid || Platform.isLinux || Platform.isMacOS) {
      final metaDataDir = Directory(p.join(overlayDir, 'cidata'));
      await metaDataDir.create(recursive: true);

      await File(p.join(metaDataDir.path, 'user-data')).writeAsString(
        '#cloud-config\n$cloudInitConfig',
      );

      await File(p.join(metaDataDir.path, 'meta-data')).writeAsString('instance-id: iid-local01\n');

      final result = await Process.run(
        'genisoimage',
        [
          '-o', configPath,
          '-V', 'cidata',
          '-joliet', '-rock',
          p.join(metaDataDir.path, 'user-data'),
          p.join(metaDataDir.path, 'meta-data'),
        ],
      );

      if (result.exitCode != 0) {
        throw StateError('Failed to create cloud-init ISO: ${result.stderr}');
      }
    }

    return configPath;
  }

  String _buildCloudInit(GuestOS guestOS, String? sharedFolder) {
    final runcmd = <String>[];

    if (guestOS == GuestOS.alpine) {
      runcmd.add('mkfs.ext4 /dev/vdb');
      runcmd.add('mkdir -p /home/user');
      runcmd.add('mount /dev/vdb /home/user');
      runcmd.add('echo "/dev/vdb /home/user ext4 defaults 0 2" >> /etc/fstab');
      runcmd.add('apk add --no-cache davfs2');
      runcmd.add(
          'echo "http://10.0.2.2:$_webdavPort /mnt/host davfs user,noauto 0 0" >> /etc/fstab');
    } else {
      runcmd.add('mkfs.ext4 /dev/vdb');
      runcmd.add('mkdir -p /home/user');
      runcmd.add('mount /dev/vdb /home/user');
      runcmd.add('echo "/dev/vdb /home/user ext4 defaults 0 2" >> /etc/fstab');
      runcmd.add('apt-get update && apt-get install -y davfs2');
      runcmd.add(
          'echo "http://10.0.2.2:$_webdavPort /mnt/host davfs user,noauto 0 0" >> /etc/fstab');
    }

    if (sharedFolder != null) {
      runcmd.add('mkdir -p /mnt/host');
    }

    return '''
runcmd:
${runcmd.map((cmd) => '  - $cmd').join('\n')}
''';
  }

  Future<void> ensureBaseImage(GuestOSImage image) async {
    final imagePath = await _resolveImagePath(image);
    final file = File(imagePath);

    if (await file.exists()) {
      return;
    }

    await _downloadImage(image, imagePath);
  }

  Future<String> _resolveImagePath(GuestOSImage image) async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '';
    final cacheDir = p.join(home, '.lwvm', 'cache');

    return p.join(cacheDir, 'images', '${image.id}-${image.arch}.qcow2');
  }

  Future<void> _downloadImage(GuestOSImage image, String imagePath) async {
    await Directory(p.dirname(imagePath)).create(recursive: true);

    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(image.url));
    final response = await request.close();

    if (response.statusCode != HttpStatus.ok) {
      throw StateError('Failed to download image: ${response.statusCode}');
    }

    final file = File(imagePath);
    final sink = file.openWrite();

    await response.pipe(sink);
    await sink.flush();
    await sink.close();

    client.close();
  }
}