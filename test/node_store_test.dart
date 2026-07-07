import 'dart:convert';

import 'package:mnd_core/contracts/node_store.dart';
import 'package:mnd_core/contracts/script_asset_store.dart';
import 'package:mnd_core/models/saved_node.dart';
import 'package:mnd_core/models/quest_descriptor.dart';
import 'package:mnd_core/models/tag.dart';
import 'package:mnd_core/models/template_model.dart';
import 'package:mnd_core/services/node_store_json_files.dart';
import 'package:test/test.dart';

class _InMemoryAssetStore implements ScriptAssetStore {
  final Map<String, String> _files = {};

  void addJson(String path, Map<String, dynamic> data) {
    _files[path] = jsonEncode(data);
  }

  @override
  Future<bool> exists(String path) async => _files.containsKey(path);

  @override
  Future<Map<String, dynamic>> readJson(String path) async {
    if (!_files.containsKey(path)) throw Exception('not found');
    return jsonDecode(_files[path]!) as Map<String, dynamic>;
  }
}

void main() {
  late _InMemoryAssetStore assets;
  late NodeStore store;

  const questId = 'test-quest-1';

  setUp(() {
    assets = _InMemoryAssetStore();
    store = FilesystemNodeStore(assets);
  });

  group('FilesystemNodeStore', () {
    test('questExists returns false for missing quest', () async {
      expect(await store.questExists('nonexistent'), isFalse);
    });

    test('questExists returns true when config.json exists', () async {
      assets.addJson('quests/$questId/config.json', {
        'title': 'Test Quest',
        'startNodeId': 'node1',
      });
      expect(await store.questExists(questId), isTrue);
    });

    test('getQuestConfig returns empty map for missing quest', () async {
      final config = await store.getQuestConfig('nonexistent');
      expect(config, isEmpty);
    });

    test('getQuestConfig returns parsed config', () async {
      final raw = {
        'title': 'My Quest',
        'startNodeId': 'start-1',
        'tags': [
          {'id': 't1', 'name': 'Action', 'folderPath': '/action'},
        ],
      };
      assets.addJson('quests/$questId/config.json', raw);

      final config = await store.getQuestConfig(questId);
      expect(config['title'], 'My Quest');
      expect(config['startNodeId'], 'start-1');
    });

    test('getAllNodes returns empty list for missing nodes.json', () async {
      final nodes = await store.getAllNodes(questId);
      expect(nodes, isEmpty);
    });

    test('getAllNodes parses nodes correctly', () async {
      assets.addJson('quests/$questId/nodes.json', {
        'nodes': [
          {'id': 'n1', 'title': 'Node 1', 'content': {}},
          {'id': 'n2', 'title': 'Node 2', 'content': {}, 'x': 100, 'y': 200},
        ],
      });

      final nodes = await store.getAllNodes(questId);
      expect(nodes.length, 2);
      expect(nodes[0].id, 'n1');
      expect(nodes[0].title, 'Node 1');
      expect(nodes[1].x, 100);
      expect(nodes[1].y, 200);
    });

    test('getAllNodes skips malformed entries', () async {
      assets.addJson('quests/$questId/nodes.json', {
        'nodes': [
          {'id': 'n1', 'title': 'Good', 'content': {}},
          'not_a_map',
          {'id': 'n3', 'title': 'Also Good', 'content': {}},
        ],
      });

      final nodes = await store.getAllNodes(questId);
      expect(nodes.length, 2);
    });

    test('getNode returns null for missing node', () async {
      assets.addJson('quests/$questId/nodes.json', {
        'nodes': [
          {'id': 'n1', 'title': 'Node 1', 'content': {}},
        ],
      });

      final node = await store.getNode(questId, 'n99');
      expect(node, isNull);
    });

    test('getNode returns correct node by id', () async {
      assets.addJson('quests/$questId/nodes.json', {
        'nodes': [
          {'id': 'n1', 'title': 'First', 'content': {}},
          {'id': 'n2', 'title': 'Second', 'content': {}},
        ],
      });

      final node = await store.getNode(questId, 'n2');
      expect(node, isNotNull);
      expect(node!.title, 'Second');
    });

    test('getTemplates returns empty map when templates.json missing', () async {
      final templates = await store.getTemplates(questId);
      expect(templates, isEmpty);
    });

    test('getTemplates parses templates correctly', () async {
      assets.addJson('quests/$questId/res/templates.json', {
        'templates': [
          {
            'id': 'tmpl1',
            'name': 'HP Bar',
            'kind': 'node',
            'payload': {'id': 'bar', 'title': 'Bar', 'content': {}},
            'schemaVersion': 1,
            'contentVersion': 1,
          },
        ],
      });

      final templates = await store.getTemplates(questId);
      expect(templates.length, 1);
      expect(templates['tmpl1']!.name, 'HP Bar');
    });

    test('getTags returns tags from config', () async {
      assets.addJson('quests/$questId/config.json', {
        'title': 'Quest',
        'tags': [
          {'id': 't1', 'name': 'Adventure', 'folderPath': '/adv'},
          {'id': 't2', 'name': 'Mystery'},
        ],
      });

      final tags = await store.getTags(questId);
      expect(tags.length, 2);
      expect(tags[0].name, 'Adventure');
      expect(tags[1].name, 'Mystery');
      expect(tags[0].questId, questId);
    });

    test('getQuestDescriptor returns null for missing quest', () async {
      final desc = await store.getQuestDescriptor('nonexistent');
      expect(desc, isNull);
    });

    test('getQuestDescriptor returns Quest from config', () async {
      assets.addJson('quests/$questId/config.json', {
        'title': 'Epic Quest',
        'startNodeId': 'start',
        'author': 'John',
        'description': 'A grand adventure',
      });

      final quest = await store.getQuestDescriptor(questId);
      expect(quest, isNotNull);
      expect(quest!.title, 'Epic Quest');
      expect(quest.startNodeId, 'start');
      expect(quest.author, 'John');
    });

    test('invalidateQuest clears all caches', () async {
      assets.addJson('quests/$questId/config.json', {'title': 'V1'});
      assets.addJson('quests/$questId/nodes.json', {
        'nodes': [{'id': 'n1', 'title': 'Node', 'content': {}}],
      });

      await store.getQuestConfig(questId);
      await store.getAllNodes(questId);

      // Change underlying data
      assets.addJson('quests/$questId/config.json', {'title': 'V2'});
      store.invalidateQuest(questId);

      final config = await store.getQuestConfig(questId);
      expect(config['title'], 'V2');
    });

    test('listQuestIds returns empty (filesystem-backed store)', () async {
      final ids = await store.listQuestIds();
      expect(ids, isEmpty);
    });
  });
}
