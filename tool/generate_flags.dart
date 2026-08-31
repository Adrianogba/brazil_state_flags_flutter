// Build-time only. Reads the CC0 source SVGs and emits `lib/src/data/*.dart`.
//
// Usage:
//   dart run tool/generate_flags.dart <path-to-icones-bandeiras-br-uf/dist>
//
// The generated files are committed, so consumers never need this tool and the
// package ships with no build step.
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

import 'svg_normalizer.dart';

/// The four artwork styles, in the order they appear in the public API.
const _styles = <String, String>{
  'full': 'FlagsFull',
  'rounded': 'FlagsRounded',
  'square-rounded': 'FlagsSquareRounded',
  'circle': 'FlagsCircle',
};

/// Source file stem -> (Dart identifier, UF code, English label).
///
/// Three states ship two drawings in the source set. They are *not* a
/// consistent "v1 detailed / v2 simple" axis. For Espírito Santo the `-v2`
/// file is the one that carries the "TRABALHA E CONFIA" motto, so it is the
/// accurate rendering and becomes the default. Ceará and Paraíba go the other
/// way: their `-v2` files drop the emblem and the NEGO lettering respectively.
const _flags = <String, List<String>>{
  '01-brasil': ['brazil', 'br', 'Brazil'],
  '02-acre': ['acre', 'ac', 'Acre'],
  '03-alagoas': ['alagoas', 'al', 'Alagoas'],
  '04-amapa': ['amapa', 'ap', 'Amapá'],
  '05-amazonas': ['amazonas', 'am', 'Amazonas'],
  '06-bahia': ['bahia', 'ba', 'Bahia'],
  '07-ceara': ['ceara', 'ce', 'Ceará'],
  '07-ceara-v2': ['cearaSimplified', '', 'Ceará (simplified)'],
  '08-distrito-federal': ['distritoFederal', 'df', 'Distrito Federal'],
  '09-espirito-santo': [
    'espiritoSantoSimplified',
    '',
    'Espírito Santo (simplified)'
  ],
  '09-espirito-santo-v2': ['espiritoSanto', 'es', 'Espírito Santo'],
  '10-goias': ['goias', 'go', 'Goiás'],
  '11-maranhao': ['maranhao', 'ma', 'Maranhão'],
  '12-mato-grosso': ['matoGrosso', 'mt', 'Mato Grosso'],
  '13-mato-grosso-do-sul': ['matoGrossoDoSul', 'ms', 'Mato Grosso do Sul'],
  '14-minas-gerais': ['minasGerais', 'mg', 'Minas Gerais'],
  '15-para': ['para', 'pa', 'Pará'],
  '16-paraiba': ['paraiba', 'pb', 'Paraíba'],
  '16-paraiba-v2': ['paraibaSimplified', '', 'Paraíba (simplified)'],
  '17-parana': ['parana', 'pr', 'Paraná'],
  '18-pernambuco': ['pernambuco', 'pe', 'Pernambuco'],
  '19-piaui': ['piaui', 'pi', 'Piauí'],
  '20-rio-de-janeiro': ['rioDeJaneiro', 'rj', 'Rio de Janeiro'],
  '21-rio-grande-do-norte': ['rioGrandeDoNorte', 'rn', 'Rio Grande do Norte'],
  '22-rio-grande-do-sul': ['rioGrandeDoSul', 'rs', 'Rio Grande do Sul'],
  '23-rondonia': ['rondonia', 'ro', 'Rondônia'],
  '24-roraima': ['roraima', 'rr', 'Roraima'],
  '25-santa-catarina': ['santaCatarina', 'sc', 'Santa Catarina'],
  '26-sao-paulo': ['saoPaulo', 'sp', 'São Paulo'],
  '27-sergipe': ['sergipe', 'se', 'Sergipe'],
  '28-tocantins': ['tocantins', 'to', 'Tocantins'],
};

/// One drawing operation lifted out of the SVG.
class Shape {
  Shape(this.color, this.path, {this.clip, this.strokeWidth = 0});
  final int color;
  final String path;
  final String? clip;
  final double strokeWidth;
}

