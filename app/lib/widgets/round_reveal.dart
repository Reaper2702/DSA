import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../theme.dart';

/// The verdict bar under the table. The cards themselves are shown on the
/// table, so this only has to say who took them.
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
    if (result.isTie) return 'Tied — nobody takes the cards';
    final winner = result.reveals.firstWhere((r) => r.isWinner);
    final takes = '${result.cardsAwarded} '
        '${result.cardsAwarded == 1 ? 'card' : 'cards'}';
    return winner.playerId == humanId
        ? 'You take $takes'
        : '${winner.playerName} takes $takes';
  }

  String? get _footnote {
    if (result.potSize > 0) {
      return '${result.potSize} cards wait in the pot for the next winner';
    }
    if (result.eliminatedIds.isEmpty) return null;
    return result.eliminatedIds.contains(humanId)
        ? 'You are out of cards'
        : 'Knocked out: ${result.eliminatedIds.length} player'
            '${result.eliminatedIds.length == 1 ? '' : 's'}';
  }

  Color get _accent {
    if (result.isTie) return AppColors.tie;
    final winner = result.reveals.firstWhere((r) => r.isWinner);
    return winner.playerId == humanId ? AppColors.win : AppColors.lose;
  }

  @override
  Widget build(BuildContext context) {
    final footnote = _footnote;
    return TweenAnimationBuilder<double>(
      key: ValueKey(result.roundNumber),
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, (1 - t) * 28), child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
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
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w700,
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              _headline,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: _accent,
              ),
            ),
            if (footnote != null) ...[
              const SizedBox(height: 3),
              Text(
                footnote,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
            ],
            const SizedBox(height: 12),
            FilledButton(onPressed: onContinue, child: Text(continueLabel)),
          ],
        ),
      ),
    );
  }
}
