import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_template_exercise.dart';
import '../models/workout_template_exercise_set.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_density.dart';

const _setContextOptions = <String>[
  'WARMUP',
  'FAILURE',
  'DROP',
  'FORCED',
];

class WorkoutTemplateExerciseWidget extends StatefulWidget {
  final int templateId;
  final WorkoutTemplateExercise wte;
  final VoidCallback onChanged;
  final VoidCallback? onRestTimerChanged;
  final void Function(int? restSeconds, String exerciseName)? onCompletedSet;
  final bool showCompletion;
  final bool canEditExerciseNotes;
  final bool canEditSetNotes;
  final bool isReadOnly;
  final List<Widget> headerActions;

  const WorkoutTemplateExerciseWidget({
    super.key,
    required this.templateId,
    required this.wte,
    required this.onChanged,
    this.onRestTimerChanged,
    this.onCompletedSet,
    this.showCompletion = false,
    this.canEditExerciseNotes = true,
    this.canEditSetNotes = true,
    this.isReadOnly = false,
    this.headerActions = const [],
  });

  @override
  State<WorkoutTemplateExerciseWidget> createState() =>
      _WorkoutTemplateExerciseWidgetState();
}

class _WorkoutTemplateExerciseWidgetState
    extends State<WorkoutTemplateExerciseWidget> {
  late List<WorkoutTemplateExerciseSet> _localSets;
  late List<int> _setIds;
  int _nextId = 0;
  Timer? _liveTicker;

  @override
  void initState() {
    super.initState();
    _localSets = widget.wte.sets.map((s) => s.copyWith()).toList();
    _setIds = List.generate(_localSets.length, (_) => _nextId++);
    _ensureLiveTicker();
  }

  @override
  void didUpdateWidget(covariant WorkoutTemplateExerciseWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFromWidget();
    _ensureLiveTicker();
  }

  void _syncFromWidget() {
    final incoming = widget.wte.sets.map((s) => s.copyWith()).toList();
    _localSets = incoming;
    if (_setIds.length != _localSets.length) {
      _setIds = List.generate(_localSets.length, (_) => _nextId++);
    }
  }

  bool get _hasLiveState =>
      _localSets.any((set) => set.stopwatchStartedAtMs != null || set.restStartedAtMs != null);

  void _ensureLiveTicker() {
    if (_hasLiveState) {
      _liveTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    } else {
      _liveTicker?.cancel();
      _liveTicker = null;
    }
  }

  void _notifyChanged() {
    widget.wte.sets = List.from(_localSets);
    _ensureLiveTicker();
    widget.onChanged();
  }

  @override
  void dispose() {
    _liveTicker?.cancel();
    super.dispose();
  }

  void _addSet() {
    final defaults = <String, double>{
      for (var k in widget.wte.paramKeys) k: 0.0
    };
    setState(() {
      final newSet = WorkoutTemplateExerciseSet(
        id: 0,
        workoutExerciseId: widget.wte.id,
        setNumber: _localSets.length + 1,
        completed: false,
        values: defaults,
      );
      _localSets.add(newSet);
      _setIds.add(_nextId++);
    });
    _notifyChanged();
  }

  void _removeSet(int idx) {
    setState(() {
      _localSets.removeAt(idx);
      _setIds.removeAt(idx);
      for (var i = 0; i < _localSets.length; i++) {
        _localSets[i].setNumber = i + 1;
      }
    });
    _notifyChanged();
  }

  Future<void> _pickSetContext(int index) async {
    final selected = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Normal set'),
              onTap: () => Navigator.pop(ctx, null),
            ),
            for (final option in _setContextOptions)
              ListTile(
                leading: _contextChip(option),
                title: Text(_contextMenuLabel(option)),
                onTap: () => Navigator.pop(ctx, option),
              ),
          ],
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _localSets[index].setContextType = selected;
    });
    _notifyChanged();
  }

  Future<void> _editExerciseNote() async {
    final next = await _showNoteEditor(
      title: '${widget.wte.exercise.name} note',
      initialValue: widget.wte.notes ?? '',
    );
    if (next == null || !mounted) return;
    setState(() {
      widget.wte.notes = next.trim().isEmpty ? '' : next.trim();
    });
    widget.onChanged();
  }

  Future<void> _editSetNote(int index) async {
    final next = await _showNoteEditor(
      title: 'Set ${_localSets[index].setNumber} note',
      initialValue: _localSets[index].notes ?? '',
    );
    if (next == null || !mounted) return;
    setState(() {
      _localSets[index].notes = next.trim().isEmpty ? null : next.trim();
    });
    _notifyChanged();
  }

  void _toggleStopwatchForSet(int index) {
    final startedAtMs = _localSets[index].stopwatchStartedAtMs;
    if (startedAtMs != null) {
      final elapsedMs = DateTime.now().millisecondsSinceEpoch - startedAtMs;
      final minutes = elapsedMs / Duration.millisecondsPerMinute;
      final rounded = double.parse(minutes.toStringAsFixed(2));
      setState(() {
        _localSets[index].values['TIME'] = rounded;
        _localSets[index].stopwatchStartedAtMs = null;
      });
      _notifyChanged();
      return;
    }

    setState(() {
      _localSets[index].stopwatchStartedAtMs =
          DateTime.now().millisecondsSinceEpoch;
    });
    _notifyChanged();
  }

  String? _liveStopwatchLabel(WorkoutTemplateExerciseSet set) {
    final startedAtMs = set.stopwatchStartedAtMs;
    if (startedAtMs == null) return null;
    final elapsed = Duration(
      milliseconds: DateTime.now().millisecondsSinceEpoch - startedAtMs,
    );
    final mins = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  int? _restSecondsRemaining(WorkoutTemplateExerciseSet set) {
    final startedAtMs = set.restStartedAtMs;
    final restSeconds = widget.wte.restSeconds;
    if (startedAtMs == null || restSeconds == null || restSeconds <= 0) {
      return null;
    }
    final elapsedSeconds =
        ((DateTime.now().millisecondsSinceEpoch - startedAtMs) / 1000).floor();
    final remaining = restSeconds - elapsedSeconds;
    if (remaining <= 0) {
      if (set.restStartedAtMs != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || set.restStartedAtMs == null) return;
          setState(() {
            set.restStartedAtMs = null;
          });
          _notifyChanged();
        });
      }
      return 0;
    }
    return remaining;
  }

  Future<void> _editRestTimer() async {
    final controller = TextEditingController(
      text: widget.wte.restSeconds?.toString() ?? '',
    );
    const presets = <int>[30, 45, 60, 90, 120, 180];
    final next = await showModalBottomSheet<int?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDensity.space(14),
          right: AppDensity.space(14),
          top: AppDensity.space(14),
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDensity.space(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.wte.exercise.name} rest timer',
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            SizedBox(height: AppDensity.space(10)),
            Wrap(
              spacing: AppDensity.space(8),
              runSpacing: AppDensity.space(8),
              children: [
                for (final seconds in presets)
                  ActionChip(
                    label: Text('${seconds}s'),
                    onPressed: () => Navigator.pop(ctx, seconds),
                  ),
              ],
            ),
            SizedBox(height: AppDensity.space(10)),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Custom seconds',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppDensity.space(10)),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, 0),
                  child: const Text('Clear'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: AppDensity.space(8)),
                FilledButton(
                  onPressed: () => Navigator.pop(
                    ctx,
                    int.tryParse(controller.text.trim()),
                  ),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    if (next == null || !mounted) return;
    setState(() {
      widget.wte.restSeconds = next <= 0 ? null : next;
    });
    widget.onRestTimerChanged?.call();
    widget.onChanged();
  }

  Future<String?> _showNoteEditor({
    required String title,
    required String initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue);
    return showModalBottomSheet<String?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppDensity.space(14),
          right: AppDensity.space(14),
          top: AppDensity.space(14),
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppDensity.space(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            SizedBox(height: AppDensity.space(10)),
            TextField(
              controller: controller,
              maxLines: 4,
              minLines: 3,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Add a pinned note',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: AppDensity.space(10)),
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, ''),
                  child: const Text('Clear'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                SizedBox(width: AppDensity.space(8)),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, controller.text),
                  child: const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    const accent = Color(0xFF2F80FF);
    return Container(
      margin: AppDensity.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDensity.circular(24),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.06),
            blurRadius: AppDensity.space(20),
            offset: Offset(0, AppDensity.space(10)),
          ),
        ],
      ),
      child: Padding(
        padding: AppDensity.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: AppDensity.space(38),
                  height: AppDensity.space(38),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: AppDensity.circular(12),
                  ),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: Color(0xFF2F80FF),
                    size: AppDensity.icon(18),
                  ),
                ),
                SizedBox(width: AppDensity.space(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.wte.exercise.name,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF232530),
                        ),
                      ),
                      if ((widget.wte.setType ?? '').trim().isNotEmpty) ...[
                        SizedBox(height: AppDensity.space(4)),
                        Container(
                          padding: AppDensity.symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF4F8FF),
                            borderRadius: AppDensity.circular(999),
                          ),
                          child: Text(
                            widget.wte.setType!,
                            style: const TextStyle(
                              color: Color(0xFF45608D),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.headerActions.isNotEmpty ||
                    widget.canEditExerciseNotes ||
                    !widget.isReadOnly)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ...widget.headerActions,
                      if (!widget.isReadOnly)
                        IconButton(
                          tooltip: widget.wte.restSeconds != null
                              ? 'Rest ${widget.wte.restSeconds}s'
                              : 'Set rest timer',
                          onPressed: _editRestTimer,
                          icon: Icon(
                            Icons.timer_outlined,
                            color: widget.wte.restSeconds != null
                                ? const Color(0xFF2F80FF)
                                : Colors.grey[600],
                          ),
                        ),
                      if (widget.canEditExerciseNotes)
                        IconButton(
                          tooltip: widget.wte.notes?.trim().isNotEmpty == true
                              ? 'Edit pinned note'
                              : 'Add pinned note',
                          onPressed: _editExerciseNote,
                          icon: Icon(
                            Icons.push_pin_outlined,
                            color: widget.wte.notes?.trim().isNotEmpty == true
                                ? const Color(0xFF2F80FF)
                                : Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
              ],
            ),
            if (widget.wte.notes?.trim().isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                margin: EdgeInsets.only(
                  top: AppDensity.space(6),
                  bottom: AppDensity.space(10),
                ),
                padding: AppDensity.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: AppDensity.circular(12),
                  border: Border.all(color: const Color(0xFFDCE8FF)),
                ),
                child: Text(
                  widget.wte.notes!.trim(),
                  style: const TextStyle(
                    color: Color(0xFF3E4A67),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (widget.wte.restSeconds != null) ...[
              Container(
                margin: EdgeInsets.only(bottom: AppDensity.space(10)),
                padding: AppDensity.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF7FF),
                  borderRadius: AppDensity.circular(999),
                  border: Border.all(color: const Color(0xFFDCE8FF)),
                ),
                child: Text(
                  'Rest ${widget.wte.restSeconds}s',
                  style: const TextStyle(
                    color: Color(0xFF45608D),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
            Container(
              width: double.infinity,
              padding: AppDensity.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FBFF),
                borderRadius: AppDensity.circular(18),
                border: Border.all(color: const Color(0xFFDCE8FF)),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < _localSets.length; i++) ...[
                    Dismissible(
                      key: ValueKey(_setIds[i]),
                      direction: widget.isReadOnly
                          ? DismissDirection.none
                          : DismissDirection.endToStart,
                      background: Container(
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        child: Text(
                          loc.delete,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      onDismissed:
                          widget.isReadOnly ? null : (_) => _removeSet(i),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color:
                              widget.showCompletion && _localSets[i].completed
                                  ? const Color(0xFFEFF7FF)
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color:
                                widget.showCompletion && _localSets[i].completed
                                    ? const Color(0xFF9CC8FF)
                                    : const Color(0xFFDCE8FF),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    loc.set_number(
                                        _localSets[i].setNumber.toString()),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      decoration: widget.showCompletion &&
                                              _localSets[i].completed
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (widget.canEditSetNotes)
                                  IconButton(
                                    onPressed: widget.isReadOnly
                                        ? null
                                        : () => _editSetNote(i),
                                    visualDensity: VisualDensity.compact,
                                    iconSize: 18,
                                    splashRadius: 18,
                                    icon: Icon(
                                      Icons.push_pin_outlined,
                                      color: _localSets[i]
                                                  .notes
                                                  ?.trim()
                                                  .isNotEmpty ==
                                              true
                                          ? const Color(0xFF2F80FF)
                                          : Colors.grey[600],
                                    ),
                                  ),
                                if (widget.showCompletion)
                                  Checkbox(
                                    value: _localSets[i].completed,
                                    visualDensity: VisualDensity.compact,
                                    onChanged: widget.isReadOnly
                                        ? null
                                        : (value) {
                                            final wasCompleted =
                                                _localSets[i].completed;
                                            setState(() {
                                              _localSets[i].completed =
                                                  value ?? false;
                                              _localSets[i].restStartedAtMs =
                                                  (value ?? false) &&
                                                          widget.wte.restSeconds !=
                                                              null &&
                                                          widget.wte.restSeconds! >
                                                              0
                                                      ? DateTime.now()
                                                          .millisecondsSinceEpoch
                                                      : null;
                                            });
                                            _notifyChanged();
                                            if (!wasCompleted &&
                                                (value ?? false)) {
                                              widget.onCompletedSet?.call(
                                                widget.wte.restSeconds,
                                                widget.wte.exercise.name,
                                              );
                                            }
                                          },
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (_localSets[i].notes?.trim().isNotEmpty == true)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F8FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: const Color(0xFFDCE8FF)),
                                ),
                                child: Text(
                                  _localSets[i].notes!.trim(),
                                  style: const TextStyle(
                                    color: Color(0xFF3E4A67),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            if (_restSecondsRemaining(_localSets[i]) != null)
                              Container(
                                width: double.infinity,
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEAF2FF),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFDCE8FF),
                                  ),
                                ),
                                child: Text(
                                  'Rest ${_restSecondsRemaining(_localSets[i])}s',
                                  style: const TextStyle(
                                    color: Color(0xFF2F80FF),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            Row(
                              children: [
                                InkWell(
                                  onTap: widget.isReadOnly
                                      ? null
                                      : () => _pickSetContext(i),
                                  borderRadius: BorderRadius.circular(999),
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 10),
                                    child: _contextChip(
                                        _localSets[i].setContextType),
                                  ),
                                ),
                                for (var key in widget.wte.paramKeys)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: _SetValueField(
                                        value: _formatFieldValue(
                                          key,
                                          _localSets[i].values[key],
                                        ),
                                        paramCode: key,
                                        stopwatchLabel: key == 'TIME'
                                            ? _liveStopwatchLabel(_localSets[i])
                                            : null,
                                        labelText: _label(key, loc),
                                        readOnly: widget.isReadOnly,
                                        onStopwatchTap: key == 'TIME' &&
                                                !widget.isReadOnly
                                            ? () => _toggleStopwatchForSet(i)
                                            : null,
                                        onChanged: widget.isReadOnly
                                            ? null
                                            : (s) {
                                                _localSets[i].values[key] =
                                                    double.tryParse(s) ?? 0.0;
                                                _notifyChanged();
                                              },
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (i != _localSets.length - 1) const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: widget.isReadOnly ? null : _addSet,
                      icon: const Icon(Icons.add),
                      label: Text(loc.add_set),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2F80FF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _label(String code, AppLocalizations l) {
    switch (code) {
      case 'KG':
        return l.kg;
      case 'REPS':
        return l.reps;
      case 'TIME':
        return l.time;
      case 'KM':
        return l.km;
      default:
        return code;
    }
  }

  String? _formatFieldValue(String code, double? value) {
    if (value == null) return null;
    final allowDecimals = code == 'TIME' || code == 'KG' || code == 'KM';
    if (!allowDecimals) {
      return value.toStringAsFixed(0);
    }
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  }

  String _contextMenuLabel(String type) {
    switch (type) {
      case 'WARMUP':
        return 'Warmup';
      case 'FAILURE':
        return 'Failure';
      case 'DROP':
        return 'Drop set';
      case 'FORCED':
        return 'Forced set';
      default:
        return type;
    }
  }

  Widget _contextChip(String? type) {
    final (Color bg, Color fg, String text) = switch (type) {
      'WARMUP' => (const Color(0xFFEAF2FF), const Color(0xFF2F80FF), 'WU'),
      'FAILURE' => (const Color(0xFFE8F1FF), const Color(0xFF2B5FB8), 'F'),
      'DROP' => (const Color(0xFFF2F7FF), const Color(0xFF4B74C9), 'DS'),
      'FORCED' => (const Color(0xFFF4F8FF), const Color(0xFF5A6CCF), 'FS'),
      _ => (const Color(0xFFEFF4FF), const Color(0xFF5A6B8F), '+'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SetValueField extends StatefulWidget {
  const _SetValueField({
    required this.value,
    required this.paramCode,
    required this.stopwatchLabel,
    required this.labelText,
    required this.readOnly,
    required this.onStopwatchTap,
    required this.onChanged,
  });

  final String? value;
  final String paramCode;
  final String? stopwatchLabel;
  final String labelText;
  final bool readOnly;
  final VoidCallback? onStopwatchTap;
  final ValueChanged<String>? onChanged;

  @override
  State<_SetValueField> createState() => _SetValueFieldState();
}

class _SetValueFieldState extends State<_SetValueField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value ?? '');
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant _SetValueField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final nextText = widget.value ?? '';
    if (_controller.text != nextText &&
        !_focusNode.hasFocus &&
        widget.stopwatchLabel == null) {
      _controller.text = nextText;
    }
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus && _controller.text.isNotEmpty) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChange)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  bool get _showStopwatch => widget.paramCode == 'TIME';

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      focusNode: _focusNode,
      decoration: InputDecoration(
        labelText: widget.labelText,
        helperText: _showStopwatch ? widget.stopwatchLabel : null,
        filled: true,
        fillColor: const Color(0xFFF7FAFF),
        suffixIcon: _showStopwatch
            ? IconButton(
                onPressed: widget.readOnly ? null : widget.onStopwatchTap,
                icon: Icon(
                  widget.stopwatchLabel != null
                      ? Icons.stop_circle_outlined
                      : Icons.timer_outlined,
                ),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDCE8FF),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFFDCE8FF),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(
            color: Color(0xFF2F80FF),
            width: 1.3,
          ),
        ),
      ),
      readOnly: widget.readOnly,
      keyboardType: TextInputType.number,
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
      ],
      onTap: () {
        if (_controller.text.isNotEmpty) {
          _controller.selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controller.text.length,
          );
        }
      },
      onChanged: widget.onChanged,
    );
  }
}
