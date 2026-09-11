import 'package:flutter/material.dart';
import 'package:trump_engine/trump_engine.dart';

import '../data/deck_repository.dart';
import '../game/match_settings.dart';
import '../theme.dart';
import 'game_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.repository = const DeckRepository()});

  final DeckRepository repository;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<DeckDefinition>> _decks;
  MatchSettings _settings = const MatchSettings();

  @override
  void initState() {
    super.initState();
    _decks = widget.repository.loadAll();
  }

  void _play(DeckDefinition deck) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameScreen(deck: deck, settings: _settings),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<DeckDefinition>>(
        future: _decks,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ErrorState(error: snapshot.error!);
          }
          final decks = snapshot.data;
          if (decks == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _Menu(
            deck: decks.first,
            settings: _settings,
            onSettingsChanged: (value) => setState(() => _settings = value),
            onPlay: () => _play(decks.first),
          );
        },
      ),
    );
  }
}

class _Menu extends StatelessWidget {
  const _Menu({
    required this.deck,
    required this.settings,
    required this.onSettingsChanged,
    required this.onPlay,
  });

  final DeckDefinition deck;
  final MatchSettings settings;
  final ValueChanged<MatchSettings> onSettingsChanged;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
        children: [
          const Text(
            'TRUMP CARDS',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
              color: AppColors.gold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            deck.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 32),
          _Section(
            title: 'Players',
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2 · 26 each')),
                ButtonSegment(value: 4, label: Text('4 · 13 each')),
              ],
              selected: {settings.playerCount},
              onSelectionChanged: (value) => onSettingsChanged(
                settings.copyWith(playerCount: value.first),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _Section(
            title: 'Match length',
            child: RadioGroup<MatchLength>(
              groupValue: settings.length,
              onChanged: (value) =>
                  onSettingsChanged(settings.copyWith(length: value)),
              child: Column(
                children: [
                  for (final length in MatchLength.values)
                    RadioListTile<MatchLength>(
                      value: length,
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      activeColor: AppColors.gold,
                      title: Text(
                        length.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        length.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          _Section(
            title: 'Opponents',
            child: SegmentedButton<AiDifficulty>(
              segments: [
                for (final difficulty in AiDifficulty.values)
                  ButtonSegment(
                    value: difficulty,
                    label: Text(difficulty.label),
                  ),
              ],
              selected: {settings.difficulty},
              onSelectionChanged: (value) => onSettingsChanged(
                settings.copyWith(difficulty: value.first),
              ),
            ),
          ),
          const SizedBox(height: 28),
          FilledButton(onPressed: onPlay, child: const Text('Deal')),
          const SizedBox(height: 16),
          const _HowToPlay(),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _HowToPlay extends StatelessWidget {
  const _HowToPlay();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: const Text('How to play', style: TextStyle(fontSize: 14)),
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      children: [
        for (final line in const [
          'The deck is split evenly and everyone plays off the top of their hand.',
          'Whoever holds the round names a stat. An arrow shows whether high '
              'or low wins it.',
          'Everyone turns over their top card. The best value takes every card '
              'played and names the next stat.',
          'A tie leaves the cards in a pot — the next clear winner sweeps those '
              'up too.',
          'Run out of cards and you are out.',
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  ', style: TextStyle(color: AppColors.gold)),
                Expanded(
                  child: Text(
                    line,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: Colors.white.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Could not load the deck.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.lose),
        ),
      ),
    );
  }
}
