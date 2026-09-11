// Generates the sample cricket deck asset.
//
// Run from the engine package:
//   dart run bin/generate_cricket_deck.dart > ../app/assets/decks/cricket.json
//
// The players are fictional. Real cricketers' names and likenesses are
// routinely licensed for commercial card games, so the deck that ships in the
// store is invented; swap this file's roster for a licensed one if you obtain
// the rights. Stats are drawn per role from an archetype so that every card
// wins on something, then checked for balance before being written out.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:trump_engine/trump_engine.dart';

enum Role { batter, keeper, allRounder, bowler, legendBatter, legendAllRounder, legendBowler }

class Roster {
  const Roster(this.name, this.country, this.role, this.description);

  final String name;
  final String country;
  final Role role;
  final String description;
}

const roster = <Roster>[
  // Specialist batters.
  Roster('Arjun Deshmukh', 'India', Role.batter, 'Top order batter'),
  Roster('Rohan Sekhri', 'India', Role.batter, 'Opening batter'),
  Roster('Tom Ashworth', 'England', Role.batter, 'Opening batter'),
  Roster('Callum Pryce', 'England', Role.batter, 'Middle order batter'),
  Roster('Jaden Whitlock', 'Australia', Role.batter, 'Top order batter'),
  Roster('Marcus Tindall', 'Australia', Role.batter, 'Middle order batter'),
  Roster('Dion Alleyne', 'West Indies', Role.batter, 'Opening batter'),
  Roster('Kyle Brathnall', 'West Indies', Role.batter, 'Middle order batter'),
  Roster('Pieter van Wyk', 'South Africa', Role.batter, 'Top order batter'),
  Roster('Ruan Bezuidenhout', 'South Africa', Role.batter, 'Middle order batter'),
  Roster('Imran Shafqat', 'Pakistan', Role.batter, 'Opening batter'),
  Roster('Hasan Zubairi', 'Pakistan', Role.batter, 'Middle order batter'),
  Roster('Nuwan Peiris', 'Sri Lanka', Role.batter, 'Top order batter'),
  Roster('Kane Marsters', 'New Zealand', Role.batter, 'Middle order batter'),

  // Wicketkeeper batters — the strike rate specialists.
  Roster('Ayaan Chaubey', 'India', Role.keeper, 'Wicketkeeper batter'),
  Roster('Sam Pettigrew', 'England', Role.keeper, 'Wicketkeeper batter'),
  Roster('Oscar Rieland', 'Australia', Role.keeper, 'Wicketkeeper batter'),
  Roster('Nico Havenga', 'South Africa', Role.keeper, 'Wicketkeeper batter'),
  Roster('Zohaib Qamar', 'Pakistan', Role.keeper, 'Wicketkeeper batter'),
  Roster('Reuben Vercoe', 'New Zealand', Role.keeper, 'Wicketkeeper batter'),

  // All-rounders.
  Roster('Karthik Ravindran', 'India', Role.allRounder, 'Batting all-rounder'),
  Roster('Yuvan Sathe', 'India', Role.allRounder, 'Bowling all-rounder'),
  Roster('Harry Stanbridge', 'England', Role.allRounder, 'Batting all-rounder'),
  Roster('Freddie Colclough', 'England', Role.allRounder, 'Bowling all-rounder'),
  Roster('Ryan Mulvaney', 'Australia', Role.allRounder, 'Batting all-rounder'),
  Roster('Toby Winslade', 'Australia', Role.allRounder, 'Bowling all-rounder'),
  Roster('Jermaine Catlyn', 'West Indies', Role.allRounder, 'Batting all-rounder'),
  Roster('Dwayne Fontenelle', 'West Indies', Role.allRounder, 'Bowling all-rounder'),
  Roster('Sipho Ndlovu', 'South Africa', Role.allRounder, 'Batting all-rounder'),
  Roster('Jacques Oosthuizen', 'South Africa', Role.allRounder, 'Bowling all-rounder'),
  Roster('Faraz Nadeem', 'Pakistan', Role.allRounder, 'Batting all-rounder'),
  Roster('Tim Halloway', 'New Zealand', Role.allRounder, 'Bowling all-rounder'),

  // Specialist bowlers.
  Roster('Ishaan Palekar', 'India', Role.bowler, 'Right-arm fast'),
  Roster('Devraj Kulkarni', 'India', Role.bowler, 'Left-arm orthodox'),
  Roster('Ollie Fairbrass', 'England', Role.bowler, 'Right-arm seam'),
  Roster('Nathan Corbyn', 'England', Role.bowler, 'Left-arm spin'),
  Roster('Beau Hargreave', 'Australia', Role.bowler, 'Right-arm fast'),
  Roster('Lachlan Ferriday', 'Australia', Role.bowler, 'Leg spin'),
  Roster('Andre Castell', 'West Indies', Role.bowler, 'Right-arm fast'),
  Roster('Shamar Linley', 'West Indies', Role.bowler, 'Left-arm fast'),
  Roster('Thabo Mkhwanazi', 'South Africa', Role.bowler, 'Right-arm fast'),
  Roster('Wynand Terblanche', 'South Africa', Role.bowler, 'Off spin'),
  Roster('Saeed Ghauri', 'Pakistan', Role.bowler, 'Right-arm fast'),
  Roster('Bilal Ahsan', 'Pakistan', Role.bowler, 'Left-arm fast'),
  Roster('Dilan Ratnasinghe', 'Sri Lanka', Role.bowler, 'Off spin'),
  Roster('Trent Blackmore', 'New Zealand', Role.bowler, 'Right-arm seam'),

  // Legends — strong, but each still has a soft stat.
  Roster('Sanjay Bhatnagar', 'India', Role.legendBatter, 'Legend • Batter'),
  Roster('Hendrik Gouws', 'South Africa', Role.legendBatter, 'Legend • Batter'),
  Roster('Gavin Thorncroft', 'England', Role.legendAllRounder, 'Legend • All-rounder'),
  Roster('Everton Maltby', 'West Indies', Role.legendAllRounder, 'Legend • All-rounder'),
  Roster('Warrick Delaine', 'Australia', Role.legendBowler, 'Legend • Fast bowler'),
  Roster('Asif Rahmani', 'Pakistan', Role.legendBowler, 'Legend • Fast bowler'),
];

