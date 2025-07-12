// lib/screens/nutrition_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/nutrition_templates_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/navigation_provider.dart';
import '../models/nutrition_plan_template.dart';
import '../widgets/nutrition_template_widget.dart';
import '../widgets/nutrition_template_form_dialog.dart';

class NutritionPage extends StatefulWidget {
  const NutritionPage({super.key});

  @override
  State<NutritionPage> createState() => _NutritionPageState();
}

class _NutritionPageState extends State<NutritionPage> {
  final _searchCtrl = TextEditingController();
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load({int? page, String? search, String? sort}) {
    final auth = context.read<AuthProvider>();
    setState(() {
      if (sort != null) _sort = sort;
    });

    context.read<NutritionTemplatesProvider>().load(
      token: auth.token!,
      toPage: page,
      newSearch: search,
      newSort: _sort,
    );
  }

  Future<void> _openCreateDialog() async {
    await showDialog<NutritionPlanTemplate>(
      context: context,
      builder: (_) => const NutritionTemplateFormDialog(),
    );
    // Always reload first page to show latest
    _load(page: 0);
  }

  @override
  Widget build(BuildContext context) {
    context.read<NavigationProvider>().setIndex(5); // adjust if needed
    final prov = context.watch<NutritionTemplatesProvider>();

    List<NutritionPlanTemplate> sorted = List.of(prov.items);
    switch (_sort) {
      case 'name':
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'newest':
      case 'oldest':
      default:
        break; // server‑sorted
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Plans'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Sort',
            onSelected: (v) => _load(sort: v),
            icon: const Icon(Icons.sort),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'newest', child: Text('Newest')),
              PopupMenuItem(value: 'oldest', child: Text('Oldest')),
              PopupMenuItem(value: 'name', child: Text('A → Z')),
              PopupMenuItem(value: 'name_desc', child: Text('Z → A')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add plan template',
            onPressed: _openCreateDialog,
          ),
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
                  onPressed: () => _load(search: _searchCtrl.text),
                ),
              ),
              onSubmitted: (v) => _load(search: v),
            ),
          ),
          if (prov.loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: sorted.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (_, i) => NutritionTemplateWidget(
                  tpl: sorted[i],
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) =>
                        NutritionTemplateFormDialog(tpl: sorted[i]),
                  ),
                ),
              ),
            ),
          _Paginator(
            page: prov.page,
            total: prov.totalPages,
            onPageSelected: (p) => _load(page: p),
          ),
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
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: List.generate(total, (i) {
        final selected = i == page;
        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: selected ? Colors.blue : null,
            foregroundColor: selected ? Colors.white : null,
            minimumSize: const Size(40, 32),
          ),
          onPressed: () => onPageSelected(i),
          child: Text('${i + 1}'),
        );
      }),
    );
  }
}
