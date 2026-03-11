// lib/screens/clients_page.dart
// (Enhanced) – adds:
//   • FloatingActionButton that opens a create‑client dialog
//   • Popup sort menu (newest | oldest | A→Z | Z→A)
//   • Keeps paging, search, avatars exactly as before.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clients_provider.dart';
import '../providers/client_folders_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../providers/navigation_provider.dart';
import '../models/client.dart';
import '../models/client_folder.dart';
import '../widgets/client_widget.dart';
import '../widgets/client_form_dialog.dart';
import '../widgets/client_folder_form_dialog.dart';
import '../widgets/reorder_clients_panel.dart';

class ClientsPage extends StatefulWidget {
  const ClientsPage({super.key});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final _searchCtrl = TextEditingController();
  String _sort = 'newest';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  Future<void> _loadAll({int? page, String? search, String? sort}) async {
    final auth = context.read<AuthProvider>();
    await Future.wait([
      _load(page: page, search: search, sort: sort),
      context.read<ClientFoldersProvider>().load(token: auth.token!),
    ]);
  }

  Future<void> _load({int? page, String? search, String? sort}) async {
    final auth = context.read<AuthProvider>();
    setState(() {
      if (sort != null) _sort = sort;
    });

    await context.read<ClientsProvider>().load(
          token: auth.token!,
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

  Future<void> _openFolderDialog({ClientFolder? folder}) async {
    final folderProv = context.read<ClientFoldersProvider>();
    final auth = context.read<AuthProvider>();
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
    final token = auth.token!;
    final next = ClientFolder(
      id: edited.id,
      name: edited.name,
      sequenceOrder: folder?.sequenceOrder ?? folderProv.items.length,
      clientCount: edited.clientCount,
      createdAt: edited.createdAt,
      updatedAt: edited.updatedAt,
    );
    await folderProv.save(token: token, folder: next);
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
    final token = context.read<AuthProvider>().token!;
    await context.read<ClientFoldersProvider>().remove(token: token, id: folder.id);
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
        heightFactor: 0.92,
        child: ReorderClientsPanel(
          folders: folderProv.items,
          clients: context.read<ClientsProvider>().items,
        ),
      ),
    );

    if (result == null || !mounted) return;

    final token = context.read<AuthProvider>().token!;
    final clientProv = context.read<ClientsProvider>();
    for (final folder in result.folders) {
      await folderProv.save(token: token, folder: folder);
    }
    for (final client in result.clients) {
      await clientProv.save(token: token, c: client);
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
    context.read<NavigationProvider>().setIndex(4);
    final prov = context.watch<ClientsProvider>();
    final folderProv = context.watch<ClientFoldersProvider>();

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
      appBar: AppBar(
        title: const Text('Clients'),
        actions: [
          if (folderProv.supported)
            IconButton(
              icon: const Icon(Icons.create_new_folder_outlined),
              tooltip: 'Add folder',
              onPressed: () => _openFolderDialog(),
            ),
          if (folderProv.supported)
            IconButton(
              icon: const Icon(Icons.drive_file_move_outline),
              tooltip: 'Organize clients',
              onPressed: _organizeClients,
            ),
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
            tooltip: 'Add client',
            onPressed: _openCreateDialog,
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
                'Client folders require the updated backend. Clients still load normally.',
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
                  onPressed: () => _load(search: _searchCtrl.text),
                ),
              ),
              onSubmitted: (v) => _load(search: v),
            ),
          ),
          if (prov.loading || folderProv.loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  if (folderProv.supported)
                    ...folderProv.items.map(
                      (folder) => _ClientFolderSection(
                        folder: folder,
                        clients: sorted
                            .where((client) => client.folderId == folder.id)
                            .toList(),
                        onEdit: () => _openFolderDialog(folder: folder),
                        onDelete: () => _deleteFolder(folder),
                      ),
                    ),
                  _UngroupedClientsSection(
                    clients: folderProv.supported
                        ? sorted.where((client) => client.folderId == null).toList()
                        : sorted,
                  ),
                ],
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

class _ClientFolderSection extends StatelessWidget {
  final ClientFolder folder;
  final List<Client> clients;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ClientFolderSection({
    required this.folder,
    required this.clients,
    required this.onEdit,
    required this.onDelete,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        folder.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${clients.length} client${clients.length == 1 ? '' : 's'}',
                        style: Theme.of(context).textTheme.bodySmall,
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
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text('No clients in this folder yet.'),
            )
          else
            ...clients.map(
              (client) => ClientWidget(
                client: client,
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

  const _UngroupedClientsSection({required this.clients});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 12),
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
              'Ungrouped Clients',
              style: Theme.of(context).textTheme.titleMedium,
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
