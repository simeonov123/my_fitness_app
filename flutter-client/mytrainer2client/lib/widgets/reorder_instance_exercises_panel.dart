import 'package:flutter/material.dart';
import '../models/instance_item.dart';

/// Bottom-sheet that re-orders (and optionally deletes) instance exercises.
/// Returns a **new ordered List<InstanceItem>** when the user taps ✔.
class ReorderInstanceExercisesPanel extends StatefulWidget {
  const ReorderInstanceExercisesPanel({super.key, required this.initial});

  final List<InstanceItem> initial;

  @override
  State<ReorderInstanceExercisesPanel> createState() =>
      _ReorderInstanceExercisesPanelState();
}

class _ReorderInstanceExercisesPanelState
    extends State<ReorderInstanceExercisesPanel> {
  late List<InstanceItem> _list;

  @override
  void initState() {
    super.initState();
    _list = List.from(widget.initial);   // make a mutable copy
    _renumber();
  }

  void _renumber() {
    for (var i = 0; i < _list.length; i++) {
      _list[i].wte.sequenceOrder = i + 1;
    }
  }

  void _done() {
    _renumber();
    Navigator.of(context).pop(_list);    // return new order
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Re-order exercises',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.check), onPressed: _done),
            ],
          ),
          const Divider(),
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _list.length,
              onReorder: (oldIdx, newIdx) {
                setState(() {
                  if (newIdx > oldIdx) newIdx--;
                  final item = _list.removeAt(oldIdx);
                  _list.insert(newIdx, item);
                  _renumber();
                });
              },
              itemBuilder: (_, idx) {
                final it = _list[idx];
                return ListTile(
                  key: ValueKey('inst-${it.instanceId}-${it.wte.exercise.id}'),
                  leading: Text('${it.wte.sequenceOrder}.'),
                  title: Text(it.wte.exercise.name),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setState(() {
                          _list.removeAt(idx);
                          _renumber();
                        }),
                      ),
                      ReorderableDragStartListener(
                          index: idx, child: const Icon(Icons.drag_handle)),
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
