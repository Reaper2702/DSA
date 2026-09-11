import 'stat.dart';
import 'trump_card.dart';

/// A themed set of cards plus the stats every one of those cards carries.
class DeckDefinition {
  const DeckDefinition({
    required this.id,
    required this.name,
    required this.stats,
    required this.cards,
    this.tagline = '',
  });

  factory DeckDefinition.fromJson(Map<String, dynamic> json) {
    return DeckDefinition(
      id: json['id'] as String,
      name: json['name'] as String,
      tagline: json['tagline'] as String? ?? '',
      stats: [
        for (final stat in json['stats'] as List<dynamic>)
          StatDefinition.fromJson(stat as Map<String, dynamic>),
      ],
      cards: [
        for (final card in json['cards'] as List<dynamic>)
          TrumpCard.fromJson(card as Map<String, dynamic>),
      ],
    );
  }

  final String id;
  final String name;
  final String tagline;
  final List<StatDefinition> stats;
  final List<TrumpCard> cards;

  StatDefinition statFor(String key) {
    for (final stat in stats) {
      if (stat.key == key) return stat;
    }
    throw ArgumentError('Deck "$id" has no stat "$key".');
  }

  /// Throws unless the deck is playable: every card must carry every stat, and
  /// card ids must be unique, or round comparison would be undefined.
  void validate() {
    if (stats.isEmpty) {
      throw StateError('Deck "$id" defines no stats.');
    }
    if (cards.length < 2) {
      throw StateError('Deck "$id" needs at least 2 cards.');
    }
    final seenIds = <String>{};
    for (final card in cards) {
      if (!seenIds.add(card.id)) {
        throw StateError('Deck "$id" has duplicate card id "${card.id}".');
      }
      for (final stat in stats) {
        if (!card.stats.containsKey(stat.key)) {
          throw StateError(
            'Card "${card.id}" in deck "$id" is missing stat "${stat.key}".',
          );
        }
      }
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (tagline.isNotEmpty) 'tagline': tagline,
        'stats': [for (final stat in stats) stat.toJson()],
        'cards': [for (final card in cards) card.toJson()],
      };
}
