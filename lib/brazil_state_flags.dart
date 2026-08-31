/// Flags of the Brazilian states and the Federal District, drawn as vectors in
/// pure Dart.
///
/// Pick a style collection, then a state:
///
/// ```dart
/// import 'package:brazil_state_flags/brazil_state_flags.dart';
///
/// BrazilStateFlag(FlagsCircle.saoPaulo, size: 48)
/// BrazilStateFlag(FlagsFull.rioDeJaneiro, width: 120)
/// BrazilStateFlag(FlagsCircle.sp, size: 24) // UF code alias
/// ```
///
/// Every flag is an independent `const`, so Dart's tree shaker removes the ones
/// an app never mentions. If you need to look flags up by a UF string at
/// runtime, import `package:brazil_state_flags/lookup.dart` and read the note
/// there about what that costs.
library;

export 'src/brazil_state_flag.dart';
export 'src/data/circle.dart';
export 'src/data/full.dart';
export 'src/data/rounded.dart';
export 'src/data/square_rounded.dart';
export 'src/flag_artwork.dart' show FlagArtwork, FlagShape, parseFlagPath;
export 'src/flag_painter.dart' show FlagPainter;
