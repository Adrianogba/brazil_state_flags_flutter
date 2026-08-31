import 'dart:ui' show Color, Path, PathFillType;

/// A single filled or stroked shape within a flag.
///
/// Instances are produced by the code generator and are always `const`, which
/// is what lets Dart's tree shaker drop the flags an app never mentions.
class FlagShape {
  /// Creates a shape. Called only by generated code.
  const FlagShape(
    this.color,
    this.path, {
    this.clip,
    this.strokeWidth = 0,
  });

  /// Opaque ARGB colour, e.g. `0xFF009B43`.
  final int color;

  /// Normalised path data using only `M`, `L`, `C` and `Z` commands.
  final String path;

  /// Optional clip region, in the same normalised form as [path].
  ///
  /// Only the Rio de Janeiro artwork uses one.
  final String? clip;

  /// Stroke width in artwork units, or `0` to fill instead of stroke.
  final double strokeWidth;

  /// Whether this shape is stroked rather than filled.
  bool get isStroked => strokeWidth > 0;

  /// This shape's colour.
  Color get resolvedColor => Color(color);
}

/// The complete vector artwork for one flag in one style.
///
/// The drawing is defined in its own coordinate space of [width] × [height]
/// units and is scaled to whatever size it is rendered at, so it stays sharp
/// at any resolution.
class FlagArtwork {
  /// Creates an artwork. Called only by generated code.
  const FlagArtwork({
    required this.width,
    required this.height,
    required this.shapes,
  });

  /// Intrinsic width of the artwork's coordinate space.
  final double width;

  /// Intrinsic height of the artwork's coordinate space.
  final double height;

  /// The shapes to draw, in painter's order (first is furthest back).
  final List<FlagShape> shapes;

  /// Width divided by height. This is `1.5` for the rectangular styles and
  /// `1.0` for the square and circular ones.
  double get aspectRatio => width / height;
}

/// Converts normalised path data into a [Path].
///
/// The generator reduces every SVG construct (arcs, quadratics, relative
/// coordinates and primitive shapes) down to absolute `M`/`L`/`C`/`Z`, so this
/// parser stays small enough to audit at a glance.
Path parseFlagPath(String data) {
  // SVG's default fill-rule is nonzero, and no source file overrides it.
  // Using evenOdd here would punch wrong holes in the coats of arms.
  final path = Path()..fillType = PathFillType.nonZero;
  final length = data.length;
  var i = 0;
  var startX = 0.0, startY = 0.0;

  double readNumber() {
    // Skip separators.
    while (i < length) {
      final c = data.codeUnitAt(i);
      if (c == 0x20 || c == 0x2C) {
        i++;
      } else {
        break;
      }
    }
    final start = i;
    if (i < length) {
      final c = data.codeUnitAt(i);
      if (c == 0x2D || c == 0x2B) i++; // - or +
    }
    while (i < length) {
      final c = data.codeUnitAt(i);
      if ((c >= 0x30 && c <= 0x39) || c == 0x2E) {
        i++;
      } else {
        break;
      }
    }
    return double.parse(data.substring(start, i));
  }

  while (i < length) {
    final command = data.codeUnitAt(i);
    i++;
    switch (command) {
      case 0x4D: // M
        final x = readNumber();
        final y = readNumber();
        startX = x;
        startY = y;
        path.moveTo(x, y);
      case 0x4C: // L
        path.lineTo(readNumber(), readNumber());
      case 0x43: // C
        final x1 = readNumber();
        final y1 = readNumber();
        final x2 = readNumber();
        final y2 = readNumber();
        final x = readNumber();
        final y = readNumber();
        path.cubicTo(x1, y1, x2, y2, x, y);
      case 0x5A: // Z
        path.close();
        // Flutter leaves the current point at the subpath start after close;
        // being explicit keeps behaviour identical across engine versions.
        path.moveTo(startX, startY);
      default:
        // Stray whitespace between commands.
        break;
    }
  }
  return path;
}
