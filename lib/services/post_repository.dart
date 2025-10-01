
class PostRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Lấy danh sách bài viết từ feed
  Future<List<PostModel>> getPosts({int limit = 20, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            location,
            hashtags,
            created_at,
            user_id,
            users!posts_user_id_fkey(username, display_name, avatar_url),
            like_count,
            comment_count,
            share_count
          ''')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<PostModel> posts = [];
      for (final item in response) {
        final user = item['users'];
        final imageUrls = item['image_urls'] as List?;
        final hashtags = item['hashtags'] as List?;
        
        // Check if current user has liked this post
        final isLiked = await hasUserLikedPost(item['id']);
        
        posts.add(PostModel(
          id: item['id'],
          title: '', // No title in schema
          content: item['content'] ?? '',
          imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
          authorId: item['user_id'],
          authorName: user?['display_name'] ?? user?['username'] ?? 'Anonymous',
          authorAvatarUrl: user?['avatar_url'],
          createdAt: DateTime.parse(item['created_at']),
          likeCount: item['like_count'] ?? 0,
          commentCount: item['comment_count'] ?? 0,
          shareCount: item['share_count'] ?? 0,
          tags: hashtags?.cast<String>(),
          isLiked: isLiked,
        ));
      }

      return posts;
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      return [];
    }
  }

  // Tạo bài viết mới
  Future<PostModel?> createPost({
    String? title, // Optional since not in schema
    required String content,
    String? imageUrl,
    List<String>? inputImageUrls,
    List<String>? hashtags,
    String? locationName,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Prepare image URLs array
      List<String>? finalImageUrls;
      if (inputImageUrls != null && inputImageUrls.isNotEmpty) {
        finalImageUrls = inputImageUrls;
      } else if (imageUrl != null) {
        finalImageUrls = [imageUrl];
      }

      final response = await _supabase.from('posts').insert({
        'content': content,
        'image_urls': finalImageUrls,
        'hashtags': hashtags,
        'location': locationName,
        'user_id': user.id,
      }).select('''
        id,
        content,
        image_urls,
        location,
        hashtags,
        created_at,
        user_id,
        users!posts_user_id_fkey(username, display_name, avatar_url),
        like_count,
        comment_count,
        share_count
      ''').single();

      final userInfo = response['users'];
      final responseImageUrls = response['image_urls'] as List?;
      final responseHashtags = response['hashtags'] as List?;

      return PostModel(
        id: response['id'],
        title: title ?? '',
        content: response['content'] ?? '',
        imageUrl: responseImageUrls?.isNotEmpty == true ? responseImageUrls!.first : null,
        authorId: response['user_id'],
        authorName: userInfo?['display_name'] ?? userInfo?['username'] ?? 'Anonymous',
        authorAvatarUrl: userInfo?['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
        likeCount: response['like_count'] ?? 0,
        commentCount: response['comment_count'] ?? 0,
        shareCount: response['share_count'] ?? 0,
        tags: responseHashtags?.cast<String>(),
      );
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  // Like/Unlike bài viết
  Future<bool> toggleLike(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      // Kiểm tra xem đã like chưa
      final existingLike = await _supabase
          .from('post_likes')
          .select()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .maybeSingle();

      if (existingLike != null) {
        // Unlike
        await _supabase
            .from('post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
        
        // Giảm like count
        await _supabase.rpc('decrement_like_count', params: {'post_id': postId});
      } else() {
        // Like
        await _supabase.from('post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
        
        // Tăng like count
        await _supabase.rpc('increment_like_count', params: {'post_id': postId});
      }

      return true;
    } catch (e) {
      debugPrint('Error toggling like: $e');
      return false;
    }
  }

  // Lấy bài viết theo ID
  Future<PostModel?> getPostById(String postId) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            location,
            hashtags,
            created_at,
            user_id,
            users!posts_user_id_fkey(username, display_name, avatar_url),
            like_count,
            comment_count,
            share_count
          ''')
          .eq('id', postId)
          .single();

      final user = response['users'];
      final imageUrls = response['image_urls'] as List?;
      final hashtags = response['hashtags'] as List?;
      
      return PostModel(
        id: response['id'],
        title: '',
        content: response['content'] ?? '',
        imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
        authorId: response['user_id'],
        authorName: user?['display_name'] ?? user?['username'] ?? 'Anonymous',
        authorAvatarUrl: user?['avatar_url'],
        createdAt: DateTime.parse(response['created_at']),
        likeCount: response['like_count'] ?? 0,
        commentCount: response['comment_count'] ?? 0,
        shareCount: response['share_count'] ?? 0,
        tags: hashtags?.cast<String>(),
      );
    } catch (e) {
      debugPrint('Error fetching post by ID: $e');
      return null;
    }
  }

  // Xóa bài viết
  Future<bool> deletePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase
          .from('posts')
          .delete()
          .eq('id', postId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting post: $e');
      return false;
    }
  }

  // Tìm kiếm bài viết
  Future<List<PostModel>> searchPosts(String query) async {
    try {
      final response = await _supabase
          .from('posts')
          .select('''
            id,
            content,
            image_urls,
            location,
            hashtags,
            created_at,
            user_id,
            users!posts_user_id_fkey(username, display_name, avatar_url),
            like_count,
            comment_count,
            share_count
          ''')
          .ilike('content', '%$query%')
          .order('created_at', ascending: false);

      final List<PostModel> posts = [];
      for (final item in response) {
        final user = item['users'];
        final imageUrls = item['image_urls'] as List?;
        final hashtags = item['hashtags'] as List?;
        
        posts.add(PostModel(
          id: item['id'],
          title: '',
          content: item['content'] ?? '',
          imageUrl: imageUrls?.isNotEmpty == true ? imageUrls!.first : null,
          authorId: item['user_id'],
          authorName: user?['display_name'] ?? user?['username'] ?? 'Anonymous',
          authorAvatarUrl: user?['avatar_url'],
          createdAt: DateTime.parse(item['created_at']),
          likeCount: item['like_count'] ?? 0,
          commentCount: item['comment_count'] ?? 0,
          shareCount: item['share_count'] ?? 0,
          tags: hashtags?.cast<String>(),
        ));
      }

      return posts;
    } catch (e) {
      debugPrint('Error searching posts: $e');
      return [];
    }
  }

  // Like a post
  Future<void> likePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrint('🧪 Attempting to like post: $postId');

      // Insert like record using post_interactions table
      await _supabase.from('post_interactions').insert({
        'post_id': postId,
        'user_id': user.id,
        "interaction_type": 'like',
      });

      debugPrint('✅ Like record created successfully');

      // The database trigger should automatically increment like_count
      // But let's also do manual update as fallback
      try {
        final currentPost = await _supabase
            .from('posts')
            .select('like_count')
            .eq('id', postId)
            .single();
        
        final newCount = (currentPost['like_count'] as int? ?? 0) + 1;
        
        await _supabase
            .from('posts')
            .update({'like_count': newCount})
            .eq('id', postId);
            
        debugPrint('✅ Like count updated manually to: $newCount');
      } catch (updateError) {
        debugPrint('⚠️ Manual like count update failed: $updateError');
        // Don't rethrow - the trigger should handle it
      }
    } catch (e) {
      debugPrint('❌ Error liking post: $e');
      rethrow;
    }
  }

  // Unlike a post
  Future<void> unlikePost(String postId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      debugPrint('🧪 Attempting to unlike post: $postId');

      // Delete like record from post_interactions table
      await _supabase
          .from('post_interactions')
          .delete()
          .eq('post_id', postId)
          .eq('user_id', user.id)
          .eq('interaction_type', 'like');

      debugPrint('✅ Like record deleted successfully');

      // The database trigger should automatically decrement like_count
      // But let's also do manual update as fallback
      try {
        final currentPost = await _supabase
            .from('posts')
            .select('like_count')
            .eq('id', postId)
            .single();
        
        final newCount = ((currentPost['like_count'] as int? ?? 1) - 1).clamp(0, double.infinity).toInt();
        
        await _supabase
            .from('posts')
            .update({'like_count': newCount})
            .eq('id', postId);
            
        debugPrint('✅ Like count updated manually to: $newCount');
      } catch (updateError) {
        debugPrint('⚠️ Manual like count update failed: $updateError');
        // Don't rethrow - the trigger should handle it
      }
    } catch (e) {
      debugPrint('❌ Error unliking post: $e');
      rethrow;
    }
  }

  // Check if user has liked a post
  Future<bool> hasUserLikedPost(String postId) async {
    try {
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
    } catch (e) {
      debugPrint('Error checking if user liked post: $e');
      return false;
    }
  }
}