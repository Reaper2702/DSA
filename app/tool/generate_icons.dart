// Rasterises the launcher icons from lib/branding/app_icon_art.dart.
//
// Run from app/:
//   flutter test tool/generate_icons.dart
//
// It is driven by the widget tester because that is the only headless way to
// get Flutter's own rasteriser, which keeps the icon identical to the artwork
// the app draws.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trump_cards/branding/app_icon_art.dart';

/// Density buckets and the baseline-dp multiplier each one needs.
const densities = <String, double>{
  'mdpi': 1,
  'hdpi': 1.5,
  'xhdpi': 2,
  'xxhdpi': 3,
  'xxxhdpi': 4,
};

const resRoot = 'android/app/src/main/res';

Future<void> render(
  WidgetTester tester,
  Widget Function(double size) art,
  double pixels,
  String path,
) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: RepaintBoundary(key: key, child: art(pixels))),
    ),
  );
  await tester.pumpAndSettle();

  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;

  // PNG encoding runs on a real background thread, so it needs the real event
  // loop rather than the tester's fake clock.
  late final Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    bytes = data!.buffer.asUint8List();
  });

  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

void main() {
  testWidgets('write launcher icons', (tester) async {
    for (final entry in densities.entries) {
      final scale = entry.value;

      // Legacy square icon, 48dp baseline.
      await render(
        tester,
        (size) => AppIconArt(size: size),
        48 * scale,
        '$resRoot/mipmap-${entry.key}/ic_launcher.png',
      );

      // Adaptive foreground, 108dp baseline with only the middle 66dp safe.
      await render(
        tester,
        (size) => AppIconArt(
          size: size,
          background: IconBackground.none,
          contentScale: 0.48,
        ),
        108 * scale,
        '$resRoot/mipmap-${entry.key}/ic_launcher_foreground.png',
      );

      await render(
        tester,
        (size) => AppIconArt(
          size: size,
          background: IconBackground.none,
          contentScale: 0.48,
          monochrome: true,
        ),
        108 * scale,
        '$resRoot/mipmap-${entry.key}/ic_launcher_monochrome.png',
      );
    }

    // Play Store listing icon.
    await render(
      tester,
      (size) => AppIconArt(size: size),
      512,
      '../store/icon-512.png',
    );
  });
}
