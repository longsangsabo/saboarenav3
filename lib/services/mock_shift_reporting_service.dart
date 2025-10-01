
class MockShiftReportingService {
  static final MockShiftReportingService _instance = MockShiftReportingService._internal();
  factory MockShiftReportingService() => _instance;
  MockShiftReportingService._internal();

  final Random _random = Random();
  static final List<ShiftSession> _mockSessions = [];
  static final List<ShiftTransaction> _mockTransactions = [];
  static final List<ShiftInventory> _mockInventory = [];
  static final List<ShiftExpense> _mockExpenses = [];
  static final List<ShiftReport> _mockReports = [];

  // =====================================================
  // MOCK DATA GENERATION
  // =====================================================

  List<String> _sampleItems = [
    'Coca Cola', 'Pepsi', 'Sting', 'Red Bull', 'Nước suối',
    'Bánh mì', 'Cơm trưa', 'Phở bò', 'Bún chả', 'Trà đá',
    'Bia Heineken', 'Bia Tiger', 'Bia Saigon', 'Rượu vang'
  ];

  List<String> _sampleCategories = ['food', 'drink', 'equipment', 'supplies'];
  List<String> _paymentMethods = ['cash', 'card', 'digital'];
  List<String> _expenseTypes = ['utilities', 'supplies', 'maintenance', 'staff'];

