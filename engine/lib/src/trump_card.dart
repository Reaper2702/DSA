/// A single playing card: a subject plus one numeric value per deck stat.
class TrumpCard {
  const TrumpCard({
    required this.id,
    required this.name,
    required this.stats,
    this.subtitle = '',
    this.imageAsset,
  });

  factory TrumpCard.fromJson(Map<String, dynamic> json) {
    final rawStats = json['stats'] as Map<String, dynamic>;
    return TrumpCard(
      id: json['id'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String? ?? '',
      imageAsset: json['image'] as String?,
      stats: {
        for (final entry in rawStats.entries) entry.key: entry.value as num,
      },
    );
  }

  final String id;
  final String name;
  final String subtitle;
  final String? imageAsset;
  final Map<String, num> stats;

  num valueOf(String statKey) {
    final value = stats[statKey];
    if (value == null) {
      throw ArgumentError('Card "$id" has no value for stat "$statKey".');
    }
    return value;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (subtitle.isNotEmpty) 'subtitle': subtitle,
        if (imageAsset != null) 'image': imageAsset,
        'stats': stats,
      };

  @override
  String toString() => 'TrumpCard($id)';
}
