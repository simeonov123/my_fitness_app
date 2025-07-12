import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/workout_template.dart';
import '../providers/clients_provider.dart';
import '../providers/workout_templates_provider.dart';
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
      context.read<WorkoutTemplatesProvider>().load(token: token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final cProv = context.watch<ClientsProvider>();
    final tProv = context.watch<WorkoutTemplatesProvider>();

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
              MultiSelectDialogField<Client>(
                items: cProv.items
                    .map((c) => MultiSelectItem<Client>(c, c.fullName))
                    .toList(),
                searchable: true,
                listType: MultiSelectListType.LIST,
                title: const Text('Clients'),
                buttonText: const Text('Choose clients'),
                onConfirm: (val) => _pickedClients = val,
                validator: (list) =>
                (list == null || list.isEmpty)
                    ? 'Pick at least one'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownSearch<WorkoutTemplate>(
                items: tProv.items,
                itemAsString: (t) => t.name,
                popupProps: const PopupProps.menu(showSearchBox: true),
                dropdownDecoratorProps: const DropDownDecoratorProps(
                  dropdownSearchDecoration:
                  InputDecoration(labelText: 'Workout template'),
                ),
                onChanged: (t) => _pickedTpl = t,
                validator: (t) => t == null ? 'Required' : null,
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
          onPressed: _submit,
          child: const Text('Create'),
        ),
      ],
    );
  }

  DateTime _merge(DateTime d, TimeOfDay t) =>
      DateTime(d.year, d.month, d.day, t.hour, t.minute);

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;

    final start = _merge(_day, _start);
    final end   = _merge(_day, _end);
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
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

    Navigator.pop(context, dto);
  }
}
