import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:trump_engine/trump_engine.dart';

/// Guards the deck asset the app actually ships. Regenerate it with
/// `dart run bin/generate_cricket_deck.dart > ../app/assets/decks/cricket.json`.
void main() {
  final file = File('../app/assets/decks/cricket.json');
  late DeckDefinition deck;

  setUpAll(() {
    deck = DeckDefinition.fromJson(
      jsonDecode(file.readAsStringSync()) as Map<String, dynamic>,
    );
  });

  test('the asset exists', () {
    expect(file.existsSync(), isTrue, reason: '${file.path} is missing');
  });

  test('it is a playable 52 card deck', () {
    deck.validate();
    expect(deck.cards, hasLength(52));
    expect(deck.stats, hasLength(6));
  });

  test('it deals evenly to two and to four players', () {
    expect(deck.cards.length % 2, 0);
    expect(deck.cards.length % 4, 0);
  });

  test('it has a stat in each direction', () {
    expect(deck.stats.any((s) => s.higherIsBetter), isTrue);
    expect(deck.stats.any((s) => !s.higherIsBetter), isTrue);
  });

  test('every card is worth playing on at least one stat', () {
    for (final card in deck.cards) {
      final best = deck.stats
          .map((stat) => StatPicker.strength(deck, card, stat))
          .reduce((a, b) => a > b ? a : b);
      expect(
        best,
        greaterThanOrEqualTo(0.5),
        reason: '${card.name} loses to most of the deck on every stat',
      );
    }
  });

  test('every stat is somebody\'s best stat', () {
    final bestStatKeys = <String>{};
    for (final card in deck.cards) {
      var bestKey = deck.stats.first.key;
      var bestValue = -1.0;
      for (final stat in deck.stats) {
        final strength = StatPicker.strength(deck, card, stat);
        if (strength > bestValue) {
          bestValue = strength;
          bestKey = stat.key;
        }
      }
      bestStatKeys.add(bestKey);
    }
    expect(bestStatKeys, hasLength(deck.stats.length));
  });
}
