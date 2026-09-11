import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;
import 'package:trump_engine/trump_engine.dart';

/// Loads the bundled deck assets. Add a path here to ship another theme.
class DeckRepository {
  const DeckRepository({AssetBundle? bundle}) : _bundle = bundle;

  static const assetPaths = ['assets/decks/cricket.json'];

  final AssetBundle? _bundle;

  AssetBundle get _assets => _bundle ?? rootBundle;

  Future<List<DeckDefinition>> loadAll() async {
    final decks = <DeckDefinition>[];
    for (final path in assetPaths) {
      final raw = await _assets.loadString(path);
      final deck = DeckDefinition.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
      deck.validate();
      decks.add(deck);
    }
    return decks;
  }
}
