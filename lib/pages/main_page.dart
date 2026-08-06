import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainPage extends StatelessWidget {
  final StatefulNavigationShell navigationShell;
  const MainPage({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,

      body: navigationShell,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [BoxShadow(blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadiusGeometry.circular(24),
            child: NavigationBar(
              backgroundColor: Theme.of(context).colorScheme.secondary,
              selectedIndex: navigationShell.currentIndex,
              indicatorColor: Colors.transparent,

              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: navigationShell.goBranch,
              destinations: [
                NavigationDestination(icon: Icon(Icons.tv), label: 'TV Series'),
                NavigationDestination(
                  icon: Icon(Icons.movie_creation_outlined),
                  label: 'Movies',
                ),
                NavigationDestination(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                NavigationDestination(
                  icon: Icon(Icons.newspaper),
                  label: 'News',
                ),
                NavigationDestination(
                  icon: Icon(Icons.account_circle_outlined),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
