import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/muscle_group.dart';
import '../models/exercise.dart';
import '../providers/exercises_provider.dart';
import '../providers/muscle_groups_provider.dart';
import '../theme/app_density.dart';

class ExerciseFormDialog extends StatefulWidget {
  const ExerciseFormDialog({
    super.key,
    this.initialExercise,
  });

  final Exercise? initialExercise;

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

  bool get _isEditing => widget.initialExercise != null;

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
    final initialExercise = widget.initialExercise;
    if (initialExercise != null) {
      _nameCtrl.text = initialExercise.name;
      _descCtrl.text = initialExercise.description ?? '';
      _selectedPreset = _presets.firstWhere(
        (preset) =>
            preset.defaultSetType == initialExercise.defaultSetType &&
            preset.defaultSetParams == initialExercise.defaultSetParams,
        orElse: () => _selectedPreset,
      );
      _selectedMuscleGroups.addAll(initialExercise.muscleGroups);
    }
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
      final provider = context.read<ExercisesProvider>();
      final created = _isEditing
          ? await provider.update(
              id: widget.initialExercise!.id,
              name: _nameCtrl.text.trim(),
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              defaultSetType: _selectedPreset.defaultSetType,
              defaultSetParams: _selectedPreset.defaultSetParams,
              muscleGroups: _selectedMuscleGroups.toList(growable: false),
            )
          : await provider.create(
              name: _nameCtrl.text.trim(),
              description:
                  _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
              defaultSetType: _selectedPreset.defaultSetType,
              defaultSetParams: _selectedPreset.defaultSetParams,
              muscleGroups: _selectedMuscleGroups.toList(growable: false),
            );
      if (!mounted) return;
      Navigator.of(context).pop(created);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Failed to update exercise: $e'
                : 'Failed to create exercise: $e',
          ),
        ),
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
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: AppDensity.symmetric(horizontal: 16, vertical: 18),
      child: Container(
        padding: EdgeInsets.fromLTRB(
          AppDensity.space(18),
          AppDensity.space(18),
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
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
                        Icons.sports_gymnastics_rounded,
                        color: Color(0xFF2F80FF),
                      ),
                    ),
                    SizedBox(width: AppDensity.space(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing ? 'Edit exercise' : 'New exercise',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppDensity.space(3)),
                          Text(
                            _isEditing
                                ? 'Update the movement name, tracking preset, and muscle groups.'
                                : 'Add a custom movement with default tracking and muscle groups.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6F7691),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppDensity.space(14)),
                TextFormField(
                  controller: _nameCtrl,
                  decoration:
                      _fieldDecoration('Name', 'Incline dumbbell press'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: AppDensity.space(10)),
                TextFormField(
                  controller: _descCtrl,
                  decoration: _fieldDecoration(
                      'Description', 'Optional coaching cue or context'),
                  maxLines: 3,
                ),
                SizedBox(height: AppDensity.space(10)),
                DropdownButtonFormField<_ExercisePreset>(
                  value: _selectedPreset,
                  decoration: _fieldDecoration(
                      'Default tracking', 'Choose a set format'),
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
                SizedBox(height: AppDensity.space(12)),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Muscle groups',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _creatingMuscleGroup
                          ? null
                          : _createCustomMuscleGroup,
                      icon: _creatingMuscleGroup
                          ? SizedBox(
                              width: AppDensity.space(12),
                              height: AppDensity.space(12),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Custom'),
                    ),
                  ],
                ),
                Text(
                  _selectedMuscleGroups.isEmpty
                      ? 'Select one or more muscle groups.'
                      : '${_selectedMuscleGroups.length} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF6F7691),
                  ),
                ),
                SizedBox(height: AppDensity.space(6)),
                if (muscleGroupsProvider.loading &&
                    muscleGroupsProvider.items.isEmpty)
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: AppDensity.space(12),
                    ),
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
                SizedBox(height: AppDensity.space(14)),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: _submitting
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: AppDensity.space(8)),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                            child: _submitting
                                ? SizedBox(
                                    width: AppDensity.space(18),
                                height: AppDensity.space(18),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                                  )
                            : Text(_isEditing ? 'Save' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, String hint) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF7FAFF),
      border: OutlineInputBorder(
        borderRadius: AppDensity.circular(18),
        borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppDensity.circular(18),
        borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppDensity.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF2F80FF),
          width: 1.4,
        ),
      ),
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
