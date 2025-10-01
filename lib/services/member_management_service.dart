
class MemberManagementService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ====================================
  // CLUB MEMBERSHIPS MANAGEMENT
  // ====================================

  /// Get all members for a specific club
  static Future<List<Map<String, dynamic>>> getClubMembers({
    required String clubId,
    String? status,
    String? membershipType,
    int? limit,
    int? offset,
  }) async {
    try {
      print('🔍 MemberManagementService: Getting members for club $clubId');
      print('🔍 Status filter: $status, Role filter: $membershipType');
      
      var query = _supabase
          .from('club_members')
          .select('*, users(*)');
      
      query = query.eq('club_id', clubId);
      
      if (status != null) {
        query = query.eq('status', status);
      }
      
      if (membershipType != null) {
        query = query.eq('role', membershipType); // Use role instead of membership_type
      }

      final response = await query;
      print('✅ MemberManagementService: Found ${response.length} members');
      
      if (limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = startIndex + limit;
        if (response.length > startIndex) {
          return List<Map<String, dynamic>>.from(
            response.sublist(startIndex, endIndex.clamp(0, response.length))
          );
        }
        return [];
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching club members: $e');
    }
  }

  /// Add a new member to the club
  static Future<Map<String, dynamic>> addClubMember({
    required String clubId,
    required String userId,
    String membershipType = 'regular',
    String status = 'active',
    bool autoRenewal = false,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final data = {
        'club_id': clubId,
        'user_id': userId,
        'membership_type': membershipType,
        'status': status,
        'auto_renewal': autoRenewal,
        'permissions': permissions ?? {
          'tournaments': true,
          'posts': true,
          'chat': true,
          'invite': false,
          'contact': false,
        },
        'joined_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('club_memberships')
          .insert(data)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error adding club member: $e');
    }
  }

  /// Update an existing member's information
  static Future<Map<String, dynamic>> updateClubMember({
    required String membershipId,
    String? membershipType,
    String? status,
    bool? autoRenewal,
    Map<String, dynamic>? permissions,
  }) async {
    try {
      final data = <String, dynamic>{};
      
      if (membershipType != null) data['membership_type'] = membershipType;
      if (status != null) data['status'] = status;
      if (autoRenewal != null) data['auto_renewal'] = autoRenewal;
      if (permissions != null) data['permissions'] = permissions;

      final response = await _supabase
          .from('club_memberships')
          .update(data)
          .eq('id', membershipId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Error updating club member: $e');
    }
  }

  /// Remove a member from the club
  static Future<void> removeClubMember(String membershipId) async {
    try {
      await _supabase
          .from('club_memberships')
          .delete()
          .eq('id', membershipId);
    } catch (e) {
      throw Exception('Error removing club member: $e');
    }
  }

  /// Get membership requests for a club
  static Future<List<Map<String, dynamic>>> getMembershipRequests({
    required String clubId,
    String? status,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('membership_requests')
          .select('*, users(*)')
          .eq('club_id', clubId);
      
      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      
      if (limit != null) {
        final startIndex = offset ?? 0;
        final endIndex = startIndex + limit;
        if (response.length > startIndex) {
          return List<Map<String, dynamic>>.from(
            response.sublist(startIndex, endIndex.clamp(0, response.length))
          );
        }
        return [];
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching membership requests: $e');
    }
  }

  /// Approve a membership request
  static Future<Map<String, dynamic>> approveMembershipRequest({
    required String requestId,
    String membershipType = 'regular',
  }) async {
    try {
      // First get the request details
      final request = await _supabase
          .from('membership_requests')
          .select('*')
          .eq('id', requestId)
          .single();

      // Create club membership
      final membership = await addClubMember(
        clubId: request['club_id'],
        userId: request['user_id'],
        membershipType: membershipType,
      );

      // Update request status
      await _supabase
          .from('membership_requests')
          .update({"status": 'approved', 'approved_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);

      return membership;
    } catch (e) {
      throw Exception('Error approving membership request: $e');
    }
  }

  /// Reject a membership request
  static Future<void> rejectMembershipRequest(String requestId) async {
    try {
      await _supabase
          .from('membership_requests')
          .update({"status": 'rejected', 'rejected_at': DateTime.now().toIso8601String()})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('Error rejecting membership request: $e');
    }
  }

  /// Get member analytics for a club
  static Future<Map<String, dynamic>> getMemberAnalytics(String clubId) async {
    try {
      final members = await getClubMembers(clubId: clubId);
      
      final totalMembers = members.length;
      final activeMembers = members.where((m) => m['status'] == 'active').length;
      
      // Calculate new members this month
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final newThisMonth = members.where((m) {
        final joinedAt = DateTime.parse(m['joined_at'] ?? now.toIso8601String());
        return joinedAt.isAfter(thisMonthStart);
      }).length;

      return() {
        'total_members': totalMembers,
        'active_members': activeMembers,
        'new_this_month': newThisMonth,
        'growth_rate': totalMembers > 0 ? (newThisMonth / totalMembers * 100) : 0.0,
      };
    } catch (e) {
      throw Exception('Error fetching member analytics: $e');
    }
  }

  /// Search members by name or email
  static Future<List<Map<String, dynamic>>> searchMembers({
    required String clubId,
    required String searchQuery,
    int? limit,
  }) async {
    try {
      final response = await _supabase
          .from('club_memberships')
          .select('*, users(*)')
          .eq('club_id', clubId)
          .or('users.display_name.ilike.%$searchQuery%,users.email.ilike.%$searchQuery%');

      if (limit != null && response.length > limit) {
        return List<Map<String, dynamic>>.from(response.sublist(0, limit));
      }
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error searching members: $e');
    }
  }

  /// Get member count by role/type
  static Future<Map<String, int>> getMemberCountByType(String clubId) async {
    try {
      final members = await getClubMembers(clubId: clubId);
      
      final counts = <String, int>{};
      for (final member in members) {
        final type = member['membership_type'] ?? 'regular';
        counts[type] = (counts[type] ?? 0) + 1;
      }
      
      return counts;
    } catch (e) {
      throw Exception('Error fetching member count by type: $e');
    }
  }
}