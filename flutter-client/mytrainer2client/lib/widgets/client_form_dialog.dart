// lib/widgets/client_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../providers/auth_provider.dart';
import '../providers/clients_provider.dart';

class ClientFormDialog extends StatefulWidget {
  /// If [client] is non-null, we’re _editing_; otherwise we’re creating.
  final Client? client;

  const ClientFormDialog({super.key, this.client});

  @override
  State<ClientFormDialog> createState() => _ClientFormDialogState();
}

class _ClientFormDialogState extends State<ClientFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameCtrl = TextEditingController(text: c?.fullName ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    // Build a Client object, preserving id if editing:
    final newClient = Client(
      id: widget.client?.id ?? 0,
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
    );

    final token = context.read<AuthProvider>().token!;
    final provider = context.read<ClientsProvider>();

    if (newClient.id == 0) {
      await provider.save(token: token, c: newClient);
    } else {
      await provider.save(token: token, c: newClient);
    }

    setState(() => _submitting = false);
    Navigator.of(context).pop(newClient);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Client' : 'Add Client'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Full name *'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Name is required' : null,
              ),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'E-mail'),
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                controller: _phoneCtrl,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
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
