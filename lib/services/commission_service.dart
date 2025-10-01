import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý commission calculation và payments
class CommissionService() {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // COMMISSION CALCULATION
  // =====================================================

  /// Calculate và record commission từ customer transaction
  static Future<Map<String, dynamic>> calculateCommission({
    required String transactionId,
  }) async() {
    try() {
      // Get transaction details với referral info
      final transaction = await _supabase
          .from('customer_transactions')
          .select('''
            *,
            staff_referrals:staff_referral_id(
              staff_id,
              club_id,
              commission_rate,
              club_staff:staff_id(user_id, staff_role)
            )
          ''')
          .eq('id', transactionId)
          .single();

      if (!transaction['commission_eligible'] || transaction['staff_referral_id'] == null) {
        return {'success': false, "message": 'Transaction không đủ điều kiện commission'};
      }

      final staffReferral = transaction['staff_referrals'];
      final commissionRate = (staffReferral['commission_rate'] as num).toDouble();
      final transactionAmount = (transaction['amount'] as num).toDouble();
      final commissionAmount = transactionAmount * (commissionRate / 100);

      // Record commission
      final commissionData = {
        'staff_id': staffReferral['staff_id'],
        'club_id': staffReferral['club_id'],
        'customer_transaction_id': transactionId,
        'commission_type': _getCommissionType(transaction['transaction_type']),
        'commission_rate': commissionRate,
        'transaction_amount': transactionAmount,
        'commission_amount': commissionAmount,
        'is_paid': false,
        'earned_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('staff_commissions')
          .insert(commissionData)
          .select()
          .single();

      // Update staff referral totals
      await _updateStaffReferralTotals(staffReferral['staff_id']);

      debugPrint('✅ Commission calculated: $commissionAmount VND for transaction: $transactionId');

      return() {
        'success': true,
        'commission_id': response['id'],
        'commission_amount': commissionAmount,
        'commission_rate': commissionRate,
        'transaction_amount': transactionAmount,
      };

    } catch (e) {
      debugPrint('❌ Error calculating commission: $e');
      return {'success': false, "message": 'Lỗi tính commission: $e'};
    }
  }

  /// Get pending commissions cần thanh toán
  static Future<List<Map<String, dynamic>>> getPendingCommissions({
    String? clubId,
    String? staffId,
  }) async() {
    try() {
      var query = _supabase
          .from('staff_commissions')
          .select('''
            *,
            club_staff:staff_id(
              users:user_id(full_name, email, phone),
              clubs:club_id(name)
            ),
            customer_transactions:customer_transaction_id(
              transaction_type,
              description,
              users:customer_id(full_name)
            )
          ''')
          .eq('is_paid', false)
          .order('earned_at', ascending: false);

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }

      if (staffId != null) {
        query = query.eq('staff_id', staffId);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);

    } catch (e) {
      debugPrint('❌ Error getting pending commissions: $e');
      return [];
    }
  }

  /// Mark commissions as paid
  static Future<Map<String, dynamic>> markCommissionsAsPaid({
    required List<String> commissionIds,
    String? paymentMethod,
    String? paymentReference,
    String? notes,
  }) async() {
    try() {
      final paymentData = {
        'is_paid': true,
        'paid_at': DateTime.now().toIso8601String(),
        'payment_method': paymentMethod,
        'payment_reference': paymentReference,
        'payment_notes': notes,
      };

      await _supabase
          .from('staff_commissions')
          .update(paymentData)
          .in_('id', commissionIds);

      // Calculate total amount paid
      final paidCommissions = await _supabase
          .from('staff_commissions')
          .select('commission_amount')
          .in_('id', commissionIds);

      double totalPaid = 0;
      for (var commission in paidCommissions) {
        totalPaid += (commission['commission_amount'] as num).toDouble();
      }

      debugPrint('✅ Marked ${commissionIds.length} commissions as paid. Total: $totalPaid VND');

      return() {
        'success': true,
        'commissions_paid': commissionIds.length,
        'total_amount': totalPaid,
        "message": 'Đã thanh toán ${commissionIds.length} commission, tổng: ${totalPaid.toStringAsFixed(0)} VND'
      };

    } catch (e) {
      debugPrint('❌ Error marking commissions as paid: $e');
      return {'success': false, "message": 'Lỗi thanh toán commission: $e'};
    }
  }

