import 'package:mnd_core/models/quest_descriptor.dart';
import 'package:mnd_core/models/saved_node.dart';
import 'package:mnd_core/models/tag.dart';
import 'package:mnd_core/models/template_model.dart';

/// Абстрактный стор структурных данных квеста: ноды, конфиг, темплейты, теги.
///
/// Позволяет заменить формат хранения (JSON-файлы → SQLite → что угодно)
/// без изменений в коде потребителей. Реализации:
/// * [FilesystemNodeStore] — JSON-файлы через [ScriptAssetStore]
/// * [SqliteNodeStore] — SQLite (в будущем)
abstract class NodeStore {
  /// Конфиг квеста (config.json).
  Future<Map<String, dynamic>> getQuestConfig(String questId);

  /// Все ноды квеста.
  Future<List<SavedNode>> getAllNodes(String questId);

  /// Одна нода по id.
  Future<SavedNode?> getNode(String questId, String nodeId);

  /// Шаблоны (templates.json).
  Future<Map<String, TemplateItem>> getTemplates(String questId);

  /// Теги из конфига.
  Future<List<Tag>> getTags(String questId);

  /// Список идентификаторов всех квестов.
  Future<List<String>> listQuestIds();

  /// Дескриптор квеста (обёртка над конфигом).
  Future<Quest?> getQuestDescriptor(String questId);

  /// Обновить дескриптор (lastOpened и т.п.).
  Future<void> updateQuestDescriptor(
    String questId,
    Map<String, dynamic> fields,
  );

  /// Существует ли квест.
  Future<bool> questExists(String questId);

  /// Purge all in-memory caches for a specific quest.
  void invalidateQuest(String questId);

  /// Purge all in-memory caches.
  void invalidateAll();
}
