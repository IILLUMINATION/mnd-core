# mnd_core

Ядро игрового движка **Meander** — текстовые квесты с поддержкой скриптов,
переменных, таблиц, таймеров и аудио.

⚠️ **Лицензия: GNU AGPL v3.0** — запрещает использование в закрытом (проприетарном) коде.
Даже SaaS-решения обязаны открывать исходный код.

## Что внутри

- **ScriptExecutor** — исполняет скрипты квеста (условия, переходы, функции, переменные)
- **Модели данных** — Quest, SavedNode, ContentItem, TemplateItem, SaveSlot, Tag
- **Контракты (порты)** — AudioPort, SaveStore, ScriptAssetStore, ScriptExpressionEngine
- **Рантайм** — InMemoryScriptRuntimeState (переменные и таблицы в памяти)
- **Сервисы** — SaveGameService, ScriptCacheService

## Зависимости

Только `flutter`, `uuid`, `meta`, `collection`. Никаких платформенных зависимостей — можно встроить в любое Flutter-приложение.

## Архитектура

```
mnd_core (чистая логика)
   ↑
mnd_player_kit (Flutter-адаптеры)
   ↑
mnd_player (полноценный плеер с UI)
```

`mnd_core` — самый нижний слой. Он не знает про файловую систему, базы данных, аудио-движки.
Всё это подключается через контракты (порты), которые реализуются в `mnd_player_kit`.

## Быстрый старт

```dart
import 'package:mnd_core/mnd_core.dart';

// Настройка движка
ScriptExecutor.configure(
  expressionEngine: myExpressionEngine,
  assetStore: myAssetStore,
);

// Запуск скрипта
final result = await ScriptExecutor.execute(
  scriptData,
  runtimeState,
  questId: 'my_quest',
  eventType: EventType.onNodeEnter,
);
```

## Тесты

```bash
cd packages/mnd_core
flutter test  # 20 тестов
```

## Связанные репо

- [mnd_player_kit](https://github.com/IILLUMINATION/mnd-kit) — Flutter-адаптеры
- [mnd_player](https://github.com/IILLUMINATION/mnd-player) — полноценный плеер
- [mnd-standalone-builder](https://github.com/IILLUMINATION/mnd-standalone-builder) — билдер standalone-приложений
