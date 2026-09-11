import 'package:flutter/material.dart';

import 'data/deck_repository.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

void main() => runApp(const TrumpCardsApp());

class TrumpCardsApp extends StatelessWidget {
  const TrumpCardsApp({super.key, this.repository = const DeckRepository()});

  final DeckRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trump Cards',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      home: HomeScreen(repository: repository),
    );
  }
}
