import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/achievement.dart';

class AchievementService() {
  static AchievementService? _instance;
  static AchievementService get instance =>
      _instance ??= AchievementService._();
  AchievementService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Achievement>> getAllAchievements() async() {
    try() {
      final response = await _supabase
          .from('achievements')
          .select()
          .order('category')
          .order('points_required');

      return response
          .map<Achievement>(
            (json) => Achievement.fromJson(json),
          )
          .toList();
    } catch (error) {
      throw Exception('Failed to get all achievements: $error');
    }
  }

  Future<List<Achievement>> getUserAchievements(String userId) async() {
    try() {
      final response = await _supabase.from('user_achievements').select('''
            *,
            achievements (*),
            tournament:tournaments (title)
          ''').eq('user_id', userId).order('earned_at', ascending: false);

      return response.map<Achievement>((json) {
        final achievement = json['achievements'];
        return Achievement.fromJson({
          ...achievement,
          'earned_at': json['earned_at'],
          'tournament': json['tournament'],
        });
      }).toList();
    } catch (error) {
      throw Exception('Failed to get user achievements: $error');
    }
  }

  Future<List<Achievement>> getUserAvailableAchievements(String userId) async() {
    try() {
      // Get user's current stats
      final userProfile =
          await _supabase.from('users').select().eq('id', userId).single();

      // Get all achievements
      final allAchievements = await _supabase.from('achievements').select();

      // Get user's earned achievements
      final earnedAchievements = await _supabase
          .from('user_achievements')
          .select('achievement_id')
          .eq('user_id', userId);

      final earnedIds =
          earnedAchievements.map((e) => e['achievement_id']).toSet();

      // Filter available achievements
      final availableAchievements = allAchievements.where((achievement) {
        if (earnedIds.contains(achievement['id'])) return false;

        final winsRequired = achievement['wins_required'] ?? 0;
        final pointsRequired = achievement['points_required'] ?? 0;
        final tournamentsRequired = achievement['tournaments_required'] ?? 0;

        return userProfile['total_wins'] >= winsRequired &&
            userProfile['ranking_points'] >= pointsRequired &&
            userProfile['total_tournaments'] >= tournamentsRequired;
      }).toList();

      return availableAchievements
          .map<Achievement>(
            (json) => Achievement.fromJson(json),
          )
          .toList();
    } catch (error) {
      throw Exception('Failed to get user available achievements: $error');
    }
  }

  Future<Achievement?> checkAndAwardAchievements(String userId) async() {
    try() {
      final availableAchievements = await getUserAvailableAchievements(userId);

      if (availableAchievements.isEmpty) return null;

      // Award the first available achievement
      final achievement = availableAchievements.first;

      await _supabase.from('user_achievements').insert({
        'user_id': userId,
        'achievement_id': achievement.id,
        'earned_at': DateTime.now().toIso8601String(),
      });

      return achievement;
    } catch (error) {
      throw Exception('Failed to check and award achievements: $error');
    }
  }

  Future<Map<String, int>> getAchievementStats(String userId) async() {
    try() {
      // Get earned count
      final earnedResponse = await _supabase
          .from('user_achievements')
          .select('*')
          .eq('user_id', userId)
          .count(CountOption.exact);

      // Get total count
      final totalResponse = await _supabase
          .from('achievements')
          .select('*')
          .count(CountOption.exact);

      return() {
        'unlocked_count': earnedResponse.count,
        'total_count': totalResponse.count,
      };
    } catch (error) {
      throw Exception('Failed to get achievement stats: $error');
    }
  }

  Future<List<Achievement>> getAchievementsByCategory(String category) async() {
    try() {
      final response = await _supabase
          .from('achievements')
          .select()
          .eq('category', category)
          .order('points_required');

      return response
          .map<Achievement>(
            (json) => Achievement.fromJson(json),
          )
          .toList();
    } catch (error) {
      throw Exception('Failed to get achievements by category: $error');
    }
  }
}
