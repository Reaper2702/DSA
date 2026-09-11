// Renders the app's screens to PNGs so the UI can be reviewed without a
// device.
//
// Run from app/:
//   flutter test tool/screenshots.dart
//
// Output goes to ../store/screens/. These are development references, not the
// Play Store listing shots — those need to come from a real device.

import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trump_cards/data/deck_repository.dart';
import 'package:trump_cards/main.dart';

const outputDir = '../store/screens';
const phone = Size(390, 844);

class _FileBundle extends CachingAssetBundle {
  _FileBundle(this.text);

  final String text;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

Future<void> shoot(WidgetTester tester, GlobalKey key, String name) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  late final Uint8List bytes;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    bytes = data!.buffer.asUint8List();
  });
  final file = File('$outputDir/$name.png')..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

void main() {
  late DeckRepository repository;
  final key = GlobalKey();

  setUpAll(() async {
    repository = DeckRepository(
      bundle: _FileBundle(File('assets/decks/cricket.json').readAsStringSync()),
    );
    // flutter test draws every glyph as a box unless a real font is loaded.
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    const fonts = {
      'Roboto': 'Roboto-Regular.ttf',
      'MaterialIcons': 'MaterialIcons-Regular.otf',
    };
    for (final entry in fonts.entries) {
      final file = flutterRoot == null
          ? null
          : File('$flutterRoot/bin/cache/artifacts/material_fonts/'
              '${entry.value}');
      if (file == null || !file.existsSync()) {
        stderr.writeln('${entry.key} not found — it will render as boxes.');
        continue;
      }
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(ByteData.sublistView(file.readAsBytesSync())));
      await loader.load();
    }
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = phone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      RepaintBoundary(key: key, child: TrumpCardsApp(repository: repository)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('menu', (tester) async {
    await open(tester);
    await shoot(tester, key, '01-menu');
  });

  testWidgets('choosing', (tester) async {
    await open(tester);
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();
    await shoot(tester, key, '02-choosing');
  });

  testWidgets('reveal', (tester) async {
    await open(tester);
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Runs'));
    await tester.pumpAndSettle();
    await shoot(tester, key, '03-reveal');
  });

  testWidgets('four player reveal', (tester) async {
    await open(tester);
    await tester.tap(find.text('4 · 13 each'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Wickets'));
    await tester.pumpAndSettle();
    await shoot(tester, key, '04-reveal-four');
  });
}
