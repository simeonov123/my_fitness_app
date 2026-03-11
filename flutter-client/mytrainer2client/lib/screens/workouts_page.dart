// lib/screens/workouts_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_folder.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/workout_folders_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/workout_template_widget.dart';
import '../widgets/workout_folder_form_dialog.dart';
import '../widgets/reorder_workouts_panel.dart';
import '../widgets/workout_template_form_dialog.dart';
import '../models/workout_template.dart';
import 'workout_template_detail_page.dart';
import '../widgets/bottom_nav_bar.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final _searchCtrl = TextEditingController();
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().setIndex(1);
      _loadAll();
    });
  }

  Future<void> _loadAll({int? page, String? search, String? sort}) async {
    final token = context.read<AuthProvider>().token!;
    await Future.wait([
      _load(page: page, search: search, sort: sort),
      context.read<WorkoutFoldersProvider>().load(token: token),
    ]);
  }

  Future<void> _load({int? page, String? search, String? sort}) async {
    final token = context.read<AuthProvider>().token!;
    setState(() {
      if (sort != null) _sort = sort;
    });
    await context.read<WorkoutTemplatesProvider>().load(
      token: token,
      toPage: page,
      newSearch: search,
      newSort: _sort,
    );
  }

  Future<void> _openCreateDialog() async {
    final auth = context.read<AuthProvider>();
    final prov = context.read<WorkoutTemplatesProvider>();
    final folderProv = context.read<WorkoutFoldersProvider>();
    final tpl = await showDialog<WorkoutTemplate>(
        context: context, builder: (_) => const WorkoutTemplateFormDialog());
    if (tpl != null) {
      final token = auth.token!;
      await prov.save(token: token, t: tpl);
      if (!mounted) return;
      _searchCtrl.clear();
      setState(() => _sort = 'newest');
      prov.resetViewState(newSearch: '', newSort: 'newest', newPage: 0);
      await folderProv.load(token: token);
    }
  }

  Future<void> _openFolderDialog({WorkoutFolder? folder}) async {
    final folderProv = context.read<WorkoutFoldersProvider>();
    if (!folderProv.supported) {
      _showFoldersUnavailableMessage();
      return;
    }
    final auth = context.read<AuthProvider>();
    final prov = folderProv;
    final edited = await showDialog<WorkoutFolder>(
      context: context,
      builder: (_) => WorkoutFolderFormDialog(folder: folder),
    );
    if (edited == null) return;

    final token = auth.token!;
    final next = WorkoutFolder(
      id: edited.id,
      name: edited.name,
      sequenceOrder: folder?.sequenceOrder ?? prov.items.length,
      workoutCount: edited.workoutCount,
      createdAt: edited.createdAt,
      updatedAt: edited.updatedAt,
    );
    await prov.save(token: token, folder: next);
    if (!mounted) return;
    await _loadAll(page: 0);
  }

  Future<void> _deleteFolder(WorkoutFolder folder) async {
    if (!context.read<WorkoutFoldersProvider>().supported) {
      _showFoldersUnavailableMessage();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text('Remove "${folder.name}"? Workouts will stay ungrouped.'),
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
    if (ok != true || !mounted) return;
    final token = context.read<AuthProvider>().token!;
    await context.read<WorkoutFoldersProvider>().remove(token: token, id: folder.id);
    if (!mounted) return;
    await _loadAll(page: 0);
  }

  Future<void> _organizeWorkouts() async {
    if (!context.read<WorkoutFoldersProvider>().supported) {
      _showFoldersUnavailableMessage();
      return;
    }
    final result = await showModalBottomSheet<ReorderWorkoutsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.9,
          minChildSize: 0.6,
          maxChildSize: 0.96,
          expand: false,
          builder: (_, __) => ReorderWorkoutsPanel(
            folders: context.read<WorkoutFoldersProvider>().items,
            workouts: context.read<WorkoutTemplatesProvider>().items,
          ),
        ),
      ),
    );
    if (result == null || !mounted) return;

    final token = context.read<AuthProvider>().token!;
    final folderProv = context.read<WorkoutFoldersProvider>();
    final workoutProv = context.read<WorkoutTemplatesProvider>();

    for (final folder in result.folders) {
      await folderProv.save(token: token, folder: folder);
    }
    for (final workout in result.workouts) {
      await workoutProv.save(token: token, t: workout);
    }
    if (!mounted) return;
    await _loadAll(page: 0);
  }

  void _openTemplate(WorkoutTemplate template) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutTemplateDetailPage(template: template),
      ),
    );
  }

  void _showFoldersUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Workout folders are not available on the current backend build yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WorkoutTemplatesProvider>();
    final folderProv = context.watch<WorkoutFoldersProvider>();

    List<WorkoutTemplate> sorted = List.of(prov.items);
    if (_sort == 'name') {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sort == 'name_desc') {
      sorted.sort((a, b) => b.name.compareTo(a.name));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        actions: [
          if (folderProv.supported)
            IconButton(
              onPressed: () => _openFolderDialog(),
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Add folder',
            ),
          if (folderProv.supported)
            IconButton(
              onPressed: _organizeWorkouts,
              icon: const Icon(Icons.drive_file_move_outline),
              tooltip: 'Organize workouts',
            ),
          PopupMenuButton<String>(
            onSelected: (v) => _load(sort: v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest')),
              PopupMenuItem(value: 'name', child: Text('A → Z')),
              PopupMenuItem(value: 'name_desc', child: Text('Z → A')),
            ],
            icon: const Icon(Icons.sort),
          ),
          IconButton(
            onPressed: _openCreateDialog,
            icon: const Icon(Icons.add),
            tooltip: 'Add template',
          ),
        ],
      ),
      body: Column(
        children: [
          if (!folderProv.supported)
            Container(
              width: double.infinity,
              color: const Color(0xFFFFF3CD),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: const Text(
                'Workout folders require the updated backend. Workouts still load normally.',
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                  hintText: 'Search…',
                  suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () => _load(search: _searchCtrl.text))),
              onSubmitted: (v) => _load(search: v),
            ),
          ),
          if (prov.loading || folderProv.loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView(
                children: [
                  if (folderProv.supported)
                    ...folderProv.items.map(
                      (folder) => _WorkoutFolderSection(
                        folder: folder,
                        workouts: sorted
                            .where((workout) => workout.folderId == folder.id)
                            .toList(),
                        onEdit: () => _openFolderDialog(folder: folder),
                        onDelete: () => _deleteFolder(folder),
                        onWorkoutTap: _openTemplate,
                      ),
                    ),
                  _UngroupedSection(
                    workouts: folderProv.supported
                        ? sorted.where((workout) => workout.folderId == null).toList()
                        : sorted,
                    onWorkoutTap: _openTemplate,
                  ),
                ],
              ),
            ),
          _Paginator(
              page: prov.page,
              total: prov.totalPages,
              onPageSelected: (p) => _load(page: p)),
        ],
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _WorkoutFolderSection extends StatelessWidget {
  final WorkoutFolder folder;
  final List<WorkoutTemplate> workouts;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<WorkoutTemplate> onWorkoutTap;

  const _WorkoutFolderSection({
    required this.folder,
    required this.workouts,
    required this.onEdit,
    required this.onDelete,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.folder_open, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        '${workouts.length} workout${workouts.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Rename')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
          if (workouts.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                'No workouts in this folder yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          else
            ...workouts.map(
              (workout) => WorkoutTemplateWidget(
                tpl: workout,
                onTap: () => onWorkoutTap(workout),
              ),
            ),
        ],
      ),
    );
  }
}

class _UngroupedSection extends StatelessWidget {
  final List<WorkoutTemplate> workouts;
  final ValueChanged<WorkoutTemplate> onWorkoutTap;

  const _UngroupedSection({
    required this.workouts,
    required this.onWorkoutTap,
  });

  @override
  Widget build(BuildContext context) {
    if (workouts.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(
              'Ungrouped Workouts',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ...workouts.map(
            (workout) => WorkoutTemplateWidget(
              tpl: workout,
              onTap: () => onWorkoutTap(workout),
            ),
          ),
        ],
      ),
    );
  }
}

class _Paginator extends StatelessWidget {
  final int page, total;
  final ValueChanged<int> onPageSelected;
  const _Paginator(
      {required this.page, required this.total, required this.onPageSelected});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    children: List.generate(
      total,
          (i) => OutlinedButton(
        style: OutlinedButton.styleFrom(
            backgroundColor: i == page ? Colors.blue : null,
            foregroundColor: i == page ? Colors.white : null,
            minimumSize: const Size(40, 32)),
        onPressed: () => onPageSelected(i),
        child: Text('${i + 1}'),
      ),
    ),
  );
}
