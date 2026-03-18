import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../models/workout_template.dart';
import '../providers/client_folders_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/workout_folders_provider.dart';
import '../theme/app_density.dart';

class TrainingSessionFormDialog extends StatefulWidget {
  const TrainingSessionFormDialog({
    super.key,
    required this.initialDay,
    this.initialStartTime,
  });

  /// pre-selected calendar day (passed from HomePage)
  final DateTime initialDay;
  final DateTime? initialStartTime;

  @override
  State<TrainingSessionFormDialog> createState() =>
      _TrainingSessionFormDialogState();
}

class _TrainingSessionFormDialogState extends State<TrainingSessionFormDialog> {
  late DateTime _day;
  TimeOfDay _start = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 11, minute: 0);
  final _name = TextEditingController();
  bool _submitting = false;

  List<Client> _pickedClients = [];
  WorkoutTemplate? _pickedTpl;

  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final initialStart = widget.initialStartTime;
    _day = initialStart ?? widget.initialDay;
    if (initialStart != null) {
      _start = TimeOfDay(hour: initialStart.hour, minute: initialStart.minute);
      final initialEnd = initialStart.add(const Duration(hours: 1));
      _end = TimeOfDay(hour: initialEnd.hour, minute: initialEnd.minute);
    }

    // 🔹 defer provider loads until after first frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      context.read<ClientsProvider>().load();
      context.read<ClientFoldersProvider>().load();
      context.read<WorkoutTemplatesProvider>().load();
      context.read<WorkoutFoldersProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cProv = context.watch<ClientsProvider>();
    final clientFolderProv = context.watch<ClientFoldersProvider>();
    final tProv = context.watch<WorkoutTemplatesProvider>();
    final folderProv = context.watch<WorkoutFoldersProvider>();
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: AppDensity.symmetric(horizontal: 16, vertical: 18),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppDensity.space(760)),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: AppDensity.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.surfaceContainerLowest,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.18),
                blurRadius: AppDensity.space(28),
                offset: Offset(0, AppDensity.space(18)),
              ),
            ],
          ),
          child: Form(
            key: _form,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                AppDensity.space(20),
                AppDensity.space(20),
                AppDensity.space(20),
                AppDensity.space(16),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: AppDensity.all(18),
                    decoration: BoxDecoration(
                      borderRadius: AppDensity.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          colors.primary.withOpacity(0.14),
                          colors.secondary.withOpacity(0.08),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: AppDensity.space(40),
                              width: AppDensity.space(40),
                              decoration: BoxDecoration(
                                color: colors.primary.withOpacity(0.14),
                                borderRadius: AppDensity.circular(12),
                              ),
                              child: Icon(
                                Icons.event_available_rounded,
                                color: colors.primary,
                              ),
                            ),
                            SizedBox(width: AppDensity.space(10)),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  top: AppDensity.space(1.5),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'New training session',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: text.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(width: AppDensity.space(6)),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        SizedBox(height: AppDensity.space(10)),
                        Text(
                          'Schedule the session, attach the workout, and invite the right clients in one pass.',
                          style: text.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        SizedBox(height: AppDensity.space(14)),
                        Wrap(
                          spacing: AppDensity.space(8),
                          runSpacing: AppDensity.space(8),
                          children: [
                            _InfoPill(
                              icon: Icons.calendar_today_rounded,
                              label: _formatDay(_day),
                            ),
                            _InfoPill(
                              icon: Icons.play_arrow_rounded,
                              label: _start.format(context),
                            ),
                            _InfoPill(
                              icon: Icons.flag_rounded,
                              label: _end.format(context),
                            ),
                            _InfoPill(
                              icon: Icons.groups_rounded,
                              label: _pickedClients.isEmpty
                                  ? 'No clients yet'
                                  : '${_pickedClients.length} selected',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: AppDensity.space(16)),
                  TextFormField(
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: 'Session name',
                      hintText:
                          'Upper body strength, Team conditioning, Morning group...',
                      filled: true,
                      fillColor: colors.surfaceContainerLowest,
                      prefixIcon: const Icon(Icons.edit_calendar_rounded),
                      border: OutlineInputBorder(
                        borderRadius: AppDensity.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  SizedBox(height: AppDensity.space(14)),
                  Text(
                    'Schedule',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: AppDensity.space(8)),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 430;
                      final medium = constraints.maxWidth < 620;
                      final columns = compact ? 1 : (medium ? 2 : 3);
                      final spacing = AppDensity.space(10);
                      final cardWidth =
                          (constraints.maxWidth - (spacing * (columns - 1))) /
                              columns;

                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          SizedBox(
                            width: cardWidth,
                            child: _ActionCard(
                              icon: Icons.date_range_rounded,
                              label: 'Day',
                              value: _formatDay(_day),
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
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _ActionCard(
                              icon: Icons.schedule_rounded,
                              label: 'Start',
                              value: _start.format(context),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _start,
                                );
                                if (t != null) setState(() => _start = t);
                              },
                            ),
                          ),
                          SizedBox(
                            width: cardWidth,
                            child: _ActionCard(
                              icon: Icons.schedule_send_rounded,
                              label: 'End',
                              value: _end.format(context),
                              onTap: () async {
                                final t = await showTimePicker(
                                  context: context,
                                  initialTime: _end,
                                );
                                if (t != null) setState(() => _end = t);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  SizedBox(height: AppDensity.space(16)),
                  FormField<List<Client>>(
                    validator: (_) => _pickedClients.isEmpty
                        ? 'Pick at least one client.'
                        : null,
                    builder: (field) => _SelectionCard(
                      icon: Icons.people_alt_rounded,
                      title: 'Clients',
                      value: _pickedClients.isEmpty
                          ? 'Choose who is joining this session'
                          : '${_pickedClients.length} client${_pickedClients.length == 1 ? '' : 's'} selected',
                      subtitle: _pickedClients.isEmpty
                          ? 'Search by name, folder, or ungrouped clients.'
                          : _pickedClients.map((c) => c.fullName).join(', '),
                      errorText: field.errorText,
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
                  ),
                  SizedBox(height: AppDensity.space(12)),
                  FormField<WorkoutTemplate>(
                    validator: (_) => _pickedTpl == null
                        ? 'Choose a workout template.'
                        : null,
                    builder: (field) => _SelectionCard(
                      icon: Icons.fitness_center_rounded,
                      title: 'Workout template',
                      value: _pickedTpl?.name ?? 'Choose the workout structure',
                      subtitle: _pickedTpl == null
                          ? 'Browse all workouts, folders, or ungrouped templates.'
                          : (_pickedTpl!.folderName ?? 'Ungrouped workout'),
                      errorText: field.errorText,
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
                  ),
                  SizedBox(height: AppDensity.space(18)),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _submitting ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _submitting ||
                                  _pickedClients.isEmpty ||
                                  _pickedTpl == null
                              ? null
                              : _submit,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                              _submitting ? 'Creating...' : 'Create session'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatDay(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
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
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: _WorkoutTemplatePickerSheet(
          workouts: workouts,
          foldersSupported: foldersSupported,
        ),
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
      builder: (_) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: _ClientPickerSheet(
          clients: clients,
          initialSelection: _pickedClients,
          foldersSupported: foldersSupported,
        ),
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
    final end = _merge(_day, _end);
    if (end.isBefore(start)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End must be after start')),
      );
      setState(() => _submitting = false);
      return;
    }

    final dto = {
      'id': 0,
      'startTime': start.toIso8601String(),
      'endTime': end.toIso8601String(),
      'sessionName': _name.text.trim().isEmpty ? null : _name.text.trim(),
      'clientIds': _pickedClients.map((c) => c.id).toList(),
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

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: colors.surface.withOpacity(0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: colors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: colors.primary),
              const SizedBox(height: 14),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String? errorText;
  final VoidCallback onTap;

  const _SelectionCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.onTap,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: colors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: colors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Icon(Icons.keyboard_arrow_right_rounded),
                ],
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 6, top: 6),
            child: Text(
              errorText!,
              style: TextStyle(
                color: colors.error,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
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

class _WorkoutTemplatePickerSheetState
    extends State<_WorkoutTemplatePickerSheet> {
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
      if (_selectedFolderId != null)
        return workout.folderId == _selectedFolderId;
      return true;
    }).toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
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
                      selected:
                          !_showUngroupedOnly && _selectedFolderId == null,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
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
      final matchesQuery = _query.isEmpty ||
          client.fullName.toLowerCase().contains(_query.toLowerCase());
      if (!matchesQuery) return false;
      if (_showUngroupedOnly) return client.folderId == null;
      if (_selectedFolderId != null)
        return client.folderId == _selectedFolderId;
      return true;
    }).toList()
      ..sort((a, b) => a.fullName.compareTo(b.fullName));

    return SafeArea(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .outlineVariant
                        .withOpacity(0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 12),
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
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
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
                      selected:
                          !_showUngroupedOnly && _selectedFolderId == null,
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
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
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
      ),
    );
  }
}
