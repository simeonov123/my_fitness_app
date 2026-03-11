import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_template_exercise.dart';
import '../models/workout_template_exercise_set.dart';
import '../l10n/app_localizations.dart';

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
  final bool showCompletion;

  const WorkoutTemplateExerciseWidget({
    super.key,
    required this.templateId,
    required this.wte,
    required this.onChanged,
    this.showCompletion = false,
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

  @override
  void initState() {
    super.initState();
    _localSets = widget.wte.sets.map((s) => s.copyWith()).toList();
    _setIds = List.generate(_localSets.length, (_) => _nextId++);
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
    widget.wte.sets = List.from(_localSets);
    widget.onChanged();
  }

  void _removeSet(int idx) {
    setState(() {
      _localSets.removeAt(idx);
      _setIds.removeAt(idx);
      for (var i = 0; i < _localSets.length; i++) {
        _localSets[i].setNumber = i + 1;
      }
    });
    widget.wte.sets = List.from(_localSets);
    widget.onChanged();
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
                title: Text(_contextLabel(option)),
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
    widget.wte.sets = List.from(_localSets);
    widget.onChanged();
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
    widget.wte.sets = List.from(_localSets);
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
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(ctx).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
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
            const SizedBox(height: 12),
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
                const SizedBox(width: 8),
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
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // header
            Row(children: [
              Expanded(child: Text(widget.wte.exercise.name)),
              IconButton(
                tooltip: widget.wte.notes?.trim().isNotEmpty == true
                    ? 'Edit pinned note'
                    : 'Add pinned note',
                onPressed: _editExerciseNote,
                icon: Icon(
                  Icons.push_pin_outlined,
                  color: widget.wte.notes?.trim().isNotEmpty == true
                      ? const Color(0xFFEF6C00)
                      : Colors.grey[600],
                ),
              ),
              Text(widget.wte.setType ?? '',
                  style: TextStyle(color: Colors.grey[600])),
            ]),
            if (widget.wte.notes?.trim().isNotEmpty == true) ...[
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFCC80)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.push_pin,
                        size: 16,
                        color: Color(0xFFEF6C00),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.wte.notes!.trim(),
                        style: const TextStyle(
                          color: Color(0xFF7A4A00),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),

            // each set row
            for (var i = 0; i < _localSets.length; i++)
              Dismissible(
                key: ValueKey(_setIds[i]),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 16),
                  child: Text(loc.delete,
                      style: const TextStyle(color: Colors.white)),
                ),
                onDismissed: (_) => _removeSet(i),
                child: ListTile(
                  leading: widget.showCompletion
                      ? Checkbox(
                          value: _localSets[i].completed,
                          onChanged: (value) {
                            setState(() {
                              _localSets[i].completed = value ?? false;
                            });
                            widget.wte.sets = List.from(_localSets);
                            widget.onChanged();
                          },
                        )
                      : null,
                  title: Text(
                    loc.set_number(_localSets[i].setNumber.toString()),
                    style: TextStyle(
                      decoration: widget.showCompletion &&
                              _localSets[i].completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _pickSetContext(i),
                        icon: _contextChip(_localSets[i].setContextType),
                        label: Text(
                          _localSets[i].setContextType == null
                              ? 'Set marker'
                              : _contextLabel(_localSets[i].setContextType!),
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () => _editSetNote(i),
                        icon: Icon(
                          Icons.push_pin_outlined,
                          color: _localSets[i].notes?.trim().isNotEmpty == true
                              ? const Color(0xFFEF6C00)
                              : Colors.grey[600],
                          size: 18,
                        ),
                        label: Text(
                          _localSets[i].notes?.trim().isNotEmpty == true
                              ? 'Edit set note'
                              : 'Add set note',
                        ),
                      ),
                      if (_localSets[i].notes?.trim().isNotEmpty == true)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF8E1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFFFE082)),
                          ),
                          child: Text(
                            _localSets[i].notes!.trim(),
                            style: const TextStyle(
                              color: Color(0xFF7A4A00),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Row(
                        children: [
                          for (var key in widget.wte.paramKeys)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: TextFormField(
                                  initialValue:
                                      _localSets[i].values[key]?.toStringAsFixed(0),
                                  decoration:
                                      InputDecoration(labelText: _label(key, loc)),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly
                                  ],
                                  onChanged: (s) {
                                    _localSets[i].values[key] =
                                        double.tryParse(s) ?? 0.0;
                                    widget.wte.sets = List.from(_localSets);
                                    widget.onChanged();
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

            // add button
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _addSet,
                icon: const Icon(Icons.add),
                label: Text(loc.add_set),
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

  String _contextLabel(String type) {
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
      'WARMUP' => (const Color(0xFFE3F2FD), const Color(0xFF1565C0), 'WU'),
      'FAILURE' => (const Color(0xFFFFEBEE), const Color(0xFFC62828), 'F'),
      'DROP' => (const Color(0xFFFFF3E0), const Color(0xFFEF6C00), 'DS'),
      'FORCED' => (const Color(0xFFF3E5F5), const Color(0xFF6A1B9A), 'FS'),
      _ => (const Color(0xFFEEEEEE), const Color(0xFF616161), '+'),
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
