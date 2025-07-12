// lib/screens/workouts_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_templates_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/workout_template_widget.dart';
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
      _load();
    });
  }

  void _load({int? page, String? search, String? sort}) {
    final token = context.read<AuthProvider>().token!;
    setState(() {
      if (sort != null) _sort = sort;
    });
    context.read<WorkoutTemplatesProvider>().load(
      token: token,
      toPage: page,
      newSearch: search,
      newSort: _sort,
    );
  }

  Future<void> _openCreateDialog() async {
    final tpl = await showDialog<WorkoutTemplate>(
        context: context, builder: (_) => const WorkoutTemplateFormDialog());
    if (tpl != null) {
      final token = context.read<AuthProvider>().token!;
      await context
          .read<WorkoutTemplatesProvider>()
          .save(token: token, t: tpl);
      _load(page: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WorkoutTemplatesProvider>();

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
              tooltip: 'Add template'),
        ],
      ),
      body: Column(
        children: [
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
          if (prov.loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) => WorkoutTemplateWidget(
                  tpl: sorted[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          WorkoutTemplateDetailPage(template: sorted[i]),
                    ),
                  ),
                ),
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
