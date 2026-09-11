# Trump Cards

A Top Trumps style statistics card game for Android, built with Flutter.

Deal the deck out evenly, play off the top of your hand, and call the stat you
think wins. Best value takes every card played and calls the next one. Run out
of cards and you are out.

```
engine/   pure Dart rules engine — no Flutter dependency, tested on its own
app/      the Flutter app, plus the Android project for Play Store builds
```

## The rules as implemented

- The deck splits evenly: 26 each for two players, 13 each for four. A deck
  that does not divide evenly leaves the remainder out of play so that nobody
  starts a card up.
- A hand is a queue. You play off the front; cards you win go to the back.
- The player holding the choice names a stat. Each stat declares its own
  direction — runs are better high, a bowling average is better low.
- Everyone still holding cards turns over their top card. The best value takes
  every card played and names the next stat.
- A tie leaves those cards in a pot. Nobody scores, and the next round that
  produces a clear winner sweeps the pot up too. The choice passes to a tied
  player who still holds cards.
- Empty your hand and you are eliminated — but only if you lose the round;
  winning on your last card keeps you in.
- The game ends when one player holds every card in play.

## Match length

Playing to elimination is the pure form of the game, and it is long. Card
counts random-walk between zero and the whole deck, so a 26 v 26 game needs on
the order of 26² rounds to resolve — measured medians are 250 to 500 rounds for
a 52 card deck, whoever is choosing and however well they choose.

That is a lot of taps, so the menu offers capped matches (20 or 40 rounds,
scored on cards held) alongside the uncapped Knockout format. The engine
expresses this as `TrumpGame.maxRounds`; `kUnlimitedRounds` plays to
elimination.

Run `dart run bin/measure_game_length.dart` in `engine/` to see the
distribution for yourself.

## The deck

`app/assets/decks/cricket.json` holds 52 fictional cricketers with six stats
each. The players are invented on purpose: real cricketers' names and
likenesses are normally licensed for commercial card games, so shipping
invented ones keeps the store build clear of that. Swap the file for a licensed
roster if you obtain the rights — nothing in the engine cares.

`engine/bin/generate_cricket_deck.dart` regenerates it. The generator draws
stats per role archetype and searches seeds until every card beats most of the
field on at least one stat, so no card is dead weight. `cricket_deck_test.dart`
guards the shipped file.

To add a deck, drop another JSON file beside it and list it in
`DeckRepository.assetPaths`.

## Development

```bash
# rules engine — needs only the Dart SDK
cd engine && dart test

# app — needs Flutter
cd app && flutter test
cd app && flutter run
```

## Building for the Play Store

1. Generate an upload key. Keep the keystore somewhere safe and backed up: lose
   it and you cannot ship an update to the same listing.

   ```bash
   keytool -genkey -v -keystore ~/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `app/android/key.properties` — it is gitignored, and must stay that
   way:

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/absolute/path/to/upload-keystore.jks
   ```

   Without this file the release build falls back to the debug key so
   `flutter run --release` still works. The Play Console rejects debug-signed
   uploads, so the file has to exist for a real build.

3. Build the bundle:

   ```bash
   cd app && flutter build appbundle --release
   ```

   The result lands in `app/build/app/outputs/bundle/release/app-release.aab`.

4. Upload it in the Play Console. A developer account is a one-time $25 fee.

Bump `version:` in `app/pubspec.yaml` before every upload — the part after `+`
is the version code, and the Play Console rejects a code it has already seen.

### Still to do before a first release

- **Launcher icon and store graphics.** The app still ships Flutter's default
  icon. You need a 512×512 icon, a 1024×500 feature graphic, and screenshots.
- **Privacy policy.** Required by the Play Console. The app collects nothing
  and has no network access, which makes the policy short, but the listing
  still needs a URL.
- **Content rating and data safety form.** Both are questionnaires in the
  console.
