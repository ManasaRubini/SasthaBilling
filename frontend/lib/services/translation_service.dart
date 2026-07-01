import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Translation {
  // Global ValueNotifier to trigger rebuilds when language changes
  static final ValueNotifier<String> languageNotifier = ValueNotifier<String>('ta');

  static String get currentLanguage => languageNotifier.value;

  // Initialize translation service: load saved language preference
  static Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lang = prefs.getString('selected_language') ?? 'ta';
      languageNotifier.value = lang;
    } catch (_) {
      languageNotifier.value = 'ta'; // Fallback to Tamil
    }
  }

  // Change language and persist preference
  static Future<void> changeLanguage(String langCode) async {
    languageNotifier.value = langCode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_language', langCode);
    } catch (_) {}
  }

  // Translate helper method
  static String translate(String key) {
    return _keys[currentLanguage]?[key] ?? key;
  }

  // Translation keys dictionary
  static final Map<String, Map<String, String>> _keys = {
    'ta': {
      // Navigation / Shell
      'nav_dashboard': 'முகப்பு',
      'nav_billing': 'பில்லிங்',
      'nav_devotees': 'பக்தர்கள்',
      'nav_reports': 'அறிக்கைகள்',
      'nav_settings': 'அமைப்புகள்',
      'logout': 'வெளியேறு',
      'temple_title': 'செம்புகுட்டி சாஸ்தா\nதிருக்கோவில்',
      'confirm_logout': 'வெளியேற விரும்புகிறீர்களா?',
      'cancel': 'இரத்து',
      'yes': 'ஆம்',

      // Login
      'login_title': 'அன்புடன் வரவேற்கிறோம் / Welcome',
      'login_subtitle': 'செம்புகுட்டி சாஸ்தா திருக்கோவில் பில்லிங் சிஸ்டம்',
      'username': 'பயனர் பெயர்',
      'password': 'கடவுச்சொல்',
      'login_btn': 'உள்நுழையவும்',
      'enter_username': 'பயனர் பெயரை உள்ளிடவும்',
      'enter_password': 'கடவுச்சொல்லை உள்ளிடவும்',

      // Dashboard
      'dashboard_title': 'முகப்பு',
      'today_collection': 'இன்று வசூல்',
      'today_bills': 'இன்று ரசீதுகள்',
      'today_vari': 'இன்று வரி',
      'today_kanikkai': 'இன்று காணிக்கை',
      'monthly_collection': 'மாதாந்திர வசூல்',
      'total_devotees': 'மொத்த பக்தர்கள்',
      'total_staff': 'மொத்த ஊழியர்கள்',
      'retry': 'மீண்டும் முயற்சி',
      'loading': 'ஏற்றுகிறது...',

      // Devotees
      'devotees_title': 'பக்தர்கள் விவரம்',
      'search_placeholder': 'பெயர், ஊர் அல்லது கைபேசி மூலம் தேடவும்...',
      'add_devotee': 'பக்தர் சேர்',
      'edit_devotee': 'பக்தர் விவரம் திருத்து',
      'name': 'பெயர்',
      'father_name': 'தந்தை பெயர்',
      'mobile': 'கைபேசி எண்',
      'village': 'ஊர்',
      'address': 'முகவரி',
      'family_id': 'குடும்ப எண் / குலதெய்வம்',
      'history': 'வரலாறு',
      'edit': 'திருத்து',
      'delete': 'நீக்கு',
      'save': 'சேமி',
      'enter_name': 'பெயரை உள்ளிடவும்',
      'enter_mobile': 'கைபேசி எண்ணை உள்ளிடவும்',
      'invalid_mobile': 'தவறான கைபேசி எண்',
      'devotee_added': 'பக்தர் வெற்றிகரமாக சேர்க்கப்பட்டார்',
      'devotee_updated': 'பக்தர் விவரம் புதுப்பிக்கப்பட்டது',
      'confirm_delete': 'நீக்க விரும்புகிறீர்களா?',

      // Billing
      'billing_title': 'பில்லிங்',
      'select_devotee': 'பக்தரைத் தேர்ந்தெடுக்கவும்',
      'search_devotee': 'பக்தரை தேடவும்...',
      'bill_type': 'பில் வகை',
      'category': 'வகை',
      'amount': 'தொகை',
      'payment_method': 'செலுத்தும் முறை',
      'transaction_id': 'பரிவர்த்தனை எண்',
      'remarks': 'குறிப்பு',
      'generate_receipt': 'ரசீது உருவாக்கு',
      'receipt_no': 'ரசீது எண்',
      'date': 'தேதி',
      'type': 'வகை',
      'staff': 'பணியாளர்',
      'cash': 'பணம்',
      'upi': 'UPI (GPay/PhonePe)',
      'card': 'அட்டை (Card)',
      'cheque': 'காசோலை (Cheque)',
      'enter_amount': 'தொகையை உள்ளிடவும்',
      'bill_success': 'ரசீது வெற்றிகரமாக உருவாக்கப்பட்டது',
      'receipt_generated': 'ரசீது உருவாக்கப்பட்டது',

      // Reports
      'reports_title': 'அறிக்கைகள்',
      'daily_report': 'தினசரி அறிக்கை',
      'monthly_report': 'மாநில / மாதாந்திர அறிக்கை',
      'staff_report': 'ஊழியர் அறிக்கை',
      'select_date': 'தேதியைத் தேர்ந்தெடுக்கவும்',
      'select_month': 'மாதத்தைத் தேர்ந்தெடுக்கவும்',
      'select_year': 'வருடத்தைத் தேர்ந்தெடுக்கவும்',
      'total': 'மொத்தம்',
      'export_pdf': 'PDF ஆக ஏற்றுமதி செய்க',
      'print': 'அச்சிடுக',
      'collection_report': 'வசூல் அறிக்கை',

      // Settings / Profile
      'settings_title': 'அமைப்புகள்',
      'profile_details': 'சுயவிவர விவரங்கள்',
      'staff_name': 'பணியாளர் பெயர்',
      'role': 'பங்கு (Role)',
      'mobile_no': 'கைபேசி எண்',
      'language': 'மொழி / Language',
      'select_language': 'மொழியைத் தேர்ந்தெடுக்கவும் / Select Language',
      'tamil': 'தமிழ் (Tamil)',
      'english': 'English',
      'active': 'செயலில் உள்ளது',
      'admin_role': 'நிர்வாகி (Admin)',
      'staff_role': 'பணியாளர் (Staff)',
    },
    'en': {
      // Navigation / Shell
      'nav_dashboard': 'Dashboard',
      'nav_billing': 'Billing',
      'nav_devotees': 'Devotees',
      'nav_reports': 'Reports',
      'nav_settings': 'Settings',
      'logout': 'Logout',
      'temple_title': 'Sembukutty Saastha\nThirukovil',
      'confirm_logout': 'Are you sure you want to logout?',
      'cancel': 'Cancel',
      'yes': 'Yes',

      // Login
      'login_title': 'Welcome',
      'login_subtitle': 'Sembukutty Saastha Thirukovil Billing System',
      'username': 'Username',
      'password': 'Password',
      'login_btn': 'Log In',
      'enter_username': 'Please enter username',
      'enter_password': 'Please enter password',

      // Dashboard
      'dashboard_title': 'Dashboard',
      'today_collection': 'Today\'s Collection',
      'today_bills': 'Today\'s Bills',
      'today_vari': 'Today\'s Tax (Vari)',
      'today_kanikkai': 'Today\'s Kanikkai',
      'monthly_collection': 'Monthly Collection',
      'total_devotees': 'Total Devotees',
      'total_staff': 'Total Staff',
      'retry': 'Retry',
      'loading': 'Loading...',

      // Devotees
      'devotees_title': 'Devotees List',
      'search_placeholder': 'Search by name, village or mobile...',
      'add_devotee': 'Add Devotee',
      'edit_devotee': 'Edit Devotee',
      'name': 'Name',
      'father_name': 'Father\'s Name',
      'mobile': 'Mobile Number',
      'village': 'Village',
      'address': 'Address',
      'family_id': 'Family ID / Deity',
      'history': 'History',
      'edit': 'Edit',
      'delete': 'Delete',
      'save': 'Save',
      'enter_name': 'Please enter name',
      'enter_mobile': 'Please enter mobile number',
      'invalid_mobile': 'Invalid mobile number',
      'devotee_added': 'Devotee added successfully',
      'devotee_updated': 'Devotee details updated',
      'confirm_delete': 'Are you sure you want to delete?',

      // Billing
      'billing_title': 'Billing',
      'select_devotee': 'Select Devotee',
      'search_devotee': 'Search devotee...',
      'bill_type': 'Bill Type',
      'category': 'Category',
      'amount': 'Amount',
      'payment_method': 'Payment Method',
      'transaction_id': 'Transaction ID',
      'remarks': 'Remarks',
      'generate_receipt': 'Generate Receipt',
      'receipt_no': 'Receipt No',
      'date': 'Date',
      'type': 'Type',
      'staff': 'Staff',
      'cash': 'Cash',
      'upi': 'UPI (GPay/PhonePe)',
      'card': 'Card',
      'cheque': 'Cheque',
      'enter_amount': 'Please enter amount',
      'bill_success': 'Receipt created successfully',
      'receipt_generated': 'Receipt Generated',

      // Reports
      'reports_title': 'Reports',
      'daily_report': 'Daily Report',
      'monthly_report': 'Monthly Report',
      'staff_report': 'Staff Report',
      'select_date': 'Select Date',
      'select_month': 'Select Month',
      'select_year': 'Select Year',
      'total': 'Total',
      'export_pdf': 'Export as PDF',
      'print': 'Print',
      'collection_report': 'Collection Report',

      // Settings / Profile
      'settings_title': 'Settings',
      'profile_details': 'Profile Details',
      'staff_name': 'Staff Name',
      'role': 'Role',
      'mobile_no': 'Mobile No',
      'language': 'Language',
      'select_language': 'Select Language',
      'tamil': 'Tamil (தமிழ்)',
      'english': 'English',
      'active': 'Active',
      'admin_role': 'Administrator',
      'staff_role': 'Staff Member',
    }
  };
}

// Extension to clean up localization calls: 'my_key'.tr()
extension TranslationExtension on String {
  String tr() => Translation.translate(this);
}
