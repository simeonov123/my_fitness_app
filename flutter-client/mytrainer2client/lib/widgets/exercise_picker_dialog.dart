import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/exercise.dart';
import '../models/muscle_group.dart';
import '../providers/exercises_provider.dart';
import '../providers/muscle_groups_provider.dart';
import '../theme/app_density.dart';
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

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDensity.symmetric(horizontal: 14, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: _PickerShell(
          title: 'Add exercises',
          subtitle:
              'Choose exercises, filter by muscle group, and target the right clients.',
          onCreateExercise: _createExercise,
          child: prov.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add to',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    SizedBox(height: AppDensity.space(6)),
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
                            selected: !_applyToAllClients &&
                                client.clientId != null &&
                                _selectedClientIds.contains(client.clientId),
                            onSelected: client.clientId == null
                                ? null
                                : (selected) {
                                    setState(() {
                                      _applyToAllClients = false;
                                      if (selected) {
                                        _selectedClientIds
                                            .add(client.clientId!);
                                      } else {
                                        _selectedClientIds
                                            .remove(client.clientId);
                                      }
                                    });
                                  },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppDensity.space(10)),
                    TextField(
                      decoration: _searchDecoration(),
                      onChanged: prov.search,
                    ),
                    SizedBox(height: AppDensity.space(6)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedMuscleGroup == null,
                            onSelected: (_) =>
                                setState(() => _selectedMuscleGroup = null),
                          ),
                          SizedBox(width: AppDensity.space(6)),
                          ...muscleGroupsProvider.items.map(
                            (group) => Padding(
                              padding: EdgeInsets.only(
                                right: AppDensity.space(6),
                              ),
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
                    SizedBox(height: AppDensity.space(8)),
                    Expanded(
                      child: visibleExercises.isEmpty
                          ? const Center(
                              child: Text(
                                  'No exercises found for the current search/filter.'),
                            )
                          : ListView.builder(
                              itemCount: visibleExercises.length,
                              itemBuilder: (_, i) {
                                final ex = visibleExercises[i];
                                final selected =
                                    _selectedExercises.contains(ex);
                                return _ExerciseTile(
                                  exercise: ex,
                                  selected: selected,
                                  onChanged: (chk) {
                                    setState(() {
                                      if (chk) {
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
                    SizedBox(height: AppDensity.space(12)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: AppDensity.space(8)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !canSubmit
                                ? null
                                : () => Navigator.pop(
                                      context,
                                      TargetedExercisePickerResult(
                                        exercises: _selectedExercises.toList(
                                            growable: false),
                                        applyToAllClients: _applyToAllClients,
                                        clientIds:
                                            Set<int>.from(_selectedClientIds),
                                      ),
                                    ),
                            child: const Text('Add selected'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDensity.symmetric(horizontal: 14, vertical: 18),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: _PickerShell(
          title: 'Add exercises',
          subtitle:
              'Search the library, filter by muscle group, or create a new exercise.',
          onCreateExercise: _createExercise,
          child: prov.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: _searchDecoration(),
                      onChanged: prov.search,
                    ),
                    SizedBox(height: AppDensity.space(6)),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: const Text('All'),
                            selected: _selectedMuscleGroup == null,
                            onSelected: (_) =>
                                setState(() => _selectedMuscleGroup = null),
                          ),
                          SizedBox(width: AppDensity.space(6)),
                          ...muscleGroupsProvider.items.map(
                            (group) => Padding(
                              padding: EdgeInsets.only(
                                right: AppDensity.space(6),
                              ),
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
                    SizedBox(height: AppDensity.space(8)),
                    Expanded(
                      child: visibleExercises.isEmpty
                          ? const Center(
                              child: Text(
                                  'No exercises found for the current search/filter.'),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: visibleExercises.length,
                              itemBuilder: (_, i) {
                                final ex = visibleExercises[i];
                                final selected = _selected.contains(ex);
                                return _ExerciseTile(
                                  exercise: ex,
                                  selected: selected,
                                  onChanged: (chk) {
                                    setState(() {
                                      if (chk) {
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
                    SizedBox(height: AppDensity.space(12)),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: AppDensity.space(8)),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _selected.isEmpty
                                ? null
                                : () =>
                                    Navigator.pop(context, _selected.toList()),
                            child: const Text('Add selected'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

InputDecoration _searchDecoration() {
  return InputDecoration(
    hintText: 'Search exercises',
    prefixIcon: const Icon(Icons.search),
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
      borderSide: const BorderSide(color: Color(0xFF2F80FF), width: 1.4),
    ),
  );
}

class _PickerShell extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onCreateExercise;
  final Widget child;

  const _PickerShell({
    required this.title,
    required this.subtitle,
    required this.onCreateExercise,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppDensity.space(18),
        AppDensity.space(14),
        AppDensity.space(18),
        AppDensity.space(14),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDensity.circular(26),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withOpacity(0.08),
            blurRadius: AppDensity.space(24),
            offset: Offset(0, AppDensity.space(12)),
          ),
        ],
      ),
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
                  Icons.add_chart_rounded,
                  color: Color(0xFF2F80FF),
                ),
              ),
              SizedBox(width: AppDensity.space(10)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    SizedBox(height: AppDensity.space(3)),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6F7691),
                          ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: AppDensity.circular(12),
                ),
                child: IconButton(
                  tooltip: 'Create exercise',
                  onPressed: onCreateExercise,
                  icon: const Icon(
                    Icons.add_circle_outline_rounded,
                    color: Color(0xFF2F80FF),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: AppDensity.space(12)),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _ExerciseTile({
    required this.exercise,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (exercise.description != null && exercise.description!.isNotEmpty)
        exercise.description!,
      if (exercise.muscleGroups.isNotEmpty)
        exercise.muscleGroups.map((g) => g.name).join(', ')
      else if (exercise.isCustom)
        'Custom exercise'
      else
        'Library exercise',
    ].join('\n');

    return Container(
      margin: EdgeInsets.only(bottom: AppDensity.space(8)),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEFF6FF) : const Color(0xFFF7FAFF),
        borderRadius: AppDensity.circular(18),
        border: Border.all(
          color: selected ? const Color(0xFF8DBBFF) : const Color(0xFFDCE8FF),
        ),
      ),
      child: CheckboxListTile(
        title: Text(
          exercise.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(subtitle),
        value: selected,
        controlAffinity: ListTileControlAffinity.leading,
        checkboxShape: RoundedRectangleBorder(
          borderRadius: AppDensity.circular(6),
        ),
        onChanged: (chk) => onChanged(chk ?? false),
      ),
    );
  }
}
