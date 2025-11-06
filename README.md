# Aidoku
A free and open source manga reading application for iOS and iPadOS.

## Features
- [x] No ads
- [x] Robust WASM source system
- [x] Online reading through external sources
- [x] Downloads
- [x] Tracker integration (AniList, MyAnimeList)

## Installation

For detailed installation instructions, check out [the website](https://aidoku.app).

### TestFlight

To join the TestFlight, you will need to join the [Aidoku Discord](https://discord.gg/kh2PYT8V8d).

### AltStore

We have an AltStore repo that contains the latest releases ipa. You can copy the [direct source URL](https://raw.githubusercontent.com/Aidoku/Aidoku/altstore/apps.json) and paste it into AltStore. Note that AltStore PAL is not supported.

### Manual Installation

The latest ipa file will always be available from the [releases page](https://github.com/Aidoku/Aidoku/releases).

## 📁 Project Structure

```
TomoScan/
├── iOS/                    # iOS-specific code
├── macOS/                  # macOS-specific code
├── Shared/                 # Shared code (Managers, Models, Extensions)
├── TomoScanTests/          # Unit tests (34 tests)
├── docs/                   # Documentation
│   ├── debugging/          # Debugging guides
│   ├── features/           # Feature specifications
│   ├── onboarding/         # Onboarding guides
│   └── tests/              # Test documentation
├── bdd/                    # SQL scripts for Supabase
└── scripts/                # Utility scripts
    ├── setup_tests.sh      # Configure tests
    ├── run_tests.sh        # Run automated checks
    └── add_error_manager.sh # Add ErrorManager to Xcode
```

## 🚀 Quick Start

### For Developers

```bash
# 1. Clone the repository
git clone https://github.com/amintt2/scanio.git
cd scanio

# 2. Open in Xcode
open Aidoku.xcodeproj

# 3. Configure tests (optional)
./scripts/setup_tests.sh

# 4. Build and run
# Press Cmd + R in Xcode
```

### Documentation

- **📚 Main Documentation**: [`docs/README.md`](docs/README.md)
- **🐛 Debugging Guide**: [`docs/debugging/`](docs/debugging/)
- **✨ Features**: [`docs/features/`](docs/features/)
- **🧪 Tests**: [`docs/tests/TESTS_SETUP_GUIDE.md`](docs/tests/TESTS_SETUP_GUIDE.md)
- **🗄️ Database**: [`bdd/README.md`](bdd/README.md)

## Contributing
Aidoku is still in a beta phase, and there are a lot of planned features and fixes. If you're interested in contributing, I'd first recommend checking with me on [Discord](https://discord.gg/kh2PYT8V8d) in the app development channel.

This repo (excluding translations) is licensed under [GPLv3](https://github.com/Aidoku/Aidoku/blob/main/LICENSE), but contributors must also sign the project [CLA](https://gist.github.com/Skittyblock/893952ff23f0df0e5cd02abbaddc2be9). Essentially, this just gives me (Skittyblock) the ability to distribute Aidoku via TestFlight/the App Store, but others must obtain an exception from me in order to do the same. Otherwise, GPLv3 applies and this code can be used freely as long as the modified source code is made available.

### Translations
Interested in translating Aidoku? We use [Weblate](https://hosted.weblate.org/engage/aidoku/) to crowdsource translations, so anyone can create an account and contribute!

Translations are licensed separately from the app code, under [Apache 2.0](https://spdx.org/licenses/Apache-2.0.html).
