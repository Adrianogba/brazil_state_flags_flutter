// Build-time only. Converts SVG geometry into normalised absolute path data
// using just four commands: M, L, C and Z.
//
// Every tricky part of SVG (elliptical arcs, smooth and quadratic curves,
// relative coordinates, primitive shapes and affine transforms) is resolved
// here, so the runtime parser shipped in `lib/` only ever has to understand
// those four commands. Nothing in this file is published.
import 'dart:math' as math;

/// A 2D affine transform, laid out as SVG writes it:
///
///     | a  c  e |
///     | b  d  f |
///     | 0  0  1 |
///
/// The source artwork pairs a translate with a rotate on 17 shapes, so a plain
/// offset is not enough. Applying the matrix to already flattened cubics is
/// exact, since affine maps take Béziers to Béziers.
class Affine {
  const Affine(this.a, this.b, this.c, this.d, this.e, this.f);

  /// The transform that changes nothing.
  static const identity = Affine(1, 0, 0, 1, 0, 0);

  final double a, b, c, d, e, f;

  factory Affine.translate(double tx, double ty) => Affine(1, 0, 0, 1, tx, ty);

  factory Affine.rotate(double degrees) {
    final r = degrees * math.pi / 180.0;
    final cos = math.cos(r);
    final sin = math.sin(r);
    return Affine(cos, sin, -sin, cos, 0, 0);
  }

  factory Affine.scale(double sx, double sy) => Affine(sx, 0, 0, sy, 0, 0);

  /// Returns `this` followed by [child], matching how SVG composes a list of
  /// transform functions from left to right.
  Affine multiply(Affine child) => Affine(
        a * child.a + c * child.b,
        b * child.a + d * child.b,
        a * child.c + c * child.d,
        b * child.c + d * child.d,
        a * child.e + c * child.f + e,
        b * child.e + d * child.f + f,
      );

  /// Maps a point through the matrix.
  (double, double) apply(double x, double y) =>
      (a * x + c * y + e, b * x + d * y + f);

  bool get isIdentity =>
      a == 1 && b == 0 && c == 0 && d == 1 && e == 0 && f == 0;
}

/// Parses an SVG `transform` attribute, composing every function it lists.
///
/// Understands translate, rotate (with and without a centre), scale and
/// matrix. Anything unrecognised is skipped rather than silently distorting
/// the artwork.
Affine parseTransform(String value) {
  var result = Affine.identity;
  final fn = RegExp(r'(\w+)\s*\(([^)]*)\)');
  for (final m in fn.allMatches(value)) {
    final name = m.group(1)!;
    final args = m
        .group(2)!
        .split(RegExp(r'[\s,]+'))
        .where((s) => s.isNotEmpty)
        .map(double.parse)
        .toList();
    switch (name) {
      case 'translate':
        result = result
            .multiply(Affine.translate(args[0], args.length > 1 ? args[1] : 0));
      case 'rotate':
        if (args.length >= 3) {
          // Rotation about an explicit centre.
          result = result
              .multiply(Affine.translate(args[1], args[2]))
              .multiply(Affine.rotate(args[0]))
              .multiply(Affine.translate(-args[1], -args[2]));
        } else {
          result = result.multiply(Affine.rotate(args[0]));
        }
      case 'scale':
        result = result.multiply(
            Affine.scale(args[0], args.length > 1 ? args[1] : args[0]));
      case 'matrix':
        result = result.multiply(
            Affine(args[0], args[1], args[2], args[3], args[4], args[5]));
    }
  }
  return result;
}

/// Scans SVG numbers, which may be packed together without separators
/// (`1.5.5` is two numbers, `-.5-1` is two more).
class _NumberScanner {
  _NumberScanner(this.source);
  final String source;
  int _pos = 0;

  bool get atEnd {
    _skipSeparators();
    return _pos >= source.length;
  }

