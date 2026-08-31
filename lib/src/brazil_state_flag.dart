import 'package:flutter/widgets.dart';

import 'flag_artwork.dart';
import 'flag_painter.dart';

/// Draws one Brazilian flag.
///
/// The artwork comes from one of the four style collections, so pick the shape
/// you want and pass the state you want:
///
/// ```dart
/// BrazilStateFlag(FlagsCircle.saoPaulo, size: 48)
/// BrazilStateFlag(FlagsFull.rioDeJaneiro, width: 120)
/// ```
///
/// Nothing is rasterised and no assets are loaded. Each flag is vector data
/// compiled into Dart, so it stays sharp at any size and an app only carries
/// the flags it actually names.
class BrazilStateFlag extends StatelessWidget {
  /// Creates a flag widget for [artwork].
  ///
  /// Give it a [size], a [width], a [height], or any combination. Whatever you
  /// leave out is worked out from the artwork's own proportions, so the flag is
  /// never stretched.
  const BrazilStateFlag(
    this.artwork, {
    super.key,
    this.size,
    this.width,
    this.height,
    this.semanticLabel,
  }) : assert(
          size == null || (width == null && height == null),
          'Pass either size, or width and/or height, but not both.',
        );

  /// The flag to draw, for example `FlagsCircle.bahia`.
  final FlagArtwork artwork;

  /// Shorthand for the longest side of the flag.
  ///
  /// The other side follows the artwork's aspect ratio. For the square and
  /// circular styles this is simply the width and the height.
  final double? size;

  /// Explicit width. Defaults to whatever keeps [height] in proportion.
  final double? width;

  /// Explicit height. Defaults to whatever keeps [width] in proportion.
  final double? height;

  /// Description announced by screen readers.
  ///
  /// Leave it null and the flag is treated as decorative, which is usually
  /// right when a label sits next to it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ratio = artwork.aspectRatio;

    double resolvedWidth;
    double resolvedHeight;

    if (size != null) {
      // The longest side gets `size`, so flags of different styles line up
      // inside the same slot.
      if (ratio >= 1) {
        resolvedWidth = size!;
        resolvedHeight = size! / ratio;
      } else {
        resolvedHeight = size!;
        resolvedWidth = size! * ratio;
      }
    } else if (width != null && height != null) {
      resolvedWidth = width!;
      resolvedHeight = height!;
    } else if (width != null) {
      resolvedWidth = width!;
      resolvedHeight = width! / ratio;
    } else if (height != null) {
      resolvedHeight = height!;
      resolvedWidth = height! * ratio;
    } else {
      // Match the default icon size on the longest side.
      resolvedWidth = ratio >= 1 ? 24.0 : 24.0 * ratio;
      resolvedHeight = ratio >= 1 ? 24.0 / ratio : 24.0;
    }

    Widget flag = SizedBox(
      width: resolvedWidth,
      height: resolvedHeight,
      child: CustomPaint(
        painter: FlagPainter(artwork),
        isComplex: artwork.shapes.length > 8,
        willChange: false,
      ),
    );

    if (semanticLabel != null) {
      flag = Semantics(
        label: semanticLabel,
        image: true,
        child: ExcludeSemantics(child: flag),
      );
    }
    return flag;
  }
}
