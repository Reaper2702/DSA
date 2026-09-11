import 'dart:collection';

import 'trump_card.dart';

/// A seat at the table. The hand is a queue: cards are played off the front and
/// winnings are appended to the back.
class Player {
  Player({
    required this.id,
    required this.name,
    Iterable<TrumpCard> hand = const [],
    this.isHuman = false,
  }) : _hand = Queue<TrumpCard>.of(hand);

  final String id;
  final String name;
  final bool isHuman;
  final Queue<TrumpCard> _hand;

  int get cardCount => _hand.length;

  /// A player is out of the game the moment their hand empties.
  bool get isActive => _hand.isNotEmpty;

  TrumpCard get topCard => _hand.first;

  List<TrumpCard> get hand => UnmodifiableListView(_hand);

  TrumpCard draw() {
    if (_hand.isEmpty) {
      throw StateError('Player "$id" has no cards left to play.');
    }
    return _hand.removeFirst();
  }

  void receive(Iterable<TrumpCard> cards) => _hand.addAll(cards);

  @override
  String toString() => 'Player($id, $cardCount cards)';
}
