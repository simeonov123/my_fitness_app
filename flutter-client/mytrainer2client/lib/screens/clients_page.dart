// lib/screens/clients_page.dart
// (Enhanced) – adds:
//   • FloatingActionButton that opens a create‑client dialog
//   • Popup sort menu (newest | oldest | A→Z | Z→A)
//   • Keeps paging, search, avatars exactly as before.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clients_provider.dart';
import '../providers/client_folders_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/navigation_provider.dart';
import '../models/client.dart';
import '../models/client_folder.dart';
import '../widgets/client_widget.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/client_folder_form_dialog.dart';
import '../widgets/client_invite_dialog.dart';
import '../widgets/reorder_clients_panel.dart';
import '../theme/app_density.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll({int? page, String? search, String? sort}) async {
    await Future.wait([
      _load(page: page, search: search, sort: sort),
      context.read<ClientFoldersProvider>().load(),
    ]);
  }

  Future<void> _load({int? page, String? search, String? sort}) async {
    setState(() {
      if (sort != null) _sort = sort;
    });

    await context.read<ClientsProvider>().load(
          toPage: page,
          newSearch: search,
          newSort: _sort,
        );
  }

  Future<void> _openCreateDialog() async {
    final created = await showDialog<Client>(
      context: context,
      builder: (_) => const ClientFormDialog(),
    );
    if (created != null) {
      _searchCtrl.clear();
      await _loadAll(page: 0, search: '', sort: 'newest');
    }
  }

  Future<void> _openInviteDialog(Client client) async {
    await showDialog<void>(
      context: context,
      builder: (_) => ClientInviteDialog(client: client),
    );
  }

  Future<void> _openFolderDialog({ClientFolder? folder}) async {
    final folderProv = context.read<ClientFoldersProvider>();
    if (!folderProv.supported) {
      _showFoldersUnavailableMessage();
      return;
    }
    final edited = await showDialog<ClientFolder>(
      context: context,
      builder: (_) => ClientFolderFormDialog(folder: folder),
    );
    if (edited == null) return;
    if (!mounted) return;
    final next = ClientFolder(
      id: edited.id,
      name: edited.name,
      sequenceOrder: folder?.sequenceOrder ?? folderProv.items.length,
      clientCount: edited.clientCount,
      createdAt: edited.createdAt,
      updatedAt: edited.updatedAt,
    );
    await folderProv.save(folder: next);
    if (!mounted) return;
    await _loadAll(page: 0);
  }

  Future<void> _deleteFolder(ClientFolder folder) async {
    if (!context.read<ClientFoldersProvider>().supported) {
      _showFoldersUnavailableMessage();
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text('Remove "${folder.name}"? Clients will stay ungrouped.'),
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
    await context.read<ClientFoldersProvider>().remove(id: folder.id);
    if (!mounted) return;
    await _loadAll(page: 0);
  }

  Future<void> _organizeClients() async {
    final folderProv = context.read<ClientFoldersProvider>();
    if (!folderProv.supported) {
      _showFoldersUnavailableMessage();
      return;
    }

    final result = await showModalBottomSheet<ReorderClientsResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.88,
        child: ReorderClientsPanel(
          folders: folderProv.items,
          clients: context.read<ClientsProvider>().items,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final clientProv = context.read<ClientsProvider>();
    for (final folder in result.folders) {
      await folderProv.save(folder: folder);
    }
    for (final client in result.clients) {
      await clientProv.save(c: client);
    }
    if (!mounted) return;
    await _loadAll(page: 0);
  }

  void _showFoldersUnavailableMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Client folders are not available on the current backend build yet.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<NavigationProvider>().setIndex(4);
    });
    final prov = context.watch<ClientsProvider>();
    final folderProv = context.watch<ClientFoldersProvider>();
    final theme = Theme.of(context);

    // Only do local sort for names—date‐based sorts come straight from the server.
    List<Client> sorted = List.of(prov.items);
    switch (_sort) {
      case 'name':
        sorted.sort((a, b) => a.fullName.compareTo(b.fullName));
        break;
      case 'name_desc':
        sorted.sort((a, b) => b.fullName.compareTo(a.fullName));
        break;
      case 'newest':
      case 'oldest':
      default:
        // no local mutation; server has already applied the right date ordering
        break;
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
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      AppDensity.space(10),
                      0,
                      AppDensity.space(16),
                    ),
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppDensity.space(14),
                          0,
                          AppDensity.space(14),
                          AppDensity.space(8),
                        ),
                        child: _ClientsHeader(
                          searchCtrl: _searchCtrl,
                          foldersSupported: folderProv.supported,
                          onSearch: () => _load(search: _searchCtrl.text),
                          onAddFolder: () => _openFolderDialog(),
                          onOrganize: _organizeClients,
                          onCreate: _openCreateDialog,
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
                              'Client folders require the updated backend. Clients still load normally.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF855A00),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      if (folderProv.supported)
                        ...folderProv.items.map(
                          (folder) => _ClientFolderSection(
                            folder: folder,
                            clients: sorted
                                .where((client) => client.folderId == folder.id)
                                .toList(),
                            onInvite: _openInviteDialog,
                            onEdit: () => _openFolderDialog(folder: folder),
                            onDelete: () => _deleteFolder(folder),
                          ),
                        ),
                      _UngroupedClientsSection(
                        clients: folderProv.supported
                            ? sorted
                                .where((client) => client.folderId == null)
                                .toList()
                            : sorted,
                        onInvite: _openInviteDialog,
                      ),
                      if (sorted.isEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                          child:
                              _ClientsEmptyState(onCreate: _openCreateDialog),
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

class _ClientsHeader extends StatelessWidget {
  final TextEditingController searchCtrl;
  final bool foldersSupported;
  final VoidCallback onSearch;
  final VoidCallback onAddFolder;
  final VoidCallback onOrganize;
  final VoidCallback onCreate;
  final ValueChanged<String> onSortSelected;

  const _ClientsHeader({
    required this.searchCtrl,
    required this.foldersSupported,
    required this.onSearch,
    required this.onAddFolder,
    required this.onOrganize,
    required this.onCreate,
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
                  Icons.group_rounded,
                  color: Color(0xFF2F80FF),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clients',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF232530),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keep your athlete roster organized, searchable, and ready to invite.',
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
                  onPressed: onCreate,
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
              hintText: 'Search clients, email, or folders',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: IconButton(
                onPressed: onSearch,
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
              filled: true,
              fillColor: const Color(0xFFF7FAFF),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                borderSide:
                    const BorderSide(color: Color(0xFF2F80FF), width: 1.4),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (foldersSupported)
                  _ClientsActionChip(
                    icon: Icons.create_new_folder_rounded,
                    label: 'New folder',
                    onTap: onAddFolder,
                  ),
                if (foldersSupported) const SizedBox(width: 10),
                if (foldersSupported)
                  _ClientsActionChip(
                    icon: Icons.drag_indicator_rounded,
                    label: 'Organize',
                    onTap: onOrganize,
                  ),
                if (foldersSupported) const SizedBox(width: 10),
                PopupMenuButton<String>(
                  tooltip: 'Sort',
                  onSelected: onSortSelected,
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'newest', child: Text('Newest')),
                    PopupMenuItem(value: 'oldest', child: Text('Oldest')),
                    PopupMenuItem(value: 'name', child: Text('A → Z')),
                    PopupMenuItem(value: 'name_desc', child: Text('Z → A')),
                  ],
                  child: const _ClientsActionChip(
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

class _ClientsActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _ClientsActionChip({
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

class _ClientsEmptyState extends StatelessWidget {
  final VoidCallback onCreate;

  const _ClientsEmptyState({required this.onCreate});

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
          const Icon(Icons.groups_rounded, size: 30, color: Color(0xFF2F80FF)),
          const SizedBox(height: 14),
          Text(
            'No clients yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first client profile and start building your roster.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFF6F7691),
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add client'),
          ),
        ],
      ),
    );
  }
}

class _ClientFolderSection extends StatelessWidget {
  final ClientFolder folder;
  final List<Client> clients;
  final ValueChanged<Client> onInvite;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientFolderSection({
    required this.folder,
    required this.clients,
    required this.onInvite,
    required this.onEdit,
    required this.onDelete,
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
                                ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4F8FF),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${clients.length} client${clients.length == 1 ? '' : 's'}',
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
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Rename folder',
                ),
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete folder',
                ),
              ],
            ),
          ),
          if (clients.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(18, 0, 18, 18),
              child: Text('No clients in this folder yet.'),
            )
          else
            ...clients.map(
              (client) => ClientWidget(
                client: client,
                onInviteTap: () => onInvite(client),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/client',
                  arguments: client,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UngroupedClientsSection extends StatelessWidget {
  final List<Client> clients;
  final ValueChanged<Client> onInvite;

  const _UngroupedClientsSection({
    required this.clients,
    required this.onInvite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 14, 18, 12),
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
                        'Ungrouped clients',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${clients.length} client${clients.length == 1 ? '' : 's'} ready to sort later',
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
          if (clients.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No ungrouped clients.'),
            )
          else
            ...clients.map(
              (client) => ClientWidget(
                client: client,
                onInviteTap: () => onInvite(client),
                onTap: () => Navigator.pushNamed(
                  context,
                  '/client',
                  arguments: client,
                ),
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
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(total, (i) {
          final selected = i == page;
          return Padding(
            padding: EdgeInsets.only(right: i == total - 1 ? 0 : 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor:
                    selected ? const Color(0xFF2F80FF) : Colors.white,
                foregroundColor:
                    selected ? Colors.white : const Color(0xFF3B4B6C),
                side: const BorderSide(color: Color(0xFFDCE8FF)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size(46, 40),
              ),
              onPressed: () => onPageSelected(i),
              child: Text('${i + 1}'),
            ),
          );
        }),
      ),
    );
  }
}
