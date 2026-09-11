import 'dart:math';

import 'package:test/test.dart';
import 'package:trump_engine/trump_engine.dart';

TrumpCard card(String id, {required num power, required num cost}) =>
    TrumpCard(id: id, name: id, stats: {'power': power, 'cost': cost});

DeckDefinition deckOf(List<TrumpCard> cards) => DeckDefinition(
      id: 'test',
      name: 'Test Deck',
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
      cards: cards,
    );

/// Card `cN` has power N and cost N, so every comparison is decisive.
DeckDefinition numberedDeck(int count) => deckOf([
      for (var i = 1; i <= count; i++) card('c$i', power: i, cost: i),
    ]);

/// Coarse values so that ties — and therefore pots — happen often.
DeckDefinition variedDeck(int count, {int seed = 99}) {
  final rng = Random(seed);
  return deckOf([
    for (var i = 1; i <= count; i++)
      card('c$i', power: rng.nextInt(8) * 10, cost: rng.nextInt(6) + 1),
  ]);
}

const seats2 = [
  PlayerSeat(id: 'p1', name: 'P1', isHuman: true),
  PlayerSeat(id: 'p2', name: 'P2'),
];

const seats4 = [
  PlayerSeat(id: 'p1', name: 'P1', isHuman: true),
  PlayerSeat(id: 'p2', name: 'P2'),
  PlayerSeat(id: 'p3', name: 'P3'),
  PlayerSeat(id: 'p4', name: 'P4'),
];

