import 'package:flutter/material.dart';

import '../models/workout_folder.dart';
import '../theme/app_density.dart';

class WorkoutFolderFormDialog extends StatefulWidget {
  final WorkoutFolder? folder;

  const WorkoutFolderFormDialog({super.key, this.folder});

  @override
  State<WorkoutFolderFormDialog> createState() =>
      _WorkoutFolderFormDialogState();
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
                    Icons.folder_open_rounded,
                    color: Color(0xFF2F80FF),
                  ),
                ),
                SizedBox(width: AppDensity.space(10)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEdit ? 'Edit workout folder' : 'New workout folder',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: AppDensity.space(3)),
                      Text(
                        'Group related templates into a cleaner workout library.',
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
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Folder name',
                  hintText: 'Strength block, Upper body, Clients',
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
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
            ),
            SizedBox(height: AppDensity.space(14)),
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
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
