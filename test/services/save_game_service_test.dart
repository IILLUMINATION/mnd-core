import 'package:flutter_test/flutter_test.dart';
import 'package:mnd_core/mnd_core.dart';

class _InMemorySaveStore implements SaveStore {
  final Map<String, Map<String, SaveSlot>> _byQuest = {};

  @override
  Future<List<SaveSlot>> list(String questId) async {
    return _byQuest[questId]?.values.toList() ?? const [];
  }

  @override
  Future<SaveSlot?> read(String questId, String slotId) async {
    return _byQuest[questId]?[slotId];
  }

  @override
  Future<void> write(SaveSlot slot) async {
    _byQuest.putIfAbsent(slot.questId, () => {})[slot.id] = slot;
  }

  @override
  Future<void> delete(String questId, String slotId) async {
    _byQuest[questId]?.remove(slotId);
  }

  @override
  Future<void> deleteAll(String questId) async {
    _byQuest.remove(questId);
  }
}

void main() {
  group('SaveGameService', () {
    test('autosave creates a special slot with autosaveId', () async {
      final store = _InMemorySaveStore();
      final svc = SaveGameService(store);

      await svc.performAutosave(
        questId: 'q1',
        currentNodeId: 'n1',
        variables: const {'hp': 10},
        tables: const {},
      );

      final slots = await svc.getSaveSlots('q1');
      expect(slots, hasLength(1));
      expect(slots.single.id, SaveGameService.autosaveId);
      expect(slots.single.currentNodeId, 'n1');
    });

    test('getSaveSlots sorts autosave first, others by date desc', () async {
      final store = _InMemorySaveStore();
      final svc = SaveGameService(store);

      await svc.performAutosave(
        questId: 'q1',
        currentNodeId: 'n0',
        variables: const {},
        tables: const {},
      );
      await svc.saveGame(
        SaveSlot(
          id: 's-old',
          questId: 'q1',
          slotName: 'Old',
          savedAt: DateTime(2020, 1, 1),
          currentNodeId: 'n1',
          variables: const {},
          tables: const {},
        ),
      );
      await svc.saveGame(
        SaveSlot(
          id: 's-new',
          questId: 'q1',
          slotName: 'New',
          savedAt: DateTime(2026, 1, 1),
          currentNodeId: 'n2',
          variables: const {},
          tables: const {},
        ),
      );

      final slots = await svc.getSaveSlots('q1');
      expect(slots.map((s) => s.id),
          orderedEquals([SaveGameService.autosaveId, 's-new', 's-old']));
    });

    test('deleteAllSaves wipes everything for the quest', () async {
      final store = _InMemorySaveStore();
      final svc = SaveGameService(store);
      await svc.performAutosave(
        questId: 'q1',
        currentNodeId: 'n1',
        variables: const {},
        tables: const {},
      );
      await svc.deleteAllSaves('q1');
      expect(await svc.getSaveSlots('q1'), isEmpty);
    });

    test('saveGame stores a custom non-autosave slot', () async {
      final store = _InMemorySaveStore();
      final svc = SaveGameService(store);

      await svc.saveGame(
        SaveSlot(
          id: 'hero_save',
          questId: 'q1',
          slotName: 'Hero',
          savedAt: DateTime(2026, 7, 7),
          currentNodeId: 'n5',
          variables: const {'gold': 999},
          tables: const {},
        ),
      );

      final slots = await svc.getSaveSlots('q1');
      expect(slots, hasLength(1));
      expect(slots.single.id, 'hero_save');
      expect(slots.single.slotName, 'Hero');
      expect(slots.single.variables['gold'], 999);
    });

    test('performAutosave twice overwrites the previous autosave', () async {
      final store = _InMemorySaveStore();
      final svc = SaveGameService(store);

      await svc.performAutosave(
        questId: 'q1',
        currentNodeId: 'n1',
        variables: const {'hp': 100},
        tables: const {},
      );
      await svc.performAutosave(
        questId: 'q1',
        currentNodeId: 'n2',
        variables: const {'hp': 50},
        tables: const {},
      );

      final slots = await svc.getSaveSlots('q1');
      expect(slots, hasLength(1));
      expect(slots.single.id, SaveGameService.autosaveId);
      expect(slots.single.currentNodeId, 'n2');
      expect(slots.single.variables['hp'], 50);
    });

    test('saves for different quests are independent', () async {
      final store = _InMemorySaveStore();
      final svc = SaveGameService(store);

      await svc.saveGame(
        SaveSlot(
          id: 's1',
          questId: 'q1',
          slotName: 'Q1 Save',
          currentNodeId: 'n1',
          variables: const {},
          tables: const {},
          savedAt: DateTime(2026, 7, 7),
        ),
      );
      await svc.saveGame(
        SaveSlot(
          id: 's2',
          questId: 'q2',
          slotName: 'Q2 Save',
          currentNodeId: 'n2',
          variables: const {},
          tables: const {},
          savedAt: DateTime(2026, 7, 7),
        ),
      );

      expect((await svc.getSaveSlots('q1')).length, 1);
      expect((await svc.getSaveSlots('q2')).length, 1);
      expect((await svc.getSaveSlots('q3')).length, 0);
    });
  });
}
