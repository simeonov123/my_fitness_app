import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/locale_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final localeProv = context.watch<LocaleProvider>();
    final auth = context.read<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.profileTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            loc.languageSectionTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: [
              ButtonSegment<String>(
                value: 'system',
                label: Text(loc.languageSystem),
              ),
              ButtonSegment<String>(
                value: 'en',
                label: Text(loc.languageEnglish),
              ),
              ButtonSegment<String>(
                value: 'bg',
                label: Text(loc.languageBulgarian),
              ),
            ],
            selected: {localeProv.localeCode},
            multiSelectionEnabled: false,
            onSelectionChanged: (selection) {
              localeProv.setLocaleCode(selection.first);
            },
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () async {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            icon: const Icon(Icons.logout),
            label: Text(loc.logoutLabel),
          ),
        ],
      ),
    );
  }
}
