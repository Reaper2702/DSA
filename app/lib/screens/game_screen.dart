import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../game/game_controller.dart';
import '../game/match_settings.dart';
import '../theme.dart';
import '../widgets/card_face.dart';
import '../widgets/opponent_strip.dart';
import '../widgets/round_reveal.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.deck, required this.settings});

  final DeckDefinition deck;
  final MatchSettings settings;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameController _controller = GameController(
    deck: widget.deck,
    settings: widget.settings,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// During a reveal the hand has already moved on, so show the card that was
  /// actually played rather than the next one up.
  TrumpCard? get _cardOnShow {
    final result = _controller.lastResult;
    final showingResult = _controller.phase == GamePhase.revealing ||
        _controller.phase == GamePhase.finished;
    if (showingResult && result != null) {
      for (final reveal in result.reveals) {
        if (reveal.playerId == GameController.humanId) return reveal.card;
      }
      return null;
    }
    return _controller.humanTopCard;
  }

  /// While a stat is being picked the round is yet to be counted, so show the
  /// one about to be played rather than the one just finished.
  int get _displayedRound {
    final played = _controller.game.roundNumber;
    return switch (_controller.phase) {
      GamePhase.humanChoosing || GamePhase.aiChoosing => played + 1,
      GamePhase.revealing || GamePhase.finished => played,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final game = _controller.game;
        final card = _cardOnShow;
        final result = _controller.lastResult;

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _TopBar(
                  roundNumber: _displayedRound,
                  maxRounds: widget.settings.length,
                  potSize: game.pot.length,
                  onQuit: () => Navigator.of(context).pop(),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: OpponentStrip(
                    opponents: _controller.opponents,
                    chooserId: game.chooser.id,
                    thinkingId: _controller.phase == GamePhase.aiChoosing
                        ? game.chooser.id
                        : null,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Center(
                      child: card == null
                          ? const _NoCardsLeft()
                          : AspectRatio(
                              aspectRatio: 0.72,
                              child: CardFace(
                                card: card,
                                deck: widget.deck,
                                interactive: _controller.humanIsChoosing,
                                onStatTap: _controller.chooseStat,
                                highlightedStat:
                                    _controller.phase == GamePhase.humanChoosing
                                        ? null
                                        : result?.stat.key,
                              ),
                            ),
                    ),
                  ),
                ),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.42,
                  ),
                  child: switch (_controller.phase) {
                    GamePhase.finished => _GameOverPanel(
                        controller: _controller,
                        settings: widget.settings,
                        onPlayAgain: _controller.restart,
                        onExit: () => Navigator.of(context).pop(),
                      ),
                    GamePhase.revealing => RoundReveal(
                        result: result!,
                        humanId: GameController.humanId,
                        continueLabel:
                            game.isOver || _controller.humanIsOut
                                ? 'See result'
                                : 'Next round',
                        onContinue: _controller.continueToNextRound,
                      ),
                    _ => _Prompt(controller: _controller),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.roundNumber,
    required this.maxRounds,
    required this.potSize,
    required this.onQuit,
  });

  final int roundNumber;
  final MatchLength maxRounds;
  final int potSize;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    final label = maxRounds.isCapped
        ? 'Round $roundNumber of ${maxRounds.maxRounds}'
        : 'Round $roundNumber';

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          IconButton(
            onPressed: onQuit,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Leave match',
          ),
          Expanded(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: potSize > 0
                ? Tooltip(
                    message: '$potSize cards in the pot from a tie',
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Icon(
                          Icons.layers_rounded,
                          size: 16,
                          color: AppColors.gold,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$potSize',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt({required this.controller});

  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final choosing = controller.humanIsChoosing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (choosing)
            const Text(
              'Your call — tap a stat',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.gold,
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${controller.game.chooser.name} is choosing…',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 6),
          Text(
            'You hold ${controller.human.cardCount} cards',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoCardsLeft extends StatelessWidget {
  const _NoCardsLeft();

  @override
  Widget build(BuildContext context) {
    return Text(
      'You are out of cards',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withValues(alpha: 0.7),
      ),
    );
  }
}

class _GameOverPanel extends StatelessWidget {
  const _GameOverPanel({
    required this.controller,
    required this.settings,
    required this.onPlayAgain,
    required this.onExit,
  });

  final GameController controller;
  final MatchSettings settings;
  final VoidCallback onPlayAgain;
  final VoidCallback onExit;

  String get _headline {
    if (controller.humanIsOut) return 'Knocked out';
    if (controller.humanWon) return 'You win';
    if (controller.game.winner == null) return 'Dead heat';
    return '${controller.game.winner!.name} wins';
  }

  String get _subhead {
    final game = controller.game;
    if (game.endedByRoundLimit) {
      return 'Match capped at ${settings.length.maxRounds} rounds — '
          'decided on cards held';
    }
    if (controller.humanIsOut) return 'You ran out of cards';
    return 'Held every card after ${game.roundNumber} rounds';
  }

  @override
  Widget build(BuildContext context) {
    final won = controller.humanWon;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.feltDeep,
        border: Border(
          top: BorderSide(
            color: won ? AppColors.win : AppColors.lose,
            width: 3,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            _headline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: won ? AppColors.win : AppColors.lose,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _subhead,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final player in controller.standings)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              player.isHuman ? 'You' : player.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: player.isHuman
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            '${player.cardCount}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.gold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onPlayAgain,
            child: const Text('Play again'),
          ),
          TextButton(
            onPressed: onExit,
            child: const Text('Change match'),
          ),
        ],
      ),
    );
  }
}
