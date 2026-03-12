import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/workout_template.dart';
import '../providers/client_folders_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/workout_folders_provider.dart';
import '../providers/auth_provider.dart';

class TrainingSessionFormDialog extends StatefulWidget {
  const TrainingSessionFormDialog({
    super.key,
    required this.initialDay,
  });

  /// pre-selected calendar day (passed from HomePage)
  final DateTime initialDay;

  @override
  State<TrainingSessionFormDialog> createState() =>
      _TrainingSessionFormDialogState();
}

class _TrainingSessionFormDialogState extends State<TrainingSessionFormDialog> {
  late DateTime _day;
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end   = const TimeOfDay(hour: 11, minute: 0);
  final _name = TextEditingController();
  bool _submitting = false;

  List<Client>     _pickedClients = [];
  WorkoutTemplate? _pickedTpl;

  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _day = widget.initialDay;

    // 🔹 defer provider loads until after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token!;
      context.read<ClientsProvider>().load(token: token);
      context.read<ClientFoldersProvider>().load(token: token);
      context.read<WorkoutTemplatesProvider>().load(token: token);
      context.read<WorkoutFoldersProvider>().load(token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cProv = context.watch<ClientsProvider>();
    final clientFolderProv = context.watch<ClientFoldersProvider>();
    final tProv = context.watch<WorkoutTemplatesProvider>();
    final folderProv = context.watch<WorkoutFoldersProvider>();

    return AlertDialog(
      title: const Text('New Training Session'),
      content: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration:
                const InputDecoration(labelText: 'Name (optional)'),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.date_range),
                title: Text('${_day.year}-${_day.month}-${_day.day}'),
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDate: _day,
                  );
                  if (d != null) setState(() => _day = d);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('Start ${_start.format(context)}'),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _start,
                  );
                  if (t != null) setState(() => _start = t);
                },
              ),
              ListTile(
                leading: const Icon(Icons.schedule),
                title: Text('End   ${_end.format(context)}'),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _end,
                  );
                  if (t != null) setState(() => _end = t);
                },
              ),
              const Divider(),
              FormField<List<Client>>(
                validator: (_) =>
                    _pickedClients.isEmpty ? 'Pick at least one' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.people_outline),
                      title: Text(
                        _pickedClients.isEmpty
                            ? 'Choose clients'
                            : '${_pickedClients.length} client${_pickedClients.length == 1 ? '' : 's'} selected',
                      ),
                      subtitle: Text(
                        _pickedClients.isEmpty
                            ? 'All, ungrouped, and folder filters available'
                            : _pickedClients.map((c) => c.fullName).join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      onTap: () async {
                        final picked = await _showClientPicker(
                          clients: cProv.items,
                          foldersSupported: clientFolderProv.supported,
                        );
                        if (picked != null) {
                          setState(() => _pickedClients = picked);
                          field.didChange(picked);
                        }
                      },
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FormField<WorkoutTemplate>(
                validator: (_) => _pickedTpl == null ? 'Required' : null,
                builder: (field) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.fitness_center),
                      title: Text(_pickedTpl?.name ?? 'Choose workout'),
                      subtitle: Text(
                        _pickedTpl == null
                            ? 'All, ungrouped, and folder filters available'
                            : (_pickedTpl!.folderName ?? 'Ungrouped workout'),
                      ),
                      trailing: const Icon(Icons.keyboard_arrow_down),
                      onTap: () async {
                        final picked = await _showWorkoutPicker(
                          workouts: tProv.items,
                          foldersSupported: folderProv.supported,
                        );
                        if (picked != null) {
                          setState(() => _pickedTpl = picked);
                          field.didChange(picked);
                        }
                      },
                    ),
                    if (field.hasError)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          field.errorText!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting || _pickedClients.isEmpty || _pickedTpl == null
              ? null
              : _submit,
          child: Text(_submitting ? 'Creating...' : 'Create'),
        ),
      ],
    );
  }

  DateTime _merge(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<WorkoutTemplate?> _showWorkoutPicker({
    required List<WorkoutTemplate> workouts,
    required bool foldersSupported,
  }) {
    return showModalBottomSheet<WorkoutTemplate>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (_) => _WorkoutTemplatePickerSheet(
        workouts: workouts,
        foldersSupported: foldersSupported,
      ),
    );
  }

  Future<List<Client>?> _showClientPicker({
    required List<Client> clients,
    required bool foldersSupported,
  }) {
    return showModalBottomSheet<List<Client>>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.white,
      builder: (_) => _ClientPickerSheet(
        clients: clients,
        initialSelection: _pickedClients,
        foldersSupported: foldersSupported,
      ),
    );
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    if (!_form.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one client and one workout.'),
        ),
      );
      setState(() => _submitting = false);
      return;
    }

    final start = _merge(_day, _start);
    final end   = _merge(_day, _end);
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
      setState(() => _submitting = false);
      return;
    }

    final dto = {
      'id'               : 0,
      'startTime'        : start.toIso8601String(),
      'endTime'          : end.toIso8601String(),
      'sessionName'      : _name.text.trim().isEmpty ? null : _name.text.trim(),
      'clientIds'        : _pickedClients.map((c) => c.id).toList(),
      'workoutTemplateId': _pickedTpl!.id,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Submitting clients ${_pickedClients.map((c) => c.id).join(', ')} workout ${_pickedTpl!.id}',
        ),
      ),
    );
    Navigator.pop(context, dto);
  }
}

