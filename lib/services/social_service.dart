import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data'; // Add this import
import '../models/post.dart';
import '../core/utils/rank_migration_helper.dart';

class SocialService() {
  static SocialService? _instance;
  static SocialService get instance => _instance ??= SocialService._();
  SocialService._();

  final SupabaseClient _supabase = Supabase.instance.client;

  Future<List<Post>> getFeedPosts({
    int limit = 20,
    int offset = 0,
  }) async() {
    try() {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey (
              full_name,
              username,
              avatar_url,
              skill_level
            )
          ''')
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<Post>((json) {
        final userProfile = json['users'];
        return Post(
          id: json['id'],
          userId: json['user_id'],
          content: json['content'],
          postType: json['post_type'] ?? 'text',
          imageUrls: json['image_urls'] != null 
              ? List<String>.from(json['image_urls'])
              : null,
          location: json['location'],
          hashtags: json['hashtags'] != null 
              ? List<String>.from(json['hashtags'])
              : null,
          tournamentId: json['tournament_id'],
          clubId: json['club_id'],
          likeCount: json['like_count'] ?? 0,
          commentCount: json['comment_count'] ?? 0,
          shareCount: json['share_count'] ?? 0,
          isPublic: json['is_public'] ?? true,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
          userName: userProfile?['full_name'] ?? userProfile?['username'],
          userAvatar: userProfile?['avatar_url'],
          userRank: RankMigrationHelper.getNewDisplayName(userProfile?['rank'] as String?),
        );
      }).toList();
    } catch (error) {
      throw Exception('Failed to get feed posts: $error');
    }
  }  Future<Post> createPost({
    required String content,
    String postType = 'text',
    List<String>? imageUrls,
    String? location,
    List<String>? hashtags,
    String? tournamentId,
    String? clubId,
  }) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final postData = {
        'user_id': user.id,
        'content': content,
        'post_type': postType,
        'image_urls': imageUrls,
        'location': location,
        'hashtags': hashtags,
        'tournament_id': tournamentId,
        'club_id': clubId,
      };

      final response = await _supabase.from('posts').insert(postData).select('''
            *,
            users!posts_user_id_fkey (
              full_name,
              username,
              avatar_url,
              skill_level
            )
          ''').single();

      final userProfile = response['users'];
      return Post(
        id: response['id'],
        userId: response['user_id'],
        content: response['content'],
        postType: response['post_type'] ?? 'text',
        imageUrls: response['image_urls'] != null
            ? List<String>.from(response['image_urls'])
            : null,
        location: response['location'],
        hashtags: response['hashtags'] != null
            ? List<String>.from(response['hashtags'])
            : null,
        tournamentId: response['tournament_id'],
        clubId: response['club_id'],
        likeCount: response['like_count'] ?? 0,
        commentCount: response['comment_count'] ?? 0,
        shareCount: response['share_count'] ?? 0,
        isPublic: response['is_public'] ?? true,
        createdAt: DateTime.parse(response['created_at']),
        updatedAt: DateTime.parse(response['updated_at']),
        userName: userProfile?['full_name'] ?? userProfile?['username'],
        userAvatar: userProfile?['avatar_url'],
        userRank: RankMigrationHelper.getNewDisplayName(userProfile?['rank'] as String?),
      );
    } catch (error) {
      throw Exception('Failed to create post: $error');
    }
  }

  Future<bool> likePost(String postId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already liked
      final existingLike = await _supabase
          .from('post_interactions')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .eq('interaction_type', 'like')
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_interactions')
            .delete()
            .eq('id', existingLike['id']);
        return false;
      } else() {
        // Like
        await _supabase.from('post_interactions').insert({
          'post_id': postId,
          'user_id': user.id,
          "interaction_type": 'like',
        });
        return true;
      }
    } catch (error) {
      throw Exception('Failed to like post: $error');
    }
  }

  Future<bool> sharePost(String postId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await _supabase.from('post_interactions').insert({
        'post_id': postId,
        'user_id': user.id,
        "interaction_type": 'share',
      });

      return true;
    } catch (error) {
      throw Exception('Failed to share post: $error');
    }
  }

  Future<bool> isPostLiked(String postId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('post_interactions')
          .select('id')
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .eq('interaction_type', 'like')
          .maybeSingle();

      return response != null;
    } catch (error) {
      throw Exception('Failed to check if post is liked: $error');
    }
  }

  Future<String?> uploadPostImage(List<int> imageBytes, String fileName) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final filePath =
          'posts/${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await _supabase.storage
          .from('public-content')
          .uploadBinary(filePath, Uint8List.fromList(imageBytes)); // Convert List<int> to Uint8List

      final publicUrl =
          _supabase.storage.from('public-content').getPublicUrl(filePath);

      return publicUrl;
    } catch (error) {
      throw Exception('Failed to upload post image: $error');
    }
  }

  Future<List<Post>> getUserPosts(String userId, {int limit = 20}) async() {
    try() {
      final response = await _supabase
          .from('posts')
          .select('''
            *,
            users!posts_user_id_fkey (
              full_name,
              username,
              avatar_url,
              skill_level
            )
          ''')
          .eq('user_id', userId)
          .eq('is_public', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<Post>((json) {
        final userProfile = json['users'];
        return Post(
          id: json['id'],
          userId: json['user_id'],
          content: json['content'],
          postType: json['post_type'] ?? 'text',
          imageUrls: json['image_urls'] != null
              ? List<String>.from(json['image_urls'])
              : null,
          location: json['location'],
          hashtags: json['hashtags'] != null
              ? List<String>.from(json['hashtags'])
              : null,
          tournamentId: json['tournament_id'],
          clubId: json['club_id'],
          likeCount: json['like_count'] ?? 0,
          commentCount: json['comment_count'] ?? 0,
          shareCount: json['share_count'] ?? 0,
          isPublic: json['is_public'] ?? true,
          createdAt: DateTime.parse(json['created_at']),
          updatedAt: DateTime.parse(json['updated_at']),
          userName: userProfile?['full_name'] ?? userProfile?['username'],
          userAvatar: userProfile?['avatar_url'],
          userRank: RankMigrationHelper.getNewDisplayName(userProfile?['rank'] as String?),
        );
      }).toList();
    } catch (error) {
      throw Exception('Failed to get user posts: $error');
    }
  }

  Future<bool> followUser(String userId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if already following
      final existingFollow = await _supabase
          .from('user_follows')
          .select()
          .eq('follower_id', user.id)
          .eq('following_id', userId)
          .maybeSingle();

      if (existingFollow != null) {
        // Unfollow
        await _supabase
            .from('user_follows')
            .delete()
            .eq('id', existingFollow['id']);
        return false;
      } else() {
        // Follow
        await _supabase.from('user_follows').insert({
          'follower_id': user.id,
          'following_id': userId,
        });
        return true;
      }
    } catch (error) {
      throw Exception('Failed to follow user: $error');
    }
  }

  Future<bool> isFollowingUser(String userId) async() {
    try() {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('user_follows')
          .select('id')
          .eq('follower_id', user.id)
          .eq('following_id', userId)
          .maybeSingle();

      return response != null;
    } catch (error) {
      throw Exception('Failed to check if following user: $error');
    }
  }
}