  void _skipSeparators() {
    while (_pos < source.length) {
      final c = source.codeUnitAt(_pos);
      // space, tab, CR, LF, comma
      if (c == 0x20 || c == 0x09 || c == 0x0D || c == 0x0A || c == 0x2C) {
        _pos++;
      } else {
        break;
      }
    }
  }

  double next() {
    _skipSeparators();
    final start = _pos;
    if (_pos < source.length && (source[_pos] == '-' || source[_pos] == '+')) {
      _pos++;
    }
    while (_pos < source.length && _isDigit(source[_pos])) {
      _pos++;
    }
    if (_pos < source.length && source[_pos] == '.') {
      _pos++;
      while (_pos < source.length && _isDigit(source[_pos])) {
        _pos++;
      }
    }
    if (_pos < source.length && (source[_pos] == 'e' || source[_pos] == 'E')) {
      final mark = _pos;
      _pos++;
      if (_pos < source.length &&
          (source[_pos] == '-' || source[_pos] == '+')) {
        _pos++;
      }
      if (_pos < source.length && _isDigit(source[_pos])) {
        while (_pos < source.length && _isDigit(source[_pos])) {
          _pos++;
        }
      } else {
        _pos = mark; // not an exponent after all
      }
    }
    if (start == _pos) {
      throw FormatException('Expected a number at offset $_pos of "$source"');
    }
    return double.parse(source.substring(start, _pos));
  }

  /// Arc flags are single characters and may not be separated from what
  /// follows them (`a1,1 0 011,1` packs both flags and the x coordinate).
  bool nextFlag() {
    _skipSeparators();
    final c = source[_pos];
    if (c != '0' && c != '1') {
      throw FormatException('Expected an arc flag at offset $_pos');
    }
    _pos++;
    return c == '1';
  }

  static bool _isDigit(String c) {
    final code = c.codeUnitAt(0);
    return code >= 0x30 && code <= 0x39;
  }
}

/// Accumulates normalised path output.
class _PathSink {
  final _buffer = StringBuffer();

  static String _fmt(double v) {
    if (!v.isFinite) return '0';
    // Three decimals is well below one device pixel at any realistic render
    // size, and keeps the generated source compact.
    var s = v.toStringAsFixed(3);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s == '-0' ? '0' : s;
  }

  void moveTo(double x, double y) => _buffer.write('M${_fmt(x)} ${_fmt(y)}');

  void lineTo(double x, double y) => _buffer.write('L${_fmt(x)} ${_fmt(y)}');

  void cubicTo(
          double x1, double y1, double x2, double y2, double x, double y) =>
      _buffer.write('C${_fmt(x1)} ${_fmt(y1)} ${_fmt(x2)} ${_fmt(y2)} '
          '${_fmt(x)} ${_fmt(y)}');

  void close() => _buffer.write('Z');

  @override
  String toString() => _buffer.toString();
}

