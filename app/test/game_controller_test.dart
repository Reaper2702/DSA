import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trump_cards/game/game_controller.dart';
import 'package:trump_cards/game/match_settings.dart';
import 'package:trump_engine/trump_engine.dart';

DeckDefinition testDeck() {
  final rng = Random(7);
  return DeckDefinition(
    id: 'test',
    name: 'Test',
    stats: const [
      StatDefinition(
        key: 'power',
        label: 'Power',
        direction: StatDirection.higherWins,
      ),
      StatDefinition(
        key: 'cost',
        label: 'Cost',
        direction: StatDirection.lowerWins,
      ),
    ],
    cards: [
      for (var i = 1; i <= 52; i++)
        TrumpCard(
          id: 'c$i',
          name: 'Card $i',
          subtitle: 'Test subject',
          stats: {'power': rng.nextInt(40), 'cost': rng.nextInt(30) + 1},
        ),
    ],
  );
}

/// The controller schedules the AI's choice on a Timer, so these run inside
/// testWidgets to get a controllable clock.
void main() {
  testWidgets('the human deals in as chooser with an even hand',
      (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(),
      random: Random(1),
    );
    addTearDown(controller.dispose);

    expect(controller.phase, GamePhase.humanChoosing);
    expect(controller.human.cardCount, 26);
    expect(controller.opponents.single.cardCount, 26);
    expect(controller.game.chooser.isHuman, isTrue);
  });

  testWidgets('four players get 13 cards each', (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(playerCount: 4),
      random: Random(1),
    );
    addTearDown(controller.dispose);

    expect(controller.game.players, hasLength(4));
    expect(
      controller.game.players.map((p) => p.cardCount),
      [13, 13, 13, 13],
    );
  });

  testWidgets('choosing a stat resolves the round and shows the reveal',
      (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(),
      random: Random(1),
    );
    addTearDown(controller.dispose);

    controller.chooseStat('power');

    expect(controller.phase, GamePhase.revealing);
    expect(controller.lastResult, isNotNull);
    expect(controller.lastResult!.stat.key, 'power');
    expect(controller.lastResult!.reveals, hasLength(2));
  });

  testWidgets('a stat tap is ignored while the result is on screen',
      (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(),
      random: Random(1),
    );
    addTearDown(controller.dispose);

    controller.chooseStat('power');
    final first = controller.lastResult;
    controller.chooseStat('cost');

    expect(controller.lastResult, same(first));
    expect(controller.game.roundNumber, 1);
  });

  testWidgets('the computer takes its turn after a thinking pause',
      (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(),
      random: Random(1),
      aiThinkingDelay: const Duration(milliseconds: 100),
    );
    addTearDown(controller.dispose);

    // Drive rounds until the computer wins one and takes over the choice.
    while (controller.phase != GamePhase.aiChoosing) {
      if (controller.phase == GamePhase.humanChoosing) {
        controller.chooseStat('power');
      } else if (controller.phase == GamePhase.revealing) {
        controller.continueToNextRound();
      } else {
        break;
      }
    }
    expect(controller.phase, GamePhase.aiChoosing,
        reason: 'the computer should win a round eventually');

    final before = controller.game.roundNumber;
    await tester.pump(const Duration(milliseconds: 50));
    expect(controller.game.roundNumber, before, reason: 'still thinking');

    await tester.pump(const Duration(milliseconds: 60));
    expect(controller.game.roundNumber, before + 1);
    expect(controller.phase, GamePhase.revealing);
  });

  testWidgets('a capped match plays through to a finish', (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(length: MatchLength.quick),
      random: Random(3),
      aiThinkingDelay: const Duration(milliseconds: 10),
    );
    addTearDown(controller.dispose);

    var guard = 0;
    while (controller.phase != GamePhase.finished && guard++ < 500) {
      switch (controller.phase) {
        case GamePhase.humanChoosing:
          controller.chooseStat('power');
        case GamePhase.revealing:
          controller.continueToNextRound();
        case GamePhase.aiChoosing:
          await tester.pump(const Duration(milliseconds: 20));
        case GamePhase.finished:
          break;
      }
    }

    expect(controller.phase, GamePhase.finished);
    expect(controller.game.isOver, isTrue);
    expect(controller.game.roundNumber, lessThanOrEqualTo(20));
    expect(controller.game.cardsInPlay, 52);
  });

  testWidgets('restart deals a fresh hand', (tester) async {
    final controller = GameController(
      deck: testDeck(),
      settings: const MatchSettings(),
      random: Random(1),
    );
    addTearDown(controller.dispose);

    controller.chooseStat('power');
    controller.restart();

    expect(controller.game.roundNumber, 0);
    expect(controller.lastResult, isNull);
    expect(controller.human.cardCount, 26);
    expect(controller.phase, GamePhase.humanChoosing);
  });
}
