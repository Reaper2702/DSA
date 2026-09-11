import 'dart:math';

import 'package:trump_engine/trump_engine.dart';

TrumpCard card(String id, {required num power, required num cost}) =>
    TrumpCard(id: id, name: id, stats: {'power': power, 'cost': cost});

DeckDefinition deckOf(List<TrumpCard> cards) => DeckDefinition(
      id: 'test',
      name: 'Test Deck',
      stats: const [
        StatDefinition(
            key: 'power', label: 'Power', direction: StatDirection.higherWins),
        StatDefinition(
            key: 'cost', label: 'Cost', direction: StatDirection.lowerWins),
      ],
      cards: cards,
    );

DeckDefinition numberedDeck(int count) =>
    deckOf([for (var i = 1; i <= count; i++) card('c$i', power: i, cost: i)]);

DeckDefinition variedDeck(int count, {int seed = 99}) {
  final rng = Random(seed);
  return deckOf([
    for (var i = 1; i <= count; i++)
      card('c$i', power: rng.nextInt(8) * 10, cost: rng.nextInt(6) + 1),
  ]);
}

const seats2 = [
  PlayerSeat(id: 'p1', name: 'P1'),
  PlayerSeat(id: 'p2', name: 'P2'),
];
const seats4 = [
  PlayerSeat(id: 'p1', name: 'P1'),
  PlayerSeat(id: 'p2', name: 'P2'),
  PlayerSeat(id: 'p3', name: 'P3'),
  PlayerSeat(id: 'p4', name: 'P4'),
];

void run(String label, DeckDefinition Function(int) deckFor,
    List<PlayerSeat> seats, bool smart) {
  const n = 400;
  final rounds = <int>[];
  for (var seed = 0; seed < n; seed++) {
    final rng = Random(seed);
    final deck = deckFor(seed);
    final game = TrumpGame.start(
        deck: deck, seats: seats, random: rng, maxRounds: 1000000);
    while (!game.isOver) {
      final stat = smart
          ? StatPicker.pick(deck, game.chooser.topCard, random: rng)
          : deck.stats[rng.nextInt(deck.stats.length)].key;
      game.playRound(stat);
    }
    rounds.add(game.roundNumber);
  }
  rounds.sort();
  int pct(int p) => rounds[min(rounds.length - 1, (rounds.length * p) ~/ 100)];
  print('$label  p50=${pct(50)} p90=${pct(90)} p99=${pct(99)} '
      'max=${rounds.last}');
}

void main() {
  run('varied   2p smart ', (s) => variedDeck(52, seed: s), seats2, true);
  run('varied   4p smart ', (s) => variedDeck(52, seed: s), seats4, true);
  run('varied   2p random', (s) => variedDeck(52, seed: s), seats2, false);
  run('varied   4p random', (s) => variedDeck(52, seed: s), seats4, false);
  run('numbered 2p smart ', (s) => numberedDeck(52), seats2, true);
  run('numbered 4p smart ', (s) => numberedDeck(52), seats4, true);
  run('numbered 2p random', (s) => numberedDeck(52), seats2, false);
  run('numbered 4p random', (s) => numberedDeck(52), seats4, false);
}
