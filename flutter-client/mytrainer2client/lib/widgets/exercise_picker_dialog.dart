import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../providers/exercises_provider.dart';
import 'exercise_form_dialog.dart';

class ExercisePickerDialog extends StatefulWidget {
  const ExercisePickerDialog({super.key});

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  final Set<Exercise> _selected = {};

  Future<void> _createExercise() async {
    final created = await showDialog<Exercise>(
      context: context,
      builder: (_) => const ExerciseFormDialog(),
    );
    if (created == null || !mounted) return;
    setState(() => _selected.add(created));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExercisesProvider>();
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Add Exercises')),
          IconButton(
            tooltip: 'Create exercise',
            onPressed: _createExercise,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      content: SizedBox(
        width: 360,
        height: 420,
        child: prov.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: prov.search,
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: prov.list.length,
                      itemBuilder: (_, i) {
                        final ex = prov.list[i];
                        final selected = _selected.contains(ex);
                        return CheckboxListTile(
                          title: Text(ex.name),
                          subtitle: ex.description == null || ex.description!.isEmpty
                              ? Text(ex.isCustom ? 'Custom exercise' : 'Library exercise')
                              : Text(ex.description!),
                          value: selected,
                          onChanged: (chk) {
                            setState(() {
                              if (chk == true) {
                                _selected.add(ex);
                              } else {
                                _selected.remove(ex);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  if (!prov.loading && prov.list.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No exercises found. Create one to get started.'),
                    ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selected.isEmpty
              ? null
              : () => Navigator.pop(context, _selected.toList()),
          child: const Text('Add Selected'),
        ),
      ],
    );
  }
}
