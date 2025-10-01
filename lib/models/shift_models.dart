// =====================================================
// SHIFT REPORTING MODELS
// Sabo Arena - Club Shift Management Models
// =====================================================

class ShiftSession {
  final String id;
  final String clubId;
  final String staffId;
  final DateTime shiftDate;
  final String startTime;
  final String? endTime;
  final DateTime? actualStartTime;
  final DateTime? actualEndTime;
  final double openingCash;
  final double? closingCash;
  final double? expectedCash;
  final double? cashDifference;
  final double totalRevenue;
  final double cashRevenue;
  final double cardRevenue;
  final double digitalRevenue;
  final String status;
  final String? notes;
  final String? handedOverTo;
  final DateTime? handedOverAt;
  final String? handoverNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final ClubStaff? staff;
  final Club? club;

  ShiftSession({
    required this.id,
    required this.clubId,
    required this.staffId,
    required this.shiftDate,
    required this.startTime,
    this.endTime,
    this.actualStartTime,
    this.actualEndTime,
    required this.openingCash,
    this.closingCash,
    this.expectedCash,
    this.cashDifference,
    required this.totalRevenue,
    required this.cashRevenue,
    required this.cardRevenue,
    required this.digitalRevenue,
    required this.status,
    this.notes,
    this.handedOverTo,
    this.handedOverAt,
    this.handoverNotes,
    required this.createdAt,
    required this.updatedAt,
    this.staff,
    this.club,
  });

