import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../theme.dart';
import 'card_face.dart';
import 'played_card.dart';

/// The other players' hands across the top of the table. Face down while a
/// stat is being chosen, turned over once the round resolves.
class OpponentStrip extends StatelessWidget {
  const OpponentStrip({
    super.key,
    required this.opponents,
    required this.chooserId,
    required this.thinkingId,
    required this.turn,
    this.reveals = const {},
    this.stat,
  });

  final List<Player> opponents;
  final String chooserId;

  /// Set while a computer player is picking a stat.
  final String? thinkingId;

  /// Round number — changing it restarts the flip.
  final int turn;

  /// What each opponent played, keyed by player id. Empty until the round
  /// resolves.
  final Map<String, RevealedCard> reveals;

  final StatDefinition? stat;

  @override
  Widget build(BuildContext context) {
    final cardWidth = opponents.length > 1 ? 76.0 : 92.0;
    return SizedBox(
      height: cardWidth / 0.72 + 42,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final opponent in opponents)
            Flexible(
              child: _OpponentTile(
                opponent: opponent,
                isChooser: opponent.id == chooserId,
                isThinking: opponent.id == thinkingId,
                reveal: reveals[opponent.id],
                stat: stat,
                turn: turn,
                cardWidth: cardWidth,
              ),
            ),
        ],
      ),
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile({
    required this.opponent,
    required this.isChooser,
    required this.isThinking,
    required this.reveal,
    required this.stat,
    required this.turn,
    required this.cardWidth,
  });

  final Player opponent;
  final bool isChooser;
  final bool isThinking;
  final RevealedCard? reveal;
  final StatDefinition? stat;
  final int turn;
  final double cardWidth;

  @override
  Widget build(BuildContext context) {
    final out = !opponent.isActive && reveal == null;
    final revealed = reveal;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Opacity(
        opacity: out ? 0.4 : 1,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: cardWidth / 0.72,
              child: Center(
                child: out
                    ? Icon(
                        Icons.do_not_disturb_alt_rounded,
                        color: Colors.white.withValues(alpha: 0.5),
                      )
                    : CardFlip(
                        turn: turn,
                        showFront: revealed != null && stat != null,
                        back: CardBack(width: cardWidth * 0.62),
                        front: revealed == null || stat == null
                            ? const SizedBox.shrink()
                            : PlayedCard(
                                reveal: revealed,
                                stat: stat!,
                                width: cardWidth,
                              ),
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              opponent.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isChooser ? FontWeight.w700 : FontWeight.w500,
                color: isChooser ? AppColors.gold : Colors.white,
              ),
            ),
            Text(
              isThinking
                  ? 'choosing…'
                  : out
                      ? 'out'
                      : '${opponent.cardCount} cards',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
