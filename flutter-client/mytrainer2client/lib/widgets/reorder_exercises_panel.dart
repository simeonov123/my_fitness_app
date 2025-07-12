// lib/widgets/reorder_exercises_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/workout_template_exercise.dart';
import '../providers/workout_templates_provider.dart';

/// Returns the updated List<WorkoutTemplateExercise> when done.
class ReorderExercisesPanel extends StatefulWidget {
  final int templateId;
  final List<WorkoutTemplateExercise> initial;

  const ReorderExercisesPanel({
    Key? key,
    required this.templateId,
    required this.initial,
  }) : super(key: key);

  @override
  State<ReorderExercisesPanel> createState() => _ReorderExercisesPanelState();
}

class _ReorderExercisesPanelState extends State<ReorderExercisesPanel> {
  late List<WorkoutTemplateExercise> _list;

  @override
  void initState() {
    super.initState();
    // Make a mutable copy
    _list = List.from(widget.initial);
    // Ensure initial numbering is correct
    _renumber();
  }

  void _renumber() {
    for (var i = 0; i < _list.length; i++) {
      _list[i].sequenceOrder = i + 1;
    }
  }

  void _onDone() {
    // Final renumber (just in case)
    _renumber();
    // Update provider
    context
        .read<WorkoutTemplatesProvider>()
        .updateExercisesOrder(widget.templateId, _list);
    // Pop and return updated list
    Navigator.of(context).pop(_list);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                t.reorder_exercises, // make sure this key exists
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.check), onPressed: _onDone),
            ],
          ),
          const Divider(),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _list.removeAt(oldIndex);
                  _list.insert(newIndex, item);
                  // **live** renumbering
                  _renumber();
                });
              },
              itemCount: _list.length,
              itemBuilder: (ctx, idx) {
                final wte = _list[idx];
                return ListTile(
                  key: ValueKey('wte-${wte.exercise.id}-$idx'),
                  leading: Text('${wte.sequenceOrder}.'),
                  title: Text(wte.exercise.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() {
                          _list.removeAt(idx);
                          _renumber();
                        }),
                      ),
                      ReorderableDragStartListener(
                        index: idx,
                        child: const Icon(Icons.drag_handle),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
