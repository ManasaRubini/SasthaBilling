import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'services/api_service.dart';
import 'services/translation_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.loadToken();
  await Translation.init(); // Load saved language setting
  runApp(const TempleBillingApp());
}

class TempleBillingApp extends StatelessWidget {
  const TempleBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String>(
      valueListenable: Translation.languageNotifier,
      builder: (context, currentLanguage, child) {
        return MaterialApp(
          title: 'செம்புகுட்டி சாஸ்தா திருக்கோவில் - Billing System',
          theme: AppTheme.lightTheme,
          debugShowCheckedModeBanner: false,
          locale: Locale(currentLanguage),
          home: ApiService.isLoggedIn ? const HomeScreen() : const LoginScreen(),
        );
      },
    );
  }
}