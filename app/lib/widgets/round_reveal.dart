import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../theme.dart';

/// The panel that shows what everybody played once a round resolves.
class RoundReveal extends StatelessWidget {
  const RoundReveal({
    super.key,
    required this.result,
    required this.humanId,
    required this.onContinue,
    required this.continueLabel,
  });

  final RoundResult result;
  final String humanId;
  final VoidCallback onContinue;
  final String continueLabel;

  String get _headline {
    if (result.isTie) {
      return 'Tie on ${result.stat.label} — ${result.potSize} cards carry over';
    }
    final winner = result.reveals.firstWhere((r) => r.isWinner);
    final takes = '${result.cardsAwarded} '
        '${result.cardsAwarded == 1 ? 'card' : 'cards'}';
    return winner.playerId == humanId
        ? 'You take $takes'
        : '${winner.playerName} takes $takes';
  }

  Color get _accent {
    if (result.isTie) return AppColors.tie;
    final winner = result.reveals.firstWhere((r) => r.isWinner);
    return winner.playerId == humanId ? AppColors.win : AppColors.lose;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.feltDeep,
        border: Border(top: BorderSide(color: _accent, width: 3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            result.stat.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _headline,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: _accent,
            ),
          ),
          const SizedBox(height: 10),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  for (final reveal in result.reveals)
                    _RevealRow(
                      reveal: reveal,
                      stat: result.stat,
                      isHuman: reveal.playerId == humanId,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(onPressed: onContinue, child: Text(continueLabel)),
        ],
      ),
    );
  }
}

class _RevealRow extends StatelessWidget {
  const _RevealRow({
    required this.reveal,
    required this.stat,
    required this.isHuman,
  });

  final RevealedCard reveal;
  final StatDefinition stat;
  final bool isHuman;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 18,
            child: reveal.isWinner
                ? const Icon(
                    Icons.emoji_events_rounded,
                    size: 16,
                    color: AppColors.gold,
                  )
                : null,
          ),
          Expanded(
            child: RichText(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              text: TextSpan(
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                children: [
                  TextSpan(
                    text: isHuman ? 'You' : reveal.playerName,
                    style: TextStyle(
                      fontWeight:
                          reveal.isWinner ? FontWeight.w700 : FontWeight.w500,
                      color: reveal.isWinner ? AppColors.gold : Colors.white,
                    ),
                  ),
                  TextSpan(
                    text: '  ${reveal.card.name}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            stat.format(reveal.value),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: reveal.isWinner ? AppColors.gold : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