  factory ShiftSession.fromJson(Map<String, dynamic> json) {
    return ShiftSession(
      id: json['id'],
      clubId: json['club_id'],
      staffId: json['staff_id'],
      shiftDate: DateTime.parse(json['shift_date']),
      startTime: json['start_time'],
      endTime: json['end_time'],
      actualStartTime: json['actual_start_time'] != null 
          ? DateTime.parse(json['actual_start_time']) 
          : null,
      actualEndTime: json['actual_end_time'] != null 
          ? DateTime.parse(json['actual_end_time']) 
          : null,
      openingCash: (json['opening_cash'] as num? ?? 0).toDouble(),
      closingCash: (json['closing_cash'] as num?)?.toDouble(),
      expectedCash: (json['expected_cash'] as num?)?.toDouble(),
      cashDifference: (json['cash_difference'] as num?)?.toDouble(),
      totalRevenue: (json['total_revenue'] as num? ?? 0).toDouble(),
      cashRevenue: (json['cash_revenue'] as num? ?? 0).toDouble(),
      cardRevenue: (json['card_revenue'] as num? ?? 0).toDouble(),
      digitalRevenue: (json['digital_revenue'] as num? ?? 0).toDouble(),
      status: json['status'] ?? 'active',
      notes: json['notes'],
      handedOverTo: json['handed_over_to'],
      handedOverAt: json['handed_over_at'] != null 
          ? DateTime.parse(json['handed_over_at']) 
          : null,
      handoverNotes: json['handover_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      staff: json['club_staff'] != null ? ClubStaff.fromJson(json['club_staff']) : null,
      club: json['clubs'] != null ? Club.fromJson(json['clubs']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'club_id': clubId,
      'staff_id': staffId,
      'shift_date': shiftDate.toIso8601String().split('T')[0],
      'start_time': startTime,
      'end_time': endTime,
      'actual_start_time': actualStartTime?.toIso8601String(),
      'actual_end_time': actualEndTime?.toIso8601String(),
      'opening_cash': openingCash,
      'closing_cash': closingCash,
      'expected_cash': expectedCash,
      'cash_difference': cashDifference,
      'total_revenue': totalRevenue,
      'cash_revenue': cashRevenue,
      'card_revenue': cardRevenue,
      'digital_revenue': digitalRevenue,
      'status': status,
      'notes': notes,
      'handed_over_to': handedOverTo,
      'handed_over_at': handedOverAt?.toIso8601String(),
      'handover_notes': handoverNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isActive => status == 'active';
  bool get isCompleted => status == 'completed';
  bool get isHandedOver => status == 'handed_over';

  Duration? get shiftDuration() {
    if (actualStartTime != null && actualEndTime != null) {
      return actualEndTime!.difference(actualStartTime!);
    }
    return null;
  }

  double get profitMargin() {
    if (totalRevenue > 0) {
      return ((totalRevenue - (expectedCash ?? 0 - openingCash)) / totalRevenue) * 100;
    }
    return 0;
  }
}

class ShiftTransaction {
  final String id;
  final String shiftSessionId;
  final String clubId;
  final String transactionType;
  final String category;
  final String description;
  final double amount;
  final String paymentMethod;
  final int? tableNumber;
  final String? customerId;
  final String? receiptNumber;
  final String recordedBy;
  final DateTime recordedAt;
  final DateTime createdAt;

  // Related data
  final ClubStaff? recordedStaff;

  ShiftTransaction({
    required this.id,
    required this.shiftSessionId,
    required this.clubId,
    required this.transactionType,
    required this.category,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    this.tableNumber,
    this.customerId,
    this.receiptNumber,
    required this.recordedBy,
    required this.recordedAt,
    required this.createdAt,
    this.recordedStaff,
  });

  factory ShiftTransaction.fromJson(Map<String, dynamic> json) {
    return ShiftTransaction(
      id: json['id'],
      shiftSessionId: json['shift_session_id'],
      clubId: json['club_id'],
      transactionType: json['transaction_type'],
      category: json['category'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      tableNumber: json['table_number'],
      customerId: json['customer_id'],
      receiptNumber: json['receipt_number'],
      recordedBy: json['recorded_by'],
      recordedAt: DateTime.parse(json['recorded_at']),
      createdAt: DateTime.parse(json['created_at']),
      recordedStaff: json['club_staff'] != null ? ClubStaff.fromJson(json['club_staff']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'shift_session_id': shiftSessionId,
      'club_id': clubId,
      'transaction_type': transactionType,
      'category': category,
      'description': description,
      'amount': amount,
      'payment_method': paymentMethod,
      'table_number': tableNumber,
      'customer_id': customerId,
      'receipt_number': receiptNumber,
      'recorded_by': recordedBy,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isRevenue => transactionType == 'revenue';
  bool get isExpense => transactionType == 'expense';
  bool get isRefund => transactionType == 'refund';
  bool get isCashPayment => paymentMethod == 'cash';
}

class ShiftInventory {
  final String id;
  final String shiftSessionId;
  final String clubId;
  final String itemName;
  final String category;
  final String unit;
  final int openingStock;
  final int? closingStock;
  final int stockUsed;
  final int stockWasted;
  final int stockAdded;
  final double? unitCost;
  final double? unitPrice;
  final int totalSold;
  final double revenueGenerated;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  ShiftInventory({
    required this.id,
    required this.shiftSessionId,
    required this.clubId,
    required this.itemName,
    required this.category,
    required this.unit,
    required this.openingStock,
    this.closingStock,
    required this.stockUsed,
    required this.stockWasted,
    required this.stockAdded,
    this.unitCost,
    this.unitPrice,
    required this.totalSold,
    required this.revenueGenerated,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ShiftInventory.fromJson(Map<String, dynamic> json) {
    return ShiftInventory(
      id: json['id'],
      shiftSessionId: json['shift_session_id'],
      clubId: json['club_id'],
      itemName: json['item_name'],
      category: json['category'],
      unit: json['unit'],
      openingStock: json['opening_stock'] ?? 0,
      closingStock: json['closing_stock'],
      stockUsed: json['stock_used'] ?? 0,
      stockWasted: json['stock_wasted'] ?? 0,
      stockAdded: json['stock_added'] ?? 0,
      unitCost: (json['unit_cost'] as num?)?.toDouble(),
      unitPrice: (json['unit_price'] as num?)?.toDouble(),
      totalSold: json['total_sold'] ?? 0,
      revenueGenerated: (json['revenue_generated'] as num? ?? 0).toDouble(),
      notes: json['notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'shift_session_id': shiftSessionId,
      'club_id': clubId,
      'item_name': itemName,
      'category': category,
      'unit': unit,
      'opening_stock': openingStock,
      'closing_stock': closingStock,
      'stock_used': stockUsed,
      'stock_wasted': stockWasted,
      'stock_added': stockAdded,
      'unit_cost': unitCost,
      'unit_price': unitPrice,
      'total_sold': totalSold,
      'revenue_generated': revenueGenerated,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  int get calculatedClosingStock => openingStock + stockAdded - stockUsed - stockWasted;
  double get wastePercentage => openingStock > 0 ? (stockWasted / openingStock) * 100 : 0;
  double get sellThroughRate => openingStock > 0 ? (totalSold / openingStock) * 100 : 0;
}

class ShiftExpense {
  final String id;
  final String shiftSessionId;
  final String clubId;
  final String expenseType;
  final String description;
  final double amount;
  final String paymentMethod;
  final String? receiptUrl;
  final String? vendorName;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String recordedBy;
  final DateTime recordedAt;
  final DateTime createdAt;

  // Related data
  final ClubStaff? recordedStaff;
  final ClubStaff? approvedStaff;

  ShiftExpense({
    required this.id,
    required this.shiftSessionId,
    required this.clubId,
    required this.expenseType,
    required this.description,
    required this.amount,
    required this.paymentMethod,
    this.receiptUrl,
    this.vendorName,
    this.approvedBy,
    this.approvedAt,
    required this.recordedBy,
    required this.recordedAt,
    required this.createdAt,
    this.recordedStaff,
    this.approvedStaff,
  });

  factory ShiftExpense.fromJson(Map<String, dynamic> json) {
    return ShiftExpense(
      id: json['id'],
      shiftSessionId: json['shift_session_id'],
      clubId: json['club_id'],
      expenseType: json['expense_type'],
      description: json['description'],
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['payment_method'],
      receiptUrl: json['receipt_url'],
      vendorName: json['vendor_name'],
      approvedBy: json['approved_by'],
      approvedAt: json['approved_at'] != null ? DateTime.parse(json['approved_at']) : null,
      recordedBy: json['recorded_by'],
      recordedAt: DateTime.parse(json['recorded_at']),
      createdAt: DateTime.parse(json['created_at']),
      recordedStaff: json['recorded_staff'] != null ? ClubStaff.fromJson(json['recorded_staff']) : null,
      approvedStaff: json['approved_staff'] != null ? ClubStaff.fromJson(json['approved_staff']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'shift_session_id': shiftSessionId,
      'club_id': clubId,
      'expense_type': expenseType,
      'description': description,
      'amount': amount,
      'payment_method': paymentMethod,
      'receipt_url': receiptUrl,
      'vendor_name': vendorName,
      'approved_by': approvedBy,
      'approved_at': approvedAt?.toIso8601String(),
      'recorded_by': recordedBy,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  bool get isApproved => approvedBy != null && approvedAt != null;
  bool get needsApproval => !isApproved && amount > 100000; // Needs approval for expenses > 100k
}

class ShiftReport {
  final String id;
  final String shiftSessionId;
  final String clubId;
  final Map<String, double> revenueSummary;
  final Map<String, double> expenseSummary;
  final Map<String, int> inventorySummary;
  final double totalRevenue;
  final double totalExpenses;
  final double netProfit;
  final int tablesServed;
  final double averageRevenuePerTable;
  final int customerCount;
  final double cashExpected;
  final double cashActual;
  final double cashVariance;
  final String status;
  final String? managerNotes;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final ShiftSession? shiftSession;
  final ClubStaff? reviewer;

  ShiftReport({
    required this.id,
    required this.shiftSessionId,
    required this.clubId,
    required this.revenueSummary,
    required this.expenseSummary,
    required this.inventorySummary,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.netProfit,
    required this.tablesServed,
    required this.averageRevenuePerTable,
    required this.customerCount,
    required this.cashExpected,
    required this.cashActual,
    required this.cashVariance,
    required this.status,
    this.managerNotes,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.shiftSession,
    this.reviewer,
  });

  factory ShiftReport.fromJson(Map<String, dynamic> json) {
    return ShiftReport(
      id: json['id'],
      shiftSessionId: json['shift_session_id'],
      clubId: json['club_id'],
      revenueSummary: Map<String, double>.from(
        (json['revenue_summary'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble()))
      ),
      expenseSummary: Map<String, double>.from(
        (json['expense_summary'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble()))
      ),
      inventorySummary: Map<String, int>.from(
        json['inventory_summary'] as Map<String, dynamic>? ?? {}
      ),
      totalRevenue: (json['total_revenue'] as num? ?? 0).toDouble(),
      totalExpenses: (json['total_expenses'] as num? ?? 0).toDouble(),
      netProfit: (json['net_profit'] as num? ?? 0).toDouble(),
      tablesServed: json['tables_served'] ?? 0,
      averageRevenuePerTable: (json['average_revenue_per_table'] as num? ?? 0).toDouble(),
      customerCount: json['customer_count'] ?? 0,
      cashExpected: (json['cash_expected'] as num? ?? 0).toDouble(),
      cashActual: (json['cash_actual'] as num? ?? 0).toDouble(),
      cashVariance: (json['cash_variance'] as num? ?? 0).toDouble(),
      status: json['status'] ?? 'draft',
      managerNotes: json['manager_notes'],
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      shiftSession: json['shift_sessions'] != null ? ShiftSession.fromJson(json['shift_sessions']) : null,
      reviewer: json['reviewer'] != null ? ClubStaff.fromJson(json['reviewer']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'shift_session_id': shiftSessionId,
      'club_id': clubId,
      'revenue_summary': revenueSummary,
      'expense_summary': expenseSummary,
      'inventory_summary': inventorySummary,
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'net_profit': netProfit,
      'tables_served': tablesServed,
      'average_revenue_per_table': averageRevenuePerTable,
      'customer_count': customerCount,
      'cash_expected': cashExpected,
      'cash_actual': cashActual,
      'cash_variance': cashVariance,
      'status': status,
      'manager_notes': managerNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  bool get isDraft => status == 'draft';
  bool get isSubmitted => status == 'submitted';
  bool get isReviewed => status == 'reviewed';
  bool get isApproved => status == 'approved';

  double get profitMargin => totalRevenue > 0 ? (netProfit / totalRevenue) * 100 : 0;
  bool get hasCashDiscrepancy => cashVariance.abs() > 10000; // Alert if variance > 10k
  
  String get performanceRating() {
    if (profitMargin >= 30) return 'Excellent';
    if (profitMargin >= 20) return 'Good';
    if (profitMargin >= 10) return 'Average';
    if (profitMargin >= 0) return 'Poor';
    return 'Loss';
  }
}

// Helper classes for related data
class ClubStaff {
  final String id;
  final String userId;
  final String role;
  final User? user;

  ClubStaff({
    required this.id,
    required this.userId,
    required this.role,
    this.user,
  });

  factory ClubStaff.fromJson(Map<String, dynamic> json) {
    return ClubStaff(
      id: json['id'],
      userId: json['user_id'],
      role: json['role'],
      user: json['users'] != null ? User.fromJson(json['users']) : null,
    );
  }
}

class User {
  final String id;
  final String fullName;
  final String? avatarUrl;

  User({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class Club {
  final String id;
  final String name;
  final String? logoUrl;

  Club({
    required this.id,
    required this.name,
    this.logoUrl,
  });

  factory Club.fromJson(Map<String, dynamic> json) {
    return Club(
      id: json['id'],
      name: json['name'],
      logoUrl: json['logo_url'],
    );
  }
}

// =====================================================
// ENUMS FOR BETTER TYPE SAFETY
// =====================================================

enum ShiftStatus { active, completed, handedOver, reviewed }
enum TransactionType { revenue, expense, refund, adjustment }
enum PaymentMethod { cash, card, digital, bankTransfer }
enum ExpenseType { utilities, supplies, maintenance, staff, other }
enum InventoryCategory { food, drink, equipment, supplies }
enum ReportStatus { draft, submitted, reviewed, approved }