import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  // Change this to your backend server address
  static const String baseUrl = 'https://sasthabilling.onrender.com/api';

  static String? _token;

  static Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('access_token');
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
  }

  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  static bool get isLoggedIn => _token != null;

  // ---------- AUTH ----------
  static Future<User> login(String username, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveToken(data['access_token']);
      return User(
        userId: data['user_id'],
        username: data['username'],
        staffName: data['staff_name'],
        role: data['role'],
      );
    }
    throw ApiException(_extractError(res));
  }

  static Future<void> logout() async {
    await clearToken();
  }

  static Future<User> getMe() async {
    final res = await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers);
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  // ---------- DASHBOARD ----------
  static Future<DashboardStats> getDashboard() async {
    final res = await http.get(Uri.parse('$baseUrl/bills/dashboard'), headers: _headers);
    if (res.statusCode == 200) {
      return DashboardStats.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  // ---------- DEVOTEES ----------
  static Future<List<Devotee>> getDevotees({String? search}) async {
    var uri = Uri.parse('$baseUrl/devotees/');
    if (search != null && search.isNotEmpty) {
      uri = uri.replace(queryParameters: {'search': search});
    }
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Devotee.fromJson(e)).toList();
    }
    throw ApiException(_extractError(res));
  }

  static Future<Devotee> createDevotee(Devotee devotee) async {
    final res = await http.post(
      Uri.parse('$baseUrl/devotees/'),
      headers: _headers,
      body: jsonEncode(devotee.toJson()),
    );
    if (res.statusCode == 200) {
      return Devotee.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  static Future<Devotee> updateDevotee(int id, Devotee devotee) async {
    final res = await http.put(
      Uri.parse('$baseUrl/devotees/$id'),
      headers: _headers,
      body: jsonEncode(devotee.toJson()),
    );
    if (res.statusCode == 200) {
      return Devotee.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  static Future<void> deleteDevotee(int id) async {
    final res = await http.delete(Uri.parse('$baseUrl/devotees/$id'), headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException(_extractError(res));
    }
  }

  static Future<List<Bill>> getDevoteeHistory(int devoteeId) async {
    final res = await http.get(Uri.parse('$baseUrl/devotees/$devoteeId/history'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Bill.fromJson(e)).toList();
    }
    throw ApiException(_extractError(res));
  }

  // ---------- BILLS ----------
  static Future<List<Bill>> getBills({int skip = 0, int limit = 50}) async {
    final res = await http.get(
      Uri.parse('$baseUrl/bills/?skip=$skip&limit=$limit'),
      headers: _headers,
    );
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => Bill.fromJson(e)).toList();
    }
    throw ApiException(_extractError(res));
  }

  static Future<Bill> createBill({
    required int devoteeId,
    required String billType,
    String? category,
    required double amount,
    required String paymentMethod,
    String? transactionId,
    String? remarks,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/bills/'),
      headers: _headers,
      body: jsonEncode({
        'devotee_id': devoteeId,
        'bill_type': billType,
        'category': category,
        'amount': amount,
        'payment_method': paymentMethod,
        'transaction_id': transactionId,
        'remarks': remarks,
      }),
    );
    if (res.statusCode == 200) {
      return Bill.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  static Future<Uint8List> downloadReceipt(int billId) async {
    final res = await http.get(Uri.parse('$baseUrl/bills/$billId/receipt'), headers: _headers);
    if (res.statusCode == 200) {
      return res.bodyBytes;
    }
    throw ApiException(_extractError(res));
  }

  static Future<void> cancelBill(int billId) async {
    final res = await http.delete(Uri.parse('$baseUrl/bills/$billId/cancel'), headers: _headers);
    if (res.statusCode != 200) {
      throw ApiException(_extractError(res));
    }
  }

  static Future<Bill> updateBill(int billId, Map<String, dynamic> data) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/bills/$billId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return Bill.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  // ---------- REPORTS ----------
  static Future<Map<String, dynamic>> getDailyReport({String? date}) async {
    var uri = Uri.parse('$baseUrl/reports/daily');
    if (date != null) uri = uri.replace(queryParameters: {'report_date': date});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw ApiException(_extractError(res));
  }

  static Future<Map<String, dynamic>> getMonthlyReport({int? year, int? month}) async {
    var uri = Uri.parse('$baseUrl/reports/monthly');
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    if (month != null) params['month'] = month.toString();
    if (params.isNotEmpty) uri = uri.replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw ApiException(_extractError(res));
  }

  static Future<Map<String, dynamic>> getStaffReport({String? date}) async {
    var uri = Uri.parse('$baseUrl/reports/staff');
    if (date != null) uri = uri.replace(queryParameters: {'report_date': date});
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    throw ApiException(_extractError(res));
  }

  // ---------- STAFF ----------
  static Future<List<User>> getStaffList() async {
    final res = await http.get(Uri.parse('$baseUrl/staff/'), headers: _headers);
    if (res.statusCode == 200) {
      final List data = jsonDecode(res.body);
      return data.map((e) => User.fromJson(e)).toList();
    }
    throw ApiException(_extractError(res));
  }

  static Future<User> createStaff({
    required String username,
    required String password,
    required String staffName,
    required String role,
    String? mobile,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/create-user'),
      headers: _headers,
      body: jsonEncode({
        'username': username,
        'password': password,
        'staff_name': staffName,
        'role': role,
        'mobile': mobile,
      }),
    );
    if (res.statusCode == 200) {
      return User.fromJson(jsonDecode(res.body));
    }
    throw ApiException(_extractError(res));
  }

  static Future<List<dynamic>> getTransactions({
    DateTime? fromDate,
    DateTime? toDate,
    String? type,
    String? category,
    String? paymentMethod,
    String? status,
    int skip = 0,
    int limit = 50,
  }) async {
    final queryParams = <String, String>{};
    if (fromDate != null) queryParams['from_date'] = fromDate.toIso8601String();
    if (toDate != null) queryParams['to_date'] = toDate.toIso8601String();
    if (type != null) queryParams['transaction_type'] = type;
    if (category != null) queryParams['category'] = category;
    if (paymentMethod != null) queryParams['payment_method'] = paymentMethod;
    if (status != null) queryParams['status'] = status;
    queryParams['skip'] = skip.toString();
    queryParams['limit'] = limit.toString();

    final uri = Uri.parse('$baseUrl/finance/transactions').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw ApiException(_extractError(res));
  }

  static Future<Map<String, dynamic>> getTransactionsSummary({
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final queryParams = {
      'from_date': fromDate.toIso8601String(),
      'to_date': toDate.toIso8601String(),
    };
    final uri = Uri.parse('$baseUrl/finance/transactions/summary').replace(queryParameters: queryParams);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(_extractError(res));
  }

  static Future<Map<String, dynamic>> createExpense({
    required DateTime expenseDate,
    required String category,
    required String description,
    required double amount,
    required String paymentMethod,
    String? referenceNo,
    String? remarks,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/finance/expenses'),
      headers: _headers,
      body: jsonEncode({
        'expense_date': expenseDate.toIso8601String(),
        'category': category,
        'description': description,
        'amount': amount,
        'payment_method': paymentMethod,
        'reference_no': referenceNo,
        'remarks': remarks,
      }),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(_extractError(res));
  }

  static Future<Map<String, dynamic>> updateExpense(
    int expenseId,
    Map<String, dynamic> data,
  ) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/finance/expenses/$expenseId'),
      headers: _headers,
      body: jsonEncode(data),
    );
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(_extractError(res));
  }

  static Future<Map<String, dynamic>> cancelExpense(
    int expenseId, {
    String? reason,
  }) async {
    final queryParams = reason != null ? {'reason': reason} : <String, String>{};
    final uri = Uri.parse('$baseUrl/finance/expenses/$expenseId').replace(
      queryParameters: queryParams.isNotEmpty ? queryParams : null,
    );
    final res = await http.delete(uri, headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(_extractError(res));
  }

  static String _extractError(http.Response res) {
    try {
      final data = jsonDecode(res.body);
      return data['detail'] ?? 'ஏதோ தவறு நடந்துவிட்டது';
    } catch (_) {
      return 'சேவையகத்துடன் இணைக்க முடியவில்லை';
    }
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}