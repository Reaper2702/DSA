import 'package:trump_engine/trump_engine.dart';

/// How long a match runs.
///
/// Playing to elimination is the pure form of the game but it is long: card
/// counts random-walk between zero and the full deck, which puts a 26 v 26
/// game in the hundreds of rounds. The capped formats are scored on card
/// count when the last round ends.
enum MatchLength {
  quick('Quick', '20 rounds — most cards wins', 20),
  standard('Standard', '40 rounds — most cards wins', 40),
  knockout('Knockout', 'Play on until someone holds all 52', kUnlimitedRounds);

  const MatchLength(this.label, this.description, this.maxRounds);

  final String label;
  final String description;
  final int maxRounds;

  bool get isCapped => maxRounds != kUnlimitedRounds;
}

class MatchSettings {
  const MatchSettings({
    this.playerCount = 2,
    this.length = MatchLength.quick,
    this.difficulty = AiDifficulty.normal,
  });

  final int playerCount;
  final MatchLength length;
  final AiDifficulty difficulty;

  MatchSettings copyWith({
    int? playerCount,
    MatchLength? length,
    AiDifficulty? difficulty,
  }) {
    return MatchSettings(
      playerCount: playerCount ?? this.playerCount,
      length: length ?? this.length,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

extension AiDifficultyLabel on AiDifficulty {
  String get label => switch (this) {
        AiDifficulty.easy => 'Casual',
        AiDifficulty.normal => 'Club',
        AiDifficulty.hard => 'Pro',
      };
}
