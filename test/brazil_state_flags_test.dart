import 'package:brazil_state_flags/brazil_state_flags.dart';
import 'package:brazil_state_flags/lookup.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// The generator is part of this package, so its geometry is testable too.
import '../tool/svg_normalizer.dart';

/// Walks [data] (or [path]) and returns points that genuinely lie on the
/// curve, unlike the control point envelope Path.getBounds() reports.
List<Offset> _samplePath(String data, {Path? path}) {
  final target = path ?? parseFlagPath(data);
  final points = <Offset>[];
  for (final metric in target.computeMetrics()) {
    if (metric.length == 0) continue;
    const steps = 48;
    for (var i = 0; i <= steps; i++) {
      final t = metric.getTangentForOffset(metric.length * i / steps);
      if (t != null) points.add(t.position);
    }
  }
  return points;
}

/// Every flag in a style, paired with the name it is exposed under.
Map<String, FlagArtwork> _circle() => {
      'brazil': FlagsCircle.brazil,
      'acre': FlagsCircle.acre,
      'alagoas': FlagsCircle.alagoas,
      'amapa': FlagsCircle.amapa,
      'amazonas': FlagsCircle.amazonas,
      'bahia': FlagsCircle.bahia,
      'ceara': FlagsCircle.ceara,
      'cearaSimplified': FlagsCircle.cearaSimplified,
      'distritoFederal': FlagsCircle.distritoFederal,
      'espiritoSanto': FlagsCircle.espiritoSanto,
      'espiritoSantoSimplified': FlagsCircle.espiritoSantoSimplified,
      'goias': FlagsCircle.goias,
      'maranhao': FlagsCircle.maranhao,
      'matoGrosso': FlagsCircle.matoGrosso,
      'matoGrossoDoSul': FlagsCircle.matoGrossoDoSul,
      'minasGerais': FlagsCircle.minasGerais,
      'para': FlagsCircle.para,
      'paraiba': FlagsCircle.paraiba,
      'paraibaSimplified': FlagsCircle.paraibaSimplified,
      'parana': FlagsCircle.parana,
      'pernambuco': FlagsCircle.pernambuco,
      'piaui': FlagsCircle.piaui,
      'rioDeJaneiro': FlagsCircle.rioDeJaneiro,
      'rioGrandeDoNorte': FlagsCircle.rioGrandeDoNorte,
      'rioGrandeDoSul': FlagsCircle.rioGrandeDoSul,
      'rondonia': FlagsCircle.rondonia,
      'roraima': FlagsCircle.roraima,
      'santaCatarina': FlagsCircle.santaCatarina,
      'saoPaulo': FlagsCircle.saoPaulo,
      'sergipe': FlagsCircle.sergipe,
      'tocantins': FlagsCircle.tocantins,
    };

