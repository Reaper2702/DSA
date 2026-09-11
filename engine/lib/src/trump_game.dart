import 'dart:collection';
import 'dart:math';

import 'deck_definition.dart';
import 'player.dart';
import 'round_result.dart';
import 'trump_card.dart';

enum GameStatus { playing, finished }

/// Effectively no round cap: a safety net against a pathological deck rather
/// than a match length.
///
/// Playing to elimination is long by nature. Card counts random-walk between
/// zero and the full deck, so a 26 v 26 game averages on the order of 26 x 26
/// rounds; measured medians are 250-500 rounds for a 52 card deck. Set
/// [TrumpGame.maxRounds] to something small to play a fixed-length match
/// instead, which is scored on card count.
const int kUnlimitedRounds = 1 << 30;

class PlayerSeat {
  const PlayerSeat({required this.id, required this.name, this.isHuman = false});

  final String id;
  final String name;
  final bool isHuman;
}

/// The rules engine.
///
/// Each round the chooser names a stat, every player still holding cards turns
/// over their top card, and the best value takes the lot. Won cards go to the
/// back of the winner's hand and the winner chooses next. A tie leaves the
/// cards in a pot that the next decisive round sweeps up as well. Play ends
/// when one player holds every card in play.
class TrumpGame {
  TrumpGame._({
    required this.deck,
    required List<Player> players,
    required Random random,
    required this.maxRounds,
  })  : _players = players,
        _random = random;

  factory TrumpGame.start({
    required DeckDefinition deck,
    required List<PlayerSeat> seats,
    Random? random,
    int maxRounds = kUnlimitedRounds,
  }) {
    if (seats.length < 2) {
      throw ArgumentError('A game needs at least 2 players.');
    }
    if (seats.map((seat) => seat.id).toSet().length != seats.length) {
      throw ArgumentError('Player ids must be unique.');
    }
    deck.validate();

    final rng = random ?? Random();
    final shuffled = List<TrumpCard>.of(deck.cards)..shuffle(rng);

    // Deal equal hands. Any remainder (3 players into 52 cards) sits out the
    // game so that nobody starts a card up.
    final perPlayer = shuffled.length ~/ seats.length;
    if (perPlayer == 0) {
      throw ArgumentError(
        'Deck "${deck.id}" has too few cards for ${seats.length} players.',
      );
    }

    final players = [
      for (var i = 0; i < seats.length; i++)
        Player(
          id: seats[i].id,
          name: seats[i].name,
          isHuman: seats[i].isHuman,
          hand: shuffled.sublist(i * perPlayer, (i + 1) * perPlayer),
        ),
    ];

    return TrumpGame._(
      deck: deck,
      players: players,
      random: rng,
      maxRounds: maxRounds,
    );
  }

  /// Builds a game from explicit hands instead of dealing, for resuming a saved
  /// game and for tests that need a known board.
  factory TrumpGame.withHands({
    required DeckDefinition deck,
    required List<PlayerSeat> seats,
    required List<List<TrumpCard>> hands,
    int chooserIndex = 0,
    List<TrumpCard> pot = const [],
    int roundNumber = 0,
    Random? random,
    int maxRounds = kUnlimitedRounds,
  }) {
    if (seats.length != hands.length) {
      throw ArgumentError('Expected one hand per seat.');
    }
    final players = [
      for (var i = 0; i < seats.length; i++)
        Player(
          id: seats[i].id,
          name: seats[i].name,
          isHuman: seats[i].isHuman,
          hand: hands[i],
        ),
    ];
    final game = TrumpGame._(
      deck: deck,
      players: players,
      random: random ?? Random(),
      maxRounds: maxRounds,
    );
    game._chooserIndex = chooserIndex;
    game._roundNumber = roundNumber;
    game._pot.addAll(pot);
    for (final player in players) {
      if (!player.isActive) game._eliminatedIds.add(player.id);
    }
    return game;
  }

  final DeckDefinition deck;

  /// Round cap. At [kUnlimitedRounds] the game runs to elimination; a small
  /// value turns the game into a fixed-length match scored on card count.
  final int maxRounds;

  final List<Player> _players;
  final Random _random;
  final List<TrumpCard> _pot = [];
  final Set<String> _eliminatedIds = {};

  int _chooserIndex = 0;
  int _roundNumber = 0;
  GameStatus _status = GameStatus.playing;
  String? _winnerId;
  bool _endedByRoundLimit = false;

  List<Player> get players => UnmodifiableListView(_players);

  List<Player> get activePlayers =>
      [for (final player in _players) if (player.isActive) player];

  Player get chooser => _players[_chooserIndex];

  int get chooserIndex => _chooserIndex;

  /// Cards stranded by tied rounds, waiting for the next decisive round.
  List<TrumpCard> get pot => UnmodifiableListView(_pot);

  int get roundNumber => _roundNumber;

  GameStatus get status => _status;

  bool get isOver => _status == GameStatus.finished;

  /// Null while the game runs, and also on the rare drawn game where the round
  /// limit is reached with two players holding identical card counts.
  Player? get winner {
    final id = _winnerId;
    return id == null ? null : _playerById(id);
  }

  /// True when the game was decided by [maxRounds] rather than by one player
  /// sweeping the table. The leader on card count takes the win.
  bool get endedByRoundLimit => _endedByRoundLimit;

  int get cardsInPlay =>
      _pot.length +
      _players.fold(0, (total, player) => total + player.cardCount);

