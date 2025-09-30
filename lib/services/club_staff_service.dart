import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service quản lý club staff và commission system
class ClubStaffService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // STAFF MANAGEMENT
  // =====================================================

  /// Assign user làm staff cho club
  static Future<Map<String, dynamic>> assignUserAsStaff({
    required String clubId,
    required String userId,
    String staffRole = 'staff',
    double commissionRate = 5.0,
    bool canEnterScores = true,
    bool canManageTournaments = false,
    bool canViewReports = false,
  }) async {
    try {
      // Check if user is club owner or manager
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        return {'success': false, 'message': 'User not authenticated'};
      }

      // Verify permission to assign staff
      final hasPermission = await _canManageStaff(currentUser.id, clubId);
      if (!hasPermission) {
        return {'success': false, 'message': 'Không có quyền thêm nhân viên'};
      }

      // Insert staff record
      final response = await _supabase.from('club_staff').insert({
        'club_id': clubId,
        'user_id': userId,
        'staff_role': staffRole,
        'commission_rate': commissionRate,
        'can_enter_scores': canEnterScores,
        'can_manage_tournaments': canManageTournaments,
        'can_view_reports': canViewReports,
        'is_active': true,
      }).select().single();

      // Create special staff referral code
      await _createStaffReferralCode(response['id'], userId, clubId);

      debugPrint('✅ User assigned as staff: $userId for club: $clubId');
      return {
        'success': true,
        'staff_id': response['id'],
        'message': 'Đã thêm nhân viên thành công!'
      };
      
    } catch (e) {
      debugPrint('❌ Error assigning staff: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Remove staff từ club
  static Future<Map<String, dynamic>> removeStaff({
    required String staffId,
    String? reason,
  }) async {
    try {
      await _supabase.from('club_staff').update({
        'is_active': false,
        'terminated_at': DateTime.now().toIso8601String(),
        'notes': reason ?? 'Terminated by manager',
      }).eq('id', staffId);

      // Deactivate staff referral codes
      await _supabase.from('referral_codes').update({
        'is_active': false,
      }).eq('staff_id', staffId);

      return {'success': true, 'message': 'Đã xóa nhân viên'};
      
    } catch (e) {
      debugPrint('❌ Error removing staff: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Get danh sách staff của club
  static Future<List<Map<String, dynamic>>> getClubStaff(String clubId) async {
    try {
      final response = await _supabase
          .from('club_staff')
          .select('''
            *,
            users:user_id(id, full_name, email, avatar_url, elo_rating),
            clubs:club_id(name, address)
          ''')
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('hired_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting club staff: $e');
      return [];
    }
  }

  // =====================================================
  // STAFF REFERRAL SYSTEM
  // =====================================================

  /// Tạo referral code đặc biệt cho staff
  static Future<String?> _createStaffReferralCode(
    String staffId, 
    String userId, 
    String clubId
  ) async {
    try {
      // Get user info
      final userResponse = await _supabase
          .from('users')
          .select('username, full_name')
          .eq('id', userId)
          .single();

      final username = userResponse['username'] ?? 'STAFF${staffId.substring(0, 6)}';
      final staffCode = 'STAFF-${username.toUpperCase()}';

      // Create staff referral code with higher commission
      await _supabase.from('referral_codes').insert({
        'user_id': userId,
        'staff_id': staffId,
        'club_id': clubId,
        'code': staffCode,
        'referral_type': 'staff',
        'spa_reward_referrer': 150, // Staff gets more bonus
        'spa_reward_referred': 75,  // Customer gets more bonus
        'commission_rate': 5.0,     // Ongoing commission rate
        'is_active': true,
      });

      debugPrint('✅ Created staff referral code: $staffCode');
      return staffCode;
      
    } catch (e) {
      debugPrint('❌ Error creating staff referral code: $e');
      return null;
    }
  }

  /// Apply staff referral code during registration
  static Future<Map<String, dynamic>> applyStaffReferral({
    required String referralCode,
    required String newCustomerId,
  }) async {
    try {
      // Get staff referral code details
      final codeResponse = await _supabase
          .from('referral_codes')
          .select('''
            *,
            club_staff:staff_id(id, club_id, commission_rate),
            users:user_id(full_name)
          ''')
          .eq('code', referralCode)
          .eq('referral_type', 'staff')
          .eq('is_active', true)
          .single();

      final staffId = codeResponse['staff_id'];
      final clubId = codeResponse['club_staff']['club_id'];
      final commissionRate = codeResponse['club_staff']['commission_rate'];

      // Create staff referral tracking
      await _supabase.from('staff_referrals').insert({
        'staff_id': staffId,
        'customer_id': newCustomerId,
        'club_id': clubId,
        'referral_method': 'qr_code',
        'referral_code': referralCode,
        'initial_bonus_spa': codeResponse['spa_reward_referrer'],
        'commission_rate': commissionRate,
        'is_active': true,
      });

      // Apply basic referral logic (SPA rewards)
      final basicResult = await _applyBasicReferral(codeResponse, newCustomerId);

      return {
        'success': true,
        'referral_type': 'staff',
        'staff_name': codeResponse['users']['full_name'],
        'referrer_reward': basicResult['referrer_reward'],
        'referred_reward': basicResult['referred_reward'],
        'commission_rate': commissionRate,
        'message': 'Bạn được giới thiệu bởi nhân viên ${codeResponse['users']['full_name']}!\n'
                  'Nhận ngay ${basicResult['referred_reward']} SPA + hưởng ưu đãi đặc biệt tại club!',
      };

    } catch (e) {
      debugPrint('❌ Error applying staff referral: $e');
      return {'success': false, 'message': 'Lỗi áp dụng mã giới thiệu: $e'};
    }
  }

  // =====================================================
  // CUSTOMER TRANSACTION & COMMISSION
  // =====================================================

  /// Record customer transaction tại club
  static Future<Map<String, dynamic>> recordCustomerTransaction({
    required String customerId,
    required String clubId,
    required String transactionType,
    required double amount,
    String? tournamentId,
    String? matchId,
    String? description,
    String? paymentMethod,
  }) async {
    try {
      // Check if customer was referred by staff
      final staffReferral = await _supabase
          .from('staff_referrals')
          .select('*')
          .eq('customer_id', customerId)
          .eq('club_id', clubId)
          .eq('is_active', true)
          .maybeSingle();

      // Create transaction record
      final transactionData = {
        'customer_id': customerId,
        'club_id': clubId,
        'transaction_type': transactionType,
        'amount': amount,
        'commission_eligible': true,
        'description': description,
        'payment_method': paymentMethod,
        'tournament_id': tournamentId,
        'match_id': matchId,
      };

      if (staffReferral != null) {
        transactionData['staff_referral_id'] = staffReferral['id'];
        transactionData['commission_rate'] = staffReferral['commission_rate'];
        transactionData['commission_amount'] = amount * (staffReferral['commission_rate'] / 100);
      }

      final response = await _supabase
          .from('customer_transactions')
          .insert(transactionData)
          .select()
          .single();

      debugPrint('✅ Recorded transaction: $amount VND for customer: $customerId');
      
      if (staffReferral != null) {
        debugPrint('   💰 Commission: ${response['commission_amount']} VND for staff');
      }

      return {
        'success': true,
        'transaction_id': response['id'],
        'commission_amount': response['commission_amount'] ?? 0,
        'has_referral_staff': staffReferral != null,
      };

    } catch (e) {
      debugPrint('❌ Error recording transaction: $e');
      return {'success': false, 'message': 'Lỗi ghi nhận giao dịch: $e'};
    }
  }

  // =====================================================
  // STAFF EARNINGS & REPORTS
  // =====================================================

  /// Get staff earnings summary
  static Future<Map<String, dynamic>> getStaffEarnings(String staffId) async {
    try {
      // Get total commissions
      final commissionsResponse = await _supabase
          .from('staff_commissions')
          .select('commission_amount, commission_type, earned_at')
          .eq('staff_id', staffId)
          .order('earned_at', ascending: false);

      // Get referral stats
      final referralsResponse = await _supabase
          .from('staff_referrals')
          .select('total_customer_spending, total_commission_earned')
          .eq('staff_id', staffId)
          .eq('is_active', true);

      // Calculate totals
      double totalCommissions = 0;
      double thisMonth = 0;
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);

      for (var commission in commissionsResponse) {
        totalCommissions += (commission['commission_amount'] as num).toDouble();
        
        final earnedAt = DateTime.parse(commission['earned_at']);
        if (earnedAt.isAfter(thisMonthStart)) {
          thisMonth += (commission['commission_amount'] as num).toDouble();
        }
      }

      double totalCustomerSpending = 0;
      int activeReferrals = referralsResponse.length;
      
      for (var referral in referralsResponse) {
        totalCustomerSpending += (referral['total_customer_spending'] as num).toDouble();
      }

      return {
        'success': true,
        'total_commissions': totalCommissions,
        'this_month_commissions': thisMonth,
        'total_customer_spending': totalCustomerSpending,
        'active_referrals': activeReferrals,
        'recent_commissions': commissionsResponse.take(10).toList(),
      };

    } catch (e) {
      debugPrint('❌ Error getting staff earnings: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  /// Get club commission summary (for owners)
  static Future<Map<String, dynamic>> getClubCommissionSummary(String clubId) async {
    try {
      final response = await _supabase
          .from('staff_commissions')
          .select('''
            *,
            club_staff:staff_id(users:user_id(full_name))
          ''')
          .eq('club_id', clubId)
          .order('earned_at', ascending: false);

      // Group by staff and calculate totals
      Map<String, dynamic> staffSummary = {};
      double totalCommissionsPaid = 0;

      for (var commission in response) {
        final staffName = commission['club_staff']['users']['full_name'];
        final amount = (commission['commission_amount'] as num).toDouble();
        
        totalCommissionsPaid += amount;
        
        if (!staffSummary.containsKey(staffName)) {
          staffSummary[staffName] = {
            'total_commissions': 0.0,
            'transaction_count': 0,
          };
        }
        
        staffSummary[staffName]['total_commissions'] += amount;
        staffSummary[staffName]['transaction_count'] += 1;
      }

      return {
        'success': true,
        'total_commissions_paid': totalCommissionsPaid,
        'staff_summary': staffSummary,
        'recent_commissions': response.take(20).toList(),
      };

    } catch (e) {
      debugPrint('❌ Error getting club commission summary: $e');
      return {'success': false, 'message': 'Lỗi: $e'};
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Check if user can manage staff
  static Future<bool> _canManageStaff(String userId, String clubId) async {
    try {
      final response = await _supabase
          .from('club_staff')
          .select('staff_role, can_manage_staff')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) return false;

      return response['staff_role'] == 'owner' || 
             response['staff_role'] == 'manager' || 
             response['can_manage_staff'] == true;

    } catch (e) {
      return false;
    }
  }

  /// Apply basic referral rewards (SPA)
  static Future<Map<String, dynamic>> _applyBasicReferral(
    Map<String, dynamic> codeData, 
    String newUserId
  ) async {
    // This would integrate with existing BasicReferralService
    // For now, just return the reward amounts
    return {
      'referrer_reward': codeData['spa_reward_referrer'],
      'referred_reward': codeData['spa_reward_referred'],
    };
  }

  /// Check if user is staff at any club
  static Future<Map<String, dynamic>?> getUserStaffInfo(String userId) async {
    try {
      final response = await _supabase
          .from('club_staff')
          .select('''
            *,
            clubs:club_id(id, name, address, owner_id)
          ''')
          .eq('user_id', userId)
          .eq('is_active', true)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('❌ Error getting staff info: $e');
      return null;
    }
  }
}