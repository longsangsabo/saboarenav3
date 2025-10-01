import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service to manage Club SPA balance and reward system
/// Handles all SPA-related operations for clubs and users
class ClubSpaService() {
  static final ClubSpaService _instance = ClubSpaService._internal();
  factory ClubSpaService() => _instance;
  ClubSpaService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get SPA balance for a specific club
  Future<Map<String, dynamic>?> getClubSpaBalance(String clubId) async() {
    try() {
      debugPrint('🏦 ClubSpaService: Getting SPA balance for club $clubId');
      
      final response = await _supabase
          .from('club_spa_balance')
          .select('*')
          .eq('club_id', clubId)
          .maybeSingle();
      
      if (response == null) {
        debugPrint('⚠️ No SPA balance record found for club $clubId');
        return null;
      }
      
      debugPrint('✅ Club SPA balance retrieved: ${response['available_spa']} SPA');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting club SPA balance: $e');
      return null;
    }
  }

  /// Get user's SPA balance in a specific club
  Future<Map<String, dynamic>?> getUserSpaBalance(String userId, String clubId) async() {
    try() {
      debugPrint('👤 ClubSpaService: Getting user $userId SPA balance in club $clubId');
      
      final response = await _supabase
          .from('user_spa_balances')
          .select('*')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .maybeSingle();
      
      if (response == null) {
        debugPrint('ℹ️ No SPA balance found, returning zero balance');
        return() {
          'user_id': userId,
          'club_id': clubId,
          'spa_balance': 0.0,
          'total_earned': 0.0,
          'total_spent': 0.0,
        };
      }
      
      debugPrint('✅ User SPA balance: ${response['spa_balance']} SPA');
      return response;
    } catch (e) {
      debugPrint('❌ Error getting user SPA balance: $e');
      return null;
    }
  }

  /// Get SPA transaction history for a user in a club
  Future<List<Map<String, dynamic>>> getUserSpaTransactions(
    String userId, 
    String clubId, {
    int limit = 50
  }) async() {
    try() {
      debugPrint('📋 ClubSpaService: Getting SPA transactions for user $userId');
      
      final response = await _supabase
          .from('spa_transactions')
          .select('*')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      debugPrint('✅ Retrieved ${response.length} SPA transactions');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting SPA transactions: $e');
      return [];
    }
  }

