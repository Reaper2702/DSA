/// Which end of the scale wins a round.
///
/// Runs are better when high; a bowling average is better when low.
enum StatDirection { higherWins, lowerWins }

/// One comparable attribute shared by every card in a deck.
class StatDefinition {
  const StatDefinition({
    required this.key,
    required this.label,
    required this.direction,
    this.unit = '',
    this.decimals = 0,
  });

  factory StatDefinition.fromJson(Map<String, dynamic> json) {
    final rawDirection = json['direction'] as String? ?? 'higher';
    return StatDefinition(
      key: json['key'] as String,
      label: json['label'] as String,
      direction: switch (rawDirection) {
        'higher' => StatDirection.higherWins,
        'lower' => StatDirection.lowerWins,
        _ => throw FormatException('Unknown stat direction "$rawDirection".'),
      },
      unit: json['unit'] as String? ?? '',
      decimals: json['decimals'] as int? ?? 0,
    );
  }

  final String key;
  final String label;
  final StatDirection direction;
  final String unit;
  final int decimals;

  bool get higherIsBetter => direction == StatDirection.higherWins;

  /// True when [a] would win a head-to-head against [b] on this stat.
  bool beats(num a, num b) => higherIsBetter ? a > b : a < b;

  String format(num value) {
    final text =
        decimals == 0 ? value.round().toString() : value.toStringAsFixed(decimals);
    return unit.isEmpty ? text : '$text$unit';
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'direction': higherIsBetter ? 'higher' : 'lower',
        if (unit.isNotEmpty) 'unit': unit,
        if (decimals != 0) 'decimals': decimals,
      };
}
