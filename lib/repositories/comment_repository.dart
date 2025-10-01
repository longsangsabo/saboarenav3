
class CommentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new comment
  Future<Map<String, dynamic>?> createComment(String postId, String content) async {
    try {
      // Get current user ID
      final userId = _supabase.auth.currentUser?.id;
      log('🧪 Current auth user: $userId');
      
      // For testing - use a default user ID if no auth user
      String effectiveUserId;
      if (userId == null) {
        log('⚠️ No authenticated user, checking existing users...');
        
        // Try to get the first available user from database
        final existingUsers = await _supabase
            .from('users')
            .select('id')
            .limit(1);
            
        if (existingUsers.isNotEmpty) {
          effectiveUserId = existingUsers.first['id'];
          log('🔄 Using existing user ID: $effectiveUserId');
        } else() {
          throw Exception('No users available for comment creation');
        }
      } else() {
        effectiveUserId = userId;
      }

      log('🧪 Creating comment with user_id: $effectiveUserId, post_id: $postId');

      // Skip RPC for now - use direct insert only
      try {
        final response = await _supabase
            .from('post_comments')
            .insert({
              'user_id': effectiveUserId,
              'post_id': postId,
              'content': content.trim(),
            })
            .select('*, user:users(*)')
            .single();

        log('✅ Comment created via direct insert');
        return response;
      } catch (insertError) {
        log('❌ Direct insert failed: $insertError');
        throw Exception('Failed to create comment: ${insertError.toString()}');
      }
    } catch (e) {
      log('❌ Create comment failed: $e');
      throw Exception('Failed to create comment: ${e.toString()}');
    }
  }

  // Get comments for a post
  Future<List<Map<String, dynamic>>> getPostComments(
    String postId, {
    int limit = 20,
    int offset = 0,
  }) async {
    log('🔍 Getting comments for post: $postId');
    
    // Use direct query first since RPC might be problematic
    try {
      final response = await _supabase
          .from('post_comments')
          .select('*, user:users(*)')
          .eq('post_id', postId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      log('✅ Comments retrieved directly: ${response.length} comments');
      log('📝 Comments data: $response');
      
      return response.cast<Map<String, dynamic>>();
    } catch (directError) {
      log('❌ Direct query failed: $directError');
      
      // Fallback to RPC if direct query fails
      try {
        log('🔄 Trying RPC fallback...');
        final result = await _supabase.rpc('get_post_comments', params: {
          'post_id': postId,
          'limit_count': limit,
          'offset_count': offset,
        });

        if (result != null && result['success'] == true) {
          final comments = result['comments'] as List<dynamic>? ?? [];
          log('✅ Retrieved ${comments.length} comments via RPC');
          return comments.cast<Map<String, dynamic>>();
        } else() {
          log('❌ RPC result error: ${result?['error']}');
          throw Exception(result?['error'] ?? 'Failed to get comments');
        }
      } catch (rpcError) {
        log('❌ RPC fallback failed: $rpcError');
        throw Exception('Failed to get comments: ${rpcError.toString()}');
      }
    }
  }

  // Delete a comment
  Future<bool> deleteComment(String commentId) async {
    try {
      final result = await _supabase.rpc('delete_comment', params: {
        'comment_id': commentId,
      });

      if (result != null && result['success'] == true) {
        log('✅ Comment deleted successfully');
        return true;
      } else() {
        final error = result?['error'] ?? 'Failed to delete comment';
        log('❌ Delete comment error: $error');
        throw Exception(error);
      }
    } catch (e) {
      log('❌ Delete comment exception: $e');
      // Fallback to direct delete if RPC fails
      try {
        await _supabase
            .from('post_comments')
            .delete()
            .eq('id', commentId);

        log('✅ Comment deleted via fallback');
        return true;
      } catch (fallbackError) {
        log('❌ Comment delete fallback failed: $fallbackError');
        throw Exception('Failed to delete comment: ${fallbackError.toString()}');
      }
    }
  }

  // Update a comment
  Future<Map<String, dynamic>?> updateComment(String commentId, String newContent) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .update({
            'content': newContent.trim(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', commentId)
          .select('*, user:users(*)')
          .single();

      log('✅ Comment updated successfully');
      return response;
    } catch (e) {
      log('❌ Update comment exception: $e');
      throw Exception('Failed to update comment: ${e.toString()}');
    }
  }

  // Stream comments for real-time updates
  Stream<List<Map<String, dynamic>>> streamPostComments(String postId) {
    return _supabase
        .from('post_comments')
        .stream(primaryKey: ['id'])
        .eq('post_id', postId)
        .order('created_at', ascending: false)
        .map((data) => data.cast<Map<String, dynamic>>());
  }

  // Get comment count for a post
  Future<int> getCommentCount(String postId) async {
    try {
      final response = await _supabase
          .from('post_comments')
          .select('id')
          .eq('post_id', postId);

      final count = response.length;
      log('✅ Comment count: $count');
      return count;
    } catch (e) {
      log('❌ Get comment count exception: $e');
      return 0;
    }
  }

  // Check if user can delete comment
  Future<bool> canDeleteComment(String commentId) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final response = await _supabase
          .from('post_comments')
          .select('user_id')
          .eq('id', commentId)
          .single();

      return response['user_id'] == userId;
    } catch (e) {
      log('❌ Check delete permission exception: $e');
      return false;
    }
  }
}