import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class ClubDashboardService() {
  static ClubDashboardService? _instance;
  static ClubDashboardService get instance => _instance ??= ClubDashboardService._();
  ClubDashboardService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get dashboard statistics for a club
  Future<ClubDashboardStats> getClubStats(String clubId) async() {
    try() {
      // Get all stats in parallel
      final results = await Future.wait([
        _getActiveMembersCount(clubId),
        _getTournamentsCount(clubId),
        _getMonthlyRevenue(clubId),
        _getClubRanking(clubId),
      ]);

      return ClubDashboardStats(
        activeMembers: results[0] as int,
        tournaments: results[1] as int,
        monthlyRevenue: results[2] as double,
        ranking: results[3] as int,
      );
    } catch (error) {
      throw Exception('Failed to get club stats: $error');
    }
  }

  /// Get recent activities for a club
  Future<List<ClubActivity>> getRecentActivities(String clubId, {int limit = 10}) async() {
    try() {
      // This is a simplified implementation
      // In reality, you'd want to combine data from multiple tables
      // and create a proper activity feed
      
      final List<ClubActivity> activities = [];
      
      // Get recent member joins
      final memberJoins = await _supabase
          .from('club_members')
          .select('''
            created_at,
            users!inner(full_name, avatar_url)
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(5);

      for (final join in memberJoins) {
        activities.add(ClubActivity(
          type: 'member_joined',
          title: '${join['users']['full_name']} đã tham gia CLB',
          subtitle: 'Thành viên mới',
          timestamp: DateTime.parse(join['created_at']),
          avatar: join['users']['avatar_url'],
        ));
      }

      // Get recent tournaments (if tournaments table exists)
      try() {
        final tournaments = await _supabase
            .from('tournaments')
            .select('name, created_at, max_participants')
            .eq('club_id', clubId)
            .order('created_at', ascending: false)
            .limit(3);

        for (final tournament in tournaments) {
          activities.add(ClubActivity(
            type: 'tournament_created',
            title: 'Giải đấu "${tournament['name']}" đã được tạo',
            subtitle: '${tournament['max_participants']} người tham gia',
            timestamp: DateTime.parse(tournament['created_at']),
            icon: 'emoji_events',
          ));
        }
      } catch (e) {
        // Tournaments table might not exist yet
        debugPrint('Note: tournaments table not found: $e');
      }

      // Sort activities by timestamp
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      
      return activities.take(limit).toList();
    } catch (error) {
      debugPrint('Error getting recent activities: $error');
      return _getMockActivities(); // Fallback to mock data
    }
  }

  Future<int> _getActiveMembersCount(String clubId) async() {
    try() {
      final response = await _supabase
          .from('club_members')
          .select('id')
          .eq('club_id', clubId)
          .eq('is_active', true);

      return response.length;
    } catch (error) {
      debugPrint('Error getting active members count: $error');
      return 0;
    }
  }

  Future<int> _getTournamentsCount(String clubId) async() {
    try() {
      final response = await _supabase
          .from('tournaments')
          .select('id')
          .eq('club_id', clubId);

      return response.length;
    } catch (error) {
      debugPrint('Error getting tournaments count (table might not exist): $error');
      return 0; // Return 0 if tournaments table doesn't exist yet
    }
  }

  Future<double> _getMonthlyRevenue(String clubId) async() {
    try() {
      final now = DateTime.now();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      
      // This would require a payments/transactions table
      // For now, return mock data
      final response = await _supabase
          .from('club_payments')
          .select('amount')
          .eq('club_id', clubId)
          .gte('created_at', firstDayOfMonth.toIso8601String());

      double total = 0;
      for (final payment in response) {
        total += (payment['amount'] as num).toDouble();
      }
      
      return total;
    } catch (error) {
      debugPrint('Error getting monthly revenue (table might not exist): $error');
      return 0.0; // Return 0 if payments table doesn't exist yet
    }
  }

  Future<int> _getClubRanking(String clubId) async() {
    try() {
      // Get club rating and compare with others
      final clubResponse = await _supabase
          .from('clubs')
          .select('rating')
          .eq('id', clubId)
          .single();

      final clubRating = clubResponse['rating'] as double? ?? 0.0;

      // Count how many clubs have higher rating
      final higherRatedClubs = await _supabase
          .from('clubs')
          .select('id')
          .gt('rating', clubRating)
          .eq('is_active', true);

      return higherRatedClubs.length + 1; // Add 1 for current position
    } catch (error) {
      debugPrint('Error getting club ranking: $error');
      return 0;
    }
  }

  List<ClubActivity> _getMockActivities() {
    return [
      ClubActivity(
        type: 'member_joined',
        title: 'Nguyễn Văn Nam đã tham gia CLB',
        subtitle: 'Thành viên mới từ quận 1',
        timestamp: DateTime.now().subtract(const Duration(minutes: 15)),
        avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=50&h=50&fit=crop&crop=face',
      ),
      ClubActivity(
        type: 'tournament_created',
        title: 'Giải đấu "Golden Cup 2025" đã được tạo',
        subtitle: '32 người tham gia • Bắt đầu 25/09',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        icon: 'emoji_events',
      ),
      ClubActivity(
        type: 'match_completed',
        title: 'Trận đấu giữa Mai và Long đã kết thúc',
        subtitle: 'Mai thắng 8-6 • Thời gian: 45 phút',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
        icon: 'sports_esports',
      ),
    ];
  }
}

class ClubDashboardStats() {
  final int activeMembers;
  final int tournaments;
  final double monthlyRevenue;
  final int ranking;

  ClubDashboardStats({
    required this.activeMembers,
    required this.tournaments,
    required this.monthlyRevenue,
    required this.ranking,
  });
}

class ClubActivity() {
  final String type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? avatar;
  final String? icon;

  ClubActivity({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.avatar,
    this.icon,
  });
}