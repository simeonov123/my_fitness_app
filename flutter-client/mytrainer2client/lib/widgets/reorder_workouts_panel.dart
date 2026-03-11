import 'package:flutter/material.dart';

import '../models/workout_folder.dart';
import '../models/workout_template.dart';

class ReorderWorkoutsResult {
  final List<WorkoutFolder> folders;
  final List<WorkoutTemplate> workouts;

  const ReorderWorkoutsResult({
    required this.folders,
    required this.workouts,
  });
}

class ReorderWorkoutsPanel extends StatefulWidget {
  final List<WorkoutFolder> folders;
  final List<WorkoutTemplate> workouts;

  const ReorderWorkoutsPanel({
    super.key,
    required this.folders,
    required this.workouts,
  });

  @override
  State<ReorderWorkoutsPanel> createState() => _ReorderWorkoutsPanelState();
}

class _ReorderWorkoutsPanelState extends State<ReorderWorkoutsPanel> {
  late List<WorkoutFolder> _folders;
  late List<WorkoutTemplate> _ungrouped;
  late Map<int, List<WorkoutTemplate>> _folderWorkouts;

  @override
  void initState() {
    super.initState();
    _folders = List.of(widget.folders)
      ..sort((a, b) => (a.sequenceOrder ?? 0).compareTo(b.sequenceOrder ?? 0));
    final sortedWorkouts = List.of(widget.workouts)
      ..sort(
        (a, b) => (a.sequenceOrder ?? 0).compareTo(b.sequenceOrder ?? 0),
      );
    _ungrouped =
        sortedWorkouts.where((workout) => workout.folderId == null).toList();
    _folderWorkouts = {
      for (final folder in _folders)
        folder.id:
            sortedWorkouts.where((workout) => workout.folderId == folder.id).toList(),
    };
  }

  void _persistAndClose() {
    final folders = <WorkoutFolder>[];
    final workouts = <WorkoutTemplate>[];

    for (var i = 0; i < _folders.length; i++) {
      final folder = _folders[i];
      folders.add(
        WorkoutFolder(
          id: folder.id,
          name: folder.name,
          sequenceOrder: i,
          workoutCount: (_folderWorkouts[folder.id] ?? const []).length,
          createdAt: folder.createdAt,
          updatedAt: folder.updatedAt,
        ),
      );
    }

    for (var i = 0; i < _ungrouped.length; i++) {
      final workout = _ungrouped[i];
      workouts.add(
        WorkoutTemplate(
          id: workout.id,
          name: workout.name,
          description: workout.description,
          folderId: null,
          folderName: null,
          sequenceOrder: i,
          exercises: workout.exercises,
          createdAt: workout.createdAt,
          updatedAt: workout.updatedAt,
        ),
      );
    }

    for (final folder in folders) {
      final entries = _folderWorkouts[folder.id] ?? const <WorkoutTemplate>[];
      for (var i = 0; i < entries.length; i++) {
        final workout = entries[i];
        workouts.add(
          WorkoutTemplate(
            id: workout.id,
            name: workout.name,
            description: workout.description,
            folderId: folder.id,
            folderName: folder.name,
            sequenceOrder: i,
            exercises: workout.exercises,
            createdAt: workout.createdAt,
            updatedAt: workout.updatedAt,
          ),
        );
      }
    }

    Navigator.of(context).pop(
      ReorderWorkoutsResult(folders: folders, workouts: workouts),
    );
  }

  void _moveWorkout(WorkoutTemplate workout, {required int? targetFolderId}) {
    setState(() {
      _removeWorkout(workout);
      if (targetFolderId == null) {
        _ungrouped.add(workout);
      } else {
        _folderWorkouts[targetFolderId] ??= [];
        _folderWorkouts[targetFolderId]!.add(workout);
      }
    });
  }

  void _removeWorkout(WorkoutTemplate workout) {
    _ungrouped.removeWhere((item) => item.id == workout.id);
    for (final entry in _folderWorkouts.entries) {
      entry.value.removeWhere((item) => item.id == workout.id);
    }
  }

