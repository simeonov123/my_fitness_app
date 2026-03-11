import 'package:flutter/material.dart';

import '../models/workout_folder.dart';

class WorkoutFolderFormDialog extends StatefulWidget {
  final WorkoutFolder? folder;

  const WorkoutFolderFormDialog({super.key, this.folder});

  @override
  State<WorkoutFolderFormDialog> createState() => _WorkoutFolderFormDialogState();
}

class _WorkoutFolderFormDialogState extends State<WorkoutFolderFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.folder?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      WorkoutFolder(
        id: widget.folder?.id ?? 0,
        name: _nameCtrl.text.trim(),
        sequenceOrder: widget.folder?.sequenceOrder,
        workoutCount: widget.folder?.workoutCount ?? 0,
        createdAt: widget.folder?.createdAt,
        updatedAt: widget.folder?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.folder != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Workout Folder' : 'New Workout Folder'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Folder name *'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
          autofocus: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
