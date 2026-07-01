import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  runApp(const TempleBillingApp());
}

class TempleBillingApp extends StatelessWidget {
  const TempleBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'செம்புகுட்டி சாஸ்தா திருக்கோவில் - Billing System',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: ApiService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}