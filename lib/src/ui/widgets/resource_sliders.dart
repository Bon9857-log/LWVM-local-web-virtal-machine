import 'package:flutter/material.dart';

class ResourceSliders extends StatefulWidget {
  final int initialRam;
  final int initialCpus;
  final int initialDiskSize;
  final void Function(int ram, int cpus, int diskSize) onChanged;

  const ResourceSliders({
    super.key,
    required this.initialRam,
    required this.initialCpus,
    required this.initialDiskSize,
    required this.onChanged,
  });

  @override
  State<ResourceSliders> createState() => _ResourceSlidersState();
}

class _ResourceSlidersState extends State<ResourceSliders> {
  late int _ram;
  late int _cpus;
  late int _diskSize;

  @override
  void initState() {
    super.initState();
    _ram = _roundToNearest((widget.initialRam / 1024).round(), 256);
    _cpus = widget.initialCpus;
    _diskSize = widget.initialDiskSize;
  }

  int _roundToNearest(int value, int step) {
    return ((value / step).round()) * step;
  }

  String _formatRam(int mb) {
    if (mb >= 1024) {
      return '${(mb / 1024).toStringAsFixed(1)} GB';
    }
    return '$mb MB';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('RAM: ${_formatRam(_ram)}', style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: _ram.toDouble(),
          min: 512,
          max: 4096,
          divisions: 15,
          label: _formatRam(_ram),
          onChanged: (v) {
            setState(() => _ram = _roundToNearest(v.round(), 256));
            widget.onChanged(_ram, _cpus, _diskSize);
          },
        ),
        const SizedBox(height: 16),
        Text('CPUs: $_cpus', style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: _cpus.toDouble(),
          min: 1,
          max: 4,
          divisions: 3,
          label: '$_cpus',
          onChanged: (v) {
            setState(() => _cpus = v.round());
            widget.onChanged(_ram, _cpus, _diskSize);
          },
        ),
        const SizedBox(height: 16),
        Text('Disk: ${_diskSize}GB', style: Theme.of(context).textTheme.bodyMedium),
        Slider(
          value: _diskSize.toDouble(),
          min: 10,
          max: 100,
          divisions: 18,
          label: '$_diskSize GB',
          onChanged: (v) {
            setState(() => _diskSize = v.round());
            widget.onChanged(_ram, _cpus, _diskSize);
          },
        ),
      ],
    );
  }
}