import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../theme.dart';

/// An opponent's card once it is turned over: what they played and what it
/// scored on the contested stat.
class PlayedCard extends StatelessWidget {
  const PlayedCard({
    super.key,
    required this.reveal,
    required this.stat,
    required this.width,
  });

  final RevealedCard reveal;
  final StatDefinition stat;
  final double width;

  @override
  Widget build(BuildContext context) {
    final won = reveal.isWinner;
    return Container(
      width: width,
      height: width / 0.72,
      decoration: BoxDecoration(
        color: AppColors.cardFace,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: won ? AppColors.gold : Colors.black.withValues(alpha: 0.25),
          width: won ? 2 : 1,
        ),
        boxShadow: [
          if (won)
            BoxShadow(
              color: AppColors.gold.withValues(alpha: 0.45),
              blurRadius: 14,
              spreadRadius: 1,
            )
          else
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Flexible(
            child: Center(
              child: Text(
                reveal.card.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 9,
                  height: 1.15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.cardInk,
                ),
              ),
            ),
          ),
          // Bounded height with scaleDown: a long value shrinks to fit, and a
          // short one is never blown up to fill the card.
          SizedBox(
            height: 28,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                stat.format(reveal.value),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: won ? AppColors.felt : AppColors.cardInk,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 14,
            child: won
                ? const Icon(
                    Icons.emoji_events_rounded,
                    size: 14,
                    color: AppColors.gold,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

/// Turns [back] over to reveal [front]. Restarts whenever [turn] changes, so
/// each round gets its own flip.
class CardFlip extends StatelessWidget {
  const CardFlip({
    super.key,
    required this.turn,
    required this.showFront,
    required this.front,
    required this.back,
    this.duration = const Duration(milliseconds: 420),
  });

  final int turn;
  final bool showFront;
  final Widget front;
  final Widget back;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      key: ValueKey(turn),
      tween: Tween(begin: 0, end: showFront ? 1 : 0),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        final flipped = t > 0.5;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0015)
            ..rotateY(t * math.pi),
          child: flipped
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: front,
                )
              : back,
        );
      },
    );
  }
}
