import 'dart:math';

import 'deck_definition.dart';
import 'stat.dart';
import 'trump_card.dart';

enum AiDifficulty {
  /// Picks at random.
  easy,

  /// Usually picks its best stat, sometimes settles for the second best.
  normal,

  /// Always picks its strongest stat.
  hard,
}

/// Chooses which stat a computer player should call.
class StatPicker {
  const StatPicker._();

  /// Fraction of the rest of the deck that [card] beats on [stat], from 0 to 1.
  static double strength(
    DeckDefinition deck,
    TrumpCard card,
    StatDefinition stat,
  ) {
    if (deck.cards.length < 2) return 1;
    final value = card.valueOf(stat.key);
    var beaten = 0;
    for (final other in deck.cards) {
      if (identical(other, card)) continue;
      if (stat.beats(value, other.valueOf(stat.key))) beaten++;
    }
    return beaten / (deck.cards.length - 1);
  }

  static String pick(
    DeckDefinition deck,
    TrumpCard card, {
    AiDifficulty difficulty = AiDifficulty.normal,
    Random? random,
  }) {
    final rng = random ?? Random();
    if (difficulty == AiDifficulty.easy) {
      return deck.stats[rng.nextInt(deck.stats.length)].key;
    }

    final ranked = List<StatDefinition>.of(deck.stats)
      ..sort((a, b) =>
          strength(deck, card, b).compareTo(strength(deck, card, a)));

    if (difficulty == AiDifficulty.normal &&
        ranked.length > 1 &&
        rng.nextDouble() < 0.25) {
      return ranked[1].key;
    }
    return ranked.first.key;
  }
}
