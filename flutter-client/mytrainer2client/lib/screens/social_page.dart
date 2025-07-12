import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import 'package:provider/provider.dart';
import '../providers/navigation_provider.dart';

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  @override
  Widget build(BuildContext context) {
    context.read<NavigationProvider>().setIndex(2);
    return const _ScaffoldWithNav(title: 'Social');
  }
}

class _ScaffoldWithNav extends StatelessWidget {
  final String title;
  const _ScaffoldWithNav({required this.title});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title)),
    bottomNavigationBar: const BottomNavBar(),
  );
}
