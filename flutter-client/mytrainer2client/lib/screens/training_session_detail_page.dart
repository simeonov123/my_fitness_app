import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/instance_item.dart';
import '../models/exercise.dart';
import '../models/training_session.dart';
import '../models/workout_instance_exercise.dart';
import '../models/workout_instance_exercise_set.dart';
import '../models/workout_template_exercise.dart';
import '../providers/auth_provider.dart';
import '../providers/exercises_provider.dart';
import '../providers/training_sessions_provider.dart';
import '../providers/workout_instance_exercises_provider.dart';
import '../utils/instance_to_template_adapter.dart';
import '../widgets/workout_template_exercise_widget.dart';
import '../widgets/exercise_picker_dialog.dart';
import '../widgets/reorder_instance_exercises_panel.dart';

class TrainingSessionDetailPage extends StatefulWidget {
  const TrainingSessionDetailPage({super.key, required this.sessionId});
  final int sessionId;

  @override
  State<TrainingSessionDetailPage> createState() =>
      _TrainingSessionDetailPageState();
}

class _TrainingSessionDetailPageState
    extends State<TrainingSessionDetailPage> {
  TrainingSession? _session;
  final List<InstanceItem> _items = [];

  bool _dirtyMeta = false;
  bool _dirtyEx   = false;

  DateTime? _start, _end;
  final _nameCtl = TextEditingController();

  /* ───────── lifecycle ───────── */

  @override
  void initState() {
    super.initState();

    // load the common-exercise list **after** the first frame to avoid the
    // framework complaining about notifyListeners() during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExercisesProvider>().loadCommon();
    });

    _loadAll();
  }

  /* ───────── data fetch ───────── */

  Future<void> _loadAll() async {
    final tok  = context.read<AuthProvider>().token!;
    final api  = context.read<TrainingSessionsProvider>().api;
    final prov = context.read<WorkoutInstanceExercisesProvider>();

    _session = await api.getOne(token: tok, id: widget.sessionId);
    _start   = _session!.start;
    _end     = _session!.end;
    _nameCtl.text = _session!.sessionName ?? '';

    await prov.load(token: tok, sessionId: widget.sessionId);
    _buildItemList(prov.items);

    if (mounted) setState(() {});
  }

  /// de-duplicate by `sequenceOrder` (backend sometimes gives duplicates
  /// after replaceAll).  We keep the entry that already owns set data.
  void _buildItemList(List<WorkoutInstanceExercise> raw) {
    final map = <int, InstanceItem>{};

    for (final ie in raw) {
      final seq = ie.sequenceOrder;
      final candidate = InstanceItem(ie.id, ie.asTemplate());

      if (!map.containsKey(seq) ||
          map[seq]!.wte.sets.isEmpty && candidate.wte.sets.isNotEmpty) {
        map[seq] = candidate;
      }
    }

    _items
      ..clear()
      ..addAll(SplayTreeMap<int, InstanceItem>.from(map).values);
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!.sessionName ?? 'Session ${_session!.id}'),
        actions: [
          IconButton(icon: const Icon(Icons.edit), onPressed: _reorder),
          if (_dirtyMeta || _dirtyEx)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveAll),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addExercises,
        child: const Icon(Icons.add),
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _metaCard(),
          const SizedBox(height: 12),
          ..._items.map(
                (it) => WorkoutTemplateExerciseWidget(
              key: ValueKey('inst-${it.instanceId}-${it.wte.sequenceOrder}'),
              templateId: _session!.id,
              wte: it.wte,
              onChanged: () => setState(() => _dirtyEx = true),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  /* ───────── meta card & date buttons ───────── */

  Widget _metaCard() {
    final f = DateFormat('yyyy-MM-dd   HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
              onChanged: (_) => setState(() => _dirtyMeta = true),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _dtBtn(
                    'Start',
                    _start!,
                    f,
                        (d) => setState(() {
                      _start = d;
                      _dirtyMeta = true;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dtBtn(
                    'End',
                    _end!,
                    f,
                        (d) => setState(() {
                      _end = d;
                      _dirtyMeta = true;
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _dtBtn(
      String label,
      DateTime val,
      DateFormat fmt,
      ValueChanged<DateTime> cb,
      ) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.schedule),
      label: Text('$label  ${fmt.format(val)}'),
      onPressed: () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDate: val,
        );
        if (d == null) return;
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(val),
        );
        if (t == null) return;
        cb(DateTime(d.year, d.month, d.day, t.hour, t.minute));
      },
    );
  }

  /* ───────── add / reorder ───────── */

  Future<void> _addExercises() async {
    final picked = await showDialog<List<Exercise>>(
      context: context,
      builder: (_) => const ExercisePickerDialog(),
    );
    if (picked == null || picked.isEmpty) return;

    setState(() {
      for (final ex in picked) {
        _items.add(
          InstanceItem(
            0,
            ex.asTemplate(seq: _items.length + 1),
          ),
        );
      }
      _dirtyEx = true;
    });
  }

  Future<void> _reorder() async {
    final updated = await showModalBottomSheet<List<InstanceItem>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: .8,
          minChildSize: .4,
          expand: false,
          builder: (_, __) =>
              ReorderInstanceExercisesPanel(initial: List.from(_items)),
        ),
      ),
    );
    if (updated != null) {
      setState(() {
        _items
          ..clear()
          ..addAll(updated);
        _dirtyEx = true;
      });
    }
  }

  /* ───────── save ───────── */

  Future<void> _saveAll() async {
    final tok  = context.read<AuthProvider>().token!;
    final api  = context.read<TrainingSessionsProvider>().api;
    final prov = context.read<WorkoutInstanceExercisesProvider>();

    if (_dirtyMeta) {
      final dto = _session!.toJson()
        ..addAll({
          'startTime'  : _start!.toIso8601String(),
          'endTime'    : _end!.toIso8601String(),
          'sessionName': _nameCtl.text.trim(),
        });
      _session =
      await api.update(token: tok, id: _session!.id, dto: dto);
      _dirtyMeta = false;
    }

    if (_dirtyEx) {
      final payload = _items
          .map((it) => it.wte.toInstance(instanceId: it.instanceId))
          .toList();
      await prov.replaceAll(
        token: tok,
        sessionId: _session!.id,
        newList: payload,
      );
      _dirtyEx = false;

      // refresh from backend so ids & sets are accurate and duplicates vanish
      await _loadAll();
    }

    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }
}

/* ───────── extension helpers ───────── */

extension _ExTemplate on Exercise {
  WorkoutTemplateExercise asTemplate({required int seq}) =>
      WorkoutTemplateExercise(
        id: 0,
        exercise: this,
        sequenceOrder: seq,
        setType: defaultSetType,
        setParams: defaultSetParams,
        notes: '',
        sets: const [],
      );
}

extension _ToInstance on WorkoutTemplateExercise {
  WorkoutInstanceExercise toInstance({required int instanceId}) =>
      WorkoutInstanceExercise(
        id: instanceId,
        exercise: exercise,
        sequenceOrder: sequenceOrder,
        setType: setType,
        setParams: setParams,
        notes: notes,
        sets: sets
            .map(
              (s) => WorkoutInstanceExerciseSet(
            id: s.id,
            workoutExerciseId: instanceId,
            setNumber: s.setNumber,
            values: Map.of(s.values),
          ),
        )
            .toList(),
      );
}
