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
  final List<InstanceClientGroup> _groups = [];
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
      if (!mounted) return;
      if (context.read<AuthProvider>().isTrainer) {
        context.read<ExercisesProvider>().loadAvailable();
      }
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
    try {
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load session: $e')),
      );
      rethrow;
    }
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
    for (final group in _groups) {
      total += _groupTotalWeightLifted(group);
    }
    return total;
  }

  double _groupTotalWeightLifted(InstanceClientGroup group) {
    var total = 0.0;
    for (final item in group.items) {
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

  int _groupCompletedSets(InstanceClientGroup group) {
    var count = 0;
    for (final item in group.items) {
      for (final set in item.wte.sets) {
        if (set.completed) count++;
      }
    }
    return count;
  }

  int _groupSetCount(InstanceClientGroup group) {
    var count = 0;
    for (final item in group.items) {
      count += item.wte.sets.length;
    }
    return count;
  }

  String get _formattedPlannedDuration => _formatDuration(_plannedDuration);

  String get _formattedActualDuration =>
      _actualDuration != null ? _formatDuration(_actualDuration!) : '--:--';

  List<ClientLeaderboardEntry> get _leaderboard {
    final rows = _groups
        .map(
          (group) => ClientLeaderboardEntry(
            clientName: group.clientName,
            totalWeightLifted: _groupTotalWeightLifted(group),
            completedSets: _groupCompletedSets(group),
            totalSets: _groupSetCount(group),
          ),
        )
        .toList();
    rows.sort((a, b) {
      final byWeight = b.totalWeightLifted.compareTo(a.totalWeightLifted);
      if (byWeight != 0) return byWeight;
      return a.clientName.toLowerCase().compareTo(b.clientName.toLowerCase());
    });
    return rows;
  }

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
    final grouped = SplayTreeMap<String, InstanceClientGroup>();

    for (final ie in raw) {
      final groupKey =
          '${ie.workoutInstanceId}:${ie.clientId ?? 0}:${ie.clientName ?? ''}';
      final group = grouped.putIfAbsent(
        groupKey,
        () => InstanceClientGroup(
          workoutInstanceId: ie.workoutInstanceId,
          clientId: ie.clientId,
          clientName: ie.clientName ?? 'Client',
          items: [],
        ),
      );

      final candidate = InstanceItem(
        ie.id,
        ie.workoutInstanceId,
        ie.clientId,
        ie.clientName,
        ie.asTemplate(),
      );

      final existingIndex = group.items.indexWhere(
        (item) => item.wte.sequenceOrder == ie.sequenceOrder,
      );
      if (existingIndex == -1) {
        group.items.add(candidate);
      } else if (group.items[existingIndex].wte.sets.isEmpty &&
          candidate.wte.sets.isNotEmpty) {
        group.items[existingIndex] = candidate;
      }
    }

    for (final group in grouped.values) {
      group.items.sort((a, b) => a.wte.sequenceOrder.compareTo(b.wte.sequenceOrder));
    }

    _groups
      ..clear()
      ..addAll(grouped.values);
  }

  /* ───────── UI ───────── */

  @override
  Widget build(BuildContext context) {
    if (_session == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final isClient = context.watch<AuthProvider>().isClient;
    final clientReadOnly = isClient && (_session!.isCompleted ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Text(_session!.sessionName ?? 'Session ${_session!.id}'),
        actions: [
          if (!isClient)
            IconButton(icon: const Icon(Icons.edit), onPressed: _reorder),
          if ((_dirtyMeta || _dirtyEx) && !clientReadOnly)
            IconButton(icon: const Icon(Icons.save), onPressed: _saveAll),
        ],
      ),
      floatingActionButton: clientReadOnly
          ? null
          : FloatingActionButton(
              onPressed: _addExercises,
              child: const Icon(Icons.add),
            ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _metaCard(isClient: isClient),
          const SizedBox(height: 12),
          _activityCard(isClient: isClient),
          const SizedBox(height: 12),
          if (!isClient && _groups.length > 1) ...[
            _leaderboardCard(),
            const SizedBox(height: 12),
          ],
          ..._groups.map(
                (group) => _clientSection(
                  group,
                  isClient: isClient,
                  clientReadOnly: clientReadOnly,
                ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _activityCard({required bool isClient}) {
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
                _statChip(
                  label: 'Clients',
                  value: '${_groups.length}',
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
            if (!isClient) ...[
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
          ],
        ),
      ),
    );
  }

  Widget _leaderboardCard() {
    final rows = _leaderboard;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined),
                const SizedBox(width: 8),
                Text(
                  'Session leaderboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...rows.asMap().entries.map(
                  (entry) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: entry.key == 0
                          ? const Color(0xFFFFF8E1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: entry.key == 0
                              ? const Color(0xFFFFC107)
                              : Colors.grey.shade300,
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: entry.key == 0
                                  ? Colors.black
                                  : Colors.grey.shade900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value.clientName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${entry.value.completedSets}/${entry.value.totalSets} sets completed',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.value.totalWeightLifted.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _metaCard({required bool isClient}) {
    final f = DateFormat('yyyy-MM-dd   HH:mm');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: _nameCtl,
              decoration: const InputDecoration(labelText: 'Name'),
              readOnly: isClient,
              onChanged: isClient ? null : (_) => setState(() => _dirtyMeta = true),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _dateTimeField(
                    label: 'Start',
                    value: _start!,
                    fmt: f,
                    icon: Icons.play_circle_outline,
                    enabled: !isClient,
                    onChanged: (d) => setState(() {
                      _start = d;
                      _dirtyMeta = true;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _dateTimeField(
                    label: 'End',
                    value: _end!,
                    fmt: f,
                    icon: Icons.flag_outlined,
                    enabled: !isClient,
                    onChanged: (d) => setState(() {
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

  Widget _dateTimeField({
    required String label,
    required DateTime value,
    required DateFormat fmt,
    required IconData icon,
    required bool enabled,
    required ValueChanged<DateTime> onChanged,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: !enabled ? null : () async {
        final d = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDate: value,
        );
        if (d == null) return;
        if (!mounted) return;
        final t = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value),
        );
        if (t == null) return;
        onChanged(DateTime(d.year, d.month, d.day, t.hour, t.minute));
      },
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFFEDE7F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF6E59A5)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(value),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (enabled) Icon(Icons.chevron_right, color: Colors.grey.shade500),
          ],
        ),
      ),
    );
  }

  /* ───────── add / reorder ───────── */

  Future<void> _addExercises() async {
    final picked = await showDialog<TargetedExercisePickerResult>(
      context: context,
      builder: (_) => TargetedExercisePickerDialog(
        clients: _groups
            .map(
              (group) => ExerciseTargetOption(
                clientId: group.clientId,
                clientName: group.clientName,
              ),
            )
            .toList(growable: false),
      ),
    );
    if (picked == null || picked.exercises.isEmpty) return;

    setState(() {
      final targetGroups = picked.applyToAllClients
          ? _groups
          : _groups
              .where(
                (group) =>
                    group.clientId != null &&
                    picked.clientIds.contains(group.clientId),
              )
              .toList(growable: false);

      for (final group in targetGroups) {
        for (final ex in picked.exercises) {
          group.items.add(
            InstanceItem(
              0,
              group.workoutInstanceId,
              group.clientId,
              group.clientName,
              ex.asTemplate(seq: group.items.length + 1),
            ),
          );
        }
      }
      _dirtyEx = true;
    });
  }

  Future<void> _reorder() async {
    if (_groups.isEmpty) return;
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
              ReorderInstanceExercisesPanel(initial: List.from(_groups.first.items)),
        ),
      ),
    );
    if (updated != null) {
      final orderedExerciseIds = updated.map((item) => item.wte.exercise.id).toList();
      setState(() {
        for (final group in _groups) {
          group.items.sort((a, b) {
            final ai = orderedExerciseIds.indexOf(a.wte.exercise.id);
            final bi = orderedExerciseIds.indexOf(b.wte.exercise.id);
            final aIndex = ai == -1 ? 1 << 20 : ai;
            final bIndex = bi == -1 ? 1 << 20 : bi;
            return aIndex.compareTo(bIndex);
          });
          for (var i = 0; i < group.items.length; i++) {
            group.items[i].wte.sequenceOrder = i + 1;
          }
        }
        _dirtyEx = true;
      });
    }
  }

  /* ───────── save ───────── */

  Future<void> _saveAll() async {
    try {
      await _saveAllInternal(showFeedback: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
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
      final groupedPayload = _groups
          .expand((group) => group.items)
          .map((it) => it.wte.toInstance(
                instanceId: it.instanceId,
                workoutInstanceId: it.workoutInstanceId,
                clientId: it.clientId,
                clientName: it.clientName,
              ))
          .toList();
      await prov.replaceAll(
        token: tok,
        sessionId: _session!.id,
        newList: groupedPayload,
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

    try {
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
    } catch (e) {
      await _activeWorkout.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start workout: $e')),
      );
    }
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
              exerciseCount: _groups.fold<int>(
                0,
                (sum, group) => sum + group.items.length,
              ),
              leaderboard: _leaderboard
                  .take(3)
                  .map(
                    (entry) => SocialLeaderboardEntry(
                      clientName: entry.clientName,
                      totalWeightLifted: entry.totalWeightLifted,
                    ),
                  )
                  .toList(growable: false),
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

  Widget _clientSection(
    InstanceClientGroup group, {
    required bool isClient,
    required bool clientReadOnly,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isClient) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Text(_initials(group.clientName)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      group.clientName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_groupTotalWeightLifted(group).toStringAsFixed(0)} kg',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_groupCompletedSets(group)}/${_groupSetCount(group)} sets',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            ...group.items.map(
              (it) => WorkoutTemplateExerciseWidget(
                key: ValueKey(
                  'inst-${group.workoutInstanceId}-${it.instanceId}-${it.wte.sequenceOrder}',
                ),
                templateId: _session!.id,
                wte: it.wte,
                showCompletion: true,
                canEditExerciseNotes: !isClient,
                canEditSetNotes: !isClient,
                isReadOnly: clientReadOnly,
                onChanged: () {
                  setState(() => _dirtyEx = true);
                  _syncActiveWorkoutNotification();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
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
  WorkoutInstanceExercise toInstance({
    required int instanceId,
    required int workoutInstanceId,
    int? clientId,
    String? clientName,
  }) =>
      WorkoutInstanceExercise(
        id: instanceId,
        workoutInstanceId: workoutInstanceId,
        clientId: clientId,
        clientName: clientName,
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
            setContextType: s.setContextType,
            notes: s.notes,
            values: Map.of(s.values),
          ),
        )
            .toList(),
      );
}

class InstanceClientGroup {
  final int workoutInstanceId;
  final int? clientId;
  final String clientName;
  final List<InstanceItem> items;

  InstanceClientGroup({
    required this.workoutInstanceId,
    required this.clientId,
    required this.clientName,
    required this.items,
  });
}

class ClientLeaderboardEntry {
  final String clientName;
  final double totalWeightLifted;
  final int completedSets;
  final int totalSets;

  ClientLeaderboardEntry({
    required this.clientName,
    required this.totalWeightLifted,
    required this.completedSets,
    required this.totalSets,
  });
}
