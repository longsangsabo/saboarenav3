import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shift_models.dart';

class ShiftReportingService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // SHIFT SESSION MANAGEMENT
  // =====================================================

  /// Start a new shift session
  Future<ShiftSession> startShift({
    required String clubId,
    required String staffId,
    required DateTime shiftDate,
    required String startTime,
    required String endTime,
    required double openingCash,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('shift_sessions')
          .insert({
            'club_id': clubId,
            'staff_id': staffId,
            'shift_date': shiftDate.toIso8601String().split('T')[0],
            'start_time': startTime,
            'end_time': endTime,
            'opening_cash': openingCash,
            'actual_start_time': DateTime.now().toIso8601String(),
            'status': 'active',
            'notes': notes,
          })
          .select()
          .single();

      return ShiftSession.fromJson(response);
    } catch (e) {
      throw Exception('Failed to start shift: $e');
    }
  }

  /// Get active shift for staff member
  Future<ShiftSession?> getActiveShift(String staffId) async {
    try {
      final response = await _supabase
          .from('shift_sessions')
          .select('''
            *,
            club_staff!inner(
              id,
              user_id,
              role,
              users!inner(id, full_name, avatar_url)
            ),
            clubs!inner(id, name, logo_url)
          ''')
          .eq('staff_id', staffId)
          .eq('status', 'active')
          .maybeSingle();

      return response != null ? ShiftSession.fromJson(response) : null;
    } catch (e) {
      throw Exception('Failed to get active shift: $e');
    }
  }

  /// End shift session
  Future<bool> endShift(String sessionId, {
    required double closingCash,
    String? notes,
  }) async {
    try {
      // Calculate cash difference
      final session = await _supabase
          .from('shift_sessions')
          .select('opening_cash, total_revenue')
          .eq('id', sessionId)
          .single();

      final openingCash = (session['opening_cash'] as num).toDouble();
      final totalRevenue = (session['total_revenue'] as num).toDouble();
      final expectedCash = openingCash + totalRevenue;
      final cashDifference = closingCash - expectedCash;

      await _supabase
          .from('shift_sessions')
          .update({
            'closing_cash': closingCash,
            'expected_cash': expectedCash,
            'cash_difference': cashDifference,
            'actual_end_time': DateTime.now().toIso8601String(),
            'status': 'completed',
            'notes': notes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      throw Exception('Failed to end shift: $e');
    }
  }

  // =====================================================
  // TRANSACTION MANAGEMENT
  // =====================================================

  /// Add transaction to shift
  Future<ShiftTransaction> addTransaction({
    required String shiftSessionId,
    required String clubId,
    required String transactionType, // 'revenue', 'expense', 'refund'
    required String category,
    required String description,
    required double amount,
    required String paymentMethod,
    int? tableNumber,
    String? customerId,
    String? receiptNumber,
    required String recordedBy,
  }) async {
    try {
      final response = await _supabase
          .from('shift_transactions')
          .insert({
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
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      // Update shift session total revenue if it's a revenue transaction
      if (transactionType == 'revenue') {
        await _updateShiftRevenue(shiftSessionId, amount, paymentMethod);
      }

      return ShiftTransaction.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add transaction: $e');
    }
  }

  /// Update shift revenue totals
  Future<void> _updateShiftRevenue(String sessionId, double amount, String paymentMethod) async {
    try {
      // Get current totals
      final session = await _supabase
          .from('shift_sessions')
          .select('total_revenue, cash_revenue, card_revenue, digital_revenue')
          .eq('id', sessionId)
          .single();

      double totalRevenue = (session['total_revenue'] as num? ?? 0).toDouble();
      double cashRevenue = (session['cash_revenue'] as num? ?? 0).toDouble();
      double cardRevenue = (session['card_revenue'] as num? ?? 0).toDouble();
      double digitalRevenue = (session['digital_revenue'] as num? ?? 0).toDouble();

      // Update totals
      totalRevenue += amount;
      switch (paymentMethod) {
        case 'cash':
          cashRevenue += amount;
          break;
        case 'card':
          cardRevenue += amount;
          break;
        case 'digital':
        case 'bank_transfer':
          digitalRevenue += amount;
          break;
      }

      await _supabase
          .from('shift_sessions')
          .update({
            'total_revenue': totalRevenue,
            'cash_revenue': cashRevenue,
            'card_revenue': cardRevenue,
            'digital_revenue': digitalRevenue,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);
    } catch (e) {
      print('Failed to update shift revenue: $e');
    }
  }

  /// Get shift transactions
  Future<List<ShiftTransaction>> getShiftTransactions(String sessionId) async {
    try {
      final response = await _supabase
          .from('shift_transactions')
          .select('''
            *,
            club_staff!shift_transactions_recorded_by_fkey(
              user_id,
              users!inner(full_name)
            )
          ''')
          .eq('shift_session_id', sessionId)
          .order('recorded_at', ascending: false);

      return response.map((json) => ShiftTransaction.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get shift transactions: $e');
    }
  }

  // =====================================================
  // INVENTORY MANAGEMENT
  // =====================================================

  /// Add inventory item to shift
  Future<ShiftInventory> addInventoryItem({
    required String shiftSessionId,
    required String clubId,
    required String itemName,
    required String category,
    required String unit,
    required int openingStock,
    int? closingStock,
    int? stockUsed,
    int? stockWasted,
    int? stockAdded,
    double? unitCost,
    double? unitPrice,
    int? totalSold,
    String? notes,
  }) async {
    try {
      final response = await _supabase
          .from('shift_inventory')
          .insert({
            'shift_session_id': shiftSessionId,
            'club_id': clubId,
            'item_name': itemName,
            'category': category,
            'unit': unit,
            'opening_stock': openingStock,
            'closing_stock': closingStock,
            'stock_used': stockUsed ?? 0,
            'stock_wasted': stockWasted ?? 0,
            'stock_added': stockAdded ?? 0,
            'unit_cost': unitCost,
            'unit_price': unitPrice,
            'total_sold': totalSold ?? 0,
            'revenue_generated': (totalSold ?? 0) * (unitPrice ?? 0),
            'notes': notes,
          })
          .select()
          .single();

      return ShiftInventory.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add inventory item: $e');
    }
  }

  /// Get shift inventory
  Future<List<ShiftInventory>> getShiftInventory(String sessionId) async {
    try {
      final response = await _supabase
          .from('shift_inventory')
          .select()
          .eq('shift_session_id', sessionId)
          .order('category', ascending: true);

      return response.map((json) => ShiftInventory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get shift inventory: $e');
    }
  }

  // =====================================================
  // EXPENSE MANAGEMENT
  // =====================================================

  /// Add expense to shift
  Future<ShiftExpense> addExpense({
    required String shiftSessionId,
    required String clubId,
    required String expenseType,
    required String description,
    required double amount,
    required String paymentMethod,
    String? receiptUrl,
    String? vendorName,
    required String recordedBy,
    String? approvedBy,
  }) async {
    try {
      final response = await _supabase
          .from('shift_expenses')
          .insert({
            'shift_session_id': shiftSessionId,
            'club_id': clubId,
            'expense_type': expenseType,
            'description': description,
            'amount': amount,
            'payment_method': paymentMethod,
            'receipt_url': receiptUrl,
            'vendor_name': vendorName,
            'recorded_by': recordedBy,
            'approved_by': approvedBy,
            'approved_at': approvedBy != null ? DateTime.now().toIso8601String() : null,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return ShiftExpense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add expense: $e');
    }
  }

  /// Get shift expenses
  Future<List<ShiftExpense>> getShiftExpenses(String sessionId) async {
    try {
      final response = await _supabase
          .from('shift_expenses')
          .select('''
            *,
            recorded_staff:club_staff!shift_expenses_recorded_by_fkey(
              user_id,
              users!inner(full_name)
            ),
            approved_staff:club_staff!shift_expenses_approved_by_fkey(
              user_id,
              users!inner(full_name)
            )
          ''')
          .eq('shift_session_id', sessionId)
          .order('recorded_at', ascending: false);

      return response.map((json) => ShiftExpense.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get shift expenses: $e');
    }
  }

  // =====================================================
  // REPORTING & ANALYTICS
  // =====================================================

  /// Generate shift report
  Future<ShiftReport> generateShiftReport(String sessionId) async {
    try {
      // Get shift summary using database function
      final summaryResponse = await _supabase
          .rpc('calculate_shift_summary', params: {'session_id': sessionId});

      // Get detailed data
      final transactions = await getShiftTransactions(sessionId);
      final expenses = await getShiftExpenses(sessionId);
      final inventory = await getShiftInventory(sessionId);

      // Process summary data
      final revenueSummary = <String, double>{};
      final expenseSummary = <String, double>{};
      final inventorySummary = <String, int>{};

      // Group transactions by category
      for (final transaction in transactions) {
        if (transaction.transactionType == 'revenue') {
          revenueSummary[transaction.category] = 
              (revenueSummary[transaction.category] ?? 0) + transaction.amount;
        }
      }

      // Group expenses by type
      for (final expense in expenses) {
        expenseSummary[expense.expenseType] = 
            (expenseSummary[expense.expenseType] ?? 0) + expense.amount;
      }

      // Group inventory by category
      for (final item in inventory) {
        inventorySummary['${item.category}_sold'] = 
            (inventorySummary['${item.category}_sold'] ?? 0) + item.totalSold;
      }

      // Get shift session data
      final session = await _supabase
          .from('shift_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      // Create or update shift report
      final reportData = {
        'shift_session_id': sessionId,
        'club_id': session['club_id'],
        'revenue_summary': revenueSummary,
        'expense_summary': expenseSummary,
        'inventory_summary': inventorySummary,
        'total_revenue': summaryResponse['total_revenue'],
        'total_expenses': summaryResponse['total_expenses'],
        'net_profit': summaryResponse['net_profit'],
        'tables_served': transactions.where((t) => t.tableNumber != null).length,
        'customer_count': transactions.where((t) => t.customerId != null).length,
        'cash_expected': session['expected_cash'] ?? 0,
        'cash_actual': session['closing_cash'] ?? 0,
        'cash_variance': session['cash_difference'] ?? 0,
        'status': 'draft',
      };

      final response = await _supabase
          .from('shift_reports')
          .upsert(reportData)
          .select()
          .single();

      return ShiftReport.fromJson(response);
    } catch (e) {
      throw Exception('Failed to generate shift report: $e');
    }
  }

  /// Get shift reports for club
  Future<List<ShiftReport>> getClubShiftReports(String clubId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('shift_reports')
          .select('''
            *,
            shift_sessions!inner(
              shift_date,
              start_time,
              end_time,
              club_staff!inner(
                user_id,
                role,
                users!inner(full_name)
              )
            )
          ''')
          .eq('club_id', clubId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at', ascending: false);

      return response.map((json) => ShiftReport.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to get shift reports: $e');
    }
  }

  /// Get shift analytics
  Future<Map<String, dynamic>> getShiftAnalytics(String clubId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('shift_reports')
          .select('total_revenue, total_expenses, net_profit, created_at')
          .eq('club_id', clubId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;

      double totalRevenue = 0;
      double totalExpenses = 0;
      double totalProfit = 0;
      int shiftCount = response.length;

      for (final report in response) {
        totalRevenue += (report['total_revenue'] as num? ?? 0).toDouble();
        totalExpenses += (report['total_expenses'] as num? ?? 0).toDouble();
        totalProfit += (report['net_profit'] as num? ?? 0).toDouble();
      }

      return {
        'total_revenue': totalRevenue,
        'total_expenses': totalExpenses,
        'total_profit': totalProfit,
        'shift_count': shiftCount,
        'average_revenue_per_shift': shiftCount > 0 ? totalRevenue / shiftCount : 0,
        'average_profit_per_shift': shiftCount > 0 ? totalProfit / shiftCount : 0,
        'profit_margin': totalRevenue > 0 ? (totalProfit / totalRevenue) * 100 : 0,
      };
    } catch (e) {
      throw Exception('Failed to get shift analytics: $e');
    }
  }

  // =====================================================
  // HANDOVER MANAGEMENT
  // =====================================================

  /// Hand over shift to another staff member
  Future<bool> handOverShift(String sessionId, {
    required String handOverToStaffId,
    required String handoverNotes,
  }) async {
    try {
      await _supabase
          .from('shift_sessions')
          .update({
            'handed_over_to': handOverToStaffId,
            'handed_over_at': DateTime.now().toIso8601String(),
            'handover_notes': handoverNotes,
            'status': 'handed_over',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', sessionId);

      return true;
    } catch (e) {
      throw Exception('Failed to hand over shift: $e');
    }
  }
}