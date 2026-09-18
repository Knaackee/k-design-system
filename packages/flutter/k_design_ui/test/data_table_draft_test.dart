import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:k_design_ui/k_design_ui.dart';

typedef Row = ({String id, String title, String status});
const original = (id: 'new', title: '', status: 'planned');
void main() {
  late KDataTableDraftController<Row> controller;
  late List<KDataTableDraftEvent<Row>> events;
  KDataTableDraftController<Row> create({
    FutureOr<Row> Function(Row, KDataTableDraftSnapshot<Row>)? save,
    KDataTableDraftSavePolicy policy = KDataTableDraftSavePolicy.explicit,
  }) {
    events = [];
    return controller = KDataTableDraftController<Row>(
      rowId: (r) => r.id,
      cloneRow: (r) => r,
      isEqual: (a, b) => a == b,
      onCommit: save ?? (r, _) => r,
      onEvent: events.add,
      savePolicy: policy,
    );
  }

  void begin() => controller.begin(original, initialColumnId: 'title');
  test(
    'defaults equality controls cleanup; other-property change survives leave',
    () async {
      create();
      begin();
      controller.update('new', (id: 'new', title: '', status: 'active'));
      expect(await controller.leave('new'), false);
      expect(controller.get('new')!.status, KDataTableDraftStatus.dirty);
      controller.update('new', original);
      expect(await controller.leave('new'), true);
      expect(controller.get('new'), null);
      expect(events.last.type, KDataTableDraftEventType.cancelled);
      controller.dispose();
    },
  );
  test('Escape cancels dirty new draft; saved rows are not drafts', () async {
    create();
    begin();
    controller.update('new', (id: 'new', title: 'Value', status: 'planned'));
    expect(controller.cancel('new', reason: 'escape'), true);
    begin();
    expect(await controller.commit('new', reason: 'enter'), true);
    expect(controller.cancel('new', reason: 'escape'), false);
    expect(
      events.where((e) => e.type == KDataTableDraftEventType.committed),
      hasLength(1),
    );
    controller.dispose();
  });
  test(
    'coalesces pending save and rejects editing cancellation and leave',
    () async {
      final pending = Completer<Row>();
      var calls = 0;
      create(
        save: (r, s) {
          calls++;
          expect(s.status, KDataTableDraftStatus.saving);
          return pending.future;
        },
      );
      begin();
      final a = controller.commit('new');
      final b = controller.commit('new');
      expect(identical(a, b), true);
      expect(calls, 1);
      expect(
        controller.update('new', (
          id: 'new',
          title: 'ignored',
          status: 'planned',
        )),
        false,
      );
      expect(controller.cancel('new'), false);
      expect(await controller.leave('new'), false);
      pending.complete(original);
      expect(await a, true);
      expect(
        events.where((e) => e.type == KDataTableDraftEventType.committed),
        hasLength(1),
      );
      controller.dispose();
    },
  );
  test('failed save preserves values and supports retry', () async {
    var fail = true;
    create(
      save: (r, _) {
        if (fail) throw StateError('Failure');
        return r;
      },
    );
    begin();
    final changed = (id: 'new', title: 'Changed', status: 'active');
    controller.update('new', changed);
    expect(await controller.commit('new'), false);
    expect(controller.get('new')!.status, KDataTableDraftStatus.error);
    expect(controller.get('new')!.current, changed);
    await Future<void>.delayed(Duration.zero);
    fail = false;
    expect(await controller.commit('new'), true);
    controller.dispose();
  });
  test('dispose ignores late completion without committed event', () async {
    final pending = Completer<Row>();
    create(save: (r, _) => pending.future);
    begin();
    final save = controller.commit('new');
    controller.dispose();
    pending.complete(original);
    expect(await save, false);
    expect(
      events.where((e) => e.type == KDataTableDraftEventType.committed),
      isEmpty,
    );
  });
  test(
    'owned overlays suppress leave, idempotent release does not replay it',
    () async {
      create();
      begin();
      final release = controller.retainInteraction('new');
      expect(await controller.leave('new'), false);
      release();
      release();
      expect(controller.get('new'), isNotNull);
      expect(await controller.leave('new'), true);
      controller.dispose();
    },
  );
  test('rowExit policy requests persistence only for changed rows', () async {
    create(policy: KDataTableDraftSavePolicy.rowExit);
    begin();
    controller.update('new', (id: 'new', title: '', status: 'done'));
    expect(await controller.leave('new'), true);
    expect(events.last.reason, 'rowExit');
    controller.dispose();
  });
  test(
    'external anchor and detached mutable snapshots preserve consumer ownership',
    () {
      final c = KDataTableDraftController<Map<String, String>>(
        rowId: (r) => r['id']!,
        cloneRow: Map.of,
        isEqual: (a, b) => a['title'] == b['title'],
        onCommit: (r, _) => r,
      );
      final source = {'id': 'x', 'title': ''};
      c.begin(
        source,
        initialColumnId: 'title',
        originIndex: 7,
        originQueryRevision: 'v1',
      );
      source['title'] = 'mutated';
      c.get('x')!.current['title'] = 'also mutated';
      expect(c.get('x')!.current['title'], '');
      expect(c.draftRows.single.originIndex, 7);
      expect(c.draftRows.single.originQueryRevision, 'v1');
      c.dispose();
    },
  );
}
