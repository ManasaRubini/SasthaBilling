class User {
  final int userId;
  final String username;
  final String staffName;
  final String role;
  final String? mobile;
  final bool isActive;

  User({
    required this.userId,
    required this.username,
    required this.staffName,
    required this.role,
    this.mobile,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'],
      username: json['username'],
      staffName: json['staff_name'],
      role: json['role'],
      mobile: json['mobile'],
      isActive: json['is_active'] ?? true,
    );
  }

  bool get isAdmin => role == 'admin';
}

class Devotee {
  final int devoteeId;
  final String devoteeName;
  final String? fatherName;
  final String? mobile;
  final String? address;
  final String? village;
  final String? familyId;
  final DateTime? createdAt;

  Devotee({
    required this.devoteeId,
    required this.devoteeName,
    this.fatherName,
    this.mobile,
    this.address,
    this.village,
    this.familyId,
    this.createdAt,
  });

  factory Devotee.fromJson(Map<String, dynamic> json) {
    return Devotee(
      devoteeId: json['devotee_id'],
      devoteeName: json['devotee_name'],
      fatherName: json['father_name'],
      mobile: json['mobile'],
      address: json['address'],
      village: json['village'],
      familyId: json['family_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'devotee_name': devoteeName,
      'father_name': fatherName,
      'mobile': mobile,
      'address': address,
      'village': village,
      'family_id': familyId,
    };
  }
}

class Bill {
  final int billId;
  final String receiptNo;
  final int devoteeId;
  final int staffId;
  final String billType;
  final String? category;
  final double amount;
  final String paymentMethod;
  final String? transactionId;
  final String? remarks;
  final String status;
  final DateTime billDate;
  final Devotee? devotee;
  final User? staff;

  Bill({
    required this.billId,
    required this.receiptNo,
    required this.devoteeId,
    required this.staffId,
    required this.billType,
    this.category,
    required this.amount,
    required this.paymentMethod,
    this.transactionId,
    this.remarks,
    required this.status,
    required this.billDate,
    this.devotee,
    this.staff,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      billId: json['bill_id'],
      receiptNo: json['receipt_no'],
      devoteeId: json['devotee_id'],
      staffId: json['staff_id'],
      billType: json['bill_type'],
      category: json['category'],
      amount: double.parse(json['amount'].toString()),
      paymentMethod: json['payment_method'],
      transactionId: json['transaction_id'],
      remarks: json['remarks'],
      status: json['status'],
      billDate: DateTime.parse(json['bill_date']),
      devotee: json['devotee'] != null ? Devotee.fromJson(json['devotee']) : null,
      staff: json['staff'] != null ? User.fromJson(json['staff']) : null,
    );
  }
}

class DashboardStats {
  final double todayCollection;
  final double todayVari;
  final double todayKanikkai;
  final int todayBillsCount;
  final int totalDevotees;
  final int totalStaff;
  final double monthlyCollection;

  DashboardStats({
    required this.todayCollection,
    required this.todayVari,
    required this.todayKanikkai,
    required this.todayBillsCount,
    required this.totalDevotees,
    required this.totalStaff,
    required this.monthlyCollection,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      todayCollection: double.parse(json['today_collection'].toString()),
      todayVari: double.parse(json['today_vari'].toString()),
      todayKanikkai: double.parse(json['today_kanikkai'].toString()),
      todayBillsCount: json['today_bills_count'],
      totalDevotees: json['total_devotees'],
      totalStaff: json['total_staff'],
      monthlyCollection: double.parse(json['monthly_collection'].toString()),
    );
  }
}