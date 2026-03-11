import 'package:flutter/material.dart';

import '../models/client.dart';
import '../models/client_folder.dart';

class ReorderClientsResult {
  final List<ClientFolder> folders;
  final List<Client> clients;

  const ReorderClientsResult({
    required this.folders,
    required this.clients,
  });
}

class ReorderClientsPanel extends StatefulWidget {
  final List<ClientFolder> folders;
  final List<Client> clients;

  const ReorderClientsPanel({
    super.key,
    required this.folders,
    required this.clients,
  });

  @override
  State<ReorderClientsPanel> createState() => _ReorderClientsPanelState();
}

class _ReorderClientsPanelState extends State<ReorderClientsPanel> {
  late List<ClientFolder> _folders;
  late List<Client> _ungrouped;
  late Map<int, List<Client>> _folderClients;

  @override
  void initState() {
    super.initState();
    _folders = List.of(widget.folders)
      ..sort((a, b) => (a.sequenceOrder ?? 0).compareTo(b.sequenceOrder ?? 0));
    final sortedClients = List.of(widget.clients)
      ..sort((a, b) => (a.sequenceOrder ?? 0).compareTo(b.sequenceOrder ?? 0));
    _ungrouped =
        sortedClients.where((client) => client.folderId == null).toList();
    _folderClients = {
      for (final folder in _folders)
        folder.id:
            sortedClients.where((client) => client.folderId == folder.id).toList(),
    };
  }

  void _persistAndClose() {
    final folders = <ClientFolder>[];
    final clients = <Client>[];

    for (var i = 0; i < _folders.length; i++) {
      final folder = _folders[i];
      folders.add(
        ClientFolder(
          id: folder.id,
          name: folder.name,
          sequenceOrder: i,
          clientCount: (_folderClients[folder.id] ?? const []).length,
          createdAt: folder.createdAt,
          updatedAt: folder.updatedAt,
        ),
      );
    }

    for (var i = 0; i < _ungrouped.length; i++) {
      final client = _ungrouped[i];
      clients.add(
        Client(
          id: client.id,
          fullName: client.fullName,
          email: client.email,
          phone: client.phone,
          folderId: null,
          folderName: null,
          sequenceOrder: i,
          createdAt: client.createdAt,
          updatedAt: client.updatedAt,
        ),
      );
    }

    for (final folder in folders) {
      final entries = _folderClients[folder.id] ?? const <Client>[];
      for (var i = 0; i < entries.length; i++) {
        final client = entries[i];
        clients.add(
          Client(
            id: client.id,
            fullName: client.fullName,
            email: client.email,
            phone: client.phone,
            folderId: folder.id,
            folderName: folder.name,
            sequenceOrder: i,
            createdAt: client.createdAt,
            updatedAt: client.updatedAt,
          ),
        );
      }
    }

    Navigator.of(context).pop(
      ReorderClientsResult(folders: folders, clients: clients),
    );
  }

  void _moveClient(Client client, {required int? targetFolderId}) {
    setState(() {
      _removeClient(client);
      if (targetFolderId == null) {
        _ungrouped.add(client);
      } else {
        _folderClients[targetFolderId] ??= [];
        _folderClients[targetFolderId]!.add(client);
      }
    });
  }

  void _removeClient(Client client) {
    _ungrouped.removeWhere((item) => item.id == client.id);
    for (final entry in _folderClients.entries) {
      entry.value.removeWhere((item) => item.id == client.id);
    }
  }

  Widget _buildClientTile(
    Client client, {
    required Key key,
    int? reorderIndex,
  }) {
    return Draggable<Client>(
      key: key,
      data: client,
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
              title: Text(client.fullName),
              subtitle: Text(client.folderName ?? 'Ungrouped'),
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.35,
        child: _ClientPanelTile(
          client: client,
          reorderIndex: reorderIndex,
        ),
      ),
      child: _ClientPanelTile(
        client: client,
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
                'Organize clients',
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
                    title: 'Ungrouped Clients',
                    subtitle: 'Drag clients here to remove them from folders',
                    dropHint: 'Drop a client here to ungroup them',
                    onAccept: (client) =>
                        _moveClient(client, targetFolderId: null),
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
                      itemBuilder: (_, index) => _buildClientTile(
                        _ungrouped[index],
                        key: ValueKey('ungrouped-client-${_ungrouped[index].id}'),
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
                      final clients = _folderClients[folder.id] ?? [];
                      return Container(
                        key: ValueKey('client-folder-${folder.id}'),
                        margin: const EdgeInsets.only(bottom: 16),
                        child: _DragSection(
                          title: folder.name,
                          subtitle:
                              'Drop clients here. Reorder with the drag handles.',
                          dropHint:
                              'Drop a client here to move them into ${folder.name}',
                          trailing: ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                          onAccept: (client) =>
                              _moveClient(client, targetFolderId: folder.id),
                          child: ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: clients.length,
                            onReorder: (oldIndex, newIndex) {
                              setState(() {
                                if (newIndex > oldIndex) newIndex--;
                                final item = clients.removeAt(oldIndex);
                                clients.insert(newIndex, item);
                              });
                            },
                            itemBuilder: (_, clientIndex) => _buildClientTile(
                              clients[clientIndex],
                              key: ValueKey(
                                'folder-${folder.id}-client-${clients[clientIndex].id}',
                              ),
                              reorderIndex: clientIndex,
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
  final ValueChanged<Client> onAccept;

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
  final ValueChanged<Client> onAccept;

  const _DropLane({
    required this.hint,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<Client>(
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
                  active ? 'Release to move client here' : hint,
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

class _ClientPanelTile extends StatelessWidget {
  final Client client;
  final int? reorderIndex;

  const _ClientPanelTile({
    required this.client,
    this.reorderIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(client.fullName),
        subtitle: client.email?.isNotEmpty == true
            ? Text(
                client.email!,
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
