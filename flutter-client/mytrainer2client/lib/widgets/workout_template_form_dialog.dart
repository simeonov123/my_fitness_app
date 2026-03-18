// lib/widgets/workout_template_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/workout_folder.dart';
import '../models/workout_template.dart';
import '../providers/workout_folders_provider.dart';
import '../theme/app_density.dart';

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
  int? _selectedFolderId;
  final bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.tpl?.name ?? '');
    _descCtrl = TextEditingController(text: widget.tpl?.description ?? '');
    _selectedFolderId = widget.tpl?.folderId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    WorkoutFolder? selectedFolder;
    for (final folder in context.read<WorkoutFoldersProvider>().items) {
      if (folder.id == _selectedFolderId) {
        selectedFolder = folder;
        break;
      }
    }
    final tpl = WorkoutTemplate(
      id: widget.tpl?.id ?? 0,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      folderId: _selectedFolderId,
      folderName: selectedFolder?.name,
      sequenceOrder: widget.tpl?.sequenceOrder,
      exercises: widget.tpl?.exercises,
      createdAt: widget.tpl?.createdAt,
      updatedAt: widget.tpl?.updatedAt,
    );
    Navigator.of(context).pop(tpl);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tpl != null;
    final folders = context.watch<WorkoutFoldersProvider>().items;
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
                        Icons.fitness_center_rounded,
                        color: Color(0xFF2F80FF),
                      ),
                    ),
                    SizedBox(width: AppDensity.space(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit
                                ? 'Edit workout template'
                                : 'New workout template',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppDensity.space(3)),
                          Text(
                            'Name the template, add a short summary, and place it in the right folder.',
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
                  decoration: _fieldDecoration(
                      'Name', 'Push day, Full body, Warmup block'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                SizedBox(height: AppDensity.space(10)),
                TextFormField(
                  controller: _descCtrl,
                  decoration: _fieldDecoration(
                      'Description', 'Optional coaching notes or intent'),
                  maxLines: 3,
                ),
                SizedBox(height: AppDensity.space(10)),
                DropdownButtonFormField<int?>(
                  value: _selectedFolderId,
                  decoration: _fieldDecoration(
                      'Folder', 'Choose where this template belongs'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('No folder'),
                    ),
                    ...folders.map(
                      (folder) => DropdownMenuItem<int?>(
                        value: folder.id,
                        child: Text(folder.name),
                      ),
                    ),
                  ],
                  onChanged: (value) =>
                      setState(() => _selectedFolderId = value),
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
                        onPressed: _submitting ? null : _submit,
                        child: const Text('Save'),
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
