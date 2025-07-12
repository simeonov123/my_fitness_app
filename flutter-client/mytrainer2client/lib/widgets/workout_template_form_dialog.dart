// lib/widgets/workout_template_form_dialog.dart
import 'package:flutter/material.dart';
import '../models/workout_template.dart';

class WorkoutTemplateFormDialog extends StatefulWidget {
  final WorkoutTemplate? tpl;
  const WorkoutTemplateFormDialog({super.key, this.tpl});

  @override
  State<WorkoutTemplateFormDialog> createState() =>
      _WorkoutTemplateFormDialogState();
}

class _WorkoutTemplateFormDialogState extends State<WorkoutTemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _descCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.tpl?.name ?? '');
    _descCtrl = TextEditingController(text: widget.tpl?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final tpl = WorkoutTemplate(
      id: widget.tpl?.id ?? 0,
      name: _nameCtrl.text.trim(),
      description:
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );
    Navigator.of(context).pop(tpl);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tpl != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Workout Template' : 'New Workout Template'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          child: const Text('Save'),
        )
      ],
    );
  }
}
