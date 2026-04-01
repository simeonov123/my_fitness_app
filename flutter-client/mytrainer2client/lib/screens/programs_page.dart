import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/program_template.dart';
import '../models/workout_template.dart';
import '../providers/auth_provider.dart';
import '../providers/clients_provider.dart';
import '../providers/navigation_provider.dart';
import '../providers/programs_provider.dart';
import '../providers/workout_templates_provider.dart';
import '../widgets/bottom_nav_bar.dart';

class ProgramsPage extends StatefulWidget {
  const ProgramsPage({super.key});

  @override
  State<ProgramsPage> createState() => _ProgramsPageState();
}

class _ProgramsPageState extends State<ProgramsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      context.read<NavigationProvider>().setIndex(auth.isTrainer ? 3 : 2);
      if (auth.isTrainer) {
        await context.read<ProgramsProvider>().loadTrainerPrograms();
      } else {
        await context.read<ProgramsProvider>().loadClientPrograms();
      }
    });
  }

  Future<void> _openProgramDialog([ProgramTemplateModel? existing]) async {
    await context.read<WorkoutTemplatesProvider>().load();
    if (!mounted) return;
    final saved = await showDialog<ProgramTemplateModel>(
      context: context,
      builder: (_) => _ProgramEditorDialog(program: existing),
    );
    if (saved == null || !mounted) return;
    await context.read<ProgramsProvider>().save(saved);
  }

  Future<void> _openAssignDialog(ProgramTemplateModel program) async {
    await context.read<ClientsProvider>().load(toPage: 0, newSort: 'name');
    if (!mounted) return;
    final result = await showDialog<_AssignmentDraft>(
      context: context,
      builder: (_) => _ProgramAssignDialog(program: program),
    );
    if (result == null || !mounted) return;
    await context.read<ProgramsProvider>().assign(
          templateId: program.id,
          clientIds: result.clientIds,
          startDate: result.startDate,
        );
  }

  Future<void> _deleteProgram(ProgramTemplateModel program) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Program'),
        content: Text('Delete "${program.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<ProgramsProvider>().delete(program.id);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ProgramsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(auth.isTrainer ? 'Programs' : 'My Program')),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : auth.isTrainer
              ? _TrainerProgramsView(
                  programs: provider.templates,
                  onCreate: () => _openProgramDialog(),
                  onEdit: _openProgramDialog,
                  onAssign: _openAssignDialog,
                  onDelete: _deleteProgram,
                )
              : _ClientProgramsView(programs: provider.clientPrograms),
      floatingActionButton: auth.isTrainer
          ? FloatingActionButton.extended(
              onPressed: () => _openProgramDialog(),
              icon: const Icon(Icons.add),
              label: const Text('New Program'),
            )
          : null,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _TrainerProgramsView extends StatelessWidget {
  final List<ProgramTemplateModel> programs;
  final VoidCallback onCreate;
  final Future<void> Function(ProgramTemplateModel program) onEdit;
  final Future<void> Function(ProgramTemplateModel program) onAssign;
  final Future<void> Function(ProgramTemplateModel program) onDelete;

  const _TrainerProgramsView({
    required this.programs,
    required this.onCreate,
    required this.onEdit,
    required this.onAssign,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.schema_outlined, size: 64),
            const SizedBox(height: 16),
            const Text(
                'Build programs from repeating workout and rest patterns.'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onCreate,
              child: const Text('Create Program'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final program = programs[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(
                                avatar: const Icon(Icons.layers_outlined),
                                label:
                                    Text('${program.mesocycles.length} cycles'),
                              ),
                              Chip(
                                avatar:
                                    const Icon(Icons.calendar_today_outlined),
                                label: Text('${program.totalDurationDays} days'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => onEdit(program),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      onPressed: () => onDelete(program),
                      icon: const Icon(Icons.delete_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 24),
                ...program.mesocycles.map(
                  (meso) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.black12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            meso.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${meso.lengthInWeeks} week(s) • ${meso.microcycle.lengthInDays}-day microcycle',
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: meso.microcycle.days
                                .map(
                                  (day) => Chip(
                                    label: Text(
                                      day.restDay
                                          ? 'Day ${day.dayIndex}: Rest'
                                          : 'Day ${day.dayIndex}: ${day.workoutTemplateName ?? 'Workout'}',
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.tonalIcon(
                    onPressed: () => onAssign(program),
                    icon: const Icon(Icons.person_add_alt_1),
                    label: const Text('Assign'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ClientProgramsView extends StatelessWidget {
  final List<ClientProgram> programs;

  const _ClientProgramsView({required this.programs});

  @override
  Widget build(BuildContext context) {
    if (programs.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No assigned programs yet.', textAlign: TextAlign.center),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final program = programs[index];
        final progress = program.totalDays == 0
            ? 0.0
            : (program.completedDays / program.totalDays).clamp(0.0, 1.0);
        return Card(
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            title: Text(program.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  '${program.completedDays}/${program.totalDays} completed • ${_fmtDate(program.startDate)} - ${_fmtDate(program.endDate)}',
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: progress),
              ],
            ),
            children: program.days
                .map(
                  (day) => ListTile(
                    title: Text(day.label),
                    subtitle: Text(day.restDay
                        ? 'Rest day'
                        : (day.workoutName ?? 'Workout')),
                    trailing: day.restDay
                        ? const Icon(Icons.hotel)
                        : Icon(day.completed
                            ? Icons.check_circle
                            : Icons.chevron_right),
                    onTap: day.trainingSessionId == null
                        ? null
                        : () => Navigator.pushNamed(
                              context,
                              '/session',
                              arguments: day.trainingSessionId,
                            ),
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _ProgramEditorDialog extends StatefulWidget {
  final ProgramTemplateModel? program;

  const _ProgramEditorDialog({this.program});

  @override
  State<_ProgramEditorDialog> createState() => _ProgramEditorDialogState();
}

class _ProgramEditorDialogState extends State<_ProgramEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  static const List<int> _macrocycleWeekOptions = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    10,
    12,
    16,
    20,
    24,
  ];
  static const List<int> _microcycleLengthOptions = [2, 3, 4, 5, 6, 7, 8];
  late final TextEditingController _nameCtrl;
  late final TextEditingController _goalCtrl;
  late final TextEditingController _descriptionCtrl;
  late List<_MesocycleDraft> _mesocycles;
  late int _macrocycleWeeks;

  @override
  void initState() {
    super.initState();
    final program = widget.program;
    _nameCtrl = TextEditingController(text: program?.name ?? '');
    _goalCtrl = TextEditingController(text: program?.goal ?? '');
    _descriptionCtrl = TextEditingController(text: program?.description ?? '');
    _mesocycles = (program?.mesocycles ?? const <ProgramMesocycle>[])
        .map(_MesocycleDraft.fromModel)
        .toList();
    final initialWeeks = _mesocycles.fold<int>(
      0,
      (sum, mesocycle) => sum + mesocycle.weeks,
    );
    _macrocycleWeeks = _macrocycleWeekOptions.contains(initialWeeks)
        ? initialWeeks
        : (initialWeeks > 0 ? initialWeeks : 8);
    if (_mesocycles.isEmpty) {
      _mesocycles = [_MesocycleDraft.empty(1)];
    }
    _normalizeMesocycleWeeks();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _goalCtrl.dispose();
    _descriptionCtrl.dispose();
    for (final mesocycle in _mesocycles) {
      mesocycle.dispose();
    }
    super.dispose();
  }

  void _addMesocycle() {
    setState(() {
      final remainingWeeks = _remainingWeeks;
      if (remainingWeeks > 0) {
        _mesocycles.add(
          _MesocycleDraft.empty(
            _mesocycles.length + 1,
            initialWeeks: remainingWeeks,
          ),
        );
      } else {
        final donorIndex =
            _mesocycles.lastIndexWhere((mesocycle) => mesocycle.weeks > 1);
        if (donorIndex == -1) return;
        _mesocycles[donorIndex].weeks -= 1;
        _mesocycles.add(
          _MesocycleDraft.empty(
            _mesocycles.length + 1,
            initialWeeks: 1,
          ),
        );
      }
      _normalizeMesocycleWeeks();
    });
  }

  void _removeMesocycle(int index) {
    setState(() {
      _mesocycles[index].dispose();
      _mesocycles.removeAt(index);
      if (_mesocycles.isEmpty) {
        _mesocycles = [_MesocycleDraft.empty(1)];
      }
      _normalizeMesocycleWeeks();
    });
  }

  int get _allocatedWeeks =>
      _mesocycles.fold<int>(0, (sum, mesocycle) => sum + mesocycle.weeks);

  int get _remainingWeeks => _macrocycleWeeks - _allocatedWeeks;

  bool get _canAddMesocycle =>
      _remainingWeeks > 0 ||
      _mesocycles.any((mesocycle) => mesocycle.weeks > 1);

  void _setMacrocycleWeeks(int? weeks) {
    if (weeks == null) return;
    setState(() {
      _macrocycleWeeks = weeks;
      _normalizeMesocycleWeeks();
    });
  }

  void _updateMesocycleWeeks(int index, int? weeks) {
    if (weeks == null) return;
    setState(() {
      _mesocycles[index].weeks = weeks;
      _normalizeMesocycleWeeks(preferredIndex: index);
    });
  }

  void _updateMicrocycleLength(int index, int? length) {
    if (length == null) return;
    setState(() {
      _mesocycles[index].microcycleLength = length;
    });
  }

  void _normalizeMesocycleWeeks({int? preferredIndex}) {
    if (_mesocycles.isEmpty) return;

    var totalWeeks = _allocatedWeeks;
    if (totalWeeks == 0) {
      _mesocycles.first.weeks = _macrocycleWeeks;
      return;
    }

    if (totalWeeks > _macrocycleWeeks) {
      final indexes = <int>[
        if (preferredIndex != null) preferredIndex,
        ...List.generate(_mesocycles.length, (index) => index)
            .where((index) => index != preferredIndex),
      ];
      for (final index in indexes.reversed) {
        if (totalWeeks <= _macrocycleWeeks) break;
        final draft = _mesocycles[index];
        final reducible = draft.weeks - 1;
        if (reducible <= 0) continue;
        final overage = totalWeeks - _macrocycleWeeks;
        final reduction = reducible < overage ? reducible : overage;
        draft.weeks = draft.weeks - reduction;
        totalWeeks -= reduction;
      }
    } else if (totalWeeks < _macrocycleWeeks) {
      final targetIndex = preferredIndex ?? (_mesocycles.length - 1);
      _mesocycles[targetIndex].weeks += _macrocycleWeeks - totalWeeks;
    }
  }

  ProgramTemplateModel _buildProgram() {
    final mesocycles = <ProgramMesocycle>[];
    var totalDurationDays = 0;
    for (var i = 0; i < _mesocycles.length; i++) {
      final draft = _mesocycles[i];
      final weeks = draft.weeks;
      final microLength = draft.microcycleLength;
      totalDurationDays += weeks * microLength;
      mesocycles.add(
        ProgramMesocycle(
          id: draft.id,
          name: draft.nameCtrl.text.trim().isEmpty
              ? 'Mesocycle ${i + 1}'
              : draft.nameCtrl.text.trim(),
          goal: draft.goalCtrl.text.trim().isEmpty
              ? null
              : draft.goalCtrl.text.trim(),
          description: draft.descriptionCtrl.text.trim().isEmpty
              ? null
              : draft.descriptionCtrl.text.trim(),
          lengthInWeeks: weeks,
          sequenceOrder: i + 1,
          microcycle: ProgramMicrocycle(
            id: draft.microcycleId,
            name: draft.microcycleNameCtrl.text.trim().isEmpty
                ? 'Microcycle ${i + 1}'
                : draft.microcycleNameCtrl.text.trim(),
            goal: null,
            description: null,
            lengthInDays: microLength,
            sequenceOrder: 1,
            days: List.generate(
              draft.days.length,
              (dayIndex) => ProgramMicrocycleDay(
                dayIndex: dayIndex + 1,
                restDay: draft.days[dayIndex].restDay,
                workoutTemplateId: draft.days[dayIndex].restDay
                    ? null
                    : draft.days[dayIndex].workoutTemplateId,
                notes: draft.days[dayIndex].notesCtrl.text.trim().isEmpty
                    ? null
                    : draft.days[dayIndex].notesCtrl.text.trim(),
              ),
            ),
          ),
        ),
      );
    }

    return ProgramTemplateModel(
      id: widget.program?.id ?? 0,
      name: _nameCtrl.text.trim(),
      goal: _goalCtrl.text.trim().isEmpty ? null : _goalCtrl.text.trim(),
      description: _descriptionCtrl.text.trim().isEmpty
          ? null
          : _descriptionCtrl.text.trim(),
      totalDurationDays: totalDurationDays,
      mesocycles: mesocycles,
      createdAt: widget.program?.createdAt,
      updatedAt: widget.program?.updatedAt,
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, _buildProgram());
  }

  @override
  Widget build(BuildContext context) {
    final workouts = context.watch<WorkoutTemplatesProvider>().items;
    final totalDays = _mesocycles.fold<int>(
      0,
      (sum, meso) => sum + (meso.weeks * meso.microcycleLength),
    );

    return Dialog(
      child: SizedBox(
        width: 860,
        height: 760,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.program == null ? 'Create Program' : 'Edit Program',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text('Macrocycle: $_macrocycleWeeks weeks • $totalDays days'),
              const SizedBox(height: 16),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Program Name'),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty)
                                ? 'Required'
                                : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _goalCtrl,
                        decoration: const InputDecoration(labelText: 'Goal'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionCtrl,
                        decoration:
                            const InputDecoration(labelText: 'Description'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<int>(
                        value: _macrocycleWeeks,
                        decoration: const InputDecoration(
                          labelText: 'Macrocycle Duration',
                          helperText:
                              'Pick the full program length, then divide it into mesocycles.',
                        ),
                        items: _macrocycleWeekOptions
                            .map(
                              (weeks) => DropdownMenuItem<int>(
                                value: weeks,
                                child: Text('$weeks week${weeks == 1 ? '' : 's'}'),
                              ),
                            )
                            .toList(),
                        onChanged: _setMacrocycleWeeks,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'Mesocycles',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_allocatedWeeks/$_macrocycleWeeks weeks allocated',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _canAddMesocycle ? _addMesocycle : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Mesocycle'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._mesocycles.asMap().entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _MesocycleEditor(
                                draft: entry.value,
                                workouts: workouts,
                                index: entry.key,
                                availableWeeks:
                                    entry.value.weeks + _remainingWeeks,
                                microcycleLengthOptions:
                                    _microcycleLengthOptions,
                                onWeeksChanged: (value) =>
                                    _updateMesocycleWeeks(entry.key, value),
                                onMicrocycleLengthChanged: (value) =>
                                    _updateMicrocycleLength(entry.key, value),
                                canRemove: _mesocycles.length > 1,
                                onRemove: () => _removeMesocycle(entry.key),
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MesocycleEditor extends StatefulWidget {
  final _MesocycleDraft draft;
  final List<WorkoutTemplate> workouts;
  final int index;
  final int availableWeeks;
  final List<int> microcycleLengthOptions;
  final ValueChanged<int?> onWeeksChanged;
  final ValueChanged<int?> onMicrocycleLengthChanged;
  final bool canRemove;
  final VoidCallback onRemove;

  const _MesocycleEditor({
    required this.draft,
    required this.workouts,
    required this.index,
    required this.availableWeeks,
    required this.microcycleLengthOptions,
    required this.onWeeksChanged,
    required this.onMicrocycleLengthChanged,
    required this.canRemove,
    required this.onRemove,
  });

  @override
  State<_MesocycleEditor> createState() => _MesocycleEditorState();
}

class _MesocycleEditorState extends State<_MesocycleEditor> {
  void _syncDays() {
    final length = widget.draft.microcycleLength;
    setState(() {
      while (widget.draft.days.length < length) {
        widget.draft.days.add(_MicrocycleDayDraft());
      }
      if (widget.draft.days.length > length) {
        widget.draft.days.removeRange(length, widget.draft.days.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Mesocycle ${widget.index + 1}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (widget.canRemove)
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            TextFormField(
              controller: widget.draft.nameCtrl,
              decoration: const InputDecoration(labelText: 'Mesocycle Name'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: widget.draft.weeks,
                    decoration: const InputDecoration(labelText: 'Weeks'),
                    items: List.generate(widget.availableWeeks, (index) => index + 1)
                        .map(
                          (weeks) => DropdownMenuItem<int>(
                            value: weeks,
                            child:
                                Text('$weeks week${weeks == 1 ? '' : 's'}'),
                          ),
                        )
                        .toList(),
                    onChanged: widget.onWeeksChanged,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: widget.draft.microcycleLength,
                    decoration:
                        const InputDecoration(labelText: 'Microcycle Length'),
                    items: widget.microcycleLengthOptions
                        .map(
                          (length) => DropdownMenuItem<int>(
                            value: length,
                            child:
                                Text('$length day${length == 1 ? '' : 's'}'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      widget.onMicrocycleLengthChanged(value);
                      _syncDays();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.draft.goalCtrl,
              decoration: const InputDecoration(labelText: 'Mesocycle Goal'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.draft.descriptionCtrl,
              decoration:
                  const InputDecoration(labelText: 'Mesocycle Description'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.draft.microcycleNameCtrl,
              decoration: const InputDecoration(labelText: 'Microcycle Name'),
            ),
            const SizedBox(height: 16),
            Text(
              'Repeating Pattern',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...widget.draft.days.asMap().entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _PatternDayEditor(
                      dayNumber: entry.key + 1,
                      draft: entry.value,
                      workouts: widget.workouts,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _PatternDayEditor extends StatefulWidget {
  final int dayNumber;
  final _MicrocycleDayDraft draft;
  final List<WorkoutTemplate> workouts;

  const _PatternDayEditor({
    required this.dayNumber,
    required this.draft,
    required this.workouts,
  });

  @override
  State<_PatternDayEditor> createState() => _PatternDayEditorState();
}

class _PatternDayEditorState extends State<_PatternDayEditor> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pattern Day ${widget.dayNumber}'),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(value: false, label: Text('Workout')),
              ButtonSegment<bool>(value: true, label: Text('Rest')),
            ],
            selected: {widget.draft.restDay},
            onSelectionChanged: (selection) {
              setState(() => widget.draft.restDay = selection.first);
            },
          ),
          if (!widget.draft.restDay) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int>(
              value: widget.draft.workoutTemplateId,
              decoration: const InputDecoration(labelText: 'Workout'),
              items: widget.workouts
                  .map(
                    (workout) => DropdownMenuItem<int>(
                      value: workout.id,
                      child: Text(workout.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => widget.draft.workoutTemplateId = value);
              },
              validator: (value) => widget.draft.restDay || value != null
                  ? null
                  : 'Select a workout',
            ),
          ],
          const SizedBox(height: 10),
          TextFormField(
            controller: widget.draft.notesCtrl,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
        ],
      ),
    );
  }
}

class _MicrocycleDayDraft {
  bool restDay;
  int? workoutTemplateId;
  final TextEditingController notesCtrl;

  _MicrocycleDayDraft({
    this.restDay = false,
    this.workoutTemplateId,
    TextEditingController? notesCtrl,
  }) : notesCtrl = notesCtrl ?? TextEditingController();
}

class _MesocycleDraft {
  final int id;
  final int microcycleId;
  final TextEditingController nameCtrl;
  final TextEditingController goalCtrl;
  final TextEditingController descriptionCtrl;
  final TextEditingController microcycleNameCtrl;
  int weeks;
  int microcycleLength;
  final List<_MicrocycleDayDraft> days;

  _MesocycleDraft({
    required this.id,
    required this.microcycleId,
    required this.nameCtrl,
    required this.goalCtrl,
    required this.descriptionCtrl,
    required this.microcycleNameCtrl,
    required this.weeks,
    required this.microcycleLength,
    required this.days,
  });

  factory _MesocycleDraft.empty(int index, {int initialWeeks = 4}) =>
      _MesocycleDraft(
        id: 0,
        microcycleId: 0,
        nameCtrl: TextEditingController(text: 'Mesocycle $index'),
        goalCtrl: TextEditingController(),
        descriptionCtrl: TextEditingController(),
        microcycleNameCtrl: TextEditingController(text: 'Microcycle $index'),
        weeks: initialWeeks,
        microcycleLength: 4,
        days: List.generate(4, (_) => _MicrocycleDayDraft()),
      );

  factory _MesocycleDraft.fromModel(ProgramMesocycle mesocycle) =>
      _MesocycleDraft(
        id: mesocycle.id,
        microcycleId: mesocycle.microcycle.id,
        nameCtrl: TextEditingController(text: mesocycle.name),
        goalCtrl: TextEditingController(text: mesocycle.goal ?? ''),
        descriptionCtrl:
            TextEditingController(text: mesocycle.description ?? ''),
        microcycleNameCtrl:
            TextEditingController(text: mesocycle.microcycle.name),
        weeks: mesocycle.lengthInWeeks,
        microcycleLength: mesocycle.microcycle.lengthInDays,
        days: _normalizeDays(
          mesocycle.microcycle.lengthInDays,
          mesocycle.microcycle.days
              .map(
                (day) => _MicrocycleDayDraft(
                  restDay: day.restDay,
                  workoutTemplateId: day.workoutTemplateId,
                  notesCtrl: TextEditingController(text: day.notes ?? ''),
                ),
              )
              .toList(),
        ),
      );

  static List<_MicrocycleDayDraft> _normalizeDays(
    int length,
    List<_MicrocycleDayDraft> days,
  ) {
    if (days.length == length) return days;
    if (days.length > length) {
      return days.sublist(0, length);
    }
    return [
      ...days,
      ...List.generate(length - days.length, (_) => _MicrocycleDayDraft()),
    ];
  }

  void dispose() {
    nameCtrl.dispose();
    goalCtrl.dispose();
    descriptionCtrl.dispose();
    microcycleNameCtrl.dispose();
    for (final day in days) {
      day.notesCtrl.dispose();
    }
  }
}

class _ProgramAssignDialog extends StatefulWidget {
  final ProgramTemplateModel program;

  const _ProgramAssignDialog({required this.program});

  @override
  State<_ProgramAssignDialog> createState() => _ProgramAssignDialogState();
}

class _ProgramAssignDialogState extends State<_ProgramAssignDialog> {
  final Set<int> _selectedClientIds = <int>{};
  DateTime _startDate = DateTime.now();

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      initialDate: _startDate,
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clients = context.watch<ClientsProvider>().items;
    return AlertDialog(
      title: Text('Assign "${widget.program.name}"'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text('Start date: ${_fmtDate(_startDate)}')),
                TextButton(
                  onPressed: _pickStartDate,
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Select clients'),
            const SizedBox(height: 8),
            SizedBox(
              height: 320,
              child: ListView(
                children: clients
                    .map(
                      (client) => CheckboxListTile(
                        value: _selectedClientIds.contains(client.id),
                        title: Text(client.fullName),
                        subtitle:
                            client.email == null ? null : Text(client.email!),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedClientIds.add(client.id);
                            } else {
                              _selectedClientIds.remove(client.id);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedClientIds.isEmpty
              ? null
              : () => Navigator.pop(
                    context,
                    _AssignmentDraft(
                      clientIds: _selectedClientIds.toList()..sort(),
                      startDate: _startDate,
                    ),
                  ),
          child: const Text('Assign'),
        ),
      ],
    );
  }
}

class _AssignmentDraft {
  final List<int> clientIds;
  final DateTime startDate;

  const _AssignmentDraft({
    required this.clientIds,
    required this.startDate,
  });
}

String _fmtDate(DateTime date) {
  final local = DateTime(date.year, date.month, date.day);
  return '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
}
