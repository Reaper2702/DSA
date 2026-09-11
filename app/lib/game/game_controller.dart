import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:trump_engine/trump_engine.dart';

import 'match_settings.dart';

enum GamePhase {
  /// Waiting for the human to name a stat.
  humanChoosing,

  /// A computer player is "thinking" before it names a stat.
  aiChoosing,

  /// The round is resolved and on screen, waiting to be dismissed.
  revealing,

  /// The match is over.
  finished,
}

/// Drives a [TrumpGame] for the UI: owns the phase machine and the delay that
/// makes a computer player look like it is thinking.
class GameController extends ChangeNotifier {
  GameController({
    required this.deck,
    required this.settings,
    Random? random,
    this.aiThinkingDelay = const Duration(milliseconds: 800),
  }) : _random = random ?? Random() {
    _deal();
  }

  static const humanId = 'you';
  static const _aiNames = ['Ravi', 'Mia', 'Kofi'];

  final DeckDefinition deck;
  final MatchSettings settings;
  final Duration aiThinkingDelay;
  final Random _random;

  late TrumpGame _game;
  GamePhase _phase = GamePhase.humanChoosing;
  RoundResult? _lastResult;
  Timer? _aiTimer;
  bool _disposed = false;

  TrumpGame get game => _game;

  GamePhase get phase => _phase;

  RoundResult? get lastResult => _lastResult;

  Player get human => _game.players.firstWhere((p) => p.id == humanId);

  List<Player> get opponents =>
      [for (final p in _game.players) if (p.id != humanId) p];

  bool get humanIsChoosing => _phase == GamePhase.humanChoosing;

  bool get humanWon => _game.winner?.id == humanId;

  bool get humanIsOut => !human.isActive;

  /// Standings for the end-of-match panel, best first.
  List<Player> get standings =>
      [..._game.players]..sort((a, b) => b.cardCount.compareTo(a.cardCount));

  /// The card the human is about to play, or null once they are out.
  TrumpCard? get humanTopCard => human.isActive ? human.topCard : null;

  void _deal() {
    final seats = <PlayerSeat>[
      const PlayerSeat(id: humanId, name: 'You', isHuman: true),
      for (var i = 0; i < settings.playerCount - 1; i++)
        PlayerSeat(id: 'ai_$i', name: _aiNames[i % _aiNames.length]),
    ];

    _game = TrumpGame.start(
      deck: deck,
      seats: seats,
      random: _random,
      maxRounds: settings.length.maxRounds,
    );
    _lastResult = null;
    _enterChoosingPhase();
  }

  void restart() {
    _aiTimer?.cancel();
    _deal();
    notifyListeners();
  }

  /// Called when the human taps a stat on their card.
  void chooseStat(String statKey) {
    if (_phase != GamePhase.humanChoosing) return;
    _playRound(statKey);
  }

  /// Dismisses the round result and moves the game on.
  void continueToNextRound() {
    if (_phase != GamePhase.revealing) return;
    if (_game.isOver) {
      _phase = GamePhase.finished;
      notifyListeners();
      return;
    }
    _enterChoosingPhase();
    notifyListeners();
  }

  void _enterChoosingPhase() {
    // Once the human is knocked out there is nothing left for them to watch,
    // so the match ends here rather than playing the computers out.
    if (_game.isOver || !human.isActive) {
      _phase = GamePhase.finished;
      return;
    }
    if (_game.chooser.isHuman) {
      _phase = GamePhase.humanChoosing;
      return;
    }
    _phase = GamePhase.aiChoosing;
    _scheduleAiChoice();
  }

  void _scheduleAiChoice() {
    _aiTimer?.cancel();
    _aiTimer = Timer(aiThinkingDelay, () {
      if (_disposed || _phase != GamePhase.aiChoosing) return;
      _playRound(
        StatPicker.pick(
          deck,
          _game.chooser.topCard,
          difficulty: settings.difficulty,
          random: _random,
        ),
      );
    });
  }

  void _playRound(String statKey) {
    _lastResult = _game.playRound(statKey);
    _phase = GamePhase.revealing;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _aiTimer?.cancel();
    super.dispose();
  }
}
