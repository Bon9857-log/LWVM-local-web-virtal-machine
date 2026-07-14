import 'package:flutter/material.dart';

class VmDisplay extends StatefulWidget {
  final bool isRunning;
  final String? vmId;
  final VoidCallback? onToggleFullscreen;

  const VmDisplay({
    super.key,
    required this.isRunning,
    this.vmId,
    this.onToggleFullscreen,
  });

  @override
  State<VmDisplay> createState() => _VmDisplayState();
}

class _VmDisplayState extends State<VmDisplay> {
  bool _isFullscreen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: widget.isRunning
                ? AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CustomPaint(
                      painter: _VmDisplayPainter(),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.power_settings_new,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'VM is not running',
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              icon: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: Colors.white70,
              ),
              onPressed: () {
                setState(() => _isFullscreen = !_isFullscreen);
                widget.onToggleFullscreen?.call();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _VmDisplayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1a1a2e);
    canvas.drawRect(Offset.zero & size, bgPaint);

    final gridPaint = Paint()
      ..color = Colors.green.withOpacity(0.2)
      ..style = PaintingStyle.stroke;

    for (double y = 0; y < size.height; y += 20) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    final textSpan = TextSpan(
      text: 'SPICE/VNC Display\n(Connect to VM)',
      style: TextStyle(
        color: Colors.green.withOpacity(0.7),
        fontSize: 14,
        fontFamily: 'monospace',
      ),
      children: const [],
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    textPainter.layout(maxWidth: size.width);
    textPainter.paint(
      canvas,
      Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}