/// Style declarations that can reach a shape, whether from a CSS class, a
/// `style=` attribute or a presentation attribute.
class Style {
  String? fill;
  String? stroke;
  double? strokeWidth;
  String? clipPathRef;

  Style clone() => Style()
    ..fill = fill
    ..stroke = stroke
    ..strokeWidth = strokeWidth
    ..clipPathRef = clipPathRef;

  void mergeDeclarations(String css) {
    for (final decl in css.split(';')) {
      final i = decl.indexOf(':');
      if (i < 0) continue;
      final key = decl.substring(0, i).trim();
      final value = decl.substring(i + 1).trim();
      switch (key) {
        case 'fill':
          fill = value;
        case 'stroke':
          stroke = value;
        case 'stroke-width':
          strokeWidth = double.tryParse(value.replaceAll('px', '').trim());
        case 'clip-path':
          final m = RegExp(r'url\(#([^)]+)\)').firstMatch(value);
          if (m != null) clipPathRef = m.group(1);
      }
    }
  }
}

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/generate_flags.dart <path-to-dist>');
    exit(64);
  }
  final dist = args.first;
  if (!Directory(dist).existsSync()) {
    stderr.writeln('Source directory not found: $dist');
    exit(66);
  }

  final outDir = Directory(p.join('lib', 'src', 'data'));
  outDir.createSync(recursive: true);

  var totalShapes = 0;
  var missing = 0;
  final summary = <String, int>{};
  // style -> (identifier, width, height), used to emit the coverage test.
  final generated = <String, List<List<String>>>{};

  for (final style in _styles.keys) {
    final className = _styles[style]!;
    final svgDir = Directory(p.join(dist, style, 'svg'));
    if (!svgDir.existsSync()) {
      stderr.writeln('Missing style directory: ${svgDir.path}');
      exit(66);
    }

    final buffer = StringBuffer();
    _writeHeader(buffer, style, className);

    var count = 0;
    for (final stem in _flags.keys) {
      // The source names variants as `<state>-<style>-v2.svg`, so the suffix
      // has to move past the style rather than staying on the stem.
      final fileName = stem.endsWith('-v2')
          ? '${stem.substring(0, stem.length - 3)}-$style-v2.svg'
          : '$stem-$style.svg';
      final file = File(p.join(svgDir.path, fileName));
      if (!file.existsSync()) {
        stderr.writeln('  ! missing ${file.path}');
        missing++;
        continue;
      }
      final parsed = _parseSvg(file.readAsStringSync());
      final meta = _flags[stem]!;
      _writeFlag(buffer, meta, parsed);
      (generated[style] ??= [])
          .add([meta[0], _num(parsed.width), _num(parsed.height)]);
      totalShapes += parsed.shapes.length;
      count++;
    }

    _writeAliases(buffer);
    buffer.writeln('}');
    File(p.join(outDir.path, '${style.replaceAll('-', '_')}.dart'))
        .writeAsStringSync(buffer.toString());
    summary[style] = count;
  }

  _writeLookupData(outDir);
  _writeCoverageTest(generated);

  stdout.writeln('Generated ${_styles.length} style files into ${outDir.path}');
  summary.forEach((k, v) => stdout.writeln('  $k: $v flags'));
  stdout.writeln('  $totalShapes shapes total');
  stdout.writeln('  plus lookup_data.dart and the coverage test');

  // Silently dropping a source file is how the `-v2` variants went missing
  // once already, so an incomplete run must fail rather than warn.
  if (missing > 0) {
    stderr.writeln('');
    stderr.writeln('FAILED: $missing source file(s) could not be read. '
        'The generated output would be incomplete.');
    exit(70);
  }
  for (final entry in summary.entries) {
    if (entry.value != _flags.length) {
      stderr.writeln('FAILED: ${entry.key} produced ${entry.value} flags, '
          'expected ${_flags.length}.');
      exit(70);
    }
  }
}

