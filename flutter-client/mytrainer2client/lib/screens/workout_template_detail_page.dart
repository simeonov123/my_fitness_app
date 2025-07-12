// lib/screens/workout_template_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/workout_template_exercise.dart';
import '../widgets/workout_template_exercise_widget.dart';
import '../widgets/exercise_picker_dialog.dart';
import '../widgets/reorder_exercises_panel.dart';
import '../providers/auth_provider.dart';
import '../providers/exercises_provider.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/workout_template_exercises_provider.dart';
import '../l10n/app_localizations.dart';

class WorkoutTemplateDetailPage extends StatefulWidget {
  final WorkoutTemplate template;
  const WorkoutTemplateDetailPage({super.key, required this.template});

  @override
  State<WorkoutTemplateDetailPage> createState() =>
      _WorkoutTemplateDetailPageState();
}

class _WorkoutTemplateDetailPageState
    extends State<WorkoutTemplateDetailPage> {
  late WorkoutTemplate _tpl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _tpl = widget.template;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().token!;
      context.read<ExercisesProvider>().loadCommon();
      context.read<WorkoutTemplateExercisesProvider>().load(
        token: token,
        templateId: _tpl.id,
      );
    });
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final loc = AppLocalizations.of(context)!;
    final action = await showDialog<UnsavedAction>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.unsaved_changes_title),
        content: Text(loc.unsaved_changes_body),
        actions: [
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, UnsavedAction.discard),
              child: Text(loc.discard)),
          TextButton(
              onPressed: () =>
                  Navigator.pop(context, UnsavedAction.cancel),
              child: Text(loc.cancel)),
          ElevatedButton(
              onPressed: () =>
                  Navigator.pop(context, UnsavedAction.save),
              child: Text(loc.save)),
        ],
      ),
    );
    switch (action) {
      case UnsavedAction.save:
        await _saveAll();
        return true;
      case UnsavedAction.discard:
        return true;
      case UnsavedAction.cancel:
      default:
        return false;
    }
  }

  Future<void> _saveAll() async {
    final token = context.read<AuthProvider>().token!;
    final wtep = context.read<WorkoutTemplateExercisesProvider>();
    await wtep.replaceAll(
      token: token,
      templateId: _tpl.id,
      newList: List.from(wtep.items),
    );
    setState(() => _isDirty = false);
  }

  void _markDirty() {
    if (!_isDirty) setState(() => _isDirty = true);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final wtep = context.watch<WorkoutTemplateExercisesProvider>();

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_tpl.name),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteTemplate,
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: _reorderExercises,
            ),
            if (_isDirty)
              IconButton(
                icon: const Icon(Icons.save),
                tooltip: loc.save,
                onPressed: _saveAll,
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addExercises,
          child: const Icon(Icons.add),
        ),
        body: wtep.loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
          itemCount: wtep.items.length,
          itemBuilder: (_, i) {
            final wte = wtep.items[i];
            return WorkoutTemplateExerciseWidget(
              key: ValueKey('tpl-${_tpl.id}-wte-$i'),
              templateId: _tpl.id,
              wte: wte,
              onChanged: _markDirty,
            );
          },
        ),
      ),
    );
  }

  Future<void> _addExercises() async {
    final picked = await showDialog<List<Exercise>>(
      context: context,
      builder: (_) => const ExercisePickerDialog(),
    );
    if (picked == null || picked.isEmpty) return;

    final wtep = context.read<WorkoutTemplateExercisesProvider>();
    final current = List<WorkoutTemplateExercise>.from(wtep.items);

    for (var ex in picked) {
      current.add(WorkoutTemplateExercise(
        id: 0,
        exercise: ex,
        sequenceOrder: current.length + 1,
        setType: ex.defaultSetType,
        setParams: ex.defaultSetParams,
        notes: '',
        sets: [],
      ));
    }

    final token = context.read<AuthProvider>().token!;
    await wtep.replaceAll(
      token: token,
      templateId: _tpl.id,
      newList: current,
    );

    setState(() => _isDirty = false);
  }

  Future<void> _reorderExercises() async {
    final updated = await showModalBottomSheet<List<WorkoutTemplateExercise>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, sc) => ReorderExercisesPanel(
            initial: context.read<WorkoutTemplateExercisesProvider>().items,
            templateId: _tpl.id,
          ),
        ),
      ),
    );
    if (updated != null) {
      final token = context.read<AuthProvider>().token!;
      await context
          .read<WorkoutTemplateExercisesProvider>()
          .replaceAll(
        token: token,
        templateId: _tpl.id,
        newList: updated,
      );
      setState(() => _isDirty = false);
    }
  }

  Future<void> _deleteTemplate() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete template?'),
        content: Text('Remove "${_tpl.name}" permanently?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      final token = context.read<AuthProvider>().token!;
      await context
          .read<WorkoutTemplatesProvider>()
          .remove(token: token, id: _tpl.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

enum UnsavedAction { save, discard, cancel }
