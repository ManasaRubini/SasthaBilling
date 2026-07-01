import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'devotees_screen.dart';
import 'billing_screen.dart';
import 'reports_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem('nav_dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('nav_billing', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('nav_devotees', Icons.people_outline, Icons.people),
    _NavItem('nav_reports', Icons.bar_chart_outlined, Icons.bar_chart),
    _NavItem('nav_settings', Icons.settings_outlined, Icons.settings),
  ];

  Widget _buildScreen(int index) {
    switch (index) {
      case 0:
        return const DashboardScreen();
      case 1:
        return const BillingScreen();
      case 2:
        return const DevoteesScreen();
      case 3:
        return const ReportsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const DashboardScreen();
    }
  }

  void _logout() async {
    // Show confirmation dialog before logging out
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('logout'.tr()),
        content: Text('confirm_logout'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('yes'.tr()),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 800;

    if (isWide) {
      // Desktop / laptop layout with side rail
      return Scaffold(
        body: Row(
          children: [
            Container(
              width: 220,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.goldGradient,
                    child: Column(
                      children: [
                        const Text('🕉', style: TextStyle(fontSize: 28, color: Colors.white)),
                        const SizedBox(height: 6),
                        Text(
                          'temple_title'.tr(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _navItems.length,
                      itemBuilder: (context, index) {
                        final item = _navItems[index];
                        final selected = _selectedIndex == index;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: selected ? AppTheme.lightOrange : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: Icon(
                              selected ? item.activeIcon : item.icon,
                              color: selected ? AppTheme.darkOrange : Colors.black54,
                            ),
                            title: Text(
                              item.translationKey.tr(),
                              style: TextStyle(
                                color: selected ? AppTheme.darkOrange : Colors.black87,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            onTap: () => setState(() => _selectedIndex = index),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.error),
                    title: Text('logout'.tr(), style: const TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
                    onTap: _logout,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            Expanded(child: _buildScreen(_selectedIndex)),
          ],
        ),
      );
    }

    // Mobile layout with bottom nav
    return Scaffold(
      body: _buildScreen(_selectedIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: AppTheme.lightOrange,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon, color: AppTheme.darkOrange),
                  label: item.translationKey.tr(),
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String translationKey;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.translationKey, this.icon, this.activeIcon);
}