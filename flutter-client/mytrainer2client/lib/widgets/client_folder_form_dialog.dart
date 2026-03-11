import 'package:flutter/material.dart';

import '../models/client_folder.dart';

class ClientFolderFormDialog extends StatefulWidget {
  final ClientFolder? folder;

  const ClientFolderFormDialog({super.key, this.folder});

  @override
  State<ClientFolderFormDialog> createState() => _ClientFolderFormDialogState();
}

class _ClientFolderFormDialogState extends State<ClientFolderFormDialog> {
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
      ClientFolder(
        id: widget.folder?.id ?? 0,
        name: _nameCtrl.text.trim(),
        sequenceOrder: widget.folder?.sequenceOrder,
        clientCount: widget.folder?.clientCount ?? 0,
        createdAt: widget.folder?.createdAt,
        updatedAt: widget.folder?.updatedAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.folder != null;
    return AlertDialog(
      title: Text(isEdit ? 'Edit Client Folder' : 'New Client Folder'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _nameCtrl,
          decoration: const InputDecoration(labelText: 'Folder name *'),
          validator: (value) =>
              value == null || value.trim().isEmpty ? 'Required' : null,
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
