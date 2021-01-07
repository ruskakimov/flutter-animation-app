import 'package:flutter/material.dart';
import 'package:mooltik/drawing/data/frame/stroke.dart';

import '../data/frame/frame_model.dart';

class FramePainter extends CustomPainter {
  FramePainter({
    @required this.frame,
    this.strokes,
    this.showCursor = false,
    this.background = Colors.white,
    this.filter,
  });

  final FrameModel frame;
  final List<Stroke> strokes;
  final bool showCursor;
  final Color background;
  final ColorFilter filter;

  @override
  void paint(Canvas canvas, Size size) {
    // Clip paint outside canvas.
    canvas.clipRect(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawColor(background, BlendMode.srcOver);

    // Scale image to fit the given size.
    canvas.scale(size.width / frame.width, size.height / frame.height);

    // Save layer to erase paintings on it with `BlendMode.clear`.
    canvas.saveLayer(Rect.fromLTWH(0, 0, frame.width, frame.height), Paint());

    if (frame.snapshot != null) {
      canvas.drawImage(
        frame.snapshot,
        Offset.zero,
        Paint()
          ..colorFilter = filter
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.low,
      );
    }

    // TODO: Remove this one.
    frame.unrasterizedStrokes.forEach((stroke) => stroke.paintOn(canvas));

    strokes?.forEach((stroke) => stroke.paintOn(canvas));

    if (showCursor && strokes.isNotEmpty) {
      final scale = size.width / frame.width;
      _drawCursor(
        canvas,
        strokes.last.lastPoint,
        strokes.last.width / 2,
        0.5 / scale,
      );
    }

    // Flatten layer. Combine drawing lines with erasing lines.
    canvas.restore();
  }

  @override
  bool shouldRepaint(FramePainter oldDelegate) => true;

  @override
  bool shouldRebuildSemantics(FramePainter oldDelegate) => false;

  void _drawCursor(
    Canvas canvas,
    Offset center,
    double radius,
    double lineWidth,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth
        ..color = Colors.grey.withOpacity(0.5),
    );
  }
}