/// Converts an SVG `d` attribute into normalised absolute `M`/`L`/`C`/`Z` data,
/// applying [transform] as it goes.
String normalisePathData(String d, [Affine transform = Affine.identity]) {
  final sink = _PathSink();
  final commands = RegExp(r'[MmLlHhVvCcSsQqTtAaZz]');
  final matches = commands.allMatches(d).toList();

  // Current point, subpath start, and the reflected control points needed by
  // the smooth (S/T) commands.
  var cx = 0.0, cy = 0.0, sx = 0.0, sy = 0.0;
  var lastCubicCtrlX = 0.0, lastCubicCtrlY = 0.0;
  var lastQuadCtrlX = 0.0, lastQuadCtrlY = 0.0;
  var prevWasCubic = false, prevWasQuad = false;

  void emitMove(double x, double y) {
    final p = transform.apply(x, y);
    sink.moveTo(p.$1, p.$2);
  }

  void emitLine(double x, double y) {
    final p = transform.apply(x, y);
    sink.lineTo(p.$1, p.$2);
  }

  void emitCubic(
      double x1, double y1, double x2, double y2, double x, double y) {
    final c1 = transform.apply(x1, y1);
    final c2 = transform.apply(x2, y2);
    final end = transform.apply(x, y);
    sink.cubicTo(c1.$1, c1.$2, c2.$1, c2.$2, end.$1, end.$2);
  }

  for (var i = 0; i < matches.length; i++) {
    final cmd = matches[i].group(0)!;
    final argsEnd = i + 1 < matches.length ? matches[i + 1].start : d.length;
    final scanner = _NumberScanner(d.substring(matches[i].end, argsEnd));
    final relative = cmd.toLowerCase() == cmd;
    final upper = cmd.toUpperCase();

    if (upper == 'Z') {
      sink.close();
      cx = sx;
      cy = sy;
      prevWasCubic = prevWasQuad = false;
      continue;
    }

    var first = true;
    while (!scanner.atEnd) {
      switch (upper) {
        case 'M':
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          cx = x;
          cy = y;
          if (first) {
            sx = x;
            sy = y;
            emitMove(x, y);
          } else {
            // Extra coordinate pairs after a moveto are implicit linetos.
            emitLine(x, y);
          }
          prevWasCubic = prevWasQuad = false;
        case 'L':
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          cx = x;
          cy = y;
          emitLine(x, y);
          prevWasCubic = prevWasQuad = false;
        case 'H':
          final x = scanner.next() + (relative ? cx : 0);
          cx = x;
          emitLine(x, cy);
          prevWasCubic = prevWasQuad = false;
        case 'V':
          final y = scanner.next() + (relative ? cy : 0);
          cy = y;
          emitLine(cx, y);
          prevWasCubic = prevWasQuad = false;
        case 'C':
          final x1 = scanner.next() + (relative ? cx : 0);
          final y1 = scanner.next() + (relative ? cy : 0);
          final x2 = scanner.next() + (relative ? cx : 0);
          final y2 = scanner.next() + (relative ? cy : 0);
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          emitCubic(x1, y1, x2, y2, x, y);
          lastCubicCtrlX = x2;
          lastCubicCtrlY = y2;
          cx = x;
          cy = y;
          prevWasCubic = true;
          prevWasQuad = false;
        case 'S':
          final x1 = prevWasCubic ? 2 * cx - lastCubicCtrlX : cx;
          final y1 = prevWasCubic ? 2 * cy - lastCubicCtrlY : cy;
          final x2 = scanner.next() + (relative ? cx : 0);
          final y2 = scanner.next() + (relative ? cy : 0);
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          emitCubic(x1, y1, x2, y2, x, y);
          lastCubicCtrlX = x2;
          lastCubicCtrlY = y2;
          cx = x;
          cy = y;
          prevWasCubic = true;
          prevWasQuad = false;
        case 'Q':
          final qx = scanner.next() + (relative ? cx : 0);
          final qy = scanner.next() + (relative ? cy : 0);
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          // Exact degree elevation from quadratic to cubic.
          emitCubic(cx + 2 / 3 * (qx - cx), cy + 2 / 3 * (qy - cy),
              x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y), x, y);
          lastQuadCtrlX = qx;
          lastQuadCtrlY = qy;
          cx = x;
          cy = y;
          prevWasQuad = true;
          prevWasCubic = false;
        case 'T':
          final qx = prevWasQuad ? 2 * cx - lastQuadCtrlX : cx;
          final qy = prevWasQuad ? 2 * cy - lastQuadCtrlY : cy;
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          emitCubic(cx + 2 / 3 * (qx - cx), cy + 2 / 3 * (qy - cy),
              x + 2 / 3 * (qx - x), y + 2 / 3 * (qy - y), x, y);
          lastQuadCtrlX = qx;
          lastQuadCtrlY = qy;
          cx = x;
          cy = y;
          prevWasQuad = true;
          prevWasCubic = false;
        case 'A':
          final rx = scanner.next();
          final ry = scanner.next();
          final rotation = scanner.next();
          final largeArc = scanner.nextFlag();
          final sweep = scanner.nextFlag();
          final x = scanner.next() + (relative ? cx : 0);
          final y = scanner.next() + (relative ? cy : 0);
          for (final c in _arcToCubics(
              cx, cy, rx, ry, rotation, largeArc, sweep, x, y)) {
            emitCubic(c[0], c[1], c[2], c[3], c[4], c[5]);
          }
          cx = x;
          cy = y;
          prevWasCubic = prevWasQuad = false;
      }
      first = false;
    }
  }
  return sink.toString();
}

