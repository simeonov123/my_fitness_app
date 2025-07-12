// lib/widgets/nutrition_template_form_dialog.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nutrition_plan_template.dart';
import '../providers/auth_provider.dart';
import '../providers/nutrition_templates_provider.dart';

class NutritionTemplateFormDialog extends StatefulWidget {
  final NutritionPlanTemplate? tpl;

  const NutritionTemplateFormDialog({Key? key, this.tpl}) : super(key: key);

  @override
  State<NutritionTemplateFormDialog> createState() =>
      _NutritionTemplateFormDialogState();
}

class _NutritionTemplateFormDialogState
    extends State<NutritionTemplateFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final t = widget.tpl;
    _nameCtrl = TextEditingController(text: t?.name ?? '');
    _descCtrl = TextEditingController(text: t?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final tpl = NutritionPlanTemplate(
      id: widget.tpl?.id ?? 0,
      name: _nameCtrl.text.trim(),
      description:
      _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
    );

    final token = context.read<AuthProvider>().token!;
    await context
        .read<NutritionTemplatesProvider>()
        .save(token: token, t: tpl);

    setState(() => _submitting = false);
    Navigator.of(context).pop(tpl);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.tpl != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Plan Template' : 'Add Plan Template'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              const Text(
                'Item editing coming soon…',
                style: TextStyle(fontStyle: FontStyle.italic),
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
              child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
