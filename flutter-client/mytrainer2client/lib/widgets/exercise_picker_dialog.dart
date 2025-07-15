import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/exercises_provider.dart';
import '../models/exercise.dart';

class ExercisePickerDialog extends StatefulWidget {
  const ExercisePickerDialog({super.key});

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  final Set<Exercise> _selected = {};

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExercisesProvider>();
    return AlertDialog(
      title: const Text('Add Exercises'),
      content: SizedBox(
        width: 300,
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
