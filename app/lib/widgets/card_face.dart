import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../theme.dart';

/// The large face-up card, with one tappable row per stat.
class CardFace extends StatelessWidget {
  const CardFace({
    super.key,
    required this.card,
    required this.deck,
    this.onStatTap,
    this.highlightedStat,
    this.interactive = false,
  });

  final TrumpCard card;
  final DeckDefinition deck;
  final ValueChanged<String>? onStatTap;
  final String? highlightedStat;

  /// When false the rows render but do not respond to taps.
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(card: card),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  children: [
                    for (final stat in deck.stats)
                      Expanded(
                        child: _StatRow(
                          stat: stat,
                          value: card.valueOf(stat.key),
                          highlighted: stat.key == highlightedStat,
                          onTap: interactive && onStatTap != null
                              ? () => onStatTap!(stat.key)
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.card});

  final TrumpCard card;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.felt, AppColors.feltDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            card.subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.gold.withValues(alpha: 0.9),
              fontSize: 12,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.stat,
    required this.value,
    required this.highlighted,
    this.onTap,
  });

  final StatDefinition stat;
  final num value;
  final bool highlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: highlighted
            ? AppColors.gold.withValues(alpha: 0.35)
            : AppColors.cardInk.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                Tooltip(
                  message: stat.higherIsBetter
                      ? 'Higher wins'
                      : 'Lower wins',
                  child: Icon(
                    stat.higherIsBetter
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    size: 14,
                    color: AppColors.cardInk.withValues(alpha: 0.45),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    stat.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.cardInk,
                      fontSize: 14,
                      fontWeight:
                          highlighted ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  stat.format(value),
                  style: const TextStyle(
                    color: AppColors.cardInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (enabled) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: AppColors.cardInk.withValues(alpha: 0.35),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A face-down card, used for opponents and for the pot.
class CardBack extends StatelessWidget {
  const CardBack({super.key, this.width = 34});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: width / 0.68,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
          width: 1.2,
        ),
        gradient: const LinearGradient(
          colors: [AppColors.felt, AppColors.feltDeep],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.style_rounded,
          size: width * 0.45,
          color: AppColors.gold.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
