// lib/screens/workouts_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/workout_folder.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/workout_folders_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/workout_template_widget.dart';
import '../widgets/workout_folder_form_dialog.dart';
import '../widgets/reorder_workouts_panel.dart';
import '../widgets/workout_template_form_dialog.dart';
import '../models/workout_template.dart';
import 'workout_template_detail_page.dart';
import '../widgets/bottom_nav_bar.dart';
import '../theme/app_density.dart';

class WorkoutsPage extends StatefulWidget {
  const WorkoutsPage({super.key});

  @override
  State<WorkoutsPage> createState() => _WorkoutsPageState();
}

class _WorkoutsPageState extends State<WorkoutsPage> {
  final _searchCtrl = TextEditingController();
  String _sort = 'newest';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NavigationProvider>().setIndex(1);
      _loadAll();
    });
  }

  Future<void> _loadAll({int? page, String? search, String? sort}) async {
    await Future.wait([
      _load(page: page, search: search, sort: sort),
      context.read<WorkoutFoldersProvider>().load(),
    ]);
  }

  Future<void> _load({int? page, String? search, String? sort}) async {
    setState(() {
      if (sort != null) _sort = sort;
    });
    await context.read<WorkoutTemplatesProvider>().load(
          toPage: page,
          newSearch: search,
          newSort: _sort,
        );
  }

  Future<void> _openCreateDialog() async {
    final prov = context.read<WorkoutTemplatesProvider>();
    final folderProv = context.read<WorkoutFoldersProvider>();
    final tpl = await showDialog<WorkoutTemplate>(
        context: context, builder: (_) => const WorkoutTemplateFormDialog());
    if (tpl != null) {
      await prov.save(t: tpl);
      if (!mounted) return;
      _searchCtrl.clear();
      setState(() => _sort = 'newest');
      prov.resetViewState(newSearch: '', newSort: 'newest', newPage: 0);
      await folderProv.load();
    }
  }

  Future<void> _openFolderDialog({WorkoutFolder? folder}) async {
    final folderProv = context.read<WorkoutFoldersProvider>();
    if (!folderProv.supported) {
      _showFoldersUnavailableMessage();
      return;
    }
    final prov = folderProv;
    final edited = await showDialog<WorkoutFolder>(
      context: context,
      builder: (_) => WorkoutFolderFormDialog(folder: folder),
    );
    if (edited == null) return;

    final next = WorkoutFolder(
      id: edited.id,
      name: edited.name,
      sequenceOrder: folder?.sequenceOrder ?? prov.items.length,
      workoutCount: edited.workoutCount,
      createdAt: edited.createdAt,
      updatedAt: edited.updatedAt,
    );
    await prov.save(folder: next);
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
    await context.read<WorkoutFoldersProvider>().remove(id: folder.id);
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

    final folderProv = context.read<WorkoutFoldersProvider>();
    final workoutProv = context.read<WorkoutTemplatesProvider>();

    for (final folder in result.folders) {
      await folderProv.save(folder: folder);
    }
    for (final workout in result.workouts) {
      await workoutProv.save(t: workout);
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
    final theme = Theme.of(context);

    List<WorkoutTemplate> sorted = List.of(prov.items);
    if (_sort == 'name') {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sort == 'name_desc') {
      sorted.sort((a, b) => b.name.compareTo(a.name));
    }

    return Scaffold(
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
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (prov.loading || folderProv.loading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      0,
                      0,
                      AppDensity.space(16),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppDensity.space(14),
                          AppDensity.space(10),
                          AppDensity.space(14),
                          AppDensity.space(8),
                        ),
                        child: _WorkoutHeader(
                          searchCtrl: _searchCtrl,
                          foldersSupported: folderProv.supported,
                          onSearch: () => _load(search: _searchCtrl.text),
                          onAddFolder: () => _openFolderDialog(),
                          onOrganize: _organizeWorkouts,
                          onAddTemplate: _openCreateDialog,
                          onSortSelected: (v) => _load(sort: v),
                        ),
                      ),
                      if (!folderProv.supported)
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            AppDensity.space(14),
                            0,
                            AppDensity.space(14),
                            AppDensity.space(10),
                          ),
                          child: Container(
                            width: double.infinity,
                            padding: AppDensity.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7E7),
                              borderRadius: AppDensity.circular(20),
                              border:
                                  Border.all(color: const Color(0xFFFFE0A3)),
                            ),
                            child: Text(
                              'Workout folders require the updated backend. Workouts still load normally.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF855A00),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (folderProv.supported)
                        ...folderProv.items.map(
                          (folder) => _WorkoutFolderSection(
                            folder: folder,
                            workouts: sorted
                                .where(
                                    (workout) => workout.folderId == folder.id)
                                .toList(),
                            onEdit: () => _openFolderDialog(folder: folder),
                            onDelete: () => _deleteFolder(folder),
                            onWorkoutTap: _openTemplate,
                          ),
                        ),
                      _UngroupedSection(
                        workouts: folderProv.supported
                            ? sorted
                                .where((workout) => workout.folderId == null)
                                .toList()
                            : sorted,
                        onWorkoutTap: _openTemplate,
                      ),
                      if (sorted.isEmpty && !prov.loading)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 6, 18, 0),
                          child:
                              _EmptyWorkoutsState(onCreate: _openCreateDialog),
                        ),
                      if (prov.totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                          child: _Paginator(
                            page: prov.page,
                            total: prov.totalPages,
                            onPageSelected: (p) => _load(page: p),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

class _WorkoutHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool foldersSupported;
  final VoidCallback onSearch;
  final VoidCallback onAddFolder;
  final VoidCallback onOrganize;
  final VoidCallback onAddTemplate;
  final ValueChanged<String> onSortSelected;

  const _WorkoutHeader({
    required this.searchCtrl,
    required this.foldersSupported,
    required this.onSearch,
    required this.onAddFolder,
    required this.onOrganize,
    required this.onAddTemplate,
    required this.onSortSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFF2F80FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Workouts',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF232530),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Build, group, and reuse your strongest training blocks.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF6F7691),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2F80FF),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: IconButton(
                  onPressed: onAddTemplate,
                  tooltip: 'Add template',
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchCtrl,
            onSubmitted: (_) => onSearch(),
            decoration: InputDecoration(
              hintText: 'Search templates, descriptions, or folders',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: const Color(0xFFF7FAFF),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 18,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: Color(0xFFDCE8FF)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(
                  color: Color(0xFF2F80FF),
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (foldersSupported)
                  _HeaderActionChip(
                    icon: Icons.create_new_folder_rounded,
                    label: 'New folder',
                    onTap: onAddFolder,
                  ),
                if (foldersSupported) const SizedBox(width: 10),
                if (foldersSupported)
                  _HeaderActionChip(
                    icon: Icons.drag_indicator_rounded,
                    label: 'Organize',
                    onTap: onOrganize,
                  ),
                if (foldersSupported) const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: onSortSelected,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'newest', child: Text('Newest')),
                    PopupMenuItem(value: 'oldest', child: Text('Oldest')),
                    PopupMenuItem(value: 'name', child: Text('A → Z')),
                    PopupMenuItem(value: 'name_desc', child: Text('Z → A')),
                  ],
                  child: const _HeaderActionChip(
                    icon: Icons.sort_rounded,
                    label: 'Sort',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _HeaderActionChip({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF2F80FF)),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: const Color(0xFF33415F),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
    if (onTap == null) return child;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: child,
    );
  }
}

class _EmptyWorkoutsState extends StatelessWidget {
  final VoidCallback onCreate;

  const _EmptyWorkoutsState({required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE8FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.auto_awesome_motion_rounded,
            size: 30,
            color: Color(0xFF2F80FF),
          ),
          const SizedBox(height: 14),
          Text(
            'No workouts yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first reusable template and start building a cleaner library for sessions.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F7691),
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create workout'),
          ),
        ],
      ),
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
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 10, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.folder_open_rounded,
                    size: 22,
                    color: Color(0xFF2F80FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF21212C),
                                ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${workouts.length} workout${workouts.length == 1 ? '' : 's'}',
                          style:
                              Theme.of(context).textTheme.labelMedium?.copyWith(
                                    color: const Color(0xFF4D5A78),
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
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
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
              child: Text(
                'No workouts in this folder yet.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: const Color(0xFF6F7691),
                    ),
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
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFDCE8FF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2F80FF).withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2FF),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.layers_rounded,
                    color: Color(0xFF2F80FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ungrouped workouts',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${workouts.length} template${workouts.length == 1 ? '' : 's'} ready to sort later',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF6F7691),
                            ),
                      ),
                    ],
                  ),
                ),
              ],
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
  Widget build(BuildContext context) {
    if (total <= 1) return const SizedBox.shrink();
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(
          total,
          (i) => Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    i == page ? const Color(0xFF2F80FF) : Colors.white,
                foregroundColor:
                    i == page ? Colors.white : const Color(0xFF3B4B6C),
                side: const BorderSide(color: Color(0xFFDCE8FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size(46, 40),
              ),
              onPressed: () => onPageSelected(i),
              child: Text('${i + 1}'),
            ),
          ),
        ),
      ),
    );
  }
}