class _WorkoutTemplatePickerSheet extends StatefulWidget {
  final List<WorkoutTemplate> workouts;
  final bool foldersSupported;

  const _WorkoutTemplatePickerSheet({
    required this.workouts,
    required this.foldersSupported,
  });

  @override
  State<_WorkoutTemplatePickerSheet> createState() =>
      _WorkoutTemplatePickerSheetState();
}

class _WorkoutTemplatePickerSheetState extends State<_WorkoutTemplatePickerSheet> {
  String _query = '';
  int? _selectedFolderId;
  bool _showUngroupedOnly = false;

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<WorkoutFoldersProvider>().items;
    final filtered = widget.workouts.where((workout) {
      final matchesQuery = _query.isEmpty ||
          workout.name.toLowerCase().contains(_query.toLowerCase());
      if (!matchesQuery) return false;
      if (_showUngroupedOnly) return workout.folderId == null;
      if (_selectedFolderId != null) return workout.folderId == _selectedFolderId;
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose workout',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search workouts',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Workouts'),
                    selected: !_showUngroupedOnly && _selectedFolderId == null,
                    onSelected: (_) => setState(() {
                      _showUngroupedOnly = false;
                      _selectedFolderId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  if (widget.foldersSupported) ...[
                    ChoiceChip(
                      label: const Text('Ungrouped'),
                      selected: _showUngroupedOnly,
                      onSelected: (_) => setState(() {
                        _showUngroupedOnly = true;
                        _selectedFolderId = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ...folders.map(
                      (folder) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(folder.name),
                          selected: !_showUngroupedOnly &&
                              _selectedFolderId == folder.id,
                          onSelected: (_) => setState(() {
                            _showUngroupedOnly = false;
                            _selectedFolderId = folder.id;
                          }),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No workouts found for this filter.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final workout = filtered[index];
                        return ListTile(
                          title: Text(workout.name),
                          subtitle: Text(workout.folderName ?? 'Ungrouped'),
                          onTap: () => Navigator.pop(context, workout),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientPickerSheet extends StatefulWidget {
  final List<Client> clients;
  final List<Client> initialSelection;
  final bool foldersSupported;

  const _ClientPickerSheet({
    required this.clients,
    required this.initialSelection,
    required this.foldersSupported,
  });

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _query = '';
  int? _selectedFolderId;
  bool _showUngroupedOnly = false;
  late final Set<int> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelection.map((c) => c.id).toSet();
  }

  @override
  Widget build(BuildContext context) {
    final folders = context.watch<ClientFoldersProvider>().items;
    final filtered = widget.clients.where((client) {
      final matchesQuery =
          _query.isEmpty || client.fullName.toLowerCase().contains(_query.toLowerCase());
      if (!matchesQuery) return false;
      if (_showUngroupedOnly) return client.folderId == null;
      if (_selectedFolderId != null) return client.folderId == _selectedFolderId;
      return true;
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Choose clients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final selected = widget.clients
                        .where((client) => _selectedIds.contains(client.id))
                        .toList();
                    Navigator.pop(context, selected);
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search clients',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value.trim()),
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('All Clients'),
                    selected: !_showUngroupedOnly && _selectedFolderId == null,
                    onSelected: (_) => setState(() {
                      _showUngroupedOnly = false;
                      _selectedFolderId = null;
                    }),
                  ),
                  const SizedBox(width: 8),
                  if (widget.foldersSupported) ...[
                    ChoiceChip(
                      label: const Text('Ungrouped'),
                      selected: _showUngroupedOnly,
                      onSelected: (_) => setState(() {
                        _showUngroupedOnly = true;
                        _selectedFolderId = null;
                      }),
                    ),
                    const SizedBox(width: 8),
                    ...folders.map(
                      (folder) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(folder.name),
                          selected: !_showUngroupedOnly &&
                              _selectedFolderId == folder.id,
                          onSelected: (_) => setState(() {
                            _showUngroupedOnly = false;
                            _selectedFolderId = folder.id;
                          }),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: filtered.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No clients found for this filter.'),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, index) {
                        final client = filtered[index];
                        final selected = _selectedIds.contains(client.id);
                        return CheckboxListTile(
                          value: selected,
                          title: Text(client.fullName),
                          subtitle: Text(client.folderName ?? 'Ungrouped'),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                          onChanged: (_) => setState(() {
                            if (selected) {
                              _selectedIds.remove(client.id);
                            } else {
                              _selectedIds.add(client.id);
                            }
                          }),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
