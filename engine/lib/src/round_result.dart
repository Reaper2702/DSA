import 'stat.dart';
import 'trump_card.dart';

enum RoundOutcome {
  /// Exactly one player held the best value and swept the table.
  win,

  /// Two or more players tied on the best value; the cards carry over.
  tie,
}

/// One player's contribution to a round.
class RevealedCard {
  const RevealedCard({
    required this.playerId,
    required this.playerName,
    required this.card,
    required this.value,
    required this.isWinner,
  });

  final String playerId;
  final String playerName;
  final TrumpCard card;
  final num value;
  final bool isWinner;
}

/// An immutable record of what happened in a single round.
class RoundResult {
  const RoundResult({
    required this.roundNumber,
    required this.stat,
    required this.chooserId,
    required this.reveals,
    required this.outcome,
    required this.winnerIds,
    required this.cardsAwarded,
    required this.potSize,
    required this.eliminatedIds,
    required this.nextChooserId,
    this.gameWinnerId,
  });

  final int roundNumber;
  final StatDefinition stat;

  /// Who picked [stat] for this round.
  final String chooserId;

  /// Every card played this round, ordered best value first.
  final List<RevealedCard> reveals;

  final RoundOutcome outcome;

  /// One id on a win, two or more on a tie.
  final List<String> winnerIds;

  /// Cards moved into the winner's hand. Zero on a tie.
  final int cardsAwarded;

  /// Cards left sitting in the carry-over pot after this round.
  final int potSize;

  final List<String> eliminatedIds;
  final String? nextChooserId;

  /// Set on the round that ends the game.
  final String? gameWinnerId;

  bool get isTie => outcome == RoundOutcome.tie;
}