/// Endpoint-to-centre parameterisation of an SVG elliptical arc, split into
/// cubic segments of at most 90°. Follows the W3C SVG 1.1 implementation notes
/// (appendix F.6.5).
List<List<double>> _arcToCubics(double x1, double y1, double rx, double ry,
    double rotationDeg, bool largeArc, bool sweep, double x2, double y2) {
  if (x1 == x2 && y1 == y2) return const [];
  if (rx == 0 || ry == 0) {
    // Degenerate radii: the spec says treat this as a straight line. Express it
    // as a cubic so the caller stays uniform.
    return [
      [x1, y1, x2, y2, x2, y2]
    ];
  }

  rx = rx.abs();
  ry = ry.abs();
  final phi = rotationDeg * math.pi / 180.0;
  final cosPhi = math.cos(phi);
  final sinPhi = math.sin(phi);

  // Step 1: translate the endpoints into the ellipse's own frame.
  final dx2 = (x1 - x2) / 2.0;
  final dy2 = (y1 - y2) / 2.0;
  final x1p = cosPhi * dx2 + sinPhi * dy2;
  final y1p = -sinPhi * dx2 + cosPhi * dy2;

  // Scale up the radii if they are too small to span the endpoints.
  final lambda = (x1p * x1p) / (rx * rx) + (y1p * y1p) / (ry * ry);
  if (lambda > 1) {
    final s = math.sqrt(lambda);
    rx *= s;
    ry *= s;
  }

  // Step 2: find the centre in that frame.
  final rxSq = rx * rx, rySq = ry * ry;
  final x1pSq = x1p * x1p, y1pSq = y1p * y1p;
  var radicand = (rxSq * rySq - rxSq * y1pSq - rySq * x1pSq) /
      (rxSq * y1pSq + rySq * x1pSq);
  if (radicand < 0) radicand = 0;
  final coef = (largeArc == sweep ? -1.0 : 1.0) * math.sqrt(radicand);
  final cxp = coef * rx * y1p / ry;
  final cyp = -coef * ry * x1p / rx;

  // Step 3: back to user space.
  final cx = cosPhi * cxp - sinPhi * cyp + (x1 + x2) / 2.0;
  final cy = sinPhi * cxp + cosPhi * cyp + (y1 + y2) / 2.0;

  // Step 4: the start angle and sweep.
  double angle(double ux, double uy, double vx, double vy) {
    final dot = ux * vx + uy * vy;
    final len = math.sqrt((ux * ux + uy * uy) * (vx * vx + vy * vy));
    var a = math.acos((dot / len).clamp(-1.0, 1.0));
    if (ux * vy - uy * vx < 0) a = -a;
    return a;
  }

  final theta1 = angle(1, 0, (x1p - cxp) / rx, (y1p - cyp) / ry);
  var deltaTheta = angle(
      (x1p - cxp) / rx, (y1p - cyp) / ry, (-x1p - cxp) / rx, (-y1p - cyp) / ry);
  if (!sweep && deltaTheta > 0) {
    deltaTheta -= 2 * math.pi;
  } else if (sweep && deltaTheta < 0) {
    deltaTheta += 2 * math.pi;
  }

  // Step 5: approximate with cubics, at most 90° each.
  final segments = (deltaTheta.abs() / (math.pi / 2)).ceil();
  final delta = deltaTheta / segments;
  // Magic constant for approximating a circular arc with a cubic Bézier.
  final t = 4 / 3 * math.tan(delta / 4);

  final result = <List<double>>[];
  var theta = theta1;
  var px = x1, py = y1;

  for (var i = 0; i < segments; i++) {
    final thetaNext = theta + delta;
    final cosT = math.cos(theta), sinT = math.sin(theta);
    final cosN = math.cos(thetaNext), sinN = math.sin(thetaNext);

    // Endpoint of this segment, in user space.
    final ex = cx + rx * cosPhi * cosN - ry * sinPhi * sinN;
    final ey = cy + rx * sinPhi * cosN + ry * cosPhi * sinN;

    // Derivatives at both ends give the control points.
    final d1x = -rx * cosPhi * sinT - ry * sinPhi * cosT;
    final d1y = -rx * sinPhi * sinT + ry * cosPhi * cosT;
    final d2x = -rx * cosPhi * sinN - ry * sinPhi * cosN;
    final d2y = -rx * sinPhi * sinN + ry * cosPhi * cosN;

    result.add([
      px + t * d1x,
      py + t * d1y,
      ex - t * d2x,
      ey - t * d2y,
      ex,
      ey,
    ]);

    theta = thetaNext;
    px = ex;
    py = ey;
  }
  return result;
}

