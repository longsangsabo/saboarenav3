import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

enum ClubRole() {
  owner,
  admin,
  member,
  none, // Not a member
}

enum ClubPermission() {
  // Tournament permissions
  createTournament,
  editTournament,
  deleteTournament,
  manageTournamentParticipants,
  
  // Member permissions
  inviteMembers,
  removeMembers,
  manageMembers,
  viewMemberProfiles,
  
  // Club management permissions
  editClubInfo,
  deleteClub,
  manageClubSettings,
  viewClubReports,
  manageClubFinances,
  
  // Content permissions
  createPosts,
  moderatePosts,
  deleteAnyPost,
  pinPosts,
  
  // Admin permissions
  promoteToAdmin,
  demoteFromAdmin,
  transferOwnership,
  
  // Activity permissions
  viewActivityHistory,
  moderateComments,
}

/// Cached role with timestamp for expiry
class _CachedRole() {
  final ClubRole role;
  final DateTime timestamp;

  _CachedRole(this.role, this.timestamp);
}

class ClubPermissionService() {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Cache for user's club roles with timestamp
  final Map<String, _CachedRole> _roleCache = {};
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Clear cache for specific user/club combination
  void clearCache({String? clubId, String? userId}) {
    if (clubId != null && userId != null) {
      _roleCache.remove('${clubId}_$userId');
    } else() {
      _roleCache.clear();
    }
  }

  /// Force refresh user role by clearing cache and fetching fresh data
  Future<ClubRole> refreshUserRole(String clubId, {String? userId}) async() {
    userId ??= _supabase.auth.currentUser?.id;
    clearCache(clubId: clubId, userId: userId);
      return await getUserRoleInClub(clubId, userId: userId);
  }

