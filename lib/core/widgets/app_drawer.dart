import 'package:burgess_go/features/auth/controllers/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  final GlobalKey _dashKey = GlobalKey();
  final GlobalKey _homesKey = GlobalKey();
  final GlobalKey _closedHomesKey = GlobalKey();
  final GlobalKey _tradesKey = GlobalKey();
  final GlobalKey _logoutKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    ShowcaseView.register();

    // Trigger the tutorial after the drawer finishes its opening animation
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenDrawerHelp = prefs.getBool('hasSeenDrawerTutorial') ?? false;

      if (!hasSeenDrawerHelp && mounted) {
        ShowcaseView.get().startShowCase([
          _dashKey,
          _homesKey,
          _closedHomesKey,
          _tradesKey,
          _logoutKey,
        ]);
        await prefs.setBool('hasSeenDrawerTutorial', true);
      }
    });
  }

  @override
  void dispose() {
    ShowcaseView.get().unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔥 Grab the current path so we can highlight the active menu item
    final currentPath = GoRouterState.of(context).uri.path;
    final theme = Theme.of(context);

    // --- HELPER: Drawer Item Builder ---
    Widget buildDrawerItem({
      required GlobalKey key,
      required String description,
      required IconData icon,
      required String title,
      required String route,
    }) {
      final isSelected = currentPath == route;

      return Showcase(
        key: key,
        description: description,
        child: ListTile(
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
              context.push(route);
            }
          },
        ),
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
                  key: _dashKey,
                  description: 'Return to your main action board and schedule.',
                  icon: Icons.dashboard,
                  title: 'Dashboard',
                  route: '/super-dash',
                ),
                buildDrawerItem(
                  key: _homesKey,
                  description:
                      'View all active homes, schedule inspections, and view history.',
                  icon: Icons.location_on,
                  title: 'My Homes',
                  route: '/locations',
                ),
                buildDrawerItem(
                  key: _closedHomesKey,
                  description: 'Access archived locations and past records.',
                  icon: Icons.archive,
                  title: 'Closed Homes',
                  route: '/closed-locations',
                ),
                buildDrawerItem(
                  key: _tradesKey,
                  description:
                      'Manage your local Trade Partners for quick defect dispatch.',
                  icon: Icons.contacts,
                  title: 'Trade Contacts',
                  route: '/trade-contacts',
                ),
              ],
            ),
          ),

          // --- FOOTER ACTIONS ---
          const Divider(height: 1),
          Showcase(
            key: _logoutKey,
            description: 'Securely log out of Burgess GO.',
            child: ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                Navigator.pop(context); // Close drawer
                // 🔥 Wired up your Riverpod Auth Controller
                ref.read(authControllerProvider.notifier).logout();
              },
            ),
          ),
          const SizedBox(height: 24), // Safe area breathing room
        ],
      ),
    );
  }
}
