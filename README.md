# 雅思词卡 / IELTS Word Card

A small, native macOS desktop flashcard app for IELTS vocabulary practice. It is designed to open quickly, stay lightweight, and keep study progress locally on the Mac.

The app includes a 300-word starter deck across 10 IELTS-friendly themes. Each card has a Chinese meaning, collocation, example sentence, and macOS text-to-speech pronunciation.

## Features

- Spaced review with three ratings: **不认识**, **有点模糊**, and **记住了**
- Due cards are prioritised; new cards follow a daily target
- Local-only progress saved under `~/Library/Application Support/IELTSWordCard/`
- Searchable word library with theme filters
- Import custom UTF-8 TSV word lists
- Backup and restore for progress and custom words
- Optional always-on-top window
- No network requests, web view, background timer, or third-party runtime

## Requirements

- macOS 13 or newer
- Apple Silicon or Intel Mac
- Xcode Command Line Tools (`xcode-select --install`)
- Python 3.9 or newer (used to generate the bundled word JSON and build the app)

## Build and run

```bash
python3 app/build.py
open 'build/雅思词卡.app'
```

The build script:

1. Generates and validates the bundled word deck.
2. Compiles the Objective-C Cocoa app with Apple Clang.
3. Runs the built-in spaced-repetition and persistence self-tests.
4. Generates the app icon and signs the local app bundle with an ad-hoc signature.

The app bundle is emitted to `build/雅思词卡.app`. Build products are ignored by Git.

## Import format

The importer accepts UTF-8 `.tsv` or `.txt` files. Use one card per line with these columns:

```text
英文<TAB>中文释义<TAB>词性<TAB>搭配<TAB>例句<TAB>主题
```

Only the first two columns are required. Duplicate words are skipped.

## Keyboard shortcuts

- `Space` / `Return`: reveal the card
- `1`, `2`, `3`: rate the revealed card
- `S`: pronounce the word
- `⌘Z`: undo the latest rating
- `⌘F`: open the word library
- `⌘P`: toggle always-on-top

## Privacy and data

Study progress and imported words stay on the local Mac. The app does not send vocabulary, progress, or telemetry over the network. The included starter deck is an original, concise practice deck and is not an official IELTS word list.

## License

MIT. See [LICENSE](LICENSE).
