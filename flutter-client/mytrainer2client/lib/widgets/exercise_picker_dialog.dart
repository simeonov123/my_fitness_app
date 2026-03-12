import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../providers/exercises_provider.dart';
import '../providers/muscle_groups_provider.dart';
import 'exercise_form_dialog.dart';

class ExerciseTargetOption {
  final int? clientId;
  final String clientName;

  const ExerciseTargetOption({
    required this.clientId,
    required this.clientName,
  });
}

class TargetedExercisePickerResult {
  final List<Exercise> exercises;
  final bool applyToAllClients;
  final Set<int> clientIds;

  const TargetedExercisePickerResult({
    required this.exercises,
    required this.applyToAllClients,
    required this.clientIds,
  });
}

class ExercisePickerDialog extends StatefulWidget {
  const ExercisePickerDialog({super.key});

  @override
  State<ExercisePickerDialog> createState() => _ExercisePickerDialogState();
}

class TargetedExercisePickerDialog extends StatefulWidget {
  const TargetedExercisePickerDialog({
    super.key,
    required this.clients,
  });

  final List<ExerciseTargetOption> clients;

  @override
  State<TargetedExercisePickerDialog> createState() =>
      _TargetedExercisePickerDialogState();
}

class _TargetedExercisePickerDialogState
    extends State<TargetedExercisePickerDialog> {
  final Set<Exercise> _selectedExercises = {};
  final Set<int> _selectedClientIds = <int>{};
  MuscleGroup? _selectedMuscleGroup;
  bool _applyToAllClients = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MuscleGroupsProvider>();
      if (!provider.loading && provider.items.isEmpty) {
        provider.load();
      }
    });
  }

  Future<void> _createExercise() async {
    final created = await showDialog<Exercise>(
      context: context,
      builder: (_) => const ExerciseFormDialog(),
    );
    if (created == null || !mounted) return;
    setState(() => _selectedExercises.add(created));
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ExercisesProvider>();
    final muscleGroupsProvider = context.watch<MuscleGroupsProvider>();
    final visibleExercises = prov.list.where((exercise) {
      final selectedGroup = _selectedMuscleGroup;
      if (selectedGroup == null) return true;
      return exercise.muscleGroups.any((group) => group.id == selectedGroup.id);
    }).toList(growable: false);

    final canSubmit = _selectedExercises.isNotEmpty &&
        (_applyToAllClients || _selectedClientIds.isNotEmpty);

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
        width: 420,
        height: 520,
        child: prov.loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add To',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All clients'),
                        selected: _applyToAllClients,
                        onSelected: (_) {
                          setState(() {
                            _applyToAllClients = true;
                            _selectedClientIds.clear();
                          });
                        },
                      ),
                      ...widget.clients.map(
                        (client) => FilterChip(
                          label: Text(client.clientName),
                          selected:
                              !_applyToAllClients &&
                              client.clientId != null &&
                              _selectedClientIds.contains(client.clientId),
                          onSelected: client.clientId == null
                              ? null
                              : (selected) {
                                  setState(() {
                                    _applyToAllClients = false;
                                    if (selected) {
                                      _selectedClientIds.add(client.clientId!);
                                    } else {
                                      _selectedClientIds.remove(client.clientId);
                                    }
                                  });
                                },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: prov.search,
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedMuscleGroup == null,
                          onSelected: (_) {
                            setState(() => _selectedMuscleGroup = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...muscleGroupsProvider.items.map(
                          (group) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(group.name),
                              selected: _selectedMuscleGroup?.id == group.id,
                              onSelected: (_) {
                                setState(() {
                                  _selectedMuscleGroup =
                                      _selectedMuscleGroup?.id == group.id
                                          ? null
                                          : group;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visibleExercises.length,
                      itemBuilder: (_, i) {
                        final ex = visibleExercises[i];
                        final selected = _selectedExercises.contains(ex);
                        return CheckboxListTile(
                          title: Text(ex.name),
                          subtitle: Text(
                            [
                              if (ex.description != null && ex.description!.isNotEmpty)
                                ex.description!,
                              if (ex.muscleGroups.isNotEmpty)
                                ex.muscleGroups.map((g) => g.name).join(', ')
                              else if (ex.isCustom)
                                'Custom exercise'
                              else
                                'Library exercise',
                            ].join('\n'),
                          ),
                          value: selected,
                          onChanged: (chk) {
                            setState(() {
                              if (chk == true) {
                                _selectedExercises.add(ex);
                              } else {
                                _selectedExercises.remove(ex);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  if (!prov.loading && visibleExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No exercises found for the current search/filter.'),
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
          onPressed: !canSubmit
              ? null
              : () => Navigator.pop(
                    context,
                    TargetedExercisePickerResult(
                      exercises: _selectedExercises.toList(growable: false),
                      applyToAllClients: _applyToAllClients,
                      clientIds: Set<int>.from(_selectedClientIds),
                    ),
                  ),
          child: const Text('Add Selected'),
        ),
      ],
    );
  }
}

class _ExercisePickerDialogState extends State<ExercisePickerDialog> {
  final Set<Exercise> _selected = {};
  MuscleGroup? _selectedMuscleGroup;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MuscleGroupsProvider>();
      if (!provider.loading && provider.items.isEmpty) {
        provider.load();
      }
    });
  }

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
    final muscleGroupsProvider = context.watch<MuscleGroupsProvider>();
    final visibleExercises = prov.list.where((exercise) {
      final selectedGroup = _selectedMuscleGroup;
      if (selectedGroup == null) return true;
      return exercise.muscleGroups.any((group) => group.id == selectedGroup.id);
    }).toList(growable: false);
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _selectedMuscleGroup == null,
                          onSelected: (_) {
                            setState(() => _selectedMuscleGroup = null);
                          },
                        ),
                        const SizedBox(width: 8),
                        ...muscleGroupsProvider.items.map(
                          (group) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(group.name),
                              selected: _selectedMuscleGroup?.id == group.id,
                              onSelected: (_) {
                                setState(() {
                                  _selectedMuscleGroup =
                                      _selectedMuscleGroup?.id == group.id
                                          ? null
                                          : group;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: visibleExercises.length,
                      itemBuilder: (_, i) {
                        final ex = visibleExercises[i];
                        final selected = _selected.contains(ex);
                        return CheckboxListTile(
                          title: Text(ex.name),
                          subtitle: Text(
                            [
                              if (ex.description != null && ex.description!.isNotEmpty)
                                ex.description!,
                              if (ex.muscleGroups.isNotEmpty)
                                ex.muscleGroups.map((g) => g.name).join(', ')
                              else if (ex.isCustom)
                                'Custom exercise'
                              else
                                'Library exercise',
                            ].join('\n'),
                          ),
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
                  if (!prov.loading && visibleExercises.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text('No exercises found for the current search/filter.'),
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
