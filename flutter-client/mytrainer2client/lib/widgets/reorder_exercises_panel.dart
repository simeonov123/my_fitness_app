// lib/widgets/reorder_exercises_panel.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/workout_template_exercise.dart';
import '../providers/workout_templates_provider.dart';
import '../theme/app_density.dart';

/// Returns the updated List<WorkoutTemplateExercise> when done.
class ReorderExercisesPanel extends StatefulWidget {
  final int templateId;
  final List<WorkoutTemplateExercise> initial;

  const ReorderExercisesPanel({
    super.key,
    required this.templateId,
    required this.initial,
  });

  @override
  State<ReorderExercisesPanel> createState() => _ReorderExercisesPanelState();
}

class _ReorderExercisesPanelState extends State<ReorderExercisesPanel> {
  late List<WorkoutTemplateExercise> _list;

  @override
  void initState() {
    super.initState();
    // Make a mutable copy
    _list = List.from(widget.initial);
    // Ensure initial numbering is correct
    _renumber();
  }

  void _renumber() {
    for (var i = 0; i < _list.length; i++) {
      _list[i].sequenceOrder = i + 1;
    }
  }

  void _onDone() {
    // Final renumber (just in case)
    _renumber();
    // Update provider
    context
        .read<WorkoutTemplatesProvider>()
        .updateExercisesOrder(widget.templateId, _list);
    // Pop and return updated list
    Navigator.of(context).pop(_list);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF9FBFF),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        AppDensity.space(14),
        AppDensity.space(10),
        AppDensity.space(14),
        AppDensity.space(14),
      ),
      child: Column(
        children: [
          Container(
            width: AppDensity.space(34),
            height: AppDensity.space(4),
            decoration: BoxDecoration(
              color: const Color(0xFFD5D9E7),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          SizedBox(height: AppDensity.space(10)),
          Row(
            children: [
              Expanded(
                child: Text(
                  t.reorder_exercises,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF232530),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80FF),
                  borderRadius: AppDensity.circular(14),
                ),
                child: IconButton(
                  icon: const Icon(Icons.check_rounded, color: Colors.white),
                  onPressed: _onDone,
                ),
              ),
            ],
          ),
          SizedBox(height: AppDensity.space(4)),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Reorder the exercise flow and remove blocks you no longer want in this template.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF6F7691),
                  ),
            ),
          ),
          SizedBox(height: AppDensity.space(12)),
          Expanded(
            child: ReorderableListView.builder(
              onReorder: (oldIndex, newIndex) {
                setState(() {
                  if (newIndex > oldIndex) newIndex--;
                  final item = _list.removeAt(oldIndex);
                  _list.insert(newIndex, item);
                  // **live** renumbering
                  _renumber();
                });
              },
              itemCount: _list.length,
              itemBuilder: (ctx, idx) {
                final wte = _list[idx];
                return Container(
                  key: ValueKey('wte-${wte.exercise.id}-$idx'),
                  margin: EdgeInsets.only(bottom: AppDensity.space(8)),
                  padding: EdgeInsets.fromLTRB(
                    AppDensity.space(12),
                    AppDensity.space(10),
                    AppDensity.space(6),
                    AppDensity.space(10),
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppDensity.circular(18),
                    border: Border.all(color: const Color(0xFFDCE8FF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2F80FF).withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: AppDensity.space(28),
                        height: AppDensity.space(28),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF2FF),
                          borderRadius: AppDensity.circular(10),
                        ),
                        child: Text(
                          '${wte.sequenceOrder}',
                          style: const TextStyle(
                            color: Color(0xFF2F80FF),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      SizedBox(width: AppDensity.space(8)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wte.exercise.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF232530),
                              ),
                            ),
                            if ((wte.setType ?? '').trim().isNotEmpty) ...[
                              SizedBox(height: AppDensity.space(3)),
                              Text(
                                wte.setType!,
                                style: TextStyle(
                                  color: Color(0xFF6F7691),
                                  fontSize: AppDensity.space(10.5),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          color: Color(0xFFCC4B4B),
                        ),
                        onPressed: () => setState(() {
                          _list.removeAt(idx);
                          _renumber();
                        }),
                      ),
                      ReorderableDragStartListener(
                        index: idx,
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.drag_handle_rounded,
                            color: Color(0xFF5D6B88),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
