// lib/screens/client_detail_page.dart

import 'package:flutter/material.dart';
import 'package:avatar_plus/avatar_plus.dart';
import 'package:provider/provider.dart';

import '../models/client.dart';
import '../providers/auth_provider.dart';
import '../providers/clients_provider.dart';
import '../widgets/client_form_dialog.dart';

class ClientDetailPage extends StatefulWidget {
  final Client client;

  const ClientDetailPage({super.key, required this.client});

  @override
  _ClientDetailPageState createState() => _ClientDetailPageState();
}

class _ClientDetailPageState extends State<ClientDetailPage> {
  late Client _client;
  // stub data for stats
  final int _workoutsCompleted = 42;
  final List<String> _activePrograms = ['Strength Training'];
  final List<String> _programHistory = ['Onboarding Program', 'Cardio Blast'];
  final String? _currentNutritionPlan = 'Keto Kickstart';
  final List<String> _nutritionHistory = ['Balanced Diet', 'Low Carb'];

  @override
  void initState() {
    super.initState();
    // keep a local, mutable copy so we can update after editing
    _client = widget.client;
  }

  Future<void> _editClient() async {
    final updated = await showDialog<Client>(
      context: context,
      builder: (_) => ClientFormDialog(client: _client),
    );
    if (updated != null) {
      final token = context.read<AuthProvider>().token!;
      await context.read<ClientsProvider>().save(token: token, c: updated);
      setState(() {
        _client = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client updated')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete client?'),
        content: Text('Are you sure you want to delete "${_client.fullName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final token = context.read<AuthProvider>().token!;
      await context
          .read<ClientsProvider>()
          .remove(token: token, id: _client.id);
      Navigator.of(context).pop(); // back to clients list
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Client deleted')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final avatarSeed =
        _client.id != 0 ? _client.id.toString() : _client.fullName;

    return Scaffold(
      appBar: AppBar(
        title: Text(_client.fullName),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit client',
            onPressed: _editClient,
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete client',
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                ClipOval(
                  child: AvatarPlus(
                    avatarSeed,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _client.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 4),
                      if (_client.createdAt != null)
                        Text(
                          'Member since: ${_client.createdAt!.toLocal().toString().split(' ').first}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  label: 'Workouts',
                  value: '$_workoutsCompleted',
                ),
                _StatCard(
                  label: 'Active Programs',
                  value: '${_activePrograms.length}',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Programs
            Text('Programs', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_activePrograms.isNotEmpty)
                      ..._activePrograms.map(
                        (p) => ListTile(
                          leading: const Icon(Icons.fitness_center),
                          title: Text(p),
                        ),
                      )
                    else
                      const Text('— None —'),
                    const Divider(),
                    const Text('History',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._programHistory.map(
                      (p) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(p),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Nutrition Plans
            Text('Nutrition Plans',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    if (_currentNutritionPlan != null)
                      ListTile(
                        leading: const Icon(Icons.restaurant_menu),
                        title: Text(_currentNutritionPlan!),
                      )
                    else
                      const Text('— None —'),
                    const Divider(),
                    const Text('History',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ..._nutritionHistory.map(
                      (n) => ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(n),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          children: [
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