/// Emits a test that names every generated constant.
///
/// Dart cannot enumerate static fields at runtime, so the only way to prove
/// that all 124 drawings really are exposed is to write them out. Generating
/// the test alongside the data keeps the two in step.
void _writeCoverageTest(Map<String, List<List<String>>> generated) {
  final b = StringBuffer();
  b.writeln('// GENERATED FILE. DO NOT EDIT BY HAND.');
  b.writeln('//');
  b.writeln('// Produced by tool/generate_flags.dart. Proves that every');
  b.writeln('// drawing in the source set is reachable from the public API.');
  b.writeln('');
  b.writeln("import 'package:brazil_state_flags/brazil_state_flags.dart';");
  b.writeln("import 'package:flutter_test/flutter_test.dart';");
  b.writeln('');
  b.writeln('void main() {');
  generated.forEach((style, flags) {
    final className = _styles[style]!;
    b.writeln("  test('$className exposes all ${flags.length} drawings', () {");
    b.writeln('    const flags = <String, FlagArtwork>{');
    for (final f in flags) {
      b.writeln("      '${f[0]}': $className.${f[0]},");
    }
    b.writeln('    };');
    b.writeln('    expect(flags, hasLength(${flags.length}));');
    b.writeln('    for (final entry in flags.entries) {');
    b.writeln('      expect(entry.value.shapes, isNotEmpty, '
        'reason: entry.key);');
    b.writeln('      expect(entry.value.width, ${flags.first[1]}, '
        'reason: entry.key);');
    b.writeln('      expect(entry.value.height, ${flags.first[2]}, '
        'reason: entry.key);');
    b.writeln('    }');
    b.writeln('  });');
    b.writeln('');
  });
  b.writeln('}');
  File(p.join('test', 'generated_coverage_test.dart'))
      .writeAsStringSync(b.toString());
}

/// Emits the tables behind `package:brazil_state_flags/lookup.dart`.
///
/// Generating these keeps them in step with the flag constants. Writing them by
/// hand would be one more place for a UF code to go stale.
void _writeLookupData(Directory outDir) {
  final b = StringBuffer();
  b.writeln('// GENERATED FILE. DO NOT EDIT BY HAND.');
  b.writeln('//');
  b.writeln('// Produced by tool/generate_flags.dart.');
  b.writeln('');
  b.writeln("import '../flag_artwork.dart';");
  for (final style in _styles.keys) {
    b.writeln("import '${style.replaceAll('-', '_')}.dart';");
  }
  b.writeln('');

  // Only entries that carry a UF code take part in lookup. The simplified
  // variants are reachable through the style classes instead.
  final withUf = _flags.values.where((m) => m[1].isNotEmpty).toList()
    ..sort((a, b) => a[1].compareTo(b[1]));

  b.writeln('/// UF code to the state name, in Portuguese.');
  b.writeln('const brazilStateNames = <String, String>{');
  for (final m in withUf) {
    b.writeln("  '${m[1].toUpperCase()}': '${m[2]}',");
  }
  b.writeln('};');
  b.writeln('');

  for (final entry in _styles.entries) {
    final varName = '${_camel(entry.key)}ByUf';
    b.writeln('/// UF code to its ${entry.key} artwork.');
    b.writeln('const $varName = <String, FlagArtwork>{');
    for (final m in withUf) {
      b.writeln("  '${m[1].toUpperCase()}': ${entry.value}.${m[0]},");
    }
    b.writeln('};');
    b.writeln('');
  }
  File(p.join(outDir.path, 'lookup_data.dart')).writeAsStringSync(b.toString());
}

String _camel(String hyphenated) {
  final parts = hyphenated.split('-');
  return parts.first +
      parts.skip(1).map((s) => s[0].toUpperCase() + s.substring(1)).join();
}

class ParsedSvg {
  ParsedSvg(this.width, this.height, this.shapes);
  final double width;
  final double height;
  final List<Shape> shapes;
}

