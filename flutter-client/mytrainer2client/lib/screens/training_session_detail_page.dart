import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/instance_item.dart';
import '../models/exercise.dart';
import '../models/training_session_realtime_event.dart';
import '../models/training_session.dart';
import '../models/workout_instance_exercise.dart';
import '../models/workout_instance_exercise_set.dart';
import '../models/workout_template_exercise.dart';
import '../providers/auth_provider.dart';
import '../providers/exercise_history_provider.dart';
import '../providers/exercises_provider.dart';
import '../providers/social_feed_provider.dart';
import '../providers/training_sessions_provider.dart';
import '../providers/workout_instance_exercises_provider.dart';
import '../models/social_post.dart';
import '../services/active_workout_service.dart';
import '../services/training_session_realtime_service.dart';
import '../services/workout_notification_service.dart';
import '../theme/app_density.dart';
import '../utils/instance_to_template_adapter.dart';
import '../widgets/workout_template_exercise_widget.dart';
import '../widgets/exercise_history_sheet.dart';
import '../widgets/exercise_picker_dialog.dart';
import '../widgets/reorder_instance_exercises_panel.dart';

class TrainingSessionDetailPage extends StatefulWidget {
  const TrainingSessionDetailPage({super.key, required this.sessionId});
  final int sessionId;

  @override
  State<TrainingSessionDetailPage> createState() =>
      _TrainingSessionDetailPageState();
}

class _TrainingSessionDetailPageState extends State<TrainingSessionDetailPage> {
  final _activeWorkout = ActiveWorkoutService();
  final _realtime = TrainingSessionRealtimeService();
  final _notifications = WorkoutNotificationService.instance;
  TrainingSession? _session;
  final List<InstanceClientGroup> _groups = [];
  Timer? _ticker;
  Timer? _autoSaveDebounce;
  Timer? _restCountdownTicker;
  Timer? _restNotificationDismissTimer;
  StreamSubscription? _realtimeSub;

  bool _dirtyMeta = false;
  bool _dirtyEx = false;
  bool _busyAction = false;
  bool _autoSaving = false;
  bool _autoSaveQueued = false;

  DateTime? _start, _end;
  final _nameCtl = TextEditingController();
  ActiveWorkoutSnapshot? _activeSnapshot;
  int? _activeRestSecondsRemaining;
  String? _activeRestExerciseName;

  /* ───────── lifecycle ───────── */

