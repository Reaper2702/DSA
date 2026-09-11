import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trump_cards/data/deck_repository.dart';
import 'package:trump_cards/main.dart';
import 'package:trump_cards/widgets/played_card.dart';
import 'package:trump_cards/widgets/round_reveal.dart';

/// Serves the real deck file from disk without going through the asset
/// bundle's real I/O, which never completes under the widget tester's clock.
class _FileBundle extends CachingAssetBundle {
  _FileBundle(this.text);

  final String text;

  @override
  Future<ByteData> load(String key) async =>
      ByteData.sublistView(Uint8List.fromList(utf8.encode(text)));

  @override
  Future<String> loadString(String key, {bool cache = true}) async => text;
}

void main() {
  late DeckRepository repository;

  setUpAll(() {
    final json =
        File('assets/decks/${DeckRepository.assetPaths.first.split('/').last}')
            .readAsStringSync();
    repository = DeckRepository(bundle: _FileBundle(json));
  });

  test('the deck ships in the asset bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final decks = await const DeckRepository().loadAll();

    expect(decks, hasLength(1));
    expect(decks.single.cards, hasLength(52));
  });

  testWidgets('deal, pick a stat, and see the round resolve', (tester) async {
    await tester.pumpWidget(TrumpCardsApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('TRUMP CARDS'), findsOneWidget);

    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();

    expect(find.text('Your call — tap a stat'), findsOneWidget);
    expect(find.text('Round 1 of 20'), findsOneWidget);
    expect(find.text('You hold 26 cards'), findsOneWidget);

    await tester.tap(find.text('Runs'));
    await tester.pumpAndSettle();

    expect(find.byType(RoundReveal), findsOneWidget);
    expect(find.text('RUNS'), findsOneWidget);
  });

  testWidgets('a four player match deals thirteen each', (tester) async {
    await tester.pumpWidget(TrumpCardsApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('4 · 13 each'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();

    expect(find.text('You hold 13 cards'), findsOneWidget);
    expect(find.text('13 cards'), findsNWidgets(3));
  });

  testWidgets('a knockout match shows an uncapped round counter',
      (tester) async {
    await tester.pumpWidget(TrumpCardsApp(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Knockout'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();

    expect(find.text('Round 1'), findsOneWidget);
  });

  // The default 800x600 test surface hides layout overflows that a real phone
  // would hit, so these play a round at phone sizes. flutter_test turns an
  // overflow into a test failure.
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    testWidgets('a four player reveal fits a ${size.width.toInt()}px screen',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(TrumpCardsApp(repository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.text('4 · 13 each'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Deal'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wickets'));
      await tester.pumpAndSettle();

      expect(find.byType(RoundReveal), findsOneWidget);
      expect(find.byType(PlayedCard), findsNWidgets(3));
    });
  }

  testWidgets('leaving a match returns to the menu', (tester) async {
    await tester.pumpWidget(TrumpCardsApp(repository: repository));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Deal'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Leave match'));
    await tester.pumpAndSettle();

    expect(find.text('TRUMP CARDS'), findsOneWidget);
  });
}