/// Inclusive stat ranges per role: matches, runs, batting average, strike
/// rate, wickets, bowling average.
const ranges = <Role, Map<String, List<num>>>{
  Role.batter: {
    'matches': [95, 215],
    'runs': [3400, 9200],
    'batting_avg': [37.0, 52.5],
    'strike_rate': [76.0, 96.0],
    'wickets': [4, 38],
    'bowling_avg': [47.0, 72.0],
  },
  Role.keeper: {
    'matches': [80, 190],
    'runs': [2600, 7200],
    'batting_avg': [31.0, 44.0],
    'strike_rate': [97.0, 124.0],
    'wickets': [3, 12],
    'bowling_avg': [55.0, 78.0],
  },
  Role.allRounder: {
    'matches': [105, 235],
    'runs': [2100, 5400],
    'batting_avg': [25.0, 37.0],
    'strike_rate': [82.0, 104.0],
    'wickets': [95, 255],
    'bowling_avg': [28.0, 37.5],
  },
  Role.bowler: {
    'matches': [70, 185],
    'runs': [180, 1150],
    'batting_avg': [7.5, 19.5],
    'strike_rate': [58.0, 94.0],
    'wickets': [175, 415],
    'bowling_avg': [20.5, 28.5],
  },
  Role.legendBatter: {
    'matches': [230, 340],
    'runs': [10500, 14200],
    'batting_avg': [50.0, 58.5],
    'strike_rate': [85.0, 98.0],
    'wickets': [8, 45],
    'bowling_avg': [44.0, 68.0],
  },
  Role.legendAllRounder: {
    'matches': [225, 330],
    'runs': [6800, 9400],
    'batting_avg': [39.0, 47.0],
    'strike_rate': [92.0, 110.0],
    'wickets': [230, 330],
    'bowling_avg': [25.5, 30.5],
  },
  Role.legendBowler: {
    'matches': [200, 315],
    'runs': [600, 1900],
    'batting_avg': [10.0, 22.0],
    'strike_rate': [62.0, 90.0],
    'wickets': [420, 560],
    'bowling_avg': [19.5, 23.5],
  },
};

