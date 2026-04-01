import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _comingSoonRoutes = {'/nutrition'};

  static const _trainerItems = [
    _NavTarget(0, '/home', Icons.home, _homeLabel),
    _NavTarget(1, '/workout', Icons.fitness_center, _workoutLabel),
    _NavTarget(2, '/social', Icons.forum, _socialLabel),
    _NavTarget(3, '/programs', Icons.list_alt, _programsLabel),
    _NavTarget(4, '/clients', Icons.people, _clientsLabel),
    _NavTarget(5, '/nutrition', Icons.restaurant, _nutritionLabel),
  ];

  static const _clientItems = [
    _NavTarget(0, '/home', Icons.home, _homeLabel),
    _NavTarget(1, '/social', Icons.forum, _socialLabel),
    _NavTarget(2, '/programs', Icons.list_alt, _programsLabel),
  ];

  static String _homeLabel(AppLocalizations loc) => loc.navHome;
  static String _workoutLabel(AppLocalizations loc) => loc.navWorkout;
  static String _socialLabel(AppLocalizations loc) => loc.navSocial;
  static String _programsLabel(AppLocalizations loc) => loc.navPrograms;
  static String _clientsLabel(AppLocalizations loc) => loc.navClients;
  static String _nutritionLabel(AppLocalizations loc) => loc.navNutrition;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final auth = context.watch<AuthProvider>();
    final nav = context.watch<NavigationProvider>();
    final items = auth.isClient ? _clientItems : _trainerItems;
    final routeName = ModalRoute.of(context)?.settings.name;
    final currentIndex = items.indexWhere((item) => item.route == routeName);

    return BottomNavigationBar(
      currentIndex: currentIndex >= 0 ? currentIndex : 0,
      type: BottomNavigationBarType.fixed,
      onTap: (idx) {
        final target = items[idx];
        if (_comingSoonRoutes.contains(target.route)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc.comingSoonMessage(target.labelBuilder(loc)),
              ),
            ),
          );
          return;
        }
        nav.setIndex(idx);
        // pushReplacement to avoid stacking many screens
        Navigator.pushReplacementNamed(context, target.route);
      },
      items: items
          .map((t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                label: t.labelBuilder(loc),
              ))
          .toList(),
    );
  }
}

class _NavTarget {
  final int idx;
  final String route;
  final IconData icon;
  final String Function(AppLocalizations) labelBuilder;
  const _NavTarget(this.idx, this.route, this.icon, this.labelBuilder);
}
