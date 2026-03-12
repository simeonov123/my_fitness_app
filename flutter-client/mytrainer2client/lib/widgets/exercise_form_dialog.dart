import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/muscle_group.dart';
import '../providers/exercises_provider.dart';
import '../providers/muscle_groups_provider.dart';

class ExerciseFormDialog extends StatefulWidget {
  const ExerciseFormDialog({super.key});

  @override
  State<ExerciseFormDialog> createState() => _ExerciseFormDialogState();
}

class _ExerciseFormDialogState extends State<ExerciseFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  late final List<_ExercisePreset> _presets;
  late _ExercisePreset _selectedPreset;
  final Set<MuscleGroup> _selectedMuscleGroups = <MuscleGroup>{};
  bool _submitting = false;
  bool _creatingMuscleGroup = false;

  @override
  void initState() {
    super.initState();
    _presets = const [
      _ExercisePreset(
        label: 'Reps',
        defaultSetType: 'Reps',
        defaultSetParams: 'REPS',
      ),
      _ExercisePreset(
        label: 'Weight + Reps',
        defaultSetType: 'Weight + Reps',
        defaultSetParams: 'KG,REPS',
      ),
      _ExercisePreset(
        label: 'Duration',
        defaultSetType: 'Duration',
        defaultSetParams: 'TIME',
      ),
      _ExercisePreset(
        label: 'Distance',
        defaultSetType: 'Distance',
        defaultSetParams: 'KM',
      ),
      _ExercisePreset(
        label: 'Distance + Duration',
        defaultSetType: 'Distance + Duration',
        defaultSetParams: 'KM,TIME',
      ),
    ];
    _selectedPreset = _presets.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<MuscleGroupsProvider>();
      if (!provider.loading && provider.items.isEmpty) {
        provider.load();
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final created = await context.read<ExercisesProvider>().create(
            name: _nameCtrl.text.trim(),
            description: _descCtrl.text.trim().isEmpty
                ? null
                : _descCtrl.text.trim(),
            defaultSetType: _selectedPreset.defaultSetType,
            defaultSetParams: _selectedPreset.defaultSetParams,
            muscleGroups: _selectedMuscleGroups.toList(growable: false),
          );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create exercise: $e')),
      );
      setState(() => _submitting = false);
    }
  }

  Future<void> _createCustomMuscleGroup() async {
    if (_creatingMuscleGroup) return;
    final nameCtrl = TextEditingController();
    try {
      final name = await showDialog<String>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('New Muscle Group'),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Muscle group name',
              hintText: 'e.g. Short Head of Bicep',
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) =>
                Navigator.of(dialogContext).pop(value.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(nameCtrl.text.trim()),
              child: const Text('Create'),
            ),
          ],
        ),
      );
      if (!mounted || name == null || name.trim().isEmpty) return;
      setState(() => _creatingMuscleGroup = true);
      final created = await context.read<MuscleGroupsProvider>().create(
            name.trim(),
          );
      if (!mounted) return;
      setState(() {
        _selectedMuscleGroups.add(created);
        _creatingMuscleGroup = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _creatingMuscleGroup = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create muscle group: $e')),
      );
    } finally {
      nameCtrl.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final muscleGroupsProvider = context.watch<MuscleGroupsProvider>();
    return AlertDialog(
      title: const Text('New Exercise'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<_ExercisePreset>(
                initialValue: _selectedPreset,
                decoration: const InputDecoration(labelText: 'Default tracking'),
                items: _presets
                    .map(
                      (preset) => DropdownMenuItem<_ExercisePreset>(
                        value: preset,
                        child: Text(preset.label),
                      ),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _selectedPreset = value);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Muscle Groups',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _creatingMuscleGroup ? null : _createCustomMuscleGroup,
                    icon: _creatingMuscleGroup
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add),
                    label: const Text('Custom'),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _selectedMuscleGroups.isEmpty
                      ? 'Select one or more muscle groups.'
                      : '${_selectedMuscleGroups.length} selected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              if (muscleGroupsProvider.loading &&
                  muscleGroupsProvider.items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: muscleGroupsProvider.items
                      .map(
                        (group) => FilterChip(
                          label: Text(group.name),
                          selected: _selectedMuscleGroups.contains(group),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedMuscleGroups.add(group);
                              } else {
                                _selectedMuscleGroups.remove(group);
                              }
                            });
                          },
                        ),
                      )
                      .toList(growable: false),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Create'),
        ),
      ],
    );
  }
}

class _ExercisePreset {
  final String label;
  final String defaultSetType;
  final String defaultSetParams;

  const _ExercisePreset({
    required this.label,
    required this.defaultSetType,
    required this.defaultSetParams,
  });
}
