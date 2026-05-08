import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🔥 Grab the current path so we can highlight the active menu item
    final currentPath = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    // --- HELPER: Drawer Item Builder ---
    Widget buildDrawerItem({
      required IconData icon,
      required String title,
      required String route,
    }) {
      final isSelected = currentPath == route;

      return ListTile(
        leading: Icon(
          icon,
          // Highlight the icon with Burgess Orange if selected
          color: isSelected ? theme.colorScheme.secondary : Colors.grey[600],
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.primary : Colors.black87,
          ),
        ),
        // Add a subtle blue background to the selected item
        tileColor: isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : null,
        onTap: () {
          Navigator.pop(context); // Close the drawer first
          if (!isSelected) {
            context.go(route);
          }
        },
      );
    }

    return Drawer(
      backgroundColor: Colors.white,
      child: Column(
        // 🔥 Swapped ListView for Column to push Logout to the bottom
        children: [
          // --- BRANDED HEADER ---
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.black12)),
            ),
            child: Center(
              child: Image.asset(
                'assets/images/goLogo_Banner.png',
                fit: BoxFit.contain,
              ),
            ),
          ),

          // --- NAVIGATION LINKS ---
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                buildDrawerItem(
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/super-dash',
                ),
                buildDrawerItem(
                  icon: Icons.location_on,
                  title: 'My Homes',
                  route: '/locations',
                ),
                buildDrawerItem(
                  icon: Icons.archive,
                  title: 'Closed Homes',
                  route: '/closed-locations',
                ),
                buildDrawerItem(
                  icon: Icons.contacts,
                  title: 'Trade Contacts',
                  route: '/trade-contacts',
                ),
              ],
            ),
          ),

          // --- FOOTER ACTIONS ---
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Navigator.pop(context); // Close drawer
              // 🔥 Wired up your Riverpod Auth Controller
              ref.read(authControllerProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 24), // Safe area breathing room
        ],
      ),
    );
  }
}