ParsedSvg _parseSvg(String source) {
  final doc = XmlDocument.parse(source);
  final svg = doc.rootElement;

  // Viewport.
  final viewBox = svg.getAttribute('viewBox')?.split(RegExp(r'[\s,]+'));
  final width = viewBox != null ? double.parse(viewBox[2]) : 0.0;
  final height = viewBox != null ? double.parse(viewBox[3]) : 0.0;

  // CSS classes.
  final classStyles = <String, Style>{};
  for (final styleEl in svg.findAllElements('style')) {
    for (final m
        in RegExp(r'\.([\w-]+)\s*\{([^}]*)\}').allMatches(styleEl.innerText)) {
      (classStyles[m.group(1)!] ??= Style()).mergeDeclarations(m.group(2)!);
    }
  }

  // clipPath definitions, resolved to normalised path data.
  final clipPaths = <String, String>{};
  for (final cp in svg.findAllElements('clipPath')) {
    final id = cp.getAttribute('id');
    if (id == null) continue;
    final segments = <String>[];
    for (final child in cp.descendantElements) {
      final d = _shapeToPath(child, Affine.identity);
      if (d.isNotEmpty) segments.add(d);
    }
    if (segments.isNotEmpty) clipPaths[id] = segments.join();
  }

  final shapes = <Shape>[];
  _walk(svg, Style(), Affine.identity, null, classStyles, clipPaths, shapes);
  return ParsedSvg(width, height, shapes);
}

void _walk(
  XmlElement element,
  Style inherited,
  Affine transform,
  String? clip,
  Map<String, Style> classStyles,
  Map<String, String> clipPaths,
  List<Shape> out,
) {
  for (final child in element.childElements) {
    final name = child.name.local;
    // `defs`, `clipPath`, `style` and `title` never draw.
    if (name == 'defs' ||
        name == 'clipPath' ||
        name == 'style' ||
        name == 'title' ||
        name == 'desc') {
      continue;
    }

    // Resolve this element's effective style: inherited, then class, then
    // `style=`, then presentation attributes.
    final style = inherited.clone();
    final cls = child.getAttribute('class');
    if (cls != null) {
      for (final c in cls.split(RegExp(r'\s+'))) {
        final s = classStyles[c];
        if (s == null) continue;
        if (s.fill != null) style.fill = s.fill;
        if (s.stroke != null) style.stroke = s.stroke;
        if (s.strokeWidth != null) style.strokeWidth = s.strokeWidth;
        if (s.clipPathRef != null) style.clipPathRef = s.clipPathRef;
      }
    }
    final inlineStyle = child.getAttribute('style');
    if (inlineStyle != null) style.mergeDeclarations(inlineStyle);
    for (final attr in ['fill', 'stroke', 'stroke-width']) {
      final v = child.getAttribute(attr);
      if (v == null) continue;
      style.mergeDeclarations('$attr:$v');
    }

    // Transform. Every transform in the source pairs a translate with a
    // rotate, so this has to compose properly rather than just offsetting.
    var localTransform = transform;
    final tr = child.getAttribute('transform');
    if (tr != null) {
      localTransform = localTransform.multiply(parseTransform(tr));
    }

    // Clip, either inherited or introduced here.
    var localClip = clip;
    final directClip = child.getAttribute('clip-path');
    if (directClip != null) {
      final m = RegExp(r'url\(#([^)]+)\)').firstMatch(directClip);
      if (m != null) localClip = clipPaths[m.group(1)!] ?? localClip;
    } else if (style.clipPathRef != null) {
      localClip = clipPaths[style.clipPathRef!] ?? localClip;
      // Consume it so descendants do not re-apply the same clip.
      style.clipPathRef = null;
    }

    if (name == 'g') {
      _walk(
          child, style, localTransform, localClip, classStyles, clipPaths, out);
      continue;
    }

    final d = _shapeToPath(child, localTransform);
    if (d.isEmpty) continue;

    final fill = _color(style.fill);
    final stroke = _color(style.stroke);

    if (fill != null) {
      out.add(Shape(fill, d, clip: localClip));
    }
    if (stroke != null) {
      out.add(Shape(stroke, d,
          clip: localClip, strokeWidth: style.strokeWidth ?? 1.0));
    }

    // Elements can still have children (rare here, but cheap to support).
    if (child.childElements.isNotEmpty) {
      _walk(
          child, style, localTransform, localClip, classStyles, clipPaths, out);
    }
  }
}