const statDefinitions = <StatDefinition>[
  StatDefinition(key: 'matches', label: 'Matches', direction: StatDirection.higherWins),
  StatDefinition(key: 'runs', label: 'Runs', direction: StatDirection.higherWins),
  StatDefinition(
      key: 'batting_avg',
      label: 'Batting Avg',
      direction: StatDirection.higherWins,
      decimals: 2),
  StatDefinition(
      key: 'strike_rate',
      label: 'Strike Rate',
      direction: StatDirection.higherWins,
      decimals: 2),
  StatDefinition(key: 'wickets', label: 'Wickets', direction: StatDirection.higherWins),
  StatDefinition(
      key: 'bowling_avg',
      label: 'Bowling Avg',
      direction: StatDirection.lowerWins,
      decimals: 2),
];

String slug(String name) => name
    .toLowerCase()
    .replaceAll(RegExp(r"[^a-z0-9]+"), '_')
    .replaceAll(RegExp(r'^_|_$'), '');

DeckDefinition buildDeck(int seed) {
  final rng = Random(seed);
  final cards = <TrumpCard>[];

  for (final entry in roster) {
    final range = ranges[entry.role]!;
    final stats = <String, num>{};
    for (final stat in statDefinitions) {
      final bounds = range[stat.key]!;
      final low = bounds[0];
      final high = bounds[1];
      final raw = low + rng.nextDouble() * (high - low);
      stats[stat.key] = stat.decimals == 0
          ? raw.round()
          : double.parse(raw.toStringAsFixed(stat.decimals));
    }
    cards.add(TrumpCard(
      id: slug(entry.name),
      name: entry.name,
      subtitle: '${entry.country} • ${entry.description}',
      stats: stats,
    ));
  }

  return DeckDefinition(
    id: 'cricket',
    name: 'Cricket All-Stars',
    tagline: 'Fifty-two fictional cricketers, one stat at a time.',
    stats: statDefinitions,
    cards: cards,
  );
}

/// A card is dead weight if it loses to the field on every stat. Every card
/// should be worth playing on something.
List<String> weakCards(DeckDefinition deck, {double floor = 0.55}) {
  final weak = <String>[];
  for (final card in deck.cards) {
    final best = deck.stats
        .map((stat) => StatPicker.strength(deck, card, stat))
        .reduce(max);
    if (best < floor) weak.add('${card.name} (best ${(best * 100).round()}%)');
  }
  return weak;
}

/// Cards that another card beats or matches on every single stat: playing them
/// is never the better choice, so they make the deck duller.
int dominatedCount(DeckDefinition deck) {
  var count = 0;
  for (final card in deck.cards) {
    for (final other in deck.cards) {
      if (identical(card, other)) continue;
      final dominates = deck.stats.every((stat) {
        final a = other.valueOf(stat.key);
        final b = card.valueOf(stat.key);
        return a == b || stat.beats(a, b);
      });
      if (dominates) {
        count++;
        break;
      }
    }
  }
  return count;
}

void main(List<String> args) {
  DeckDefinition? chosen;
  var bestScore = 1 << 30;
  var bestSeed = 0;
  for (var seed = 1; seed <= 2000; seed++) {
    final deck = buildDeck(seed);
    deck.validate();
    final score = weakCards(deck).length * 10 + dominatedCount(deck);
    if (score < bestScore) {
      bestScore = score;
      bestSeed = seed;
      chosen = deck;
      if (score == 0) break;
    }
  }

  chosen!;
  stderr.writeln('Seed $bestSeed: ${weakCards(chosen).length} weak cards, '
      '${dominatedCount(chosen)} dominated cards.');
  for (final weak in weakCards(chosen)) {
    stderr.writeln('  weak: $weak');
  }

  for (final stat in chosen.stats) {
    final values = chosen.cards.map((c) => c.valueOf(stat.key)).toList()..sort();
    final distinct = values.toSet().length;
    stderr.writeln('${stat.label.padRight(12)} '
        '${stat.format(values.first)} .. ${stat.format(values.last)}  '
        '($distinct distinct of ${values.length})');
  }

  stdout.write(const JsonEncoder.withIndent('  ').convert(chosen.toJson()));
  stdout.writeln();
}
