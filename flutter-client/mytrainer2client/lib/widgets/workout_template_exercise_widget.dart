import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/workout_template_exercise.dart';
import '../models/workout_template_exercise_set.dart';
import '../l10n/app_localizations.dart';

class WorkoutTemplateExerciseWidget extends StatefulWidget {
  final int templateId;
  final WorkoutTemplateExercise wte;
  final VoidCallback onChanged;

  const WorkoutTemplateExerciseWidget({
    Key? key,
    required this.templateId,
    required this.wte,
    required this.onChanged,
  }) : super(key: key);

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
              Text(widget.wte.setType ?? '',
                  style: TextStyle(color: Colors.grey[600])),
            ]),
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
                  child:
                  Text(loc.delete, style: const TextStyle(color: Colors.white)),
                ),
                onDismissed: (_) => _removeSet(i),
                child: ListTile(
                  title: Text(loc.set_number(_localSets[i].setNumber.toString())),
                  subtitle: Row(
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
}