String _shapeToPath(XmlElement el, Affine t) {
  double attr(String name, [double fallback = 0]) =>
      double.tryParse(el.getAttribute(name) ?? '') ?? fallback;

  switch (el.name.local) {
    case 'path':
      final d = el.getAttribute('d');
      if (d == null || d.trim().isEmpty) return '';
      return normalisePathData(d, t);
    case 'rect':
      return rectToPath(attr('x'), attr('y'), attr('width'), attr('height'),
          attr('rx'), attr('ry'), t);
    case 'circle':
      return circleToPath(attr('cx'), attr('cy'), attr('r'), t);
    case 'ellipse':
      return ellipseToPath(attr('cx'), attr('cy'), attr('rx'), attr('ry'), t);
    case 'polygon':
      return polygonToPath(el.getAttribute('points') ?? '', t, close: true);
    case 'polyline':
      return polygonToPath(el.getAttribute('points') ?? '', t, close: false);
    case 'line':
      return lineToPath(attr('x1'), attr('y1'), attr('x2'), attr('y2'), t);
    default:
      return '';
  }
}

/// Parses an SVG paint value into an ARGB int, or null when nothing is drawn.
int? _color(String? value) {
  if (value == null) return null;
  final v = value.trim().toLowerCase();
  if (v.isEmpty || v == 'none' || v == 'transparent') return null;
  if (v.startsWith('#')) {
    var hex = v.substring(1);
    if (hex.length == 3) {
      hex = hex.split('').map((c) => '$c$c').join();
    }
    if (hex.length == 6) return 0xFF000000 | int.parse(hex, radix: 16);
    if (hex.length == 8) return int.parse(hex, radix: 16);
    return null;
  }
  // The source set only uses hex and `none`; named colours are a safety net.
  const named = {
    'black': 0xFF000000,
    'white': 0xFFFFFFFF,
    'red': 0xFFFF0000,
    'green': 0xFF008000,
    'blue': 0xFF0000FF,
    'yellow': 0xFFFFFF00,
  };
  return named[v];
}

void _writeHeader(StringBuffer b, String style, String className) {
  b.writeln('// GENERATED FILE. DO NOT EDIT BY HAND.');
  b.writeln('//');
  b.writeln('// Produced by tool/generate_flags.dart from the CC0 artwork at');
  b.writeln('// https://github.com/pierrelapalu/icones-bandeiras-br-uf');
  b.writeln('// Re-run the generator instead of editing this file.');
  b.writeln('');
  b.writeln("import '../flag_artwork.dart';");
  b.writeln('');
  b.writeln('/// Brazilian flags drawn in the `$style` style.');
  b.writeln('///');
  b.writeln('/// Each entry is an independent `const`, so an app that');
  b.writeln('/// references one flag does not carry the rest into its binary.');
  b.writeln('abstract final class $className {');
}

void _writeFlag(StringBuffer b, List<String> meta, ParsedSvg svg) {
  final id = meta[0];
  final label = meta[2];
  b.writeln('  /// The flag of $label.');
  b.writeln('  static const $id = FlagArtwork(');
  b.writeln('    width: ${_num(svg.width)},');
  b.writeln('    height: ${_num(svg.height)},');
  b.writeln('    shapes: <FlagShape>[');
  for (final s in svg.shapes) {
    final parts = <String>[
      '0x${s.color.toRadixString(16).padLeft(8, '0').toUpperCase()}',
      "'${s.path}'",
    ];
    if (s.clip != null) parts.add("clip: '${s.clip}'");
    if (s.strokeWidth > 0) parts.add('strokeWidth: ${_num(s.strokeWidth)}');
    b.writeln('      FlagShape(${parts.join(', ')}),');
  }
  b.writeln('    ],');
  b.writeln('  );');
  b.writeln('');
}

void _writeAliases(StringBuffer b) {
  b.writeln('  // --- UF code aliases -----------------------------------');
  b.writeln('  // Short forms matching the `uf` field used in Brazilian');
  b.writeln('  // address forms. Each is the same object as the named');
  b.writeln('  // constant above, so using one costs nothing extra.');
  for (final meta in _flags.values) {
    final uf = meta[1];
    if (uf.isEmpty) continue;
    b.writeln('  /// Alias for [${meta[0]}] (${uf.toUpperCase()}).');
    b.writeln('  static const $uf = ${meta[0]};');
  }
}

String _num(double v) {
  if (v == v.roundToDouble()) return v.toStringAsFixed(1);
  return v.toString();
}