  Player _playerById(String id) =>
      _players.firstWhere((player) => player.id == id);

  RoundResult playRound(String statKey) {
    if (isOver) {
      throw StateError('The game has already finished.');
    }
    final stat = deck.statFor(statKey);
    final contenders = activePlayers;
    if (contenders.length < 2) {
      throw StateError('A round needs at least 2 players holding cards.');
    }

    _roundNumber++;
    final chooserId = chooser.id;

    final pile = <TrumpCard>[..._pot];
    final played = <String, TrumpCard>{};
    final values = <String, num>{};
    for (final player in contenders) {
      final card = player.draw();
      pile.add(card);
      played[player.id] = card;
      values[player.id] = card.valueOf(statKey);
    }

    var best = values[contenders.first.id]!;
    for (final value in values.values) {
      if (stat.beats(value, best)) best = value;
    }
    final winnerIds = [
      for (final player in contenders)
        if (_sameValue(values[player.id]!, best)) player.id,
    ];

    _pot.clear();
    var cardsAwarded = 0;
    final RoundOutcome outcome;
    if (winnerIds.length == 1) {
      outcome = RoundOutcome.win;
      final winner = _playerById(winnerIds.single);
      winner.receive(_orderPile(pile, played[winner.id]!));
      cardsAwarded = pile.length;
      _chooserIndex = _players.indexOf(winner);
    } else {
      outcome = RoundOutcome.tie;
      _pot.addAll(pile);
      _chooserIndex = _chooserAfterTie(winnerIds);
    }

    _rescueStrandedPot(winnerIds);

    final eliminatedIds = [
      for (final player in _players)
        if (!player.isActive && _eliminatedIds.add(player.id)) player.id,
    ];

    String? gameWinnerId;
    final remaining = activePlayers;
    if (remaining.length == 1) {
      remaining.single.receive(_pot);
      _pot.clear();
      _status = GameStatus.finished;
      gameWinnerId = _winnerId = remaining.single.id;
    } else if (_roundNumber >= maxRounds) {
      _status = GameStatus.finished;
      _endedByRoundLimit = true;
      gameWinnerId = _winnerId = _leaderOnCardCount();
    } else if (!chooser.isActive) {
      _chooserIndex = _nextActiveFrom(_chooserIndex);
    }

    final reveals = [
      for (final player in contenders)
        RevealedCard(
          playerId: player.id,
          playerName: player.name,
          card: played[player.id]!,
          value: values[player.id]!,
          isWinner: winnerIds.contains(player.id),
        ),
    ]..sort((a, b) => stat.beats(a.value, b.value)
        ? -1
        : stat.beats(b.value, a.value)
            ? 1
            : 0);

    return RoundResult(
      roundNumber: _roundNumber,
      stat: stat,
      chooserId: chooserId,
      reveals: List.unmodifiable(reveals),
      outcome: outcome,
      winnerIds: List.unmodifiable(winnerIds),
      cardsAwarded: cardsAwarded,
      potSize: _pot.length,
      eliminatedIds: List.unmodifiable(eliminatedIds),
      nextChooserId: isOver ? null : chooser.id,
      gameWinnerId: gameWinnerId,
    );
  }

  /// The winner's own card returns first so it is the last thing they replay;
  /// the rest are shuffled so two-player games cannot settle into a loop that
  /// deals the same pair back to each other forever.
  List<TrumpCard> _orderPile(List<TrumpCard> pile, TrumpCard winningCard) {
    final rest = List<TrumpCard>.of(pile)..remove(winningCard);
    rest.shuffle(_random);
    return [winningCard, ...rest];
  }

  /// After a tie the next chooser is a tied player who still holds cards,
  /// scanning clockwise from the current chooser.
  int _chooserAfterTie(List<String> winnerIds) {
    for (var offset = 0; offset < _players.length; offset++) {
      final index = (_chooserIndex + offset) % _players.length;
      final player = _players[index];
      if (player.isActive && winnerIds.contains(player.id)) return index;
    }
    return _nextActiveFrom(_chooserIndex);
  }

  int _nextActiveFrom(int index) {
    for (var offset = 1; offset <= _players.length; offset++) {
      final candidate = (index + offset) % _players.length;
      if (_players[candidate].isActive) return candidate;
    }
    return index;
  }

  /// If a tie drains every hand at once the pot has no one left to claim it, so
  /// deal it back out among the tied players and keep the game alive.
  void _rescueStrandedPot(List<String> winnerIds) {
    if (_pot.isEmpty || activePlayers.isNotEmpty) return;

    final claimants = [for (final id in winnerIds) _playerById(id)];
    final pool = List<TrumpCard>.of(_pot)..shuffle(_random);
    _pot.clear();
    for (var i = 0; i < pool.length; i++) {
      claimants[i % claimants.length].receive([pool[i]]);
    }
    _chooserIndex = _players.indexOf(claimants.first);
  }

  /// Null when the top two are level, which scores the game as a draw.
  String? _leaderOnCardCount() {
    final ranked = List<Player>.of(_players)
      ..sort((a, b) => b.cardCount.compareTo(a.cardCount));
    if (ranked.length > 1 && ranked[0].cardCount == ranked[1].cardCount) {
      return null;
    }
    return ranked.first.id;
  }

  static bool _sameValue(num a, num b) => (a - b).abs() < 1e-9;
}
