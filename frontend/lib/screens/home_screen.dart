import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'dashboard_screen.dart';
import 'devotees_screen.dart';
import 'billing_screen.dart';
import 'reports_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem('முகப்பு', 'Dashboard', Icons.dashboard_outlined, Icons.dashboard),
    _NavItem('பில்லிங்', 'Billing', Icons.receipt_long_outlined, Icons.receipt_long),
    _NavItem('பக்தர்கள்', 'Devotees', Icons.people_outline, Icons.people),
    _NavItem('அறிக்கைகள்', 'Reports', Icons.bar_chart_outlined, Icons.bar_chart),
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
      default:
        return const DashboardScreen();
    }
  }

  void _logout() async {
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
                    child: const Column(
                      children: [
                        Text('🕉', style: TextStyle(fontSize: 28, color: Colors.white)),
                        SizedBox(height: 6),
                        Text(
                          'செம்புகுட்டி சாஸ்தா\nதிருக்கோவில்',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                              item.tamilLabel,
                              style: TextStyle(
                                color: selected ? AppTheme.darkOrange : Colors.black87,
                                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(item.englishLabel, style: const TextStyle(fontSize: 11)),
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
                    title: const Text('வெளியேறு', style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.w600)),
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
                  label: item.tamilLabel,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String tamilLabel;
  final String englishLabel;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(this.tamilLabel, this.englishLabel, this.icon, this.activeIcon);
}