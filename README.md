# mnd_core

Core of the **Meander** text-quest engine — data models, contracts (ports),
script executor, runtime state, and persistence services.

Zero platform-specific dependencies. No path_provider, no Firebase,
no audio backends. Everything is plugged in through small ports so
the engine can be embedded in any Flutter app, on any platform.

## Features

- **Script executor** — interprets Meander's quest scripting language
- **Data models** — Quest, SavedNode, ContentItem, TemplateItem, SaveSlot, etc.
- **Contract ports** — AudioPort, SaveStore, ScriptAssetStore, ScriptExpressionEngine
- **Runtime state** — In-memory variable and table storage
- **Save game service** — abstract save/load with configurable backends
- **Script cache** — in-memory cache for script JSON with deduplication

## Usage

```dart
import 'package:mnd_core/mnd_core.dart';

// Configure the engine with your implementations
ScriptExecutor.configure(
  assetStore: myAssetStore,
  expressionEngine: myExpressionEngine,
);

// Execute scripts
ScriptExecutor.execute(someScript, myRuntimeState);
```

## License

GNU Affero General Public License v3.0