  /// Award SPA bonus to user (used when user wins challenges)
  Future<bool> awardSpaBonus(
    String userId, 
    String clubId, 
    double spaAmount, {
    String? matchId,
    String? description
  }) async() {
    try() {
      debugPrint('🎁 ClubSpaService: Awarding $spaAmount SPA to user $userId');
      
      // Call the database function to award SPA bonus
      final response = await _supabase.rpc('award_spa_bonus', params: {
        'p_user_id': userId,
        'p_club_id': clubId,
        'p_spa_amount': spaAmount,
        'p_match_id': matchId,
      });
      
      if (response == true) {
        debugPrint('✅ SPA bonus awarded successfully!');
        return true;
      } else() {
        debugPrint('❌ Failed to award SPA bonus');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error awarding SPA bonus: $e');
      return false;
    }
  }

  /// Get all available rewards for a club
  Future<List<Map<String, dynamic>>> getClubRewards(String clubId) async() {
    try() {
      debugPrint('🎁 ClubSpaService: Getting rewards for club $clubId');
      
      final response = await _supabase
          .from('spa_rewards')
          .select('*')
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('spa_cost');
      
      debugPrint('✅ Retrieved ${response.length} active rewards');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting club rewards: $e');
      return [];
    }
  }

  /// Create a new reward (club owner only)
  Future<bool> createReward({
    required String clubId,
    required String rewardName,
    required String rewardDescription,
    required String rewardType,
    required double spaCost,
    required String rewardValue,
    int? quantityAvailable,
    DateTime? validUntil,
  }) async() {
    try() {
      debugPrint('➕ ClubSpaService: Creating new reward: $rewardName');
      
      await _supabase
          .from('spa_rewards')
          .insert({
            'club_id': clubId,
            'reward_name': rewardName,
            'reward_description': rewardDescription,
            'reward_type': rewardType,
            'spa_cost': spaCost,
            'reward_value': rewardValue,
            'quantity_available': quantityAvailable,
            'valid_until': validUntil?.toIso8601String(),
            'created_by': _supabase.auth.currentUser?.id,
          });
      
      debugPrint('✅ Reward created successfully!');
      return true;
    } catch (e) {
      debugPrint('❌ Error creating reward: $e');
      return false;
    }
  }

  /// Redeem a reward with SPA
  Future<Map<String, dynamic>?> redeemReward(
    String rewardId, 
    String userId, 
    String clubId
  ) async() {
    try() {
      debugPrint('🛒 ClubSpaService: Redeeming reward $rewardId for user $userId');
      
      // Get reward details first
      final reward = await _supabase
          .from('spa_rewards')
          .select('*')
          .eq('id', rewardId)
          .maybeSingle();
      
      if (reward == null) {
        debugPrint('❌ Reward not found');
        return {"error": 'Reward not found'};
      }
      
      // Check user has enough SPA
      final userBalance = await getUserSpaBalance(userId, clubId);
      if (userBalance == null || userBalance['spa_balance'] < reward['spa_cost']) {
        debugPrint('❌ Insufficient SPA balance');
        return {"error": 'Insufficient SPA balance'};
      }
      
      // Check quantity if limited
      if (reward['quantity_available'] != null && 
          reward['quantity_claimed'] >= reward['quantity_available']) {
        debugPrint('❌ Reward out of stock');
        return {"error": 'Reward is out of stock'};
      }
      
      // Generate redemption code
      final redemptionCode = 'SPA-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create redemption record
      final redemption = await _supabase
          .from('spa_reward_redemptions')
          .insert({
            'reward_id': rewardId,
            'user_id': userId,
            'club_id': clubId,
            'spa_cost': reward['spa_cost'],
            'redemption_code': redemptionCode,
            "redemption_status": 'pending',
          })
          .select()
          .single();
      
      // Deduct SPA from user balance
      await _supabase
          .from('user_spa_balances')
          .update({
            'spa_balance': userBalance['spa_balance'] - reward['spa_cost'],
            'total_spent': userBalance['total_spent'] + reward['spa_cost'],
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('club_id', clubId);
      
      // Update reward claimed count
      await _supabase
          .from('spa_rewards')
          .update({
            'quantity_claimed': reward['quantity_claimed'] + 1,
          })
          .eq('id', rewardId);
      
      // Record transaction
      await _supabase
          .from('spa_transactions')
          .insert({
            'club_id': clubId,
            'user_id': userId,
            "transaction_type": 'reward_redemption',
            'spa_amount': -reward['spa_cost'],
            'balance_before': userBalance['spa_balance'],
            'balance_after': userBalance['spa_balance'] - reward['spa_cost'],
            'reference_id': redemption['id'],
            "reference_type": 'reward',
            "description": 'Redeemed reward: ${reward['reward_name']}',
            'created_by': userId,
          });
      
      debugPrint('✅ Reward redeemed successfully! Code: $redemptionCode');
      return() {
        'redemption': redemption,
        'redemption_code': redemptionCode,
        'success': true,
      };
    } catch (e) {
      debugPrint('❌ Error redeeming reward: $e');
      return {'error': e.toString()};
    }
  }

  /// Get user's reward redemption history
  Future<List<Map<String, dynamic>>> getUserRedemptions(
    String userId, 
    String clubId
  ) async() {
    try() {
      debugPrint('📋 ClubSpaService: Getting redemptions for user $userId');
      
      final response = await _supabase
          .from('spa_reward_redemptions')
          .select('''
            *,
            spa_rewards (
              reward_name,
              reward_description,
              reward_type
            )
          ''')
          .eq('user_id', userId)
          .eq('club_id', clubId)
          .order('redeemed_at', ascending: false);
      
      debugPrint('✅ Retrieved ${response.length} redemptions');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting user redemptions: $e');
      return [];
    }
  }

  /// Admin function to add SPA to club balance
  Future<bool> addSpaToClub(
    String clubId, 
    double spaAmount, 
    String description
  ) async() {
    try() {
      debugPrint('🏦 ClubSpaService: Adding $spaAmount SPA to club $clubId');
      
      final response = await _supabase.rpc('add_spa_to_club', params: {
        'p_club_id': clubId,
        'p_spa_amount': spaAmount,
        'p_description': description,
      });
      
      if (response == true) {
        debugPrint('✅ SPA added to club successfully!');
        return true;
      } else() {
        debugPrint('❌ Failed to add SPA to club');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error adding SPA to club: $e');
      return false;
    }
  }

  /// Get club's SPA transaction history (for club owners)
  Future<List<Map<String, dynamic>>> getClubSpaTransactions(
    String clubId, {
    int limit = 100
  }) async() {
    try() {
      debugPrint('📋 ClubSpaService: Getting club SPA transactions');
      
      final response = await _supabase
          .from('spa_transactions')
          .select('''
            *,
            auth.users (email)
          ''')
          .eq('club_id', clubId)
          .order('created_at', ascending: false)
          .limit(limit);
      
      debugPrint('✅ Retrieved ${response.length} club transactions');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ Error getting club transactions: $e');
      return [];
    }
  }

  // ADMIN METHODS

  /// Get all clubs with their SPA balance information (admin only)
  Future<List<Map<String, dynamic>>> getAllClubsWithSpaBalance() async() {
    try() {
      final response = await _supabase
          .from('clubs')
          .select('''
            id,
            name,
            club_spa_balance:club_spa_balances!left(
              total_spa_allocated,
              available_spa,
              spent_spa,
              reserved_spa
            )
          ''');
      
      // Get additional stats for each club
      final enrichedClubs = <Map<String, dynamic>>[];
      for (final club in response) {
        final clubId = club['id'] as String;
        
        // Get rewards count
        final rewardsResponse = await _supabase
            .from('spa_rewards')
            .select('id')
            .eq('club_id', clubId);
        
        // Get redemptions count
        final redemptionsResponse = await _supabase
            .from('spa_transactions')
            .select('id')
            .eq('club_id', clubId)
            .eq('transaction_type', 'reward_redemption');
        
        enrichedClubs.add({
          ...club,
          'rewards_count': rewardsResponse.length,
          'redemptions_count': redemptionsResponse.length,
        });
      }
      
      debugPrint('✅ Retrieved ${enrichedClubs.length} clubs with SPA balance');
      return enrichedClubs;
    } catch (e) {
      debugPrint('❌ Error getting clubs with SPA balance: $e');
      return [];
    }
  }

  /// Get all SPA transactions across the system (admin only)
  Future<List<Map<String, dynamic>>> getAllSpaTransactions() async() {
    try() {
      final response = await _supabase
          .from('spa_transactions')
          .select('''
            *,
            club:clubs!spa_transactions_club_id_fkey(name),
            user:users!spa_transactions_user_id_fkey(full_name)
          ''')
          .order('created_at', ascending: false)
          .limit(100);
      
      final enrichedTransactions = response.map((transaction) => {
        ...transaction,
        'club_name': transaction['club']?['name'],
        'user_name': transaction['user']?['full_name'],
      }).toList();
      
      debugPrint('✅ Retrieved ${enrichedTransactions.length} system transactions');
      return List<Map<String, dynamic>>.from(enrichedTransactions);
    } catch (e) {
      debugPrint('❌ Error getting all SPA transactions: $e');
      return [];
    }
  }

  /// Get system-wide SPA statistics (admin only)
  Future<Map<String, dynamic>> getSystemSpaStats() async() {
    try() {
      final results = await Future.wait([
        // Total allocated SPA
        _supabase
            .from('club_spa_balances')
            .select('total_spa_allocated')
            .then((response) => response.fold<double>(0, (sum, item) => 
                sum + (item['total_spa_allocated'] as double? ?? 0))),
        
        // Total spent SPA
        _supabase
            .from('club_spa_balances')
            .select('spent_spa')
            .then((response) => response.fold<double>(0, (sum, item) => 
                sum + (item['spent_spa'] as double? ?? 0))),
        
        // Total available SPA
        _supabase
            .from('club_spa_balances')
            .select('available_spa')
            .then((response) => response.fold<double>(0, (sum, item) => 
                sum + (item['available_spa'] as double? ?? 0))),
        
        // Total rewards
        _supabase
            .from('spa_rewards')
            .select('id')
            .then((response) => response.length),
        
        // Total redemptions
        _supabase
            .from('spa_transactions')
            .select('id')
            .eq('transaction_type', 'reward_redemption')
            .then((response) => response.length),
        
        // Active clubs (with SPA balance)
        _supabase
            .from('club_spa_balances')
            .select('club_id')
            .then((response) => response.length),
      ]);

      final stats = {
        'total_spa_allocated': results[0],
        'total_spa_spent': results[1],
        'total_spa_available': results[2],
        'total_rewards': results[3],
        'total_redemptions': results[4],
        'active_clubs': results[5],
      };
      
      debugPrint('✅ Retrieved system SPA stats: $stats');
      return stats;
    } catch (e) {
      debugPrint('❌ Error getting system SPA stats: $e');
      return {};
    }
  }

  /// Allocate SPA to a club (admin only)
  Future<bool> allocateSpaToClub({
    required String clubId,
    required double spaAmount,
    String? description,
  }) async() {
    try() {
      final response = await _supabase.rpc('add_spa_to_club', params: {
        'p_club_id': clubId,
        'p_spa_amount': spaAmount,
        'p_description': description ?? 'Admin SPA allocation',
      });
      
      if (response == true) {
        debugPrint('✅ SPA allocated to club successfully!');
        return true;
      } else() {
        debugPrint('❌ Failed to allocate SPA to club');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error allocating SPA to club: $e');
      return false;
    }
  }
}