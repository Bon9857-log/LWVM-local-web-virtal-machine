import 'package:flutter/material.dart';
import '../../models/vm_config.dart';
import '../widgets/widgets.dart';

class CreateVmWizard extends StatefulWidget {
  const CreateVmWizard({super.key});

  @override
  State<CreateVmWizard> createState() => _CreateVmWizardState();
}

class _CreateVmWizardState extends State<CreateVmWizard> {
  int _currentStep = 0;
  GuestOS _selectedOs = GuestOS.alpine;
  ImageType _selectedImageType = ImageType.minimal;
  
  int _ram = 2048;
  int _cpus = 2;
  int _diskSize = 20;
  
  final Map<int, int> _portForwards = {
    22: 2222,
    80: 8080,
    443: 8443,
  };
  
  final List<SharedFolder> _sharedFolders = [];

  void _onResourceChanged(int ram, int cpus, int disk) {
    setState(() {
      _ram = ram;
      _cpus = cpus;
      _diskSize = disk;
    });
  }

  VmConfig _buildConfig() {
    return VmConfig(
      cpus: _cpus,
      ram: _ram,
      diskSize: _diskSize,
      guestOS: _selectedOs,
      imageType: _selectedImageType,
      sshPort: _portForwards[22]?.toString(),
      webPort: _portForwards[80]?.toString(),
      httpsPort: _portForwards[443]?.toString(),
      customPortForwards: {
        for (final entry in _portForwards.entries)
          if (![22, 80, 443, 3389].contains(entry.key)) entry.key: entry.value,
      }..removeWhere((key, value) => key == null || value == null),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create VM'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() => _currentStep++);
          } else {
            Navigator.of(context).pop(_buildConfig());
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        steps: [
          Step(
            title: const Text('Select Guest OS'),
            content: _buildOsSelection(),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Select Image'),
            content: _buildImageSelection(),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Resources'),
            content: ResourceSliders(
              initialRam: _ram,
              initialCpus: _cpus,
              initialDiskSize: _diskSize,
              onChanged: _onResourceChanged,
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: const Text('Network'),
            content: Column(
              children: [
                PortForwardEditor(
                  initialForwards: _portForwards.entries
                      .map((e) => PortForward(
                            hostPort: e.value,
                            guestPort: e.key,
                          ))
                      .toList(),
                  onChanged: (forwards) {
                    setState(() {
                      _portForwards.clear();
                      for (final f in forwards) {
                        _portForwards[f.guestPort] = f.hostPort;
                      }
                    });
                  },
                ),
                const SizedBox(height: 16),
                SharedFolderPicker(
                  initialFolders: _sharedFolders,
                  onChanged: (folders) => setState(() => _sharedFolders.clear()..addAll(folders)),
                ),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
          Step(
            title: const Text('Review & Create'),
            content: _buildReview(),
            isActive: _currentStep >= 4,
          ),
        ],
        controlsBuilder: (context, controls) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
FilledButton(
                   onPressed: controls.onStepContinue,
                   child: Text(_currentStep == 4 ? 'Create' : 'Continue'),
                 ),
                const SizedBox(width: 8),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: controls.onStepCancel,
                    child: const Text('Back'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildOsSelection() {
    return Column(
      children: [
        RadioListTile<GuestOS>(
          value: GuestOS.alpine,
          groupValue: _selectedOs,
          onChanged: (v) => setState(() => _selectedOs = v!),
          title: const Text('Alpine Linux'),
          subtitle: const Text('Minimal (~500MB)'),
          secondary: const Icon(Icons.radio_button_checked),
        ),
        RadioListTile<GuestOS>(
          value: GuestOS.ubuntu,
          groupValue: _selectedOs,
          onChanged: (v) => setState(() => _selectedOs = v!),
          title: const Text('Ubuntu Minimal'),
          subtitle: const Text('Standard (~3GB)'),
          secondary: const Icon(Icons.radio_button_checked),
        ),
RadioListTile<GuestOS>(
           value: GuestOS.zorin,
           groupValue: _selectedOs,
           onChanged: (v) => setState(() => _selectedOs = v!),
           title: const Text('Zorin OS 17'),
           subtitle: const Text('Premium Desktop (~2.5GB)'),
           secondary: const Icon(Icons.radio_button_checked),
         ),
      ],
    );
  }

  Widget _buildImageSelection() {
    final availableImages = _availableImagesForOs(_selectedOs);
    
    return Column(
      children: [
        for (final image in availableImages)
          RadioListTile<ImageType>(
            value: image.$1,
            groupValue: _selectedImageType,
            onChanged: (v) => setState(() => _selectedImageType = v!),
            title: Text(image.$2),
            subtitle: Text(image.$3),
          ),
      ],
    );
  }

  List<(ImageType, String, String)> _availableImagesForOs(GuestOS os) {
    switch (os) {
      case GuestOS.alpine:
        return [
          (ImageType.minimal, 'Alpine Linux', 'Minimal (~500MB)'),
          (ImageType.thickDev, 'Alpine Dev', 'Pre-baked dev tools (~500MB)'),
          (ImageType.thickMinimal, 'Minimal Linux', 'BusyBox + SSH (~100MB)'),
        ];
      case GuestOS.ubuntu:
        return [
          (ImageType.minimal, 'Ubuntu Minimal', 'Standard (~3GB)'),
          (ImageType.thickWebdev, 'Ubuntu WebDev', 'Docker, VSCode, Node, Python (~3GB)'),
          (ImageType.thickDatasci, 'Ubuntu DataSci', 'Jupyter, PyTorch, Pandas (~4GB)'),
        ];
      case GuestOS.zorin:
        return [
          (ImageType.minimal, 'Zorin OS 17', 'Desktop (~2.5GB)'),
        ];
    }
  }

  Widget _buildReview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Guest OS: ${_selectedOs.name}', style: Theme.of(context).textTheme.bodyLarge),
            Text('Image: ${_selectedImageType.name}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('RAM: ${_formatRam(_ram)}', style: Theme.of(context).textTheme.bodyLarge),
            Text('CPUs: $_cpus', style: Theme.of(context).textTheme.bodyLarge),
            Text('Disk: ${_diskSize}GB', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Port Forwards:', style: Theme.of(context).textTheme.bodyMedium),
            for (final entry in _portForwards.entries)
              Text('  ${entry.key} -> ${entry.value}', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            Text('Shared Folders: ${_sharedFolders.length}', style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }

  String _formatRam(int mb) {
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(1)} GB';
    return '$mb MB';
  }
}