  Widget _buildWorkoutTile(
    WorkoutTemplate workout, {
    required Key key,
    int? folderId,
    int? reorderIndex,
  }) {
    return Draggable<WorkoutTemplate>(
      key: key,
      data: workout,
      maxSimultaneousDrags: 1,
      feedback: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Card(
            margin: EdgeInsets.zero,
            child: ListTile(
              dense: true,
              title: Text(workout.name),
              subtitle: Text(folderId == null ? 'Ungrouped' : 'Move workout'),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _WorkoutPanelTile(
          workout: workout,
          reorderIndex: reorderIndex,
        ),
      ),
      child: _WorkoutPanelTile(
        workout: workout,
        reorderIndex: reorderIndex,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'Organize workouts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: _persistAndClose,
                icon: const Icon(Icons.check),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _DragSection(
                    title: 'Ungrouped Workouts',
                    subtitle: 'Drag workouts here to remove them from folders',
                    dropHint: 'Drop a workout here to ungroup it',
                    onAccept: (workout) =>
                        _moveWorkout(workout, targetFolderId: null),
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _ungrouped.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) newIndex--;
                          final item = _ungrouped.removeAt(oldIndex);
                          _ungrouped.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (_, index) => _buildWorkoutTile(
                        _ungrouped[index],
                        key: ValueKey('ungrouped-${_ungrouped[index].id}'),
                        reorderIndex: index,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _folders.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex--;
                        final folder = _folders.removeAt(oldIndex);
                        _folders.insert(newIndex, folder);
                      });
                    },
                    itemBuilder: (_, index) {
                      final folder = _folders[index];
                      final workouts = _folderWorkouts[folder.id] ?? [];
                      return Container(
                        key: ValueKey('folder-${folder.id}'),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _DragSection(
                          title: folder.name,
                          subtitle:
                              'Drop workouts here. Reorder with the drag handles.',
                          dropHint: 'Drop a workout here to move it into ${folder.name}',
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                          onAccept: (workout) =>
                              _moveWorkout(workout, targetFolderId: folder.id),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: workouts.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = workouts.removeAt(oldIndex);
                                workouts.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (_, workoutIndex) => _buildWorkoutTile(
                              workouts[workoutIndex],
                              key: ValueKey(
                                'folder-${folder.id}-workout-${workouts[workoutIndex].id}',
                              ),
                              folderId: folder.id,
                              reorderIndex: workoutIndex,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragSection extends StatelessWidget {
  final String title;
  final String subtitle;
  final String dropHint;
  final Widget child;
  final Widget? trailing;
  final ValueChanged<WorkoutTemplate> onAccept;

  const _DragSection({
    required this.title,
    required this.subtitle,
    required this.dropHint,
    required this.child,
    required this.onAccept,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
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
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 8),
          _DropLane(
            hint: dropHint,
            onAccept: onAccept,
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _DropLane extends StatelessWidget {
  final String hint;
  final ValueChanged<WorkoutTemplate> onAccept;

  const _DropLane({
    required this.hint,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<WorkoutTemplate>(
      onWillAcceptWithDetails: (_) => true,
      onAcceptWithDetails: (details) => onAccept(details.data),
      builder: (context, candidateData, rejectedData) {
        final active = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFE3F2FD) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active ? const Color(0xFF1976D2) : Colors.grey.shade400,
              width: active ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                active ? Icons.move_down : Icons.input,
                color: active ? const Color(0xFF1976D2) : Colors.grey.shade700,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  active ? 'Release to move workout here' : hint,
                  style: TextStyle(
                    color: active ? const Color(0xFF1976D2) : Colors.grey.shade800,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WorkoutPanelTile extends StatelessWidget {
  final WorkoutTemplate workout;
  final int? reorderIndex;

  const _WorkoutPanelTile({
    required this.workout,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(workout.name),
        subtitle: workout.description?.isNotEmpty == true
            ? Text(
                workout.description!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : null,
        trailing: reorderIndex == null
            ? const Icon(Icons.open_with)
            : ReorderableDragStartListener(
                index: reorderIndex!,
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(Icons.drag_handle),
                ),
              ),
      ),
    );
  }
}