  @override
  void initState() {
    super.initState();

    // load the available exercise list **after** the first frame to avoid the
    // framework complaining about notifyListeners() during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      if (auth.isTrainer) {
        context.read<ExercisesProvider>().loadAvailable();
      } else {
        context.read<ExercisesProvider>().loadCommon();
      }
    });

    _loadAll();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _autoSaveDebounce?.cancel();
    _restCountdownTicker?.cancel();
    _restNotificationDismissTimer?.cancel();
    _realtimeSub?.cancel();
    unawaited(_realtime.disconnect());
    _nameCtl.dispose();
    super.dispose();
  }

  /* ───────── data fetch ───────── */

  Future<void> _loadAll() async {
    try {
      final api = context.read<TrainingSessionsProvider>().api;
      final prov = context.read<WorkoutInstanceExercisesProvider>();

      _session = await api.getOne(id: widget.sessionId);
      _start = _session!.start;
      _end = _session!.end;
      _nameCtl.text = _session!.sessionName ?? '';

      await prov.load(sessionId: widget.sessionId);
      _buildItemList(prov.items);
      await _restoreActiveWorkout();
      await _connectRealtime();
      await _syncSocialPost();

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
    final snapshot = await _activeWorkout.load(widget.sessionId);
    _activeSnapshot = snapshot;
    _syncSessionTicker();

    if (_isActiveForCurrentSession) {
      await _syncActiveWorkoutNotification();
    }
  }

  void _syncSessionTicker() {
    final shouldTick = _isSessionRunning || _isActiveForCurrentSession;
    if (shouldTick) {
      _ticker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _ticker?.cancel();
      _ticker = null;
    }
  }

  bool get _isActiveForCurrentSession =>
      _activeSnapshot?.sessionId == widget.sessionId;

  bool get _isSessionRunning =>
      (_session?.status ?? '').toUpperCase() == 'IN_PROGRESS' &&
      _session?.actualStartTime != null &&
      _session?.actualEndTime == null;

  Duration get _elapsed {
    if (context.read<AuthProvider>().isTrainer &&
        _isActiveForCurrentSession &&
        _activeSnapshot != null) {
      return DateTime.now().difference(_activeSnapshot!.startedAt);
    }

    final actualStart = _session?.actualStartTime;
    if (_isSessionRunning && actualStart != null) {
      return DateTime.now().difference(actualStart);
    }

    return Duration.zero;
  }

  Duration get _plannedDuration => _end!.difference(_start!);

  void _markMetaDirty() {
    _dirtyMeta = true;
    _scheduleAutoSave();
  }

  void _markExercisesDirty() {
    _dirtyEx = true;
    _scheduleAutoSave();
  }

  void _scheduleAutoSave({Duration delay = const Duration(milliseconds: 700)}) {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(delay, () {
      unawaited(_runAutoSave());
    });
  }

  Future<void> _runAutoSave() async {
    if (!mounted || (!_dirtyMeta && !_dirtyEx) || _busyAction) return;
    if (_autoSaving) {
      _autoSaveQueued = true;
      return;
    }

    _autoSaving = true;
    if (mounted) setState(() {});
    try {
      await _saveAllInternal(showFeedback: false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-save failed: $e')),
      );
    } finally {
      _autoSaving = false;
      if (_autoSaveQueued) {
        _autoSaveQueued = false;
        _scheduleAutoSave(delay: Duration.zero);
      } else if (mounted) {
        setState(() {});
      }
    }
  }

  Duration? get _actualDuration {
    if (_elapsed > Duration.zero) {
      return _elapsed;
    }
    final actualStart = _session?.actualStartTime;
    final actualEnd = _session?.actualEndTime;
    if (actualStart != null) {
      if (actualEnd != null) {
        return actualEnd.difference(actualStart);
      }
      if ((_session?.status ?? '').toUpperCase() == 'IN_PROGRESS') {
        return DateTime.now().difference(actualStart);
      }
    }
    return null;
  }

  bool get _isSoloSession =>
      (_session?.sessionType ?? '').toUpperCase() == 'SOLO';

  int get _participantCount => _isSoloSession
      ? 1
      : (_session?.clientIds.length ?? _groups.length);

  void _startRestTimer({
    required String exerciseName,
    required int restSeconds,
  }) {
    if (restSeconds <= 0) return;
    _restCountdownTicker?.cancel();
    _restNotificationDismissTimer?.cancel();
    setState(() {
      _activeRestExerciseName = exerciseName;
      _activeRestSecondsRemaining = restSeconds;
    });
    _restCountdownTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _activeRestSecondsRemaining == null) {
        timer.cancel();
        return;
      }
      if (_activeRestSecondsRemaining! <= 1) {
        timer.cancel();
        unawaited(_handleRestTimerCompleted());
        return;
      }
      setState(() {
        _activeRestSecondsRemaining = _activeRestSecondsRemaining! - 1;
      });
    });
  }

  Future<void> _handleRestTimerCompleted() async {
    final exerciseName = _activeRestExerciseName ?? 'Rest timer';
    if (mounted) {
      setState(() {
        _activeRestSecondsRemaining = 0;
      });
    }
    await _notifications.showRestTimerFinished(
      title: 'Rest complete',
      body: 'Your time is up for $exerciseName',
    );
    _restNotificationDismissTimer = Timer(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() {
        _activeRestSecondsRemaining = null;
        _activeRestExerciseName = null;
      });
    });
  }

  void _dismissRestTimer() {
    _restCountdownTicker?.cancel();
    _restNotificationDismissTimer?.cancel();
    setState(() {
      _activeRestSecondsRemaining = null;
      _activeRestExerciseName = null;
    });
  }

  Future<void> _openExerciseHistory(InstanceItem item) async {
    if (item.instanceId <= 0 || !mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ExerciseHistoryProvider>(),
        child: ExerciseHistorySheet(
          sessionId: widget.sessionId,
          entryId: item.instanceId,
          onOpenSnapshot: (snapshotSessionId) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => TrainingSessionDetailPage(
                  sessionId: snapshotSessionId,
                ),
              ),
            );
          },
        ),
      ),
    );
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

  double _groupBestSetKg(InstanceClientGroup group) {
    var best = 0.0;
    for (final item in group.items) {
      for (final set in item.wte.sets) {
        final kg = set.values['KG'];
        if (kg != null && kg > best) {
          best = kg;
        }
      }
    }
    return best;
  }

  int _groupBestSetReps(InstanceClientGroup group) {
    var best = 0;
    for (final item in group.items) {
      for (final set in item.wte.sets) {
        final reps = set.values['REPS'];
        if (reps != null && reps > best) {
          best = reps.round();
        }
      }
    }
    return best;
  }

  SocialPerformanceHighlight? _bestVolumeHighlightForGroups(
    List<InstanceClientGroup> groups, {
    bool includePerformer = true,
  }) {
    _ExercisePerformanceSnapshot? best;
    for (final group in groups) {
      for (final item in group.items) {
        for (final set in item.wte.sets) {
          if (!set.completed) continue;
          final kg = set.values['KG'];
          final reps = set.values['REPS'];
          if (kg == null || reps == null) continue;
          final volume = kg * reps;
          if (best == null || volume > best.volume) {
            best = _ExercisePerformanceSnapshot(
              clientName: group.clientName,
              exerciseName: item.wte.exercise.name,
              setNumber: set.setNumber,
              volume: volume,
              kg: kg,
              reps: reps.round(),
            );
          }
        }
      }
    }
    if (best == null) return null;
    final performer = includePerformer ? ' • ${best.clientName}' : '';
    return SocialPerformanceHighlight(
      label: 'Best set volume',
      value: '${best.volume.toStringAsFixed(0)} kg',
      detail:
          '${best.exerciseName} • Set ${best.setNumber} • ${best.kg.toStringAsFixed(0)}kg x ${best.reps}$performer',
    );
  }

  SocialPerformanceHighlight? _heaviestHighlightForGroups(
    List<InstanceClientGroup> groups, {
    bool includePerformer = true,
  }) {
    _ExercisePerformanceSnapshot? best;
    for (final group in groups) {
      for (final item in group.items) {
        for (final set in item.wte.sets) {
          if (!set.completed) continue;
          final kg = set.values['KG'];
          if (kg == null) continue;
          final reps = (set.values['REPS'] ?? 0).round();
          if (best == null || kg > best.kg) {
            best = _ExercisePerformanceSnapshot(
              clientName: group.clientName,
              exerciseName: item.wte.exercise.name,
              setNumber: set.setNumber,
              volume: kg * (reps > 0 ? reps : 1),
              kg: kg,
              reps: reps,
            );
          }
        }
      }
    }
    if (best == null) return null;
    final repPart = best.reps > 0 ? ' • ${best.reps} reps' : '';
    final performer = includePerformer ? ' • ${best.clientName}' : '';
    return SocialPerformanceHighlight(
      label: 'Heaviest weight',
      value: '${best.kg.toStringAsFixed(0)} kg',
      detail: '${best.exerciseName}$repPart • Set ${best.setNumber}$performer',
    );
  }

  SocialPerformanceHighlight? _bestRepsHighlightForGroups(
    List<InstanceClientGroup> groups, {
    bool includePerformer = true,
  }) {
    _ExercisePerformanceSnapshot? best;
    for (final group in groups) {
      for (final item in group.items) {
        for (final set in item.wte.sets) {
          if (!set.completed) continue;
          final reps = set.values['REPS'];
          if (reps == null) continue;
          final repsInt = reps.round();
          final kg = set.values['KG'] ?? 0;
          if (best == null || repsInt > best.reps) {
            best = _ExercisePerformanceSnapshot(
              clientName: group.clientName,
              exerciseName: item.wte.exercise.name,
              setNumber: set.setNumber,
              volume: kg * repsInt,
              kg: kg,
              reps: repsInt,
            );
          }
        }
      }
    }
    if (best == null) return null;
    final weightPart = best.kg > 0 ? ' • ${best.kg.toStringAsFixed(0)} kg' : '';
    final performer = includePerformer ? ' • ${best.clientName}' : '';
    return SocialPerformanceHighlight(
      label: 'Best reps',
      value: '${best.reps} reps',
      detail:
          '${best.exerciseName}$weightPart • Set ${best.setNumber}$performer',
    );
  }

  int get _completedSetCountOverall =>
      _groups.fold<int>(0, (sum, group) => sum + _groupCompletedSets(group));

  int get _totalSetCountOverall =>
      _groups.fold<int>(0, (sum, group) => sum + _groupSetCount(group));

  double get _bestSetKgOverall => _groups.fold<double>(
        0,
        (best, group) =>
            _groupBestSetKg(group) > best ? _groupBestSetKg(group) : best,
      );

  int get _bestSetRepsOverall => _groups.fold<int>(
        0,
        (best, group) =>
            _groupBestSetReps(group) > best ? _groupBestSetReps(group) : best,
      );

  Future<void> _syncSocialPost() async {
    if (_session == null || !(_session!.isCompleted ?? false) || !mounted) {
      return;
    }

    final provider = context.read<SocialFeedProvider>();
    final auth = context.read<AuthProvider>();
    final completedAt = _session!.actualEndTime ?? _session!.endTime;
    final durationSeconds =
        (_session!.actualDuration ?? _session!.plannedDuration).inSeconds;
    final leaderboard = _leaderboard
        .take(3)
        .map(
          (entry) => SocialLeaderboardEntry(
            clientName: entry.clientName,
            totalWeightLifted: entry.totalWeightLifted,
          ),
        )
        .toList(growable: false);
    final overallVolumeHighlight = _bestVolumeHighlightForGroups(_groups);
    final overallHeaviestHighlight = _heaviestHighlightForGroups(_groups);
    final overallBestRepsHighlight = _bestRepsHighlightForGroups(_groups);

    if (auth.isClient) {
      if (_groups.isEmpty) return;
      final group = _groups.first;
      final rankIndex = _leaderboard.indexWhere(
        (entry) => entry.clientName == group.clientName,
      );
      await provider.addPost(
        SocialPost(
          id: 'session-${_session!.id}-client-${group.clientId ?? 'me'}',
          ownerRole: 'CLIENT',
          ownerClientId: group.clientId,
          ownerClientName: group.clientName,
          title: 'You completed a workout',
          workoutTitle: _session!.sessionName ?? 'Workout ${_session!.id}',
          trainerName: 'Your trainer',
          clientSummary: 'Personal performance recap',
          completedAt: completedAt,
          durationSeconds: durationSeconds,
          totalWeightLifted: _groupTotalWeightLifted(group),
          sessionTotalWeightLifted: _totalWeightLifted,
          exerciseCount: group.items.length,
          participantCount: 1,
          completedSetCount: _groupCompletedSets(group),
          totalSetCount: _groupSetCount(group),
          bestSetKg: _groupBestSetKg(group),
          bestSetReps: _groupBestSetReps(group),
          rank: rankIndex >= 0 ? rankIndex + 1 : null,
          leaderboard: const [],
          bestVolumeHighlight:
              _bestVolumeHighlightForGroups([group], includePerformer: false),
          heaviestHighlight:
              _heaviestHighlightForGroups([group], includePerformer: false),
          bestRepsHighlight:
              _bestRepsHighlightForGroups([group], includePerformer: false),
        ),
      );
      return;
    }

    await provider.addPost(
      SocialPost(
        id: 'session-${_session!.id}',
        ownerRole: 'TRAINER',
        title: 'Congratulations',
        workoutTitle: _session!.sessionName ?? 'Workout ${_session!.id}',
        trainerName: _trainerDisplayName(),
        clientSummary: _clientSummary(),
        completedAt: completedAt,
        durationSeconds: durationSeconds,
        totalWeightLifted: _totalWeightLifted,
        sessionTotalWeightLifted: _totalWeightLifted,
        exerciseCount:
            _groups.fold<int>(0, (sum, group) => sum + group.items.length),
        participantCount: _participantCount,
        completedSetCount: _completedSetCountOverall,
        totalSetCount: _totalSetCountOverall,
        bestSetKg: _bestSetKgOverall,
        bestSetReps: _bestSetRepsOverall,
        leaderboard: leaderboard,
        bestVolumeHighlight: overallVolumeHighlight,
        heaviestHighlight: overallHeaviestHighlight,
        bestRepsHighlight: overallBestRepsHighlight,
      ),
    );
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

  Future<void> _connectRealtime() async {
    await _realtimeSub?.cancel();
    await _realtime.connect(sessionId: widget.sessionId);
    _realtimeSub = _realtime.stream.listen(_handleRealtimeEvent);
  }

  void _handleRealtimeEvent(TrainingSessionRealtimeEvent event) async {
    if (!mounted) return;
    switch (event.type) {
      case 'SESSION_UPDATED':
        if (event.session != null) {
          _applySessionUpdate(TrainingSession.fromJson(event.session!));
          await _syncSocialPost();
        }
        break;
      case 'INSTANCE_UPDATED':
        if (event.instanceExercises != null) {
          final items = event.instanceExercises!
              .map(WorkoutInstanceExercise.fromJson)
              .toList();
          _buildItemList(items);
          _dirtyEx = false;
          if (mounted) {
            setState(() {});
          }
          await _syncActiveWorkoutNotification();
          await _syncSocialPost();
        }
        break;
    }
  }

  void _applySessionUpdate(TrainingSession updated) {
    _session = updated;
    _start = updated.start;
    _end = updated.end;
    _nameCtl.text = updated.sessionName ?? '';
    _dirtyMeta = false;

    _syncSessionTicker();

    if (mounted) {
      setState(() {});
    }
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
          clientName: ie.clientName ?? (_isSoloSession ? 'You' : 'Client'),
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
      } else {
        group.items[existingIndex] = candidate;
      }
    }

    for (final group in grouped.values) {
      group.items
          .sort((a, b) => a.wte.sequenceOrder.compareTo(b.wte.sequenceOrder));
    }

    _groups
      ..clear()
      ..addAll(grouped.values);

    _ensureGroupsInitialized();
  }

  void _ensureGroupsInitialized() {
    if (_session == null || _groups.isNotEmpty) return;

    if (_isSoloSession || _session!.clientIds.isEmpty) {
      _groups.add(
        InstanceClientGroup(
          workoutInstanceId: 0,
          clientId: null,
          clientName: 'You',
          items: [],
        ),
      );
      return;
    }

    for (var i = 0; i < _session!.clientIds.length; i++) {
      final clientId = _session!.clientIds[i];
      final clientName = i < _session!.clientNames.length
          ? _session!.clientNames[i]
          : 'Client ${i + 1}';
      _groups.add(
        InstanceClientGroup(
          workoutInstanceId: 0,
          clientId: clientId,
          clientName: clientName,
          items: [],
        ),
      );
    }
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
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(_session!.sessionName ?? 'Session ${_session!.id}'),
        actions: [
          if (!clientReadOnly)
            IconButton(icon: const Icon(Icons.edit), onPressed: _reorder),
          if (!clientReadOnly)
            Padding(
              padding: EdgeInsets.only(right: AppDensity.space(10)),
              child: Icon(
                _autoSaving
                    ? Icons.sync_rounded
                    : (_dirtyMeta || _dirtyEx)
                        ? Icons.cloud_upload_rounded
                        : Icons.cloud_done_rounded,
                color: const Color(0xFF2F80FF),
              ),
            ),
        ],
      ),
      floatingActionButton: clientReadOnly
          ? null
          : FloatingActionButton(
              onPressed: _addExercises,
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: _activeRestSecondsRemaining == null
          ? null
          : SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDensity.space(14),
                  0,
                  AppDensity.space(14),
                  AppDensity.space(10),
                ),
                child: Container(
                  padding: AppDensity.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2740),
                    borderRadius: AppDensity.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 18,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white),
                      SizedBox(width: AppDensity.space(10)),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _activeRestExerciseName == null
                                  ? 'Rest timer'
                                  : 'Rest for $_activeRestExerciseName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: AppDensity.space(2)),
                            Text(
                              _formatDuration(
                                Duration(seconds: _activeRestSecondsRemaining!),
                              ),
                              style: const TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _dismissRestTimer,
                        icon: const Icon(Icons.close_rounded),
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFF7F8FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            0,
            AppDensity.space(10),
            0,
            AppDensity.space(_activeRestSecondsRemaining == null ? 96 : 132),
          ),
          children: [
            _metaCard(isClient: isClient, clientReadOnly: clientReadOnly),
            SizedBox(height: AppDensity.space(10)),
            _activityCard(isClient: isClient),
            SizedBox(height: AppDensity.space(10)),
            if (!isClient && _groups.length > 1) ...[
              _leaderboardCard(),
              SizedBox(height: AppDensity.space(10)),
            ],
            ..._groups.map(
              (group) => _clientSection(
                group,
                isClient: isClient,
                clientReadOnly: clientReadOnly,
              ),
            ),
            SizedBox(height: AppDensity.space(44)),
          ],
        ),
      ),
    );
  }

  Widget _activityCard({required bool isClient}) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDensity.space(14)),
      decoration: _surfaceDecoration(),
      child: Padding(
        padding: AppDensity.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.timer_outlined),
                SizedBox(width: AppDensity.space(6)),
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
            SizedBox(height: AppDensity.space(10)),
            Wrap(
              spacing: AppDensity.space(10),
              runSpacing: AppDensity.space(10),
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
                  label: _isSoloSession ? 'Participant' : 'Clients',
                  value: '$_participantCount',
                ),
              ],
            ),
            SizedBox(height: AppDensity.space(10)),
            Wrap(
              spacing: AppDensity.space(10),
              runSpacing: AppDensity.space(10),
              children: [
                if (!_isActiveForCurrentSession)
                  ElevatedButton.icon(
                    onPressed: _busyAction ? null : _startWorkout,
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

  Widget _leaderboardCard() {
    final rows = _leaderboard;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDensity.space(14)),
      decoration: _surfaceDecoration(),
      child: Padding(
        padding: AppDensity.all(13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_outlined),
                SizedBox(width: AppDensity.space(6)),
                Text(
                  'Session leaderboard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            SizedBox(height: AppDensity.space(10)),
            ...rows.asMap().entries.map(
                  (entry) => Container(
                    margin: EdgeInsets.only(bottom: AppDensity.space(8)),
                    padding: AppDensity.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: entry.key == 0
                          ? const Color(0xFFEAF2FF)
                          : const Color(0xFFF7FAFF),
                      borderRadius: AppDensity.circular(12),
                      border: Border.all(
                        color: entry.key == 0
                            ? const Color(0xFFD0E3FF)
                            : const Color(0xFFE3ECFF),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: AppDensity.space(13),
                          backgroundColor: entry.key == 0
                              ? const Color(0xFF2F80FF)
                              : const Color(0xFFDCE8FF),
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: entry.key == 0
                                  ? Colors.white
                                  : Colors.grey.shade900,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        SizedBox(width: AppDensity.space(8)),
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
                                  fontSize: AppDensity.space(10.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.value.totalWeightLifted.toStringAsFixed(0)} kg',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: AppDensity.space(14),
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
      padding: AppDensity.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: AppDensity.circular(14),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Color(0xFF6F7691),
              fontSize: AppDensity.space(10.5),
            ),
          ),
          SizedBox(height: AppDensity.space(3)),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDensity.space(16),
              fontWeight: FontWeight.w700,
              color: Color(0xFF232530),
            ),
          ),
        ],
      ),
    );
  }

  /* ───────── meta card & date buttons ───────── */

  Widget _metaCard({required bool isClient, required bool clientReadOnly}) {
    final f = DateFormat('yyyy-MM-dd   HH:mm');
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppDensity.space(14)),
      decoration: _surfaceDecoration(),
      child: Padding(
        padding: AppDensity.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: AppDensity.space(40),
                  height: AppDensity.space(40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: AppDensity.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_note_rounded,
                    color: Color(0xFF2F80FF),
                  ),
                ),
                SizedBox(width: AppDensity.space(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Session details',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      SizedBox(height: AppDensity.space(2)),
                      Text(
                        'Manage the name and schedule for this workout instance.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6F7691),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppDensity.space(12)),
            TextFormField(
              controller: _nameCtl,
              decoration: InputDecoration(
                labelText: 'Name',
                filled: true,
                fillColor: const Color(0xFFF7FAFF),
                border: OutlineInputBorder(
                  borderRadius: AppDensity.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDensity.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDensity.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF2F80FF),
                    width: 1.4,
                  ),
                ),
              ),
              readOnly: clientReadOnly,
              onChanged: clientReadOnly ? null : (_) => setState(_markMetaDirty),
            ),
            SizedBox(height: AppDensity.space(12)),
            Row(
              children: [
                Expanded(
                  child: _dateTimeField(
                    label: 'Start',
                    value: _start!,
                    fmt: f,
                    icon: Icons.play_circle_outline,
                    enabled: !clientReadOnly,
                    onChanged: (d) => setState(() {
                      _start = d;
                      _markMetaDirty();
                    }),
                  ),
                ),
                SizedBox(width: AppDensity.space(6)),
                Expanded(
                  child: _dateTimeField(
                    label: 'End',
                    value: _end!,
                    fmt: f,
                    icon: Icons.flag_outlined,
                    enabled: !clientReadOnly,
                    onChanged: (d) => setState(() {
                      _end = d;
                      _markMetaDirty();
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
      borderRadius: AppDensity.circular(14),
      onTap: !enabled
          ? null
          : () async {
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
        padding: AppDensity.symmetric(horizontal: 11, vertical: 11),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAFF),
          borderRadius: AppDensity.circular(16),
          border: Border.all(color: const Color(0xFFDCE8FF)),
        ),
        child: Row(
          children: [
            Container(
              width: AppDensity.space(30),
              height: AppDensity.space(30),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: AppDensity.circular(10),
              ),
              child: Icon(icon, size: 18, color: const Color(0xFF2F80FF)),
            ),
            SizedBox(width: AppDensity.space(8)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Color(0xFF6F7691),
                      fontSize: AppDensity.space(10.5),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppDensity.space(3)),
                  Text(
                    fmt.format(value),
                    style: TextStyle(
                      fontSize: AppDensity.space(12.5),
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF232530),
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
      _markExercisesDirty();
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
          builder: (_, __) => ReorderInstanceExercisesPanel(
              initial: List.from(_groups.first.items)),
        ),
      ),
    );
    if (updated != null) {
      setState(() {
        for (final group in _groups) {
          final reordered = <InstanceItem>[];
          for (final updatedItem in updated) {
            final match = group.items
                .where((item) => item.wte.exercise.id == updatedItem.wte.exercise.id)
                .firstOrNull;
            if (match != null) {
              reordered.add(match);
            }
          }
          group.items
            ..clear()
            ..addAll(reordered);
          for (var i = 0; i < group.items.length; i++) {
            group.items[i].wte.sequenceOrder = i + 1;
          }
        }
        _markExercisesDirty();
      });
    }
  }

  /* ───────── save ───────── */

  Future<void> _saveAllInternal({required bool showFeedback}) async {
    final api = context.read<TrainingSessionsProvider>().api;
    final prov = context.read<WorkoutInstanceExercisesProvider>();

    if (_dirtyMeta) {
      final dto = _session!.toJson()
        ..addAll({
          'startTime': _start!.toIso8601String(),
          'endTime': _end!.toIso8601String(),
          'sessionName': _nameCtl.text.trim(),
        });
      _session = await api.update(id: _session!.id, dto: dto);
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
        sessionId: _session!.id,
        newList: groupedPayload,
      );
      _buildItemList(prov.items);
      _dirtyEx = false;
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

      final api = context.read<TrainingSessionsProvider>().api;
      final dto = _session!.toJson()
        ..addAll({
          'status': 'IN_PROGRESS',
          'isCompleted': false,
          'actualStartTime': startedAt.toIso8601String(),
          'actualEndTime': null,
        });
      _session = await api.update(id: _session!.id, dto: dto);

      _activeSnapshot = snapshot;
      await _syncActiveWorkoutNotification();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
      if (mounted) setState(() {});
    } catch (e) {
      await _activeWorkout.clear(widget.sessionId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start workout: $e')),
      );
    }
  }

  Future<void> _discardWorkout() async {
    setState(() => _busyAction = true);
    try {
      await _activeWorkout.clear(widget.sessionId);
      await _notifications.cancelActiveWorkout();
      _ticker?.cancel();
      _activeSnapshot = null;
      if (!mounted) return;

      if (_session != null) {
        final api = context.read<TrainingSessionsProvider>().api;
        final dto = _session!.toJson()
          ..addAll({
            'status': 'PLANNED',
            'isCompleted': false,
            'actualStartTime': null,
            'actualEndTime': null,
          });
        _session = await api.update(id: _session!.id, dto: dto);
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
      final totalLiftedAtCompletion = _totalWeightLifted;
      await _saveAllInternal(showFeedback: false);
      if (!mounted) return;

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
      _session = await api.update(id: _session!.id, dto: dto);
      _dirtyMeta = false;

      await _activeWorkout.clear(widget.sessionId);
      await _notifications.cancelActiveWorkout();
      _ticker?.cancel();
      _activeSnapshot = null;
      if (!mounted) return;
      await _syncSocialPost();

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
    if (_isSoloSession) return 'Personal workout recap';
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
    return Container(
      margin: EdgeInsets.fromLTRB(
        AppDensity.space(14),
        0,
        AppDensity.space(14),
        AppDensity.space(10),
      ),
      decoration: _surfaceDecoration(),
      child: Padding(
        padding: AppDensity.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isClient) ...[
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: const Color(0xFFEAF2FF),
                    child: Text(
                      _initials(group.clientName),
                      style: const TextStyle(
                        color: Color(0xFF2F80FF),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  SizedBox(width: AppDensity.space(8)),
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
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: AppDensity.space(14),
                        ),
                      ),
                      SizedBox(height: AppDensity.space(2)),
                      Text(
                        '${_groupCompletedSets(group)}/${_groupSetCount(group)} sets',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: AppDensity.space(10.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: AppDensity.space(6)),
            ],
            ...group.items.map(
              (it) => WorkoutTemplateExerciseWidget(
                key: ValueKey(
                  'inst-${group.workoutInstanceId}-${it.wte.exercise.id}-${it.wte.sequenceOrder}',
                ),
                templateId: _session!.id,
                wte: it.wte,
                showCompletion: true,
                canEditExerciseNotes: !clientReadOnly,
                canEditSetNotes: !clientReadOnly,
                isReadOnly: clientReadOnly,
                headerActions: [
                  IconButton(
                    tooltip: 'Exercise history',
                    onPressed: () => _openExerciseHistory(it),
                    icon: const Icon(
                      Icons.insights_rounded,
                      color: Color(0xFF2F80FF),
                    ),
                  ),
                ],
                onChanged: () {
                  setState(_markExercisesDirty);
                  _syncActiveWorkoutNotification();
                },
                onRestTimerChanged: () {
                  setState(_markExercisesDirty);
                },
                onCompletedSet: (restSeconds, exerciseName) {
                  if (restSeconds != null && restSeconds > 0) {
                    _startRestTimer(
                      exerciseName: exerciseName,
                      restSeconds: restSeconds,
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  BoxDecoration _surfaceDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: AppDensity.circular(24),
      border: Border.all(color: const Color(0xFFDCE8FF)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF2F80FF).withOpacity(0.06),
          blurRadius: 24,
          offset: const Offset(0, 12),
        ),
      ],
    );
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
        restSeconds: null,
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
        restSeconds: restSeconds,
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
                  stopwatchStartedAtMs: s.stopwatchStartedAtMs,
                  restStartedAtMs: s.restStartedAtMs,
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

class _ExercisePerformanceSnapshot {
  final String clientName;
  final String exerciseName;
  final int setNumber;
  final double volume;
  final double kg;
  final int reps;

  _ExercisePerformanceSnapshot({
    required this.clientName,
    required this.exerciseName,
    required this.setNumber,
    required this.volume,
    required this.kg,
    required this.reps,
  });
}
