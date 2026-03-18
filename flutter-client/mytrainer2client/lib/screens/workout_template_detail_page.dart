// lib/screens/workout_template_detail_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../models/workout_template.dart';
import '../models/workout_template_exercise.dart';
import '../widgets/workout_template_exercise_widget.dart';
import '../widgets/exercise_picker_dialog.dart';
import '../widgets/reorder_exercises_panel.dart';
import '../providers/exercises_provider.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/workout_template_exercises_provider.dart';
import '../theme/app_density.dart';
import '../l10n/app_localizations.dart';

class WorkoutTemplateDetailPage extends StatefulWidget {
  final WorkoutTemplate template;
  const WorkoutTemplateDetailPage({super.key, required this.template});

  @override
  State<WorkoutTemplateDetailPage> createState() =>
      _WorkoutTemplateDetailPageState();
}

class _WorkoutTemplateDetailPageState extends State<WorkoutTemplateDetailPage> {
  late WorkoutTemplate _tpl;
  bool _isDirty = false;

  @override
  void initState() {
    super.initState();
    _tpl = widget.template;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExercisesProvider>().loadAvailable();
      context.read<WorkoutTemplateExercisesProvider>().load(
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
              onPressed: () => Navigator.pop(context, UnsavedAction.discard),
              child: Text(loc.discard)),
          TextButton(
              onPressed: () => Navigator.pop(context, UnsavedAction.cancel),
              child: Text(loc.cancel)),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, UnsavedAction.save),
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
    final wtep = context.read<WorkoutTemplateExercisesProvider>();
    await wtep.replaceAll(
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
    final exerciseCount = wtep.items.length;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
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
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFFF7F8FF),
                Color(0xFFFFFFFF),
              ],
            ),
          ),
          child: wtep.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: EdgeInsets.fromLTRB(
                    0,
                    AppDensity.space(10),
                    0,
                    AppDensity.space(18),
                  ),
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppDensity.space(14),
                      ),
                      child: _TemplateHeroCard(
                        title: _tpl.name,
                        description: _tpl.description,
                        folderName: _tpl.folderName,
                        exerciseCount: exerciseCount,
                        isDirty: _isDirty,
                      ),
                    ),
                    SizedBox(height: AppDensity.space(6)),
                    if (wtep.items.isEmpty)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppDensity.space(14),
                        ),
                        child: _TemplateEmptyState(onAdd: _addExercises),
                      )
                    else
                      ...List.generate(wtep.items.length, (i) {
                        final wte = wtep.items[i];
                        return WorkoutTemplateExerciseWidget(
                          key: ValueKey('tpl-${_tpl.id}-wte-$i'),
                          templateId: _tpl.id,
                          wte: wte,
                          onChanged: _markDirty,
                        );
                      }),
                  ],
                ),
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
    if (!mounted) return;

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

    await wtep.replaceAll(
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
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.7,
        child: SafeArea(
          top: false,
          child: ReorderExercisesPanel(
            initial: context.read<WorkoutTemplateExercisesProvider>().items,
            templateId: _tpl.id,
          ),
        ),
      ),
    );
    if (updated != null) {
      if (!mounted) return;
      await context.read<WorkoutTemplateExercisesProvider>().replaceAll(
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
      if (!mounted) return;
      await context.read<WorkoutTemplatesProvider>().remove(id: _tpl.id);
      if (mounted) Navigator.pop(context);
    }
  }
}

enum UnsavedAction { save, discard, cancel }

class _TemplateHeroCard extends StatelessWidget {
  final String title;
  final String? description;
  final String? folderName;
  final int exerciseCount;
  final bool isDirty;

  const _TemplateHeroCard({
    required this.title,
    required this.description,
    required this.folderName,
    required this.exerciseCount,
    required this.isDirty,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDensity.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDensity.circular(26),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppDensity.space(44),
                height: AppDensity.space(44),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: AppDensity.circular(16),
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
                      title,
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF232530),
                              ),
                    ),
                    SizedBox(height: AppDensity.space(3)),
                    Text(
                      description?.trim().isNotEmpty == true
                          ? description!.trim()
                          : 'Reusable workout structure for future sessions.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6F7691),
                            height: 1.35,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppDensity.space(12)),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                icon: Icons.list_alt_rounded,
                label:
                    '$exerciseCount exercise${exerciseCount == 1 ? '' : 's'}',
              ),
              if (folderName?.trim().isNotEmpty == true)
                _HeroPill(
                  icon: Icons.folder_open_rounded,
                  label: folderName!.trim(),
                ),
              _HeroPill(
                icon: isDirty
                    ? Icons.edit_note_rounded
                    : Icons.check_circle_outline,
                label: isDirty ? 'Unsaved changes' : 'Saved',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroPill({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDensity.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: AppDensity.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xFF2F80FF)),
          SizedBox(width: AppDensity.space(5)),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF3E4A67),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _TemplateEmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _TemplateEmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppDensity.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDensity.circular(24),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_motion_rounded,
              color: Color(0xFF2F80FF)),
          SizedBox(height: AppDensity.space(12)),
          Text(
            'No exercises yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          SizedBox(height: AppDensity.space(6)),
          Text(
            'Start building the template by adding the first exercise block.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F7691),
                ),
          ),
          SizedBox(height: AppDensity.space(12)),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add exercise'),
          ),
        ],
      ),
    );
  }
}
