import 'package:flutter/material.dart';

import '../theme.dart';

enum IconBackground {
  /// Filled rounded square, for the legacy launcher icon and the store listing.
  gradient,

  /// Transparent, for the adaptive icon foreground layer.
  none,
}

/// The launcher artwork: two fanned cards with a rising bar chart on the front
/// one. Drawn as paths rather than text or icon fonts so it renders identically
/// wherever it is rasterised, and stays legible down to 48px.
class AppIconPainter extends CustomPainter {
  const AppIconPainter({
    this.background = IconBackground.gradient,
    this.contentScale = 0.74,
    this.monochrome = false,
  });

  final IconBackground background;

  /// Artwork size as a fraction of the canvas. The adaptive icon only
  /// guarantees the middle 66 of 108dp is visible, so the foreground layer
  /// uses a much smaller value than the legacy icon.
  final double contentScale;

  /// Flat white silhouette for Android's themed icon slot.
  final bool monochrome;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;

    if (background == IconBackground.gradient) {
      final rect = Offset.zero & size;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(side * 0.22)),
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFF16543F), AppColors.feltDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect),
      );
    }

    final unit = side * contentScale;
    final centre = Offset(size.width / 2, size.height / 2);
    final back = centre + Offset(-unit * 0.15, unit * 0.03);
    final front = centre + Offset(unit * 0.09, -unit * 0.01);
    const backTilt = -0.28;
    const frontTilt = 0.12;

    if (monochrome) {
      // Android's themed icon keeps only the alpha channel and tints it, so
      // the artwork has to be carved out of one silhouette: the bars and the
      // gap between the cards are erased rather than painted.
      canvas.saveLayer(Offset.zero & size, Paint());
      _cardShape(canvas, back, unit, backTilt, Paint()..color = Colors.white);
      _cardShape(canvas, front, unit, frontTilt,
          Paint()..blendMode = BlendMode.clear,
          inflate: unit * 0.035);
      _cardShape(canvas, front, unit, frontTilt, Paint()..color = Colors.white);
      _bars(canvas, front, unit, frontTilt,
          Paint()..blendMode = BlendMode.clear);
      canvas.restore();
      return;
    }

    _cardShape(canvas, back, unit, backTilt, Paint()..color = AppColors.gold);
    _cardShape(
        canvas, front, unit, frontTilt, Paint()..color = AppColors.cardFace);
    _bars(canvas, front, unit, frontTilt, Paint()..color = AppColors.felt);
  }

  void _cardShape(
    Canvas canvas,
    Offset centre,
    double unit,
    double rotation,
    Paint paint, {
    double inflate = 0,
  }) {
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rotation);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: unit * 0.50 + inflate * 2,
          height: unit * 0.72 + inflate * 2,
        ),
        Radius.circular(unit * 0.07 + inflate),
      ),
      paint,
    );
    canvas.restore();
  }

  /// Three rising bars: the deck's stats, without committing to a direction.
  void _bars(
    Canvas canvas,
    Offset centre,
    double unit,
    double rotation,
    Paint paint,
  ) {
    final width = unit * 0.50;
    final height = unit * 0.72;
    final barWidth = width * 0.16;
    final baseline = height * 0.27;
    const heights = [0.26, 0.42, 0.58];

    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.rotate(rotation);
    for (var i = 0; i < heights.length; i++) {
      final barHeight = height * heights[i];
      final x = width * (i - 1) * 0.26;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
              x - barWidth / 2, baseline - barHeight, barWidth, barHeight),
          Radius.circular(barWidth * 0.35),
        ),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(AppIconPainter oldDelegate) =>
      oldDelegate.background != background ||
      oldDelegate.contentScale != contentScale ||
      oldDelegate.monochrome != monochrome;
}

class AppIconArt extends StatelessWidget {
  const AppIconArt({
    super.key,
    required this.size,
    this.background = IconBackground.gradient,
    this.contentScale = 0.74,
    this.monochrome = false,
  });

  final double size;
  final IconBackground background;
  final double contentScale;
  final bool monochrome;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: AppIconPainter(
        background: background,
        contentScale: contentScale,
        monochrome: monochrome,
      ),
    );
  }
}