void main() {
  group('coverage', () {
    test('every style exposes all 31 drawings', () {
      expect(_circle(), hasLength(31));
      // Lookup only carries the 28 canonical entries, since the simplified
      // variants have no UF code of their own.
      for (final style in FlagStyle.values) {
        final resolved = brazilStateNames.keys
            .map((uf) => flagForUf(uf, style: style))
            .toList();
        expect(resolved, hasLength(28));
        expect(resolved, everyElement(isNotNull));
      }
    });

    test('all 26 states, the Federal District and Brazil are present', () {
      expect(brazilStateNames.keys, contains('DF'));
      expect(brazilStateNames.keys, contains('BR'));
      expect(brazilStateNames, hasLength(28));
      expect(brazilStateNames['SP'], 'São Paulo');
      expect(brazilStateNames['ES'], 'Espírito Santo');
    });
  });

  group('artwork integrity', () {
    test('no flag is empty and every colour is opaque', () {
      for (final entry in _circle().entries) {
        final art = entry.value;
        expect(art.shapes, isNotEmpty, reason: '${entry.key} has no shapes');
        for (final shape in art.shapes) {
          expect(shape.path, isNotEmpty,
              reason: '${entry.key} has an empty path');
          expect(shape.resolvedColor.a, 1.0,
              reason: '${entry.key} has a translucent shape');
        }
      }
    });

    test('styles report the dimensions their viewBox declares', () {
      expect(FlagsCircle.saoPaulo.width, 200);
      expect(FlagsCircle.saoPaulo.height, 200);
      expect(FlagsCircle.saoPaulo.aspectRatio, 1.0);

      expect(FlagsFull.saoPaulo.width, 300);
      expect(FlagsFull.saoPaulo.height, 200);
      expect(FlagsFull.saoPaulo.aspectRatio, 1.5);

      expect(FlagsSquareRounded.saoPaulo.aspectRatio, 1.0);
      expect(FlagsRounded.saoPaulo.aspectRatio, 1.5);
    });

    // The generator converts elliptical arcs into cubics by hand. Sampling
    // points along the finished curves is what actually proves that maths.
    // Note that Path.getBounds() is no good here: it returns control point
    // bounds, and the control points of a Bezier arc legitimately sit outside
    // the curve they describe.
    test('every drawn point stays inside the viewBox', () {
      for (final entry in _circle().entries) {
        final art = entry.value;
        for (final shape in art.shapes) {
          for (final point in _samplePath(shape.path)) {
            const slack = 1.5; // room for stroke width and rounding
            expect(point.dx, inInclusiveRange(-slack, art.width + slack),
                reason: '${entry.key} draws outside horizontally');
            expect(point.dy, inInclusiveRange(-slack, art.height + slack),
                reason: '${entry.key} draws outside vertically');
          }
        }
      }
    });

    test('arc conversion traces a true circle', () {
      // A 200 unit circle built the way the generator builds one. Every
      // sampled point must sit on the rim, which catches a wrong sweep
      // direction, a bad centre, or radii that were not scaled correctly.
      final circle =
          parseFlagPath(ellipseToPath(100, 100, 100, 100, Affine.identity));
      final points = _samplePath('', path: circle);
      expect(points, isNotEmpty);
      for (final point in points) {
        final r = (point - const Offset(100, 100)).distance;
        expect(r, closeTo(100, 0.5), reason: 'point $point is off the rim');
      }
    });

    test('rounded rectangles keep their corners', () {
      // 100x50 box with 10 unit corners. Sampled points must stay inside, and
      // the extremes must actually reach the edges.
      final rect =
          parseFlagPath(rectToPath(0, 0, 100, 50, 10, 10, Affine.identity));
      final points = _samplePath('', path: rect);
      var maxX = 0.0, maxY = 0.0;
      for (final point in points) {
        expect(point.dx, inInclusiveRange(-0.01, 100.01));
        expect(point.dy, inInclusiveRange(-0.01, 50.01));
        maxX = point.dx > maxX ? point.dx : maxX;
        maxY = point.dy > maxY ? point.dy : maxY;
      }
      expect(maxX, closeTo(100, 0.5));
      expect(maxY, closeTo(50, 0.5));
    });
  });

  group('path parser', () {
    test('reads move, line, cubic and close', () {
      final path = parseFlagPath('M0 0L10 0C10 5 5 10 0 10Z');
      final bounds = path.getBounds();
      expect(bounds.left, 0);
      expect(bounds.top, 0);
      expect(bounds.right, closeTo(10, 0.01));
      expect(bounds.bottom, closeTo(10, 0.01));
    });

    test('handles negative and fractional coordinates', () {
      final bounds = parseFlagPath('M-5.5 -2.25L4.5 7.75Z').getBounds();
      expect(bounds.left, closeTo(-5.5, 0.001));
      expect(bounds.top, closeTo(-2.25, 0.001));
    });

    test('Paraíba simplified is the two bar design, without NEGO', () {
      // The plain variant is red and black only. The white of the lettering
      // appearing here would mean the wrong source file was picked up.
      final colours =
          FlagsFull.paraibaSimplified.shapes.map((s) => s.color).toSet();
      expect(colours, {0xFFD9251D, 0xFF1D1D1B});
      expect(FlagsFull.paraibaSimplified.shapes, hasLength(2));

      // While the default Paraíba flag does carry it.
      expect(
        FlagsFull.paraiba.shapes.map((s) => s.color),
        contains(0xFFF0F0F0),
      );
    });

    test('Espírito Santo defaults to the drawing with the motto', () {
      // Here the source `-v2` file is the detailed one, so the default must be
      // the richer artwork and the simplified name the plainer one.
      expect(
        FlagsCircle.espiritoSanto.shapes.length,
        greaterThan(FlagsCircle.espiritoSantoSimplified.shapes.length),
      );
    });
  });

  group('lookup', () {
    test('resolves every UF code in all four styles', () {
      for (final uf in brazilStateNames.keys) {
        for (final style in FlagStyle.values) {
          expect(flagForUf(uf, style: style), isNotNull, reason: '$uf $style');
        }
      }
    });

    test('is case and whitespace insensitive', () {
      expect(flagForUf('sp'), same(FlagsCircle.saoPaulo));
      expect(flagForUf('  Sp '), same(FlagsCircle.saoPaulo));
      expect(flagForUf('SP', style: FlagStyle.full), same(FlagsFull.saoPaulo));
    });

    test('returns null for codes that do not exist', () {
      expect(flagForUf('XX'), isNull);
      expect(flagForUf(''), isNull);
      expect(stateNameForUf('ZZ'), isNull);
    });

    test('brazilStates is ordered and complete', () {
      expect(brazilStates, hasLength(28));
      final codes = brazilStates.map((s) => s.uf).toList();
      final sorted = [...codes]..sort();
      expect(codes, sorted);
      expect(brazilStates.first.flag(FlagStyle.circle), isNotNull);
    });
  });

  group('UF aliases', () {
    test('point at the same objects as the named constants', () {
      expect(FlagsCircle.sp, same(FlagsCircle.saoPaulo));
      expect(FlagsCircle.rj, same(FlagsCircle.rioDeJaneiro));
      expect(FlagsCircle.df, same(FlagsCircle.distritoFederal));
      expect(FlagsFull.mg, same(FlagsFull.minasGerais));
      expect(FlagsCircle.es, same(FlagsCircle.espiritoSanto));
    });
  });

  group('widget', () {
    testWidgets('sizes itself from the artwork proportions', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BrazilStateFlag(FlagsFull.saoPaulo, size: 60),
          ),
        ),
      );
      // 3:2 artwork, so the longest side takes the given size.
      final size = tester.getSize(find.byType(BrazilStateFlag));
      expect(size.width, 60);
      expect(size.height, 40);
    });

    testWidgets('square styles get equal sides', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BrazilStateFlag(FlagsCircle.bahia, size: 48),
          ),
        ),
      );
      expect(tester.getSize(find.byType(BrazilStateFlag)), const Size(48, 48));
    });

    testWidgets('derives the missing dimension from width', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: BrazilStateFlag(FlagsFull.parana, width: 150),
          ),
        ),
      );
      expect(
          tester.getSize(find.byType(BrazilStateFlag)), const Size(150, 100));
    });

    testWidgets('exposes a semantic label when one is given', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
              child: BrazilStateFlag(
            FlagsCircle.bahia,
            size: 32,
            semanticLabel: 'Bandeira da Bahia',
          )),
        ),
      );
      expect(find.bySemanticsLabel('Bandeira da Bahia'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('paints every flag without throwing', (tester) async {
      for (final entry in _circle().entries) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: BrazilStateFlag(entry.value, size: 64),
          ),
        );
        expect(tester.takeException(), isNull, reason: entry.key);
      }
    });
  });
}
