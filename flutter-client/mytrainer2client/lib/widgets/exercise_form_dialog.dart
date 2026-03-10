import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/exercises_provider.dart';

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
  bool _submitting = false;

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

  @override
  Widget build(BuildContext context) {
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