void main() {
  group('dealing', () {
    test('two players get 26 cards each from a 52 card deck', () {
      final game = TrumpGame.start(
        deck: numberedDeck(52),
        seats: seats2,
        random: Random(1),
      );

      expect(game.players.map((p) => p.cardCount), [26, 26]);
      expect(game.cardsInPlay, 52);
    });

    test('four players get 13 cards each from a 52 card deck', () {
      final game = TrumpGame.start(
        deck: numberedDeck(52),
        seats: seats4,
        random: Random(1),
      );

      expect(game.players.map((p) => p.cardCount), [13, 13, 13, 13]);
      expect(game.cardsInPlay, 52);
    });

    test('hands stay equal when the deck does not divide evenly', () {
      final game = TrumpGame.start(
        deck: numberedDeck(52),
        seats: const [
          PlayerSeat(id: 'p1', name: 'P1'),
          PlayerSeat(id: 'p2', name: 'P2'),
          PlayerSeat(id: 'p3', name: 'P3'),
        ],
        random: Random(1),
      );

      expect(game.players.map((p) => p.cardCount), [17, 17, 17]);
      expect(game.cardsInPlay, 51);
    });

    test('no card is dealt to two players', () {
      final game = TrumpGame.start(
        deck: numberedDeck(52),
        seats: seats4,
        random: Random(5),
      );

      final dealt = [
        for (final player in game.players) ...player.hand.map((c) => c.id),
      ];
      expect(dealt.toSet(), hasLength(52));
    });

    test('a game needs at least two players', () {
      expect(
        () => TrumpGame.start(
          deck: numberedDeck(52),
          seats: const [PlayerSeat(id: 'p1', name: 'P1')],
        ),
        throwsArgumentError,
      );
    });
  });

  group('resolving a round', () {
    test('the highest value wins a stat where high is best', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[3]], // c1, c4
          [deck.cards[1], deck.cards[2]], // c2, c3
        ],
      );

      final result = game.playRound('power');

      expect(result.outcome, RoundOutcome.win);
      expect(result.winnerIds, ['p2']);
      expect(result.cardsAwarded, 2);
      expect(game.players[0].cardCount, 1);
      expect(game.players[1].cardCount, 3);
    });

    test('the lowest value wins a stat where low is best', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[3]], // c1, c4
          [deck.cards[1], deck.cards[2]], // c2, c3
        ],
      );

      final result = game.playRound('cost');

      expect(result.winnerIds, ['p1']);
      expect(game.players[0].cardCount, 3);
    });

    test('the round winner chooses the next stat', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[3]],
          [deck.cards[1], deck.cards[2]],
        ],
      );
      expect(game.chooser.id, 'p1');

      final result = game.playRound('power');

      expect(game.chooser.id, 'p2');
      expect(result.nextChooserId, 'p2');
    });

    test('winnings go to the back of the hand, winning card first', () {
      final deck = numberedDeck(6);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[4], deck.cards[0], deck.cards[1]], // c5, c1, c2
          [deck.cards[2], deck.cards[3], deck.cards[5]], // c3, c4, c6
        ],
      );

      game.playRound('power'); // c5 beats c3

      expect(
        game.players[0].hand.map((c) => c.id),
        ['c1', 'c2', 'c5', 'c3'],
      );
    });

    test('reveals are ordered best value first', () {
      final deck = numberedDeck(8);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats4,
        hands: [
          [deck.cards[1]], // c2
          [deck.cards[6]], // c7
          [deck.cards[3]], // c4
          [deck.cards[5]], // c6
        ],
      );

      final result = game.playRound('power');

      expect(result.reveals.map((r) => r.card.id), ['c7', 'c6', 'c4', 'c2']);
      expect(result.reveals.first.isWinner, isTrue);
    });

    test('an unknown stat is rejected', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[1]],
          [deck.cards[2], deck.cards[3]],
        ],
      );

      expect(() => game.playRound('nope'), throwsArgumentError);
    });
  });

  group('ties', () {
    test('tied cards go into the pot and nobody scores', () {
      final deck = deckOf([
        card('a', power: 5, cost: 1),
        card('b', power: 5, cost: 2),
        card('c', power: 9, cost: 3),
        card('d', power: 1, cost: 4),
      ]);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[2]], // a, c
          [deck.cards[1], deck.cards[3]], // b, d
        ],
      );

      final result = game.playRound('power');

      expect(result.outcome, RoundOutcome.tie);
      expect(result.winnerIds, ['p1', 'p2']);
      expect(result.cardsAwarded, 0);
      expect(result.potSize, 2);
      expect(game.players.map((p) => p.cardCount), [1, 1]);
      expect(game.cardsInPlay, 4);
    });

    test('the next decisive round sweeps the pot as well', () {
      final deck = deckOf([
        card('a', power: 5, cost: 1),
        card('b', power: 5, cost: 2),
        card('c', power: 9, cost: 3),
        card('d', power: 1, cost: 4),
      ]);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[2]],
          [deck.cards[1], deck.cards[3]],
        ],
      );

      game.playRound('power');
      final result = game.playRound('power'); // c beats d

      expect(result.cardsAwarded, 4);
      expect(result.potSize, 0);
      expect(game.players[0].cardCount, 4);
    });

    test('a tie keeps the choice with a tied player who still has cards', () {
      final deck = deckOf([
        card('a', power: 5, cost: 1),
        card('b', power: 1, cost: 2),
        card('c', power: 5, cost: 3),
        card('d', power: 2, cost: 4),
        card('e', power: 2, cost: 5),
        card('f', power: 3, cost: 6),
        card('g', power: 9, cost: 7),
        card('h', power: 4, cost: 8),
      ]);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats4,
        chooserIndex: 1,
        hands: [
          [deck.cards[0], deck.cards[4]], // a(5), e
          [deck.cards[1], deck.cards[5]], // b(1), f
          [deck.cards[2], deck.cards[6]], // c(5), g
          [deck.cards[3], deck.cards[7]], // d(2), h
        ],
      );

      // p1 and p3 tie on power 5; p2 (the chooser) loses, so the choice moves
      // clockwise to the first tied player still holding cards.
      final result = game.playRound('power');

      expect(result.outcome, RoundOutcome.tie);
      expect(result.winnerIds, containsAll(['p1', 'p3']));
      expect(game.chooser.id, 'p3');
    });

    test('a tie that empties every hand deals the pot back out', () {
      final deck = deckOf([
        card('a', power: 5, cost: 1),
        card('b', power: 5, cost: 2),
        card('c', power: 5, cost: 3),
        card('d', power: 5, cost: 4),
      ]);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[2]],
          [deck.cards[1], deck.cards[3]],
        ],
        random: Random(3),
      );

      game.playRound('power'); // tie, pot of 2
      game.playRound('power'); // tie again, both hands now empty

      expect(game.isOver, isFalse);
      expect(game.cardsInPlay, 4);
      expect(game.players.map((p) => p.cardCount), [2, 2]);
      expect(game.pot, isEmpty);
    });
  });

  group('elimination and winning', () {
    test('a player who loses their last card is eliminated', () {
      final deck = numberedDeck(6);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats4,
        hands: [
          [deck.cards[5], deck.cards[0]], // c6, c1
          [deck.cards[1]], // c2 — last card
          [deck.cards[2], deck.cards[3]],
          [deck.cards[4]], // c5 — last card
        ],
      );

      final result = game.playRound('power'); // c6 wins

      expect(result.winnerIds, ['p1']);
      expect(result.eliminatedIds, containsAll(['p2', 'p4']));
      expect(game.activePlayers.map((p) => p.id), ['p1', 'p3']);
    });

    test('a player who wins on their last card stays in', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[3]], // c4 — last card, but it wins
          [deck.cards[0], deck.cards[1]],
        ],
      );

      final result = game.playRound('power');

      expect(result.eliminatedIds, isEmpty);
      expect(game.players[0].cardCount, 2);
      expect(game.isOver, isFalse);
    });

    test('the game ends when one player holds every card in play', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[3], deck.cards[2]], // c4, c3
          [deck.cards[0], deck.cards[1]], // c1, c2
        ],
        random: Random(11),
      );

      while (!game.isOver) {
        game.playRound('power');
      }

      expect(game.winner, isNotNull);
      expect(game.winner!.id, 'p1');
      expect(game.winner!.cardCount, 4);
      expect(game.endedByRoundLimit, isFalse);
    });

    test('playing on after the game is over is rejected', () {
      final deck = numberedDeck(4);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[3], deck.cards[2]],
          [deck.cards[0], deck.cards[1]],
        ],
        random: Random(11),
      );
      while (!game.isOver) {
        game.playRound('power');
      }

      expect(() => game.playRound('power'), throwsStateError);
    });

    test('the round limit ends the game and scores it on card count', () {
      final deck = deckOf([
        card('a', power: 5, cost: 1),
        card('b', power: 5, cost: 2),
        card('c', power: 5, cost: 3),
        card('d', power: 5, cost: 4),
      ]);
      final game = TrumpGame.withHands(
        deck: deck,
        seats: seats2,
        hands: [
          [deck.cards[0], deck.cards[2]],
          [deck.cards[1], deck.cards[3]],
        ],
        maxRounds: 2,
        random: Random(3),
      );

      game.playRound('power');
      game.playRound('power');

      expect(game.isOver, isTrue);
      expect(game.endedByRoundLimit, isTrue);
      expect(game.winner, isNull, reason: '2-2 on cards is a draw');
    });
  });

  group('full games', () {
    test('cards are never created or destroyed, and every game ends', () {
      for (var seed = 0; seed < 200; seed++) {
        final rng = Random(seed);
        final deck = variedDeck(52, seed: seed);
        final seats = seed.isEven ? seats2 : seats4;
        final game = TrumpGame.start(deck: deck, seats: seats, random: rng);
        final dealt = game.cardsInPlay;

        while (!game.isOver) {
          final stat = StatPicker.pick(deck, game.chooser.topCard, random: rng);
          game.playRound(stat);
          if (game.cardsInPlay != dealt) {
            fail('seed $seed: ${game.cardsInPlay} cards in play, expected $dealt');
          }
          if (!game.isOver && !game.chooser.isActive) {
            fail('seed $seed: an eliminated player was left holding the choice');
          }
        }

        expect(game.endedByRoundLimit, isFalse, reason: 'seed $seed stalled');
        expect(game.winner!.cardCount, dealt, reason: 'seed $seed');
      }
    });

    test('a capped match is scored on card count without eliminating anyone',
        () {
      final rng = Random(4);
      final deck = variedDeck(52, seed: 4);
      final game = TrumpGame.start(
        deck: deck,
        seats: seats2,
        random: rng,
        maxRounds: 20,
      );

      while (!game.isOver) {
        game.playRound(StatPicker.pick(deck, game.chooser.topCard, random: rng));
      }

      expect(game.roundNumber, 20);
      expect(game.endedByRoundLimit, isTrue);
      expect(game.cardsInPlay, 52);
      expect(game.winner!.cardCount, greaterThan(26));
    });

    test('play to elimination always terminates on its own', () {
      // Both stats move together here, so choosing "cost" is the exact inverse
      // of choosing "power" — the worst case for settling the game.
      for (var seed = 0; seed < 60; seed++) {
        final rng = Random(seed);
        final deck = numberedDeck(52);
        final seats = seed.isEven ? seats2 : seats4;
        final game = TrumpGame.start(deck: deck, seats: seats, random: rng);

        while (!game.isOver) {
          game.playRound(rng.nextBool() ? 'power' : 'cost');
        }

        expect(game.endedByRoundLimit, isFalse, reason: 'seed $seed stalled');
        expect(game.winner!.cardCount, 52);
      }
    });
  });
}
