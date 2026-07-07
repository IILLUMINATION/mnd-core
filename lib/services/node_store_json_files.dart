import 'package:mnd_core/contracts/node_store.dart';
import 'package:mnd_core/contracts/script_asset_store.dart';
import 'package:mnd_core/models/quest_descriptor.dart';
import 'package:mnd_core/models/saved_node.dart';
import 'package:mnd_core/models/tag.dart';
import 'package:mnd_core/models/template_model.dart';

/// JSON-файловая имплементация [NodeStore] поверх [ScriptAssetStore].
///
/// Ожидает структуру:
/// ```
/// quests/{questId}/
///   config.json          → { title, startNodeId, ..., tags: [...], ... }
///   nodes.json           → { nodes: [...] }
///   res/
///     templates.json     → { templates: [...] }
/// ```
class FilesystemNodeStore implements NodeStore {
  final ScriptAssetStore _assets;

  final Map<String, Map<String, dynamic>> _configCache = {};
  final Map<String, Map<String, SavedNode>> _nodesByIdCache = {};
  final Map<String, Map<String, TemplateItem>> _templatesCache = {};
  final Map<String, List<Tag>> _tagsCache = {};
  final Map<String, Quest> _descriptorCache = {};

  FilesystemNodeStore(this._assets);

  String _configPath(String questId) => 'quests/$questId/config.json';
  String _nodesPath(String questId) => 'quests/$questId/nodes.json';
  String _templatesPath(String questId) =>
      'quests/$questId/res/templates.json';

  // ─────────────────── Config ───────────────────

  @override
  Future<Map<String, dynamic>> getQuestConfig(String questId) async {
    if (_configCache.containsKey(questId)) return _configCache[questId]!;
    final path = _configPath(questId);
    if (!await _assets.exists(path)) return {};
    final config = await _assets.readJson(path);
    _configCache[questId] = config;
    return config;
  }

  // ─────────────────── Nodes ───────────────────

  @override
  Future<List<SavedNode>> getAllNodes(String questId) async {
    final byId = await _ensureNodesCache(questId);
    return byId.values.toList();
  }

  @override
  Future<SavedNode?> getNode(String questId, String nodeId) async {
    final byId = await _ensureNodesCache(questId);
    return byId[nodeId];
  }

  Future<Map<String, SavedNode>> _ensureNodesCache(String questId) async {
    if (_nodesByIdCache.containsKey(questId)) return _nodesByIdCache[questId]!;

    final path = _nodesPath(questId);
    if (!await _assets.exists(path)) {
      return _nodesByIdCache[questId] = {};
    }

    final data = await _assets.readJson(path);
    final list = data['nodes'] as List<dynamic>? ?? const [];
    final byId = <String, SavedNode>{};

    for (final raw in list) {
      if (raw is Map<String, dynamic>) {
        try {
          final node = SavedNode.fromJson(raw);
          byId[node.id] = node;
        } catch (_) {}
      }
    }

    return _nodesByIdCache[questId] = byId;
  }

  // ─────────────────── Templates ───────────────────

  @override
  Future<Map<String, TemplateItem>> getTemplates(String questId) async {
    if (_templatesCache.containsKey(questId)) return _templatesCache[questId]!;

    final path = _templatesPath(questId);
    if (!await _assets.exists(path)) {
      return _templatesCache[questId] = {};
    }

    try {
      final data = await _assets.readJson(path);
      final items = data['templates'] as List<dynamic>? ?? [];
      final byId = <String, TemplateItem>{};
      for (final raw in items) {
        if (raw is Map<String, dynamic>) {
          try {
            final t = TemplateItem.fromJson(raw);
            byId[t.id] = t;
          } catch (_) {}
        }
      }
      return _templatesCache[questId] = byId;
    } catch (_) {
      return _templatesCache[questId] = {};
    }
  }

  // ─────────────────── Tags ───────────────────

  @override
  Future<List<Tag>> getTags(String questId) async {
    if (_tagsCache.containsKey(questId)) return _tagsCache[questId]!;

    try {
      final config = await getQuestConfig(questId);
      final tagsJson = config['tags'] as List<dynamic>? ?? [];
      final tags = tagsJson.map((json) {
        final tag = Tag.fromJson(json as Map<String, dynamic>);
        return Tag(
          id: tag.id,
          name: tag.name,
          questId: questId,
          backgroundAssetId: tag.backgroundAssetId,
          backgroundAudioId: tag.backgroundAudioId,
          folderPath: tag.folderPath,
        );
      }).toList();
      tags.sort((a, b) => a.name.compareTo(b.name));
      return _tagsCache[questId] = tags;
    } catch (_) {
      return [];
    }
  }

  // ─────────────────── Quest listing ───────────────────

  @override
  Future<List<String>> listQuestIds() async {
    // FilesystemNodeStore cannot discover quest directories from
    // ScriptAssetStore alone; callers should provide a separate
    // discovery mechanism or pass ExtendedAssetStore for listDirectory.
    return [];
  }

  @override
  Future<Quest?> getQuestDescriptor(String questId) async {
    if (_descriptorCache.containsKey(questId)) {
      return _descriptorCache[questId];
    }
    try {
      final config = await getQuestConfig(questId);
      if (config.isEmpty) return null;
      final quest = Quest.fromJson(config).copyWith(id: questId);
      _descriptorCache[questId] = quest;
      return quest;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateQuestDescriptor(
    String questId,
    Map<String, dynamic> fields,
  ) async {
    _descriptorCache.remove(questId);
    // Write-back is not supported via ScriptAssetStore — external code
    // (quest_provider) handles persistence of config updates.
  }

  @override
  Future<bool> questExists(String questId) async {
    return _assets.exists(_configPath(questId));
  }

  // ─────────────────── Cache invalidation ───────────────────

  @override
  void invalidateQuest(String questId) {
    _configCache.remove(questId);
    _nodesByIdCache.remove(questId);
    _templatesCache.remove(questId);
    _tagsCache.remove(questId);
    _descriptorCache.remove(questId);
  }

  @override
  void invalidateAll() {
    _configCache.clear();
    _nodesByIdCache.clear();
    _templatesCache.clear();
    _tagsCache.clear();
    _descriptorCache.clear();
  }
}
