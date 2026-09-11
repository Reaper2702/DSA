import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../theme.dart';
import 'card_face.dart';

/// Face-down hands of the other players, with live card counts.
class OpponentStrip extends StatelessWidget {
  const OpponentStrip({
    super.key,
    required this.opponents,
    required this.chooserId,
    required this.thinkingId,
  });

  final List<Player> opponents;
  final String chooserId;

  /// Set while a computer player is picking a stat.
  final String? thinkingId;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final opponent in opponents)
          Flexible(
            child: _OpponentTile(
              opponent: opponent,
              isChooser: opponent.id == chooserId,
              isThinking: opponent.id == thinkingId,
            ),
          ),
      ],
    );
  }
}

class _OpponentTile extends StatelessWidget {
  const _OpponentTile({
    required this.opponent,
    required this.isChooser,
    required this.isThinking,
  });

  final Player opponent;
  final bool isChooser;
  final bool isThinking;

  @override
  Widget build(BuildContext context) {
    final out = !opponent.isActive;
    return Opacity(
      opacity: out ? 0.4 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 46,
              child: out
                  ? Icon(
                      Icons.do_not_disturb_alt_rounded,
                      color: Colors.white.withValues(alpha: 0.5),
                    )
                  : const CardBack(width: 30),
            ),
            const SizedBox(height: 6),
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