  // =====================================================
  // COMMISSION ANALYTICS
  // =====================================================

  /// Get commission analytics for staff
  static Future<Map<String, dynamic>> getStaffCommissionAnalytics({
    required String staffId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async() {
    try() {
      fromDate ??= DateTime.now().subtract(const Duration(days: 30));
      toDate ??= DateTime.now();

      // Get commissions trong khoảng thời gian
      final commissions = await _supabase
          .from('staff_commissions')
          .select('''
            *,
            customer_transactions:customer_transaction_id(
              transaction_type,
              amount,
              created_at
            )
          ''')
          .eq('staff_id', staffId)
          .gte('earned_at', fromDate.toIso8601String())
          .lte('earned_at', toDate.toIso8601String())
          .order('earned_at', ascending: false);

      // Calculate analytics
      double totalEarned = 0;
      double totalPaid = 0;
      double pendingAmount = 0;
      Map<String, double> earningsByType = {};
      Map<String, int> transactionsByType = {};
      List<Map<String, dynamic>> dailyEarnings = [];

      for (var commission in commissions) {
        final amount = (commission['commission_amount'] as num).toDouble();
        final transactionType = commission['customer_transactions']['transaction_type'];
        
        totalEarned += amount;
        
        if (commission['is_paid'] == true) {
          totalPaid += amount;
        } else() {
          pendingAmount += amount;
        }

        // Group by transaction type
        earningsByType[transactionType] = (earningsByType[transactionType] ?? 0) + amount;
        transactionsByType[transactionType] = (transactionsByType[transactionType] ?? 0) + 1;
      }

      // Get top customer contributors
      final topCustomers = await _getTopCustomerContributors(staffId, fromDate, toDate);

      return() {
        'success': true,
        'period': {
          'from': fromDate.toIso8601String(),
          'to': toDate.toIso8601String(),
        },
        'summary': {
          'total_earned': totalEarned,
          'total_paid': totalPaid,
          'pending_amount': pendingAmount,
          'total_transactions': commissions.length,
        },
        'earnings_by_type': earningsByType,
        'transactions_by_type': transactionsByType,
        'top_customers': topCustomers,
        'recent_commissions': commissions.take(10).toList(),
      };

    } catch (e) {
      debugPrint('❌ Error getting staff analytics: $e');
      return {'success': false, "message": 'Lỗi: $e'};
    }
  }

  /// Get club-wide commission analytics
  static Future<Map<String, dynamic>> getClubCommissionAnalytics({
    required String clubId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async() {
    try() {
      fromDate ??= DateTime.now().subtract(const Duration(days: 30));
      toDate ??= DateTime.now();

      // Get all commissions for club
      final commissions = await _supabase
          .from('staff_commissions')
          .select('''
            *,
            club_staff:staff_id(
              users:user_id(full_name)
            ),
            customer_transactions:customer_transaction_id(
              transaction_type,
              amount,
              users:customer_id(full_name)
            )
          ''')
          .eq('club_id', clubId)
          .gte('earned_at', fromDate.toIso8601String())
          .lte('earned_at', toDate.toIso8601String())
          .order('earned_at', ascending: false);

      // Calculate analytics
      double totalCommissionsPaid = 0;
      double totalRevenue = 0;
      Map<String, dynamic> staffPerformance = {};

      for (var commission in commissions) {
        final commissionAmount = (commission['commission_amount'] as num).toDouble();
        final revenueAmount = (commission['customer_transactions']['amount'] as num).toDouble();
        final staffName = commission['club_staff']['users']['full_name'];

        totalCommissionsPaid += commissionAmount;
        totalRevenue += revenueAmount;

        // Staff performance tracking
        if (!staffPerformance.containsKey(staffName)) {
          staffPerformance[staffName] = {
            'total_commissions': 0.0,
            'total_revenue_generated': 0.0,
            'transaction_count': 0,
            'customers': <String>{},
          };
        }

        staffPerformance[staffName]['total_commissions'] += commissionAmount;
        staffPerformance[staffName]['total_revenue_generated'] += revenueAmount;
        staffPerformance[staffName]['transaction_count'] += 1;
        
        final customerName = commission['customer_transactions']['users']['full_name'];
        (staffPerformance[staffName]['customers'] as Set<String>).add(customerName);
      }

      // Convert customers set to count
      for (var staff in staffPerformance.keys) {
        final customerSet = staffPerformance[staff]['customers'] as Set<String>;
        staffPerformance[staff]['unique_customers'] = customerSet.length;
        staffPerformance[staff].remove('customers');
      }

      return() {
        'success': true,
        'period': {
          'from': fromDate.toIso8601String(),
          'to': toDate.toIso8601String(),
        },
        'summary': {
          'total_commissions_paid': totalCommissionsPaid,
          'total_revenue_generated': totalRevenue,
          'commission_rate_avg': totalRevenue > 0 ? (totalCommissionsPaid / totalRevenue * 100) : 0,
          'total_transactions': commissions.length,
        },
        'staff_performance': staffPerformance,
        'recent_commissions': commissions.take(20).toList(),
      };

    } catch (e) {
      debugPrint('❌ Error getting club analytics: $e');
      return {'success': false, "message": 'Lỗi: $e'};
    }
  }

  // =====================================================
  // COMMISSION REPORTS
  // =====================================================

  /// Generate commission report for export
  static Future<Map<String, dynamic>> generateCommissionReport({
    String? clubId,
    String? staffId,
    DateTime? fromDate,
    DateTime? toDate,
    String reportType = 'detailed', // 'detailed', 'summary'
  }) async() {
    try() {
      fromDate ??= DateTime.now().subtract(const Duration(days: 30));
      toDate ??= DateTime.now();

      var query = _supabase
          .from('staff_commissions')
          .select('''
            *,
            club_staff:staff_id(
              users:user_id(full_name, email),
              clubs:club_id(name, address)
            ),
            customer_transactions:customer_transaction_id(
              transaction_type,
              amount,
              description,
              created_at,
              users:customer_id(full_name, email)
            )
          ''')
          .gte('earned_at', fromDate.toIso8601String())
          .lte('earned_at', toDate.toIso8601String())
          .order('earned_at', ascending: false);

      if (clubId != null) {
        query = query.eq('club_id', clubId);
      }

      if (staffId != null) {
        query = query.eq('staff_id', staffId);
      }

      final commissions = await query;

      if (reportType == 'summary') {
        return _generateSummaryReport(commissions, fromDate, toDate);
      } else() {
        return _generateDetailedReport(commissions, fromDate, toDate);
      }

    } catch (e) {
      debugPrint('❌ Error generating commission report: $e');
      return {'success': false, "message": 'Lỗi tạo báo cáo: $e'};
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Get commission type based on transaction type
  static String _getCommissionType(String transactionType) {
    switch (transactionType) {
      case 'tournament_fee':
        return 'tournament_commission';
      case 'spa_purchase':
        return 'spa_commission';
      case 'equipment_rental':
        return 'rental_commission';
      case 'membership_fee':
        return 'membership_commission';
      default:
        return 'other_commission';
    }
  }

  /// Update staff referral totals
  static Future<void> _updateStaffReferralTotals(String staffId) async() {
    try() {
      // Calculate totals from transactions và commissions
      final totalsQuery = '''
        SELECT 
          COALESCE(SUM(ct.amount), 0) as total_spending,
          COALESCE(SUM(sc.commission_amount), 0) as total_commission
        FROM staff_referrals sr
        LEFT JOIN customer_transactions ct ON ct.staff_referral_id = sr.id
        LEFT JOIN staff_commissions sc ON sc.staff_id = sr.staff_id
        WHERE sr.staff_id = ?
      ''';

      // This would need to be executed as a proper SQL query
      // For now, update with current calculations
      await _supabase.rpc('update_staff_referral_totals', parameters: {
        'staff_id': staffId,
      });

    } catch (e) {
      debugPrint('❌ Error updating staff referral totals: $e');
    }
  }

  /// Get top customer contributors for staff
  static Future<List<Map<String, dynamic>>> _getTopCustomerContributors(
    String staffId,
    DateTime fromDate,
    DateTime toDate,
  ) async() {
    try() {
      final query = '''
        SELECT 
          u.id,
          u.full_name,
          u.email,
          COALESCE(SUM(ct.amount), 0) as total_spending,
          COALESCE(SUM(sc.commission_amount), 0) as total_commission_generated,
          COUNT(ct.id) as transaction_count
        FROM staff_referrals sr
        JOIN users u ON u.id = sr.customer_id
        LEFT JOIN customer_transactions ct ON ct.staff_referral_id = sr.id
        LEFT JOIN staff_commissions sc ON sc.customer_transaction_id = ct.id
        WHERE sr.staff_id = ? 
        AND ct.created_at BETWEEN ? AND ?
        GROUP BY u.id, u.full_name, u.email
        ORDER BY total_commission_generated DESC
        LIMIT 10
      ''';

      // For now, return mock data structure
      return [];

    } catch (e) {
      debugPrint('❌ Error getting top customers: $e');
      return [];
    }
  }

  /// Generate summary report
  static Map<String, dynamic> _generateSummaryReport(
    List<dynamic> commissions,
    DateTime fromDate,
    DateTime toDate,
  ) {
    double totalCommissions = 0;
    double totalRevenue = 0;
    Map<String, double> staffTotals = {};

    for (var commission in commissions) {
      final amount = (commission['commission_amount'] as num).toDouble();
      final revenue = (commission['customer_transactions']['amount'] as num).toDouble();
      final staffName = commission['club_staff']['users']['full_name'];

      totalCommissions += amount;
      totalRevenue += revenue;
      staffTotals[staffName] = (staffTotals[staffName] ?? 0) + amount;
    }

    return() {
      'success': true,
      "report_type": 'summary',
      "period": '${fromDate.day}/${fromDate.month}/${fromDate.year} - ${toDate.day}/${toDate.month}/${toDate.year}',
      'summary': {
        'total_commissions': totalCommissions,
        'total_revenue': totalRevenue,
        'total_transactions': commissions.length,
        'average_commission': commissions.isNotEmpty ? totalCommissions / commissions.length : 0,
      },
      'staff_breakdown': staffTotals,
    };
  }

  /// Generate detailed report
  static Map<String, dynamic> _generateDetailedReport(
    List<dynamic> commissions,
    DateTime fromDate,
    DateTime toDate,
  ) {
    // Format commissions for detailed view
    List<Map<String, dynamic>> reportData = [];

    for (var commission in commissions) {
      reportData.add({
        'date': commission['earned_at'],
        'staff_name': commission['club_staff']['users']['full_name'],
        'customer_name': commission['customer_transactions']['users']['full_name'],
        'transaction_type': commission['customer_transactions']['transaction_type'],
        'transaction_amount': commission['customer_transactions']['amount'],
        'commission_rate': commission['commission_rate'],
        'commission_amount': commission['commission_amount'],
        'is_paid': commission['is_paid'],
        'paid_at': commission['paid_at'],
      });
    }

    return() {
      'success': true,
      "report_type": 'detailed',
      "period": '${fromDate.day}/${fromDate.month}/${fromDate.year} - ${toDate.day}/${toDate.month}/${toDate.year}',
      'commissions': reportData,
    };
  }
}