import 'dart:async';
import 'dart:collection';
import 'dart:convert';

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
import '../providers/social_feed_provider.dart';
import '../providers/training_sessions_provider.dart';
import '../providers/workout_instance_exercises_provider.dart';
import '../models/social_post.dart';
import '../services/active_workout_service.dart';
import '../services/workout_notification_service.dart';
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
  final _activeWorkout = ActiveWorkoutService();
  final _notifications = WorkoutNotificationService.instance;
  TrainingSession? _session;
  final List<InstanceItem> _items = [];
  Timer? _ticker;

  bool _dirtyMeta = false;
  bool _dirtyEx   = false;
  bool _busyAction = false;

  DateTime? _start, _end;
  final _nameCtl = TextEditingController();
  ActiveWorkoutSnapshot? _activeSnapshot;

  /* ───────── lifecycle ───────── */

  @override
  void initState() {
    super.initState();

    // load the available exercise list **after** the first frame to avoid the
    // framework complaining about notifyListeners() during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExercisesProvider>().loadAvailable();
    });

    _loadAll();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _nameCtl.dispose();
    super.dispose();
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
    await _restoreActiveWorkout();

    if (mounted) setState(() {});
  }

  Future<void> _restoreActiveWorkout() async {
    final snapshot = await _activeWorkout.load();
    _ticker?.cancel();
    _activeSnapshot = snapshot;

    if (_isActiveForCurrentSession) {
      await _syncActiveWorkoutNotification();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  bool get _isActiveForCurrentSession =>
      _activeSnapshot?.sessionId == widget.sessionId;

  Duration get _elapsed =>
      _isActiveForCurrentSession && _activeSnapshot != null
          ? DateTime.now().difference(_activeSnapshot!.startedAt)
          : Duration.zero;

  Duration get _plannedDuration => _end!.difference(_start!);

  Duration? get _actualDuration {
    if (_isActiveForCurrentSession && _activeSnapshot != null) {
      return _elapsed;
    }
    final actualStart = _session?.actualStartTime;
    final actualEnd = _session?.actualEndTime;
    if (actualStart != null && actualEnd != null) {
      return actualEnd.difference(actualStart);
    }
    return null;
  }

  double get _totalWeightLifted {
    var total = 0.0;
    for (final item in _items) {
      for (final set in item.wte.sets) {
        if (!set.completed) continue;
        final kg = set.values['KG'];
        final reps = set.values['REPS'];
        if (kg != null && reps != null) {
          total += kg * reps;
        }
      }
    }
    return total;
  }

  String get _formattedPlannedDuration => _formatDuration(_plannedDuration);

  String get _formattedActualDuration =>
      _actualDuration != null ? _formatDuration(_actualDuration!) : '--:--';

  String _formatDuration(Duration elapsed) {
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '${elapsed.inMinutes.toString().padLeft(2, '0')}:$seconds';
  }

  Future<void> _syncActiveWorkoutNotification() async {
    if (!_isActiveForCurrentSession || _activeSnapshot == null) return;
    await _notifications.showActiveWorkout(
      title: _activeSnapshot!.sessionName,
      startedAt: _activeSnapshot!.startedAt,
      totalWeightLifted: _totalWeightLifted,
    );
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
          _activityCard(),
          const SizedBox(height: 12),
          ..._items.map(
                (it) => WorkoutTemplateExerciseWidget(
              key: ValueKey('inst-${it.instanceId}-${it.wte.sequenceOrder}'),
              templateId: _session!.id,
              wte: it.wte,
              showCompletion: true,
              onChanged: () {
                setState(() => _dirtyEx = true);
                _syncActiveWorkoutNotification();
              },
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _activityCard() {
    final runningElsewhere =
        _activeSnapshot != null && !_isActiveForCurrentSession;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _isActiveForCurrentSession
                        ? 'Workout in progress'
                        : 'Workout tracker',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _statChip(
                  label: 'Planned',
                  value: _formattedPlannedDuration,
                ),
                _statChip(
                  label: 'Actual',
                  value: _formattedActualDuration,
                ),
                _statChip(
                  label: 'Total lifted',
                  value: '${_totalWeightLifted.toStringAsFixed(0)} kg',
                ),
              ],
            ),
            if (runningElsewhere) ...[
              const SizedBox(height: 12),
              Text(
                'Another workout is already running: ${_activeSnapshot!.sessionName}',
                style: TextStyle(color: Colors.orange[800]),
              ),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                if (!_isActiveForCurrentSession)
                  ElevatedButton.icon(
                    onPressed: runningElsewhere || _busyAction ? null : _startWorkout,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start'),
                  ),
                if (_isActiveForCurrentSession) ...[
                  OutlinedButton.icon(
                    onPressed: _busyAction ? null : _discardWorkout,
                    icon: const Icon(Icons.close),
                    label: const Text('Discard'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _busyAction ? null : _completeWorkout,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Complete'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
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
        if (!mounted) return;
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
    await _saveAllInternal(showFeedback: true);
  }

  Future<void> _saveAllInternal({required bool showFeedback}) async {
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

    if (showFeedback && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  Future<void> _startWorkout() async {
    if (_session == null) return;

    final startedAt = DateTime.now();
    final snapshot = ActiveWorkoutSnapshot(
      sessionId: _session!.id,
      sessionName: _session!.sessionName ?? 'Session ${_session!.id}',
      startedAt: startedAt,
    );

    await _activeWorkout.save(snapshot);
    if (!mounted) return;

    final tok = context.read<AuthProvider>().token!;
    final api = context.read<TrainingSessionsProvider>().api;
    final dto = _session!.toJson()
      ..addAll({
        'status': 'IN_PROGRESS',
        'isCompleted': false,
        'actualStartTime': startedAt.toIso8601String(),
        'actualEndTime': null,
      });
    _session = await api.update(token: tok, id: _session!.id, dto: dto);

    _activeSnapshot = snapshot;
    await _syncActiveWorkoutNotification();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    if (mounted) setState(() {});
  }

  Future<void> _discardWorkout() async {
    setState(() => _busyAction = true);
    try {
      await _activeWorkout.clear();
      await _notifications.cancelActiveWorkout();
      _ticker?.cancel();
      _activeSnapshot = null;
      if (!mounted) return;

      if (_session != null) {
        final tok = context.read<AuthProvider>().token!;
        final api = context.read<TrainingSessionsProvider>().api;
        final dto = _session!.toJson()
          ..addAll({
            'status': 'PLANNED',
            'isCompleted': false,
            'actualStartTime': null,
            'actualEndTime': null,
          });
        _session = await api.update(token: tok, id: _session!.id, dto: dto);
      }

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Active workout discarded')),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  Future<void> _completeWorkout() async {
    if (_session == null) return;

    setState(() => _busyAction = true);
    try {
      final actualDurationSeconds = _elapsed.inSeconds;
      final totalLiftedAtCompletion = _totalWeightLifted;
      await _saveAllInternal(showFeedback: false);
      if (!mounted) return;

      final tok = context.read<AuthProvider>().token!;
      final api = context.read<TrainingSessionsProvider>().api;
      final finishedAt = DateTime.now();
      final actualStartedAt =
          _activeSnapshot?.startedAt ?? _session!.actualStartTime ?? finishedAt;
      final dto = _session!.toJson()
        ..addAll({
          'status': 'COMPLETED',
          'isCompleted': true,
          'actualStartTime': actualStartedAt.toIso8601String(),
          'actualEndTime': finishedAt.toIso8601String(),
        });
      _session = await api.update(token: tok, id: _session!.id, dto: dto);
      _dirtyMeta = false;

      await _activeWorkout.clear();
      await _notifications.cancelActiveWorkout();
      _ticker?.cancel();
      _activeSnapshot = null;
      if (!mounted) return;
      await context.read<SocialFeedProvider>().addPost(
            SocialPost(
              id: 'session-${_session!.id}',
              title: 'Congratulations',
              workoutTitle:
                  _session!.sessionName ?? 'Workout ${_session!.id}',
              trainerName: _trainerDisplayName(),
              clientSummary: _clientSummary(),
              completedAt: finishedAt,
              durationSeconds: actualDurationSeconds,
              totalWeightLifted: totalLiftedAtCompletion,
              exerciseCount: _items.length,
            ),
          );

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Workout completed. Total lifted: ${totalLiftedAtCompletion.toStringAsFixed(0)} kg',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busyAction = false);
    }
  }

  String _clientSummary() {
    final count = _session?.clientIds.length ?? 0;
    if (count == 0) return 'No clients assigned';
    if (count == 1) return 'Performed by 1 client';
    return 'Performed by $count clients';
  }

  String _trainerDisplayName() {
    final token = context.read<AuthProvider>().token;
    if (token == null) return 'Trainer';

    try {
      final parts = token.split('.');
      if (parts.length < 2) return 'Trainer';
      final normalized = base64Url.normalize(parts[1]);
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(normalized)),
      ) as Map<String, dynamic>;
      return (payload['preferred_username'] as String?) ??
          (payload['name'] as String?) ??
          'Trainer';
    } catch (_) {
      return 'Trainer';
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
            completed: s.completed,
            values: Map.of(s.values),
          ),
        )
            .toList(),
      );
}
