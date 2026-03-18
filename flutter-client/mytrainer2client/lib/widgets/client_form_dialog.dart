// lib/widgets/client_form_dialog.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/client_folder.dart';
import '../providers/client_folders_provider.dart';
import '../providers/clients_provider.dart';
import '../theme/app_density.dart';

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
  int? _selectedFolderId;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final c = widget.client;
    _nameCtrl = TextEditingController(text: c?.fullName ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _selectedFolderId = c?.folderId;
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
    ClientFolder? selectedFolder;
    for (final folder in context.read<ClientFoldersProvider>().items) {
      if (folder.id == _selectedFolderId) {
        selectedFolder = folder;
        break;
      }
    }
    final newClient = Client(
      id: widget.client?.id ?? 0,
      fullName: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      folderId: _selectedFolderId,
      folderName: selectedFolder?.name,
      sequenceOrder: widget.client?.sequenceOrder,
    );

    final provider = context.read<ClientsProvider>();

    if (newClient.id == 0) {
      await provider.save(c: newClient);
    } else {
      await provider.save(c: newClient);
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop(newClient);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.client != null;
    final folders = context.watch<ClientFoldersProvider>().items;
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
                        Icons.person_add_alt_1_rounded,
                        color: Color(0xFF2F80FF),
                      ),
                    ),
                    SizedBox(width: AppDensity.space(10)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEdit ? 'Edit client' : 'Add client',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: AppDensity.space(3)),
                          Text(
                            'Capture the essentials and place the client in the right folder.',
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
                  decoration: _fieldDecoration('Full name', 'Simeon Simeonov'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                SizedBox(height: AppDensity.space(10)),
                TextFormField(
                  controller: _emailCtrl,
                  decoration: _fieldDecoration('E-mail', 'name@example.com'),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: AppDensity.space(10)),
                TextFormField(
                  controller: _phoneCtrl,
                  decoration: _fieldDecoration('Phone', '+359 ...'),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: AppDensity.space(10)),
                DropdownButtonFormField<int?>(
                  value: _selectedFolderId,
                  decoration: _fieldDecoration('Folder', 'Choose a folder'),
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
                            : const Text('Save'),
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
