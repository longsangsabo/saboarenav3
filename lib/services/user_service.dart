import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_profile.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class UserService() {
  static UserService? _instance;
  static UserService get instance => _instance ??= UserService._();
  UserService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserProfile?> getCurrentUserProfile() async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response =
          await _supabase.from('users').select().eq('id', user.id).single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get current user profile: $error');
    }
  }

  Future<UserProfile> getUserProfileById(String userId) async() {
    try() {
      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to get user profile: $error');
    }
  }

  Future<List<UserProfile>> getTopRankedPlayers({int limit = 10}) async() {
    try() {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get top ranked players: $error');
    }
  }

  Future<List<UserProfile>> searchUsers(String query, {int limit = 20}) async() {
    try() {
      final response = await _supabase
          .from('users')
          .select()
          .or('full_name.ilike.%$query%,username.ilike.%$query%')
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to search users: $error');
    }
  }

  Future<List<UserProfile>> getNearbyPlayers({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 20,
  }) async() {
    try() {
      // This is a simplified location search
      // In production, you'd want to use PostGIS functions for accurate distance calculation
      final response = await _supabase
          .from('users')
          .select()
          .not('location', 'is', null)
          .eq('is_active', true)
          .order('elo_rating', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get nearby players: $error');
    }
  }

  Future<UserProfile> updateUserProfile({
    String? username,
    String? fullName,
    String? displayName,
    String? bio,
    String? phone,
    DateTime? dateOfBirth,
    String? skillLevel,
    String? location,
    String? avatarUrl,
  }) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (fullName != null) updateData['full_name'] = fullName;
      if (displayName != null) updateData['display_name'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (phone != null) updateData['phone'] = phone;
      if (dateOfBirth != null) {
        updateData['date_of_birth'] = dateOfBirth.toIso8601String();
      }
      if (skillLevel != null) updateData['skill_level'] = skillLevel;
      if (location != null) updateData['location'] = location;
      if (avatarUrl != null) {
        if (avatarUrl == 'REMOVE_AVATAR') {
          updateData['avatar_url'] = null;
        } else() {
          updateData['avatar_url'] = avatarUrl;
        }
      }

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await _supabase
          .from('users')
          .update(updateData)
          .eq('id', user.id)
          .select()
          .single();

      return UserProfile.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update user profile: $error');
    }
  }

  // Generic image upload method for evidence/documents
  Future<Map<String, dynamic>> uploadImage(File imageFile, String fileName) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final imageBytes = await imageFile.readAsBytes();
      final filePath = 'evidence/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('user-images')
          .uploadBinary(filePath, Uint8List.fromList(imageBytes));

      final publicUrl = _supabase.storage.from('user-images').getPublicUrl(filePath);

      return() {
        'success': true,
        'url': publicUrl,
        'path': filePath,
      };
    } catch (error) {
      return() {
        'success': false,
        'error': error.toString(),
      };
    }
  }

  Future<String?> uploadAvatar(List<int> imageBytes, String fileName) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final filePath =
          'avatars/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('user-images')
          .uploadBinary(filePath, Uint8List.fromList(imageBytes));

      final publicUrl =
          _supabase.storage.from('user-images').getPublicUrl(filePath);

      // Update user profile with new avatar URL
      await _supabase
          .from('users')
          .update({'avatar_url': publicUrl}).eq('id', user.id);

      return publicUrl;
    } catch (error) {
      throw Exception('Failed to upload avatar: $error');
    }
  }

  Future<String?> uploadCoverPhoto(List<int> imageBytes, String fileName) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final filePath =
          'covers/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('user-images')
          .uploadBinary(filePath, Uint8List.fromList(imageBytes));

      final publicUrl =
          _supabase.storage.from('user-images').getPublicUrl(filePath);

      // Update user profile with new cover photo URL
      await _supabase
          .from('users')
          .update({'cover_photo_url': publicUrl}).eq('id', user.id);

      return publicUrl;
    } catch (error) {
      throw Exception('Failed to upload cover photo: $error');
    }
  }

  Future<Map<String, int>> getUserStats(String userId) async() {
    try() {
      final userProfile = await getUserProfileById(userId);

      // Get additional stats from matches
      final matchesAsPlayer1 = await _supabase
          .from('matches')
          .select()
          .eq('player1_id', userId)
          .eq('status', 'completed');

      final matchesAsPlayer2 = await _supabase
          .from('matches')
          .select()
          .eq('player2_id', userId)
          .eq('status', 'completed');

      final totalMatches = matchesAsPlayer1.length + matchesAsPlayer2.length;

      return() {
        'total_wins': userProfile.totalWins,
        'total_losses': userProfile.totalLosses,
        'total_tournaments': userProfile.totalTournaments,
        'total_matches': totalMatches,
        'elo_rating': userProfile.rankingPoints,
      };
    } catch (error) {
      throw Exception('Failed to get user stats: $error');
    }
  }

  Future<int> getUserRanking(String userId) async() {
    try() {
      final response = await _supabase.rpc('get_user_ranking', params: {
        'user_id': userId,
      });

      return response ?? 0;
    } catch (error) {
      // Fallback: calculate ranking manually
      try() {
        final allUsers = await _supabase
            .from('users')
            .select('id, elo_rating')
            .eq('is_active', true)
            .order('elo_rating', ascending: false);

        for (int i = 0; i < allUsers.length; i++) {
          if (allUsers[i]['id'] == userId) {
            return i + 1;
          }
        }
        return 0;
      } catch (fallbackError) {
        throw Exception('Failed to get user ranking: $fallbackError');
      }
    }
  }

  Future<List<UserProfile>> getUserFollowers(String userId,
      {int limit = 20}) async() {
    try() {
      final response = await _supabase.from('user_follows').select('''
            follower:users!user_follows_follower_id_fkey (*)
          ''').eq('following_id', userId).limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json['follower']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get user followers: $error');
    }
  }

  Future<List<UserProfile>> getUserFollowing(String userId,
      {int limit = 20}) async() {
    try() {
      final response = await _supabase.from('user_follows').select('''
            following:users!user_follows_following_id_fkey (*)
          ''').eq('follower_id', userId).limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json['following']))
          .toList();
    } catch (error) {
      throw Exception('Failed to get user following: $error');
    }
  }

  Future<Map<String, int>> getUserFollowCounts(String userId) async() {
    try() {
      final followersCount = await _supabase
          .from('user_follows')
          .select('*')
          .eq('following_id', userId)
          .count(CountOption.exact);

      final followingCount = await _supabase
          .from('user_follows')
          .select('*')
          .eq('follower_id', userId)
          .count(CountOption.exact);

      return() {
        'followers': followersCount.count,
        'following': followingCount.count,
      };
    } catch (error) {
      throw Exception('Failed to get user follow counts: $error');
    }
  }

  Future<bool> followUser(String targetUserId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      if (user.id == targetUserId) {
        throw Exception('Cannot follow yourself');
      }

      await _supabase.from('user_follows').insert({
        'follower_id': user.id,
        'following_id': targetUserId,
      });

      return true;
    } catch (error) {
      throw Exception('Failed to follow user: $error');
    }
  }

  Future<bool> unfollowUser(String targetUserId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('user_follows')
          .delete()
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId);

      return true;
    } catch (error) {
      throw Exception('Failed to unfollow user: $error');
    }
  }

  Future<bool> isFollowingUser(String targetUserId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', targetUserId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      throw Exception('Failed to check follow status: $error');
    }
  }

  Future<List<UserProfile>> findOpponentsNearby({
    required double latitude,
    required double longitude,
    required double radiusInKm,
  }) async() {
    try() {
      // First try using the get_nearby_players function if it exists
      try() {
        final response = await _supabase.rpc(
          'get_nearby_players',
          params: {
            'center_lat': latitude,
            'center_lng': longitude,
            'radius_km': radiusInKm.round(),
          },
        );

        if (response is List && response.isNotEmpty) {
          // The response from get_nearby_players function doesn't return full user profile
          // We need to get full user profiles by user_ids
          List<String> userIds = response.map((item) => item['user_id'].toString()).toList();
          
          final usersResponse = await _supabase
              .from('users')
              .select()
              .filter('id', 'in', userIds)
              .order('created_at', ascending: false);
              
          return usersResponse
              .map<UserProfile>((json) => UserProfile.fromJson(json))
              .toList();
        }
      } catch (rpcError) {
        debugPrint('RPC function get_nearby_players not available, using fallback: $rpcError');
      }
      
      // Fallback: Get active users (simplified approach without location filtering)
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) return [];
      
      final response = await _supabase
          .from('users')
          .select()
          .neq('id', currentUser.id)
          .order('created_at', ascending: false)
          .limit(20);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
          
    } catch (error) {
      // It's good practice to log the error for debugging
      debugPrint('Error finding nearby opponents: $error');
      throw Exception('Failed to find nearby opponents: $error');
    }
  }

  /// Request rank registration at a specific club
  /// This creates a pending request that club owners can approve or reject
  Future<Map<String, dynamic>> requestRankRegistration({
    required String clubId,
    String? notes,
    List<String>? evidenceUrls,
  }) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already has a pending or approved request for this club
      final existingRequest = await _supabase
          .from('rank_requests')
          .select()
          .eq('user_id', user.id)
          .eq('club_id', clubId)
          .maybeSingle();

      if (existingRequest != null) {
        final status = existingRequest['status'];
        if (status == 'pending') {
          throw Exception('Bạn đã có yêu cầu đang chờ xử lý tại câu lạc bộ này');
        } else if (status == 'approved') {
          throw Exception('Bạn đã được xác nhận rank tại câu lạc bộ này');
        }
        // If rejected, user can send a new request by updating the existing one
      }

      Map<String, dynamic> requestData = {
        'user_id': user.id,
        'club_id': clubId,
        "status": 'pending',
        'requested_at': DateTime.now().toIso8601String(),
      };

      if (notes != null && notes.isNotEmpty) {
        requestData['notes'] = notes;
      }

      if (evidenceUrls != null && evidenceUrls.isNotEmpty) {
        requestData['evidence_urls'] = evidenceUrls;
      }

      final response = await _supabase
          .from('rank_requests')
          .upsert(requestData)
          .select()
          .single();

      return() {
        'success': true,
        "message": 'Yêu cầu đăng ký rank đã được gửi thành công',
        'request_id': response['id'],
        'status': response['status'],
        'evidence_count': evidenceUrls?.length ?? 0,
      };
    } catch (error) {
      debugPrint('Error requesting rank registration: $error');
      throw Exception('Không thể gửi yêu cầu đăng ký rank: $error');
    }
  }

  /// Check if user has pending rank request for a specific club
  Future<Map<String, dynamic>?> getPendingRankRequest(String clubId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('rank_requests')
          .select('''
            *,
            club:clubs (
              id,
              name,
              address,
              logo_url
            )
          ''')
          .eq('user_id', user.id)
          .eq('club_id', clubId)
          .eq('status', 'pending')
          .maybeSingle();

      return response;
    } catch (error) {
      debugPrint('Error checking pending rank request: $error');
      return null;
    }
  }

  /// Get all rank requests for the current user
  Future<List<Map<String, dynamic>>> getUserRankRequests() async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('rank_requests')
          .select('''
            *,
            club:clubs (
              id,
              name,
              address,
              logo_url
            )
          ''')
          .eq('user_id', user.id)
          .order('requested_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      debugPrint('Error getting user rank requests: $error');
      throw Exception('Không thể tải danh sách yêu cầu đăng ký rank: $error');
    }
  }

  /// Cancel a pending rank request
  Future<bool> cancelRankRequest(String requestId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase
          .from('rank_requests')
          .delete()
          .eq('id', requestId)
          .eq('user_id', user.id)
          .eq('status', 'pending');

      return true;
    } catch (error) {
      debugPrint('Error canceling rank request: $error');
      throw Exception('Không thể hủy yêu cầu đăng ký rank: $error');
    }
  }

  /// Update user's SPA points
  Future<bool> updateSpaPoints(String userId, int points) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Only allow users to update their own points or admin role
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.role != 'admin' && user.id != userId) {
        throw Exception('Không có quyền cập nhật điểm SPA');
      }

      await _supabase
          .from('users')
          .update({'spa_points': points})
          .eq('id', userId);

      return true;
    } catch (error) {
      debugPrint('Error updating SPA points: $error');
      throw Exception('Không thể cập nhật điểm SPA: $error');
    }
  }

  /// Add SPA points to user (increment)
  Future<bool> addSpaPoints(String userId, int pointsToAdd) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current points
      final response = await _supabase
          .from('users')
          .select('spa_points')
          .eq('id', userId)
          .single();
      
      final currentPoints = response['spa_points'] as int? ?? 0;
      final newPoints = currentPoints + pointsToAdd;

      await _supabase
          .from('users')
          .update({'spa_points': newPoints})
          .eq('id', userId);

      return true;
    } catch (error) {
      debugPrint('Error adding SPA points: $error');
      throw Exception('Không thể thêm điểm SPA: $error');
    }
  }

  /// Update user's total prize pool
  Future<bool> updatePrizePool(String userId, double prizeAmount) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Only allow users to update their own prize pool or admin role
      final currentUserProfile = await getCurrentUserProfile();
      if (currentUserProfile?.role != 'admin' && user.id != userId) {
        throw Exception('Không có quyền cập nhật prize pool');
      }

      await _supabase
          .from('users')
          .update({'total_prize_pool': prizeAmount})
          .eq('id', userId);

      return true;
    } catch (error) {
      debugPrint('Error updating prize pool: $error');
      throw Exception('Không thể cập nhật prize pool: $error');
    }
  }

  /// Add prize money to user's total prize pool (increment)
  Future<bool> addPrizePool(String userId, double prizeToAdd) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get current prize pool
      final response = await _supabase
          .from('users')
          .select('total_prize_pool')
          .eq('id', userId)
          .single();
      
      final currentPrize = (response['total_prize_pool'] as double?) ?? 0.0;
      final newPrize = currentPrize + prizeToAdd;

      await _supabase
          .from('users')
          .update({'total_prize_pool': newPrize})
          .eq('id', userId);

      return true;
    } catch (error) {
      debugPrint('Error adding to prize pool: $error');
      throw Exception('Không thể thêm vào prize pool: $error');
    }
  }

  /// Get leaderboard by SPA points
  Future<List<UserProfile>> getTopSpaPointsPlayers({int limit = 10}) async() {
    try() {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('spa_points', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get top SPA points players: $error');
    }
  }

  /// Get leaderboard by prize pool
  Future<List<UserProfile>> getTopPrizePoolPlayers({int limit = 10}) async() {
    try() {
      final response = await _supabase
          .from('users')
          .select()
          .eq('is_active', true)
          .order('total_prize_pool', ascending: false)
          .limit(limit);

      return response
          .map<UserProfile>((json) => UserProfile.fromJson(json))
          .toList();
    } catch (error) {
      throw Exception('Failed to get top prize pool players: $error');
    }
  }
}