  void _initializeMockData() {
    if (_mockSessions.isNotEmpty) return;

    final clubId = 'demo_club_001';
    final staffId = 'demo_staff_001';

    // Generate last 7 days of shift sessions
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final sessionId = 'session_${date.day}_${date.month}';
      
      final session = ShiftSession(
        id: sessionId,
        clubId: clubId,
        staffId: staffId,
        shiftDate: date,
        startTime: '08:00:00',
        endTime: '16:00:00',
        actualStartTime: DateTime(date.year, date.month, date.day, 8, 0),
        actualEndTime: i == 0 ? null : DateTime(date.year, date.month, date.day, 16, 0),
        openingCash: 500000 + _random.nextDouble() * 200000,
        closingCash: i != 0 ? 800000 + _random.nextDouble() * 400000 : null,
        expectedCash: i != 0 ? 850000 + _random.nextDouble() * 300000 : null,
        cashDifference: i != 0 ? (_random.nextDouble() - 0.5) * 50000 : null,
        totalRevenue: 1200000 + _random.nextDouble() * 800000,
        cashRevenue: 800000 + _random.nextDouble() * 400000,
        cardRevenue: 300000 + _random.nextDouble() * 200000,
        digitalRevenue: 100000 + _random.nextDouble() * 200000,
        status: i == 0 ? "active" : 'completed',
        notes: i == 0 ? "Ca hiện tại đang hoạt động" : 'Ca hoàn thành bình thường',
        createdAt: DateTime(date.year, date.month, date.day, 7, 30),
        updatedAt: DateTime(date.year, date.month, date.day, 16, 30),
      );

      _mockSessions.add(session);

      // Generate transactions for each session
      _generateMockTransactions(sessionId, clubId, date);
      
      // Generate inventory for each session
      _generateMockInventory(sessionId, clubId);
      
      // Generate expenses for each session
      _generateMockExpenses(sessionId, clubId, date);

      // Generate report for completed sessions
      if (i != 0) {
        _generateMockReport(sessionId, clubId, session);
      }
    }
  }

  void _generateMockTransactions(String sessionId, String clubId, DateTime date) {
    final transactionCount = 15 + _random.nextInt(25);
    
    for (int i = 0; i < transactionCount; i++) {
      final hour = 8 + _random.nextInt(8);
      final minute = _random.nextInt(60);
      
      final transaction = ShiftTransaction(
        id: 'trans_${sessionId}_$i',
        shiftSessionId: sessionId,
        clubId: clubId,
        transactionType: _random.nextBool() ? "revenue" : 'expense',
        category: _random.nextBool() ? "table_fee" : 'food',
        description: _generateTransactionDescription(),
        amount: 20000 + _random.nextDouble() * 180000,
        paymentMethod: _paymentMethods[_random.nextInt(_paymentMethods.length)],
        tableNumber: _random.nextBool() ? 1 + _random.nextInt(20) : null,
        recordedBy: 'demo_staff_001',
        recordedAt: DateTime(date.year, date.month, date.day, hour, minute),
        createdAt: DateTime(date.year, date.month, date.day, hour, minute),
      );

      _mockTransactions.add(transaction);
    }
  }

  void _generateMockInventory(String sessionId, String clubId) {
    for (int i = 0; i < 8; i++) {
      final item = _sampleItems[_random.nextInt(_sampleItems.length)];
      final category = _sampleCategories[_random.nextInt(_sampleCategories.length)];
      final openingStock = 10 + _random.nextInt(40);
      final sold = _random.nextInt(openingStock ~/ 2);
      final wasted = _random.nextInt(3);
      
      final inventory = ShiftInventory(
        id: 'inv_${sessionId}_$i',
        shiftSessionId: sessionId,
        clubId: clubId,
        itemName: item,
        category: category,
        unit: category == 'drink' ? "chai" : 'phần',
        openingStock: openingStock,
        closingStock: openingStock - sold - wasted,
        stockUsed: sold,
        stockWasted: wasted,
        stockAdded: 0,
        unitCost: 15000 + _random.nextDouble() * 35000,
        unitPrice: 25000 + _random.nextDouble() * 75000,
        totalSold: sold,
        revenueGenerated: sold * (25000 + _random.nextDouble() * 75000),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      _mockInventory.add(inventory);
    }
  }

  void _generateMockExpenses(String sessionId, String clubId, DateTime date) {
    final expenseCount = 3 + _random.nextInt(5);
    
    for (int i = 0; i < expenseCount; i++) {
      final hour = 9 + _random.nextInt(6);
      
      final expense = ShiftExpense(
        id: 'exp_${sessionId}_$i',
        shiftSessionId: sessionId,
        clubId: clubId,
        expenseType: _expenseTypes[_random.nextInt(_expenseTypes.length)],
        description: _generateExpenseDescription(),
        amount: 50000 + _random.nextDouble() * 200000,
        paymentMethod: _paymentMethods[_random.nextInt(_paymentMethods.length)],
        vendorName: _generateVendorName(),
        recordedBy: 'demo_staff_001',
        approvedBy: _random.nextBool() ? 'demo_manager_001' : null,
        approvedAt: _random.nextBool() ? DateTime(date.year, date.month, date.day, hour + 1) : null,
        recordedAt: DateTime(date.year, date.month, date.day, hour),
        createdAt: DateTime(date.year, date.month, date.day, hour),
      );

      _mockExpenses.add(expense);
    }
  }

  void _generateMockReport(String sessionId, String clubId, ShiftSession session) {
    final transactions = _mockTransactions.where((t) => t.shiftSessionId == sessionId).toList();
    final inventory = _mockInventory.where((i) => i.shiftSessionId == sessionId).toList();
    final expenses = _mockExpenses.where((e) => e.shiftSessionId == sessionId).toList();

    final revenueSummary = <String, double>{};
    final expenseSummary = <String, double>{};
    final inventorySummary = <String, int>{};

    // Calculate summaries
    for (final trans in transactions) {
      if (trans.transactionType == 'revenue') {
        revenueSummary[trans.category] = (revenueSummary[trans.category] ?? 0) + trans.amount;
      }
    }

    for (final exp in expenses) {
      expenseSummary[exp.expenseType] = (expenseSummary[exp.expenseType] ?? 0) + exp.amount;
    }

    for (final inv in inventory) {
      inventorySummary['${inv.category}_sold'] = (inventorySummary['${inv.category}_sold'] ?? 0) + inv.totalSold;
    }

    final totalExpenses = expenses.fold(0.0, (sum, exp) => sum + exp.amount);
    final netProfit = session.totalRevenue - totalExpenses;

    final report = ShiftReport(
      id: 'report_$sessionId',
      shiftSessionId: sessionId,
      clubId: clubId,
      revenueSummary: revenueSummary,
      expenseSummary: expenseSummary,
      inventorySummary: inventorySummary,
      totalRevenue: session.totalRevenue,
      totalExpenses: totalExpenses,
      netProfit: netProfit,
      tablesServed: transactions.where((t) => t.tableNumber != null).length,
      averageRevenuePerTable: transactions.isNotEmpty 
          ? session.totalRevenue / transactions.where((t) => t.tableNumber != null).length
          : 0,
      customerCount: transactions.where((t) => t.customerId != null).length,
      cashExpected: session.expectedCash ?? 0,
      cashActual: session.closingCash ?? 0,
      cashVariance: session.cashDifference ?? 0,
      status: 'approved',
      createdAt: session.updatedAt,
      updatedAt: session.updatedAt,
    );

    _mockReports.add(report);
  }

  String _generateTransactionDescription() {
    final descriptions = [
      'Tiền bàn số ${1 + _random.nextInt(20)}',
      'Bán đồ uống',
      'Bán thức ăn',
      'Phụ thu thêm giờ',
      'Dịch vụ thêm',
      'Combo bàn + nước',
      'Thuê thiết bị',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateExpenseDescription() {
    final descriptions = [
      'Mua đồ uống bổ sung',
      'Chi phí điện nước',
      'Bảo trì thiết bị',
      'Mua vật dụng tiêu hao',
      'Chi phí vệ sinh',
      'Sửa chữa bàn bi-a',
      'Mua phụ kiện',
    ];
    return descriptions[_random.nextInt(descriptions.length)];
  }

  String _generateVendorName() {
    final vendors = [
      'Cửa hàng Minh Hạnh',
      'Siêu thị Big C',
      'Đại lý nước giải khát',
      'Cửa hàng vật liệu',
      'Công ty điện lạnh',
      'Thợ sửa chữa',
    ];
    return vendors[_random.nextInt(vendors.length)];
  }

  // =====================================================
  // MOCK SERVICE METHODS
  // =====================================================

  Future<ShiftSession?> getActiveShift(String staffId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _initializeMockData();
    
    return _mockSessions.where((s) => s.staffId == staffId && s.status == 'active').firstOrNull;
  }

  Future<List<ShiftTransaction>> getShiftTransactions(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initializeMockData();
    
    return _mockTransactions.where((t) => t.shiftSessionId == sessionId).toList();
  }

  Future<List<ShiftInventory>> getShiftInventory(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initializeMockData();
    
    return _mockInventory.where((i) => i.shiftSessionId == sessionId).toList();
  }

  Future<List<ShiftExpense>> getShiftExpenses(String sessionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _initializeMockData();
    
    return _mockExpenses.where((e) => e.shiftSessionId == sessionId).toList();
  }

  Future<List<ShiftReport>> getClubShiftReports(String clubId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _initializeMockData();
    
    var reports = _mockReports.where((r) => r.clubId == clubId).toList();
    
    if (status != null) {
      reports = reports.where((r) => r.status == status).toList();
    }
    
    if (startDate != null) {
      reports = reports.where((r) => r.createdAt.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      reports = reports.where((r) => r.createdAt.isBefore(endDate)).toList();
    }
    
    return reports;
  }

  Future<Map<String, dynamic>> getShiftAnalytics(String clubId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));
    _initializeMockData();
    
    var reports = _mockReports.where((r) => r.clubId == clubId).toList();
    
    if (startDate != null) {
      reports = reports.where((r) => r.createdAt.isAfter(startDate)).toList();
    }
    
    if (endDate != null) {
      reports = reports.where((r) => r.createdAt.isBefore(endDate)).toList();
    }

    double totalRevenue = 0;
    double totalExpenses = 0;
    double totalProfit = 0;

    for (final report in reports) {
      totalRevenue += report.totalRevenue;
      totalExpenses += report.totalExpenses;
      totalProfit += report.netProfit;
    }

    return() {
      'total_revenue': totalRevenue,
      'total_expenses': totalExpenses,
      'total_profit': totalProfit,
      'shift_count': reports.length,
      'average_revenue_per_shift': reports.isNotEmpty ? totalRevenue / reports.length : 0,
      'average_profit_per_shift': reports.isNotEmpty ? totalProfit / reports.length : 0,
      'profit_margin': totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0,
    };
  }

  Future<ShiftSession> startShift({
    required String clubId,
    required String staffId,
    required DateTime shiftDate,
    required String startTime,
    required String endTime,
    required double openingCash,
    String? notes,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    
    final newSession = ShiftSession(
      id: 'new_session_${DateTime.now().millisecondsSinceEpoch}',
      clubId: clubId,
      staffId: staffId,
      shiftDate: shiftDate,
      startTime: startTime,
      endTime: endTime,
      actualStartTime: DateTime.now(),
      openingCash: openingCash,
      totalRevenue: 0,
      cashRevenue: 0,
      cardRevenue: 0,
      digitalRevenue: 0,
      status: 'active',
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _mockSessions.add(newSession);
    return newSession;
  }

  Future<bool> endShift(String sessionId, {required double closingCash}) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    final sessionIndex = _mockSessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex != -1) {
      final session = _mockSessions[sessionIndex];
      final expectedCash = session.openingCash + session.cashRevenue;
      final updatedSession = ShiftSession(
        id: session.id,
        clubId: session.clubId,
        staffId: session.staffId,
        shiftDate: session.shiftDate,
        startTime: session.startTime,
        endTime: session.endTime,
        actualStartTime: session.actualStartTime,
        actualEndTime: DateTime.now(),
        openingCash: session.openingCash,
        closingCash: closingCash,
        expectedCash: expectedCash,
        cashDifference: closingCash - expectedCash,
        totalRevenue: session.totalRevenue,
        cashRevenue: session.cashRevenue,
        cardRevenue: session.cardRevenue,
        digitalRevenue: session.digitalRevenue,
        status: 'completed',
        notes: session.notes,
        createdAt: session.createdAt,
        updatedAt: DateTime.now(),
      );
      
      _mockSessions[sessionIndex] = updatedSession;
      return true;
    }
    
    return false;
  }
}