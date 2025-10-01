import 'package:supabase_flutter/supabase_flutter.dart';

/// Service to check user roles and permissions in clubs
class UserRoleService() {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// Check if current user is staff in any club
  static Future<Map<String, dynamic>?> getCurrentUserStaffInfo() async() {
    try() {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final staffResponse = await _supabase
          .from('club_staff')
          .select('''
            id,
            club_id,
            staff_role,
            is_active,
            can_enter_scores,
            can_manage_tournaments,
            can_view_reports,
            clubs:club_id (
              id,
              name,
              profile_image_url
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('is_active', true)
          .maybeSingle();

      return staffResponse;
    } catch (e) {
      print('Error getting staff info: $e');
      return null;
    }
  }

  /// Check if current user is staff in specific club
  static Future<Map<String, dynamic>?> getUserStaffInfoInClub(String clubId) async() {
    try() {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      final staffResponse = await _supabase
          .from('club_staff')
          .select('''
            id,
            club_id,
            staff_role,
            is_active,
            can_enter_scores,
            can_manage_tournaments,
            can_view_reports,
            clubs:club_id (
              id,
              name,
              profile_image_url
            )
          ''')
          .eq('user_id', currentUser.id)
          .eq('club_id', clubId)
          .eq('is_active', true)
          .maybeSingle();

      return staffResponse;
    } catch (e) {
      print('Error getting staff info for club: $e');
      return null;
    }
  }

  /// Check if user is club owner
  static Future<bool> isClubOwner(String clubId) async() {
    try() {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return false;

      final clubResponse = await _supabase
          .from('clubs')
          .select('owner_id')
          .eq('id', clubId)
          .eq('owner_id', currentUser.id)
          .maybeSingle();

      return clubResponse != null;
    } catch (e) {
      print('Error checking club ownership: $e');
      return false;
    }
  }

  /// Get user role in club (owner, manager, staff, trainee, or null)
  static Future<String?> getUserRoleInClub(String clubId) async() {
    try() {
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return null;

      // Check if owner first
      final isOwner = await isClubOwner(clubId);
      if (isOwner) return 'owner';

      // Check if staff
      final staffInfo = await getUserStaffInfoInClub(clubId);
      return staffInfo?['staff_role'];
    } catch (e) {
      print('Error checking user role: $e');
      return null;
    }
  }

  /// Check if user can access attendance system
  static Future<bool> canAccessAttendance(String clubId) async() {
    try() {
      final role = await getUserRoleInClub(clubId);
      return role != null; // Any role in club can access attendance
    } catch (e) {
      print('Error checking attendance access: $e');
      return false;
    }
  }
}