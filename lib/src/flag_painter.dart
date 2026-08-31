import 'dart:math' as math;

import 'package:flutter/rendering.dart';

import 'flag_artwork.dart';

/// Parsed paths, keyed by their normalised data.
///
/// The key space is closed. It can only ever contain paths from this
/// package's own generated data, so it cannot grow without bound.
final Map<String, Path> _pathCache = <String, Path>{};

Path _cachedPath(String data) => _pathCache[data] ??= parseFlagPath(data);

/// Paints a [FlagArtwork], scaled to fit and centred within the canvas.
class FlagPainter extends CustomPainter {
  /// Creates a painter for [artwork].
  const FlagPainter(this.artwork);

  /// The flag to draw.
  final FlagArtwork artwork;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || artwork.width <= 0 || artwork.height <= 0) return;

    // Uniform scale so the artwork is never distorted, then centre it.
    final scale = math.min(
      size.width / artwork.width,
      size.height / artwork.height,
    );
    final dx = (size.width - artwork.width * scale) / 2;
    final dy = (size.height - artwork.height * scale) / 2;

    canvas.save();
    canvas.translate(dx, dy);
    canvas.scale(scale);

    String? activeClip;
    var clipDepth = 0;

    for (final shape in artwork.shapes) {
      // Clips are contiguous in generated output, so open and close them as
      // the run changes rather than saving per shape.
      if (shape.clip != activeClip) {
        if (clipDepth > 0) {
          canvas.restore();
          clipDepth = 0;
        }
        if (shape.clip != null) {
          canvas.save();
          canvas.clipPath(_cachedPath(shape.clip!));
          clipDepth = 1;
        }
        activeClip = shape.clip;
      }

      final paint = Paint()
        ..color = shape.resolvedColor
        ..isAntiAlias = true;
      if (shape.isStroked) {
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = shape.strokeWidth
          ..strokeMiterLimit = 10;
      } else {
        paint.style = PaintingStyle.fill;
      }
      canvas.drawPath(_cachedPath(shape.path), paint);
    }

    if (clipDepth > 0) canvas.restore();
    canvas.restore();
  }

  @override
  bool shouldRepaint(FlagPainter oldDelegate) =>
      !identical(oldDelegate.artwork, artwork);
}
