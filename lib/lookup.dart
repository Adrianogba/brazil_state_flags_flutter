/// Runtime lookup of flags by UF code, for dropdowns and address forms.
///
/// This is a separate import on purpose. The tables here name every flag in a
/// style, so importing this library means your app carries all 28 of them
/// rather than only the ones you wrote out by hand. That is the right trade
/// when you genuinely need to pick a flag from a string at runtime, and the
/// wrong one when you just want two or three fixed flags.
///
/// ```dart
/// import 'package:brazil_state_flags/lookup.dart';
///
/// final flag = flagForUf('sp', style: FlagStyle.circle);
/// if (flag != null) BrazilStateFlag(flag, size: 32);
///
/// // Building a picker:
/// for (final state in brazilStates) {
///   print('${state.uf} ${state.name}');
/// }
/// ```
library;

import 'src/data/lookup_data.dart';
import 'src/flag_artwork.dart';

export 'src/data/lookup_data.dart' show brazilStateNames;

/// The four artwork styles.
enum FlagStyle {
  /// Rectangular, 3:2, square corners.
  full,

  /// Rectangular, 3:2, rounded corners.
  rounded,

  /// Square with rounded corners.
  squareRounded,

  /// Circular.
  circle,
}

/// One state, paired with the artwork for it.
class BrazilState {
  const BrazilState._(this.uf, this.name);

  /// Two letter UF code, upper case, for example `SP`.
  final String uf;

  /// State name in Portuguese, for example `São Paulo`.
  final String name;

  /// This state's flag in [style].
  FlagArtwork flag(FlagStyle style) => flagForUf(uf, style: style)!;

  @override
  String toString() => 'BrazilState($uf, $name)';
}

/// Every state and the Federal District, ordered by UF code.
///
/// Handy for building a dropdown. `BR` is included at its alphabetical
/// position and is the national flag rather than a state.
final List<BrazilState> brazilStates = List.unmodifiable(
  brazilStateNames.entries
      .map((e) => BrazilState._(e.key, e.value))
      .toList(growable: false),
);

/// Returns the flag for [uf], or null when the code is not recognised.
///
/// [uf] is case insensitive and surrounding whitespace is ignored, so values
/// straight out of a text field work without cleaning them up first.
FlagArtwork? flagForUf(String uf, {FlagStyle style = FlagStyle.circle}) {
  final key = uf.trim().toUpperCase();
  return switch (style) {
    FlagStyle.full => fullByUf[key],
    FlagStyle.rounded => roundedByUf[key],
    FlagStyle.squareRounded => squareRoundedByUf[key],
    FlagStyle.circle => circleByUf[key],
  };
}

/// The state name in Portuguese for [uf], or null when unrecognised.
String? stateNameForUf(String uf) => brazilStateNames[uf.trim().toUpperCase()];
