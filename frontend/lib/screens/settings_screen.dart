import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/translation_service.dart';
import '../models/models.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  User? _currentUser;
  bool _loading = true;
  String? _error;

  List<User> _staffList = [];
  bool _loadingStaff = false;
  String? _staffError;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = await ApiService.getMe();
      setState(() => _currentUser = user);
      if (user.isAdmin) {
        _loadStaff();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadStaff() async {
    setState(() {
      _loadingStaff = true;
      _staffError = null;
    });
    try {
      final list = await ApiService.getStaffList();
      setState(() => _staffList = list.where((u) => u.userId != _currentUser?.userId).toList());
    } catch (e) {
      setState(() => _staffError = e.toString());
    } finally {
      setState(() => _loadingStaff = false);
    }
  }

  Future<void> _openAddStaffDialog() async {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final mobileController = TextEditingController();
    String selectedRole = 'staff';

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add New Staff / புதிய பணியாளர் சேர்க்க'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Staff Name / பெயர்'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username / பயனர் பெயர்'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password / கடவுச்சொல்'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: mobileController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(labelText: 'Mobile / கைபேசி (Optional)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role / உரிமை'),
                      items: const [
                        DropdownMenuItem(value: 'staff', child: Text('Billing Staff / பணியாளர்')),
                        DropdownMenuItem(value: 'admin', child: Text('Administrator / நிர்வாகி')),
                      ],
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedRole = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel / மூடு'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Add / சேர்'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true) {
      if (nameController.text.trim().isEmpty ||
          usernameController.text.trim().isEmpty ||
          passwordController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name, Username, and Password are required'), backgroundColor: AppTheme.error),
        );
        return;
      }

      setState(() => _loadingStaff = true);
      try {
        await ApiService.createStaff(
          username: usernameController.text.trim(),
          password: passwordController.text,
          staffName: nameController.text.trim(),
          role: selectedRole,
          mobile: mobileController.text.trim().isEmpty ? null : mobileController.text.trim(),
        );
        _loadStaff();
      } catch (e) {
        setState(() => _loadingStaff = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    return Scaffold(
      appBar: isWide
          ? null
          : AppBar(title: Text('nav_settings'.tr())),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isWide)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'nav_settings'.tr(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.dark,
                  ),
                ),
              ),
            
            // Profile Card Section
            Text(
              'profile_details'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkOrange,
              ),
            ),
            const SizedBox(height: 10),
            
            if (_loading)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(child: CircularProgressIndicator()),
                ),
              )
            else if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline, color: AppTheme.error, size: 36),
                        const SizedBox(height: 8),
                        Text(_error!, style: const TextStyle(color: AppTheme.error)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadProfile,
                          child: Text('retry'.tr()),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_currentUser != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildProfileRow(
                        Icons.person_outline,
                        'staff_name'.tr(),
                        _currentUser!.staffName,
                      ),
                      const Divider(height: 24),
                      _buildProfileRow(
                        Icons.account_circle_outlined,
                        'username'.tr(),
                        _currentUser!.username,
                      ),
                      const Divider(height: 24),
                      _buildProfileRow(
                        Icons.admin_panel_settings_outlined,
                        'role'.tr(),
                        _currentUser!.isAdmin ? 'admin_role'.tr() : 'staff_role'.tr(),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _currentUser!.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'active'.tr(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _currentUser!.isActive ? Colors.green[800] : Colors.red[800],
                            ),
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      _buildProfileRow(
                        Icons.phone_android_outlined,
                        'mobile_no'.tr(),
                        _currentUser!.mobile ?? '-',
                      ),
                    ],
                  ),
                ),
              ),

            if (_currentUser?.isAdmin == true) ...[
              const SizedBox(height: 30),
              const Text(
                'Staff Management / பணியாளர் நிர்வாகம்',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.darkOrange,
                ),
              ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _openAddStaffDialog,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Staff / பணியாளர் சேர்க்க'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.saffron,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_loadingStaff)
                        const Center(child: CircularProgressIndicator())
                      else if (_staffError != null)
                        Text(_staffError!, style: const TextStyle(color: AppTheme.error))
                      else if (_staffList.isEmpty)
                        const Text('No other staff members found / பணியாளர்கள் யாரும் இல்லை')
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _staffList.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final staff = _staffList[index];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(staff.staffName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('Username: ${staff.username} · Role: ${staff.role}'),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: staff.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  staff.isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    color: staff.isActive ? Colors.green[800] : Colors.red[800],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 30),
            
            // Language Selection Section
            Text(
              'language'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.darkOrange,
              ),
            ),
            const SizedBox(height: 10),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ValueListenableBuilder<String>(
                      valueListenable: Translation.languageNotifier,
                      builder: (context, currentLanguage, child) {
                        return Column(
                          children: [
                            RadioListTile<String>(
                              title: Text('tamil'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              value: 'ta',
                              groupValue: currentLanguage,
                              activeColor: AppTheme.saffron,
                              onChanged: (val) {
                                if (val != null) {
                                  Translation.changeLanguage(val);
                                }
                              },
                            ),
                            const Divider(height: 1),
                            RadioListTile<String>(
                              title: Text('english'.tr(), style: const TextStyle(fontWeight: FontWeight.w600)),
                              value: 'en',
                              groupValue: currentLanguage,
                              activeColor: AppTheme.saffron,
                              onChanged: (val) {
                                if (val != null) {
                                  Translation.changeLanguage(val);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileRow(IconData icon, String label, String value, {Widget? trailing}) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.darkOrange, size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppTheme.dark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }
}
