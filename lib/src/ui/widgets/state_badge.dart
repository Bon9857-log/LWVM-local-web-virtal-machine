import 'package:flutter/material.dart';
import '../../models/vm_instance.dart';

class StateBadge extends StatelessWidget {
  final VmState state;
  final double? size;

  const StateBadge({super.key, required this.state, this.size = 12});

  @override
  Widget build(BuildContext context) {
    final color = switch (state) {
      VmState.running => Colors.green,
      VmState.starting => Colors.orange,
      VmState.stopping => Colors.orange,
      VmState.stopped => Colors.grey,
      VmState.error => Colors.red,
    };

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}