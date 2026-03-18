import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _comingSoonRoutes = {'/programs', '/nutrition'};

  static const _trainerItems = [
    _NavTarget(0, '/home', Icons.home, 'Home'),
    _NavTarget(1, '/workout', Icons.fitness_center, 'Workout'),
    _NavTarget(2, '/social', Icons.forum, 'Social'),
    _NavTarget(3, '/programs', Icons.list_alt, 'Programs'),
    _NavTarget(4, '/clients', Icons.people, 'Clients'),
    _NavTarget(5, '/nutrition', Icons.restaurant, 'Nutrition'),
  ];

  static const _clientItems = [
    _NavTarget(0, '/home', Icons.home, 'Home'),
    _NavTarget(1, '/social', Icons.forum, 'Social'),
  ];

  @override
  Widget build(BuildContext context) {
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
            SnackBar(content: Text('${target.label} is coming soon')),
          );
          return;
        }
        nav.setIndex(idx);
        // pushReplacement to avoid stacking many screens
        Navigator.pushReplacementNamed(context, target.route);
      },
      items: items
          .map((t) =>
              BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
          .toList(),
    );
  }
}

class _NavTarget {
  final int idx;
  final String route;
  final IconData icon;
  final String label;
  const _NavTarget(this.idx, this.route, this.icon, this.label);
}