// ---------------------------------------------------------------------------
// Primitive shapes, each expressed as path data and then normalised.
// ---------------------------------------------------------------------------

String rectToPath(
    double x, double y, double w, double h, double rx, double ry, Affine t) {
  if (w <= 0 || h <= 0) return '';
  // A missing radius mirrors the other per the SVG spec.
  if (rx == 0 && ry > 0) rx = ry;
  if (ry == 0 && rx > 0) ry = rx;
  rx = math.min(rx, w / 2);
  ry = math.min(ry, h / 2);

  if (rx == 0 || ry == 0) {
    return normalisePathData('M$x,$y H${x + w} V${y + h} H$x Z', t);
  }
  final d = StringBuffer()
    ..write('M${x + rx},$y')
    ..write('H${x + w - rx}')
    ..write('A$rx,$ry 0 0 1 ${x + w},${y + ry}')
    ..write('V${y + h - ry}')
    ..write('A$rx,$ry 0 0 1 ${x + w - rx},${y + h}')
    ..write('H${x + rx}')
    ..write('A$rx,$ry 0 0 1 $x,${y + h - ry}')
    ..write('V${y + ry}')
    ..write('A$rx,$ry 0 0 1 ${x + rx},$y')
    ..write('Z');
  return normalisePathData(d.toString(), t);
}

String circleToPath(double cx, double cy, double r, Affine t) =>
    ellipseToPath(cx, cy, r, r, t);

String ellipseToPath(double cx, double cy, double rx, double ry, Affine t) {
  if (rx <= 0 || ry <= 0) return '';
  // Two half-arcs, which keeps every arc well under the 180° degenerate case.
  final d = 'M${cx - rx},$cy '
      'A$rx,$ry 0 1 0 ${cx + rx},$cy '
      'A$rx,$ry 0 1 0 ${cx - rx},$cy Z';
  return normalisePathData(d, t);
}

String polygonToPath(String points, Affine t, {required bool close}) {
  final scanner = _NumberScanner(points);
  final buffer = StringBuffer();
  var first = true;
  while (!scanner.atEnd) {
    final x = scanner.next();
    final y = scanner.next();
    buffer.write(first ? 'M$x,$y' : 'L$x,$y');
    first = false;
  }
  if (first) return '';
  if (close) buffer.write('Z');
  return normalisePathData(buffer.toString(), t);
}

String lineToPath(double x1, double y1, double x2, double y2, Affine t) =>
    normalisePathData('M$x1,$y1 L$x2,$y2', t);
