import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({super.key});

  static const _items = [
    _NavTarget(0, '/home',       Icons.home,       'Home'),
    _NavTarget(1, '/workout',    Icons.fitness_center, 'Workout'),
    _NavTarget(2, '/social',     Icons.forum,      'Social'),
    _NavTarget(3, '/programs',   Icons.list_alt,   'Programs'),
    _NavTarget(4, '/clients',    Icons.people,     'Clients'),
    _NavTarget(5, '/nutrition',  Icons.restaurant, 'Nutrition'),
  ];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavigationProvider>();

    return BottomNavigationBar(
      currentIndex: nav.index,
      type: BottomNavigationBarType.fixed,
      onTap: (idx) {
        nav.setIndex(idx);
        // pushReplacement to avoid stacking many screens
        Navigator.pushReplacementNamed(context, _items[idx].route);
      },
      items: _items
          .map((t) => BottomNavigationBarItem(icon: Icon(t.icon), label: t.label))
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