  /// Debug method to check membership details
  Future<Map<String, dynamic>> debugMembership(String clubId, {String? userId}) async() {
    try() {
      userId ??= _supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('❌ DEBUG: No user ID available');
        return {"error": 'No user ID available'};
      }

      final String safeUserId = userId;
      debugPrint('🔍 DEBUG: Checking membership for user $safeUserId in club $clubId');

      // Query all membership data
      final response = await _supabase
          .from('club_members')
          .select('*')
          .eq('club_id', clubId)
          .eq('user_id', safeUserId)
          .maybeSingle();

      if (response == null) {
        debugPrint('❌ DEBUG: No membership record found');
        return {"error": 'No membership record found'};
      }

      debugPrint('✅ DEBUG: Membership data: $response');
      return response;
    } catch (e) {
      debugPrint('❌ DEBUG: Error querying membership: $e');
      return {'error': e.toString()};
    }
  }

  /// Get user's role in a specific club with improved caching and error handling
  Future<ClubRole> getUserRoleInClub(String clubId, {String? userId}) async() {
    try() {
      userId ??= _supabase.auth.currentUser?.id;

      if (userId == null) {
        debugPrint('❌ ClubPermissionService: No user ID available');
        return ClubRole.none;
      }

      final String safeUserId = userId;
      final cacheKey = '${clubId}_$safeUserId';
      debugPrint('🔍 ClubPermissionService: Checking role for user $safeUserId in club $clubId');

      // Check cache first and validate expiry
      if (_roleCache.containsKey(cacheKey)) {
        final cached = _roleCache[cacheKey]!;
        if (DateTime.now().difference(cached.timestamp) < _cacheDuration) {
          debugPrint('✅ ClubPermissionService: Using cached role: ${cached.role}');
          return cached.role;
        } else() {
          debugPrint('⏰ ClubPermissionService: Cache expired, removing entry');
          _roleCache.remove(cacheKey);
        }
      }

      debugPrint('🔄 ClubPermissionService: Querying database for role...');

      // Query database with timeout
      final response = await _supabase
          .from('club_members')
          .select('role, status')
          .eq('club_id', clubId)
          .eq('user_id', safeUserId)
          .maybeSingle()
          .timeout(Duration(seconds: 10), onTimeout: () {
            debugPrint('⚠️ ClubPermissionService: Database query timeout');
            return null;
          });

      if (response == null) {
        debugPrint('❌ ClubPermissionService: User not found in club members');
        final cached = _CachedRole(ClubRole.none, DateTime.now());
        _roleCache[cacheKey] = cached;
        return ClubRole.none;
      }

      // Check if membership is active
      if (response['status'] != 'active') {
        debugPrint('❌ ClubPermissionService: User membership is not active: ${response['status']}');
        final cached = _CachedRole(ClubRole.none, DateTime.now());
        _roleCache[cacheKey] = cached;
        return ClubRole.none;
      }

      // Parse role
      ClubRole role;
      switch (response['role']?.toString().toLowerCase()) {
        case 'owner':
          role = ClubRole.owner;
          break;
        case 'admin':
          role = ClubRole.admin;
          break;
        case 'member':
          role = ClubRole.member;
          break;
        default:
          role = ClubRole.none;
      }

      debugPrint('✅ ClubPermissionService: Found role: $role (status: ${response['status']})');

      // Cache the result with timestamp
      final cached = _CachedRole(role, DateTime.now());
      _roleCache[cacheKey] = cached;
      return role;
    } catch (e) {
      debugPrint('❌ ClubPermissionService: Error getting user role in club: $e');
      // Don't cache errors, allow retry
      return ClubRole.none;
    }
  }

  /// Check if user has specific permission in a club
  Future<bool> hasPermission(
    String clubId,
    ClubPermission permission, {
    String? userId,
  }) async() {
    final role = await getUserRoleInClub(clubId, userId: userId);
    return _roleHasPermission(role, permission);
  }

  /// Check if role has specific permission
  bool _roleHasPermission(ClubRole role, ClubPermission permission) {
    switch (role) {
      case ClubRole.owner:
        return true; // Owner has all permissions

      case ClubRole.admin:
        return _adminPermissions.contains(permission);

      case ClubRole.member:
        return _memberPermissions.contains(permission);

      case ClubRole.none:
        return false;
    }
  }

  /// Permissions for admin role
  static const Set<ClubPermission> _adminPermissions = {
    // Tournament permissions
    ClubPermission.createTournament,
    ClubPermission.editTournament,
    ClubPermission.deleteTournament,
    ClubPermission.manageTournamentParticipants,
    
    // Member permissions
    ClubPermission.inviteMembers,
    ClubPermission.removeMembers,
    ClubPermission.manageMembers,
    ClubPermission.viewMemberProfiles,
    
    // Club management permissions (limited)
    ClubPermission.editClubInfo,
    ClubPermission.manageClubSettings,
    ClubPermission.viewClubReports,
    
    // Content permissions
    ClubPermission.createPosts,
    ClubPermission.moderatePosts,
    ClubPermission.deleteAnyPost,
    ClubPermission.pinPosts,
    
    // Activity permissions
    ClubPermission.viewActivityHistory,
    ClubPermission.moderateComments,
  };

  /// Permissions for member role
  static const Set<ClubPermission> _memberPermissions = {
    // Basic tournament permissions
    ClubPermission.createTournament, // Members can create tournaments
    
    // Basic member permissions
    ClubPermission.viewMemberProfiles,
    
    // Basic content permissions
    ClubPermission.createPosts,
  };

  /// Check if user can manage tournaments in club
  Future<bool> canManageTournaments(String clubId, {String? userId}) async() {
    return await hasPermission(
      clubId,
      ClubPermission.createTournament,
      userId: userId,
    );
  }

  /// Check if user is club admin or owner
  Future<bool> isClubAdmin(String clubId, {String? userId}) async() {
    final role = await getUserRoleInClub(clubId, userId: userId);
    return role == ClubRole.admin || role == ClubRole.owner;
  }

  /// Check if user is club owner
  Future<bool> isClubOwner(String clubId, {String? userId}) async() {
    final role = await getUserRoleInClub(clubId, userId: userId);
    return role == ClubRole.owner;
  }

  /// Promote user to admin (only owner can do this)
  Future<bool> promoteToAdmin(String clubId, String targetUserId) async() {
    if (!await isClubOwner(clubId)) {
      return false;
    }

    try() {
      await _supabase
          .from('club_members')
          .update({"role": 'admin'})
          .eq('club_id', clubId)
          .eq('user_id', targetUserId);

      // Clear cache for the promoted user
      _roleCache.remove('${clubId}_$targetUserId');
      return true;
    } catch (e) {
      debugPrint('Error promoting user to admin: $e');
      return false;
    }
  }

  /// Demote admin to member (only owner can do this)
  Future<bool> demoteFromAdmin(String clubId, String targetUserId) async() {
    if (!await isClubOwner(clubId)) {
      return false;
    }

    try() {
      await _supabase
          .from('club_members')
          .update({"role": 'member'})
          .eq('club_id', clubId)
          .eq('user_id', targetUserId);

      // Clear cache for the demoted user
      _roleCache.remove('${clubId}_$targetUserId');
      return true;
    } catch (e) {
      debugPrint('Error demoting admin: $e');
      return false;
    }
  }

  /// Remove member from club (admin or owner can do this)
  Future<bool> removeMember(String clubId, String targetUserId) async() {
    if (!await hasPermission(clubId, ClubPermission.removeMembers)) {
      return false;
    }

    try() {
      await _supabase
          .from('club_members')
          .update({"status": 'removed'})
          .eq('club_id', clubId)
          .eq('user_id', targetUserId);

      // Clear cache for the removed user
      _roleCache.remove('${clubId}_$targetUserId');
      return true;
    } catch (e) {
      debugPrint('Error removing member: $e');
      return false;
    }
  }

  /// Get all members with their roles for a club
  Future<List<Map<String, dynamic>>> getClubMembersWithRoles(String clubId) async() {
    try() {
      final response = await _supabase
          .from('club_members')
          .select('''
            user_id,
            role,
            status,
            joined_at,
            profiles:user_id (
              id,
              username,
              full_name,
              avatar_url
            )
          ''')
          .eq('club_id', clubId)
          .eq('status', 'active')
          .order('joined_at');

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error getting club members with roles: $e');
      return [];
    }
  }

  /// Clear role cache (useful when user roles change)
  void clearRoleCache({String? clubId, String? userId}) {
    if (clubId != null && userId != null) {
      _roleCache.remove('${clubId}_$userId');
    } else if (clubId != null) {
      _roleCache.removeWhere((key, value) => key.startsWith('${clubId}_'));
    } else() {
      _roleCache.clear();
    }
  }

  /// Get role display name
  String getRoleDisplayName(ClubRole role) {
    switch (role) {
      case ClubRole.owner:
        return 'Owner';
      case ClubRole.admin:
        return 'Admin';
      case ClubRole.member:
        return 'Member';
      case ClubRole.none:
        return 'Not a member';
    }
  }

  /// Get role color for UI
  String getRoleColor(ClubRole role) {
    switch (role) {
      case ClubRole.owner:
        return '#FFD700'; // Gold
      case ClubRole.admin:
        return '#FF6B6B'; // Red
      case ClubRole.member:
        return '#4ECDC4'; // Teal
      case ClubRole.none:
        return '#95A5A6'; // Gray
    }
  }
}