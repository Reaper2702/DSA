// Renders the Play Store feature graphic (1024x500).
//
// Run from app/:
//   flutter test tool/generate_feature_graphic.dart
//
// The listing crops this image on some surfaces, so everything that matters
// stays well inside the edges.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trump_cards/branding/app_icon_art.dart';
import 'package:trump_cards/theme.dart';

const output = '../store/feature-graphic-1024x500.png';

class FeatureGraphic extends StatelessWidget {
  const FeatureGraphic({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1024,
      height: 500,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF17583F), AppColors.feltDeep],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        // No MaterialApp here, so the font family has to be set explicitly or
        // every glyph falls back to the platform default.
        child: DefaultTextStyle(
          style: const TextStyle(fontFamily: 'Roboto', color: Colors.white),
          child: Row(
          children: [
            const SizedBox(width: 84),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TRUMP CARDS',
                    style: TextStyle(
                      fontSize: 62,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      color: AppColors.gold,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Pick a stat. Take the cards.',
                    style: TextStyle(
                      fontSize: 27,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.88),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fifty-two cricketers, one stat at a time.',
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 360,
              height: 500,
              child: AppIconArt(
                size: 360,
                background: IconBackground.none,
                contentScale: 1.0,
              ),
            ),
            const SizedBox(width: 40),
          ],
          ),
        ),
      ),
    );
  }
}

void main() {
  setUpAll(() async {
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final roboto = flutterRoot == null
        ? null
        : File('$flutterRoot/bin/cache/artifacts/material_fonts/'
            'Roboto-Regular.ttf');
    if (roboto != null && roboto.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(roboto.readAsBytesSync())));
      await loader.load();
    } else {
      stderr.writeln('Roboto not found — text will render as boxes.');
    }
  });

  testWidgets('write the feature graphic', (tester) async {
    tester.view.physicalSize = const Size(1024, 500);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(key: key, child: const FeatureGraphic()),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    late final Uint8List bytes;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      bytes = data!.buffer.asUint8List();
    });

    final file = File(output)..parent.createSync(recursive: true);
    file.writeAsBytesSync(bytes);
  });
}
