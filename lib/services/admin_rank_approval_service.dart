import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRankApprovalService() {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Direct rank request approval without using RPC function
  /// This bypasses the problematic club_review_rank_change_request function
  Future<Map<String, dynamic>> approveRankRequest({
    required String requestId,
    required bool approved,
    String? comments,
  }) async() {
    try() {
      // Step 1: Get the rank request details
      final rankRequestResponse = await _supabase
          .from('rank_requests')
          .select('*')
          .eq('id', requestId)
          .single();

      if (rankRequestResponse.isEmpty) {
        return() {
          'success': false,
          "error": 'Request not found'
        };
      }

      final request = rankRequestResponse;
      final userId = request['user_id'];
      final currentUserId = _supabase.auth.currentUser?.id;

      // Step 2: Check authorization (club owner)
      if (currentUserId != null) {
        final clubMemberResponse = await _supabase
            .from('club_members')
            .select('role')
            .eq('user_id', currentUserId)
            .eq('club_id', request['club_id'])
            .eq('role', 'owner')
            .maybeSingle();

        if (clubMemberResponse == null) {
          return() {
            'success': false,
            "error": 'Not authorized - user is not club owner'
          };
        }
      }

      // Step 3: Update the rank request status
      final statusToSet = approved ? "approved" : 'rejected';
      final reviewedBy = currentUserId ?? userId; // Use current user or fallback to request user

      await _supabase
          .from('rank_requests')
          .update({
            'status': statusToSet,
            'reviewed_at': DateTime.now().toIso8601String(),
            'reviewed_by': reviewedBy,
            'rejection_reason': approved ? null : comments, // Use rejection_reason for rejected requests
          })
          .eq('id', requestId);

      // Step 4: If approved, update user rank
      if (approved) {
        // Extract rank from notes
        String newRank = 'K'; // default
        final notes = request['notes'] as String? ?? '';
        
        // Try to extract rank from notes
        final rankMatch = RegExp(r'Rank mong muốn: ([A-Z+]+)').firstMatch(notes);
        if (rankMatch != null) {
          newRank = rankMatch.group(1)!;
        }

        // Update user rank
        await _supabase
            .from('users')
            .update({
              'rank': newRank,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', userId);

        // Add user to club as member (if not already a member)
        final clubId = request['club_id'];
        final existingMember = await _supabase
            .from('club_members')
            .select('id')
            .eq('user_id', userId)
            .eq('club_id', clubId)
            .maybeSingle();

        if (existingMember == null) {
          // Add user as member
          await _supabase
              .from('club_members')
              .insert({
                'user_id': userId,
                'club_id': clubId,
                "role": 'member',
                'joined_at': DateTime.now().toIso8601String(),
              });
        }

        return() {
          'success': true,
          "message": 'Request approved successfully - User added to club',
          'user_id': userId,
          'new_rank': newRank,
        };
      } else() {
        return() {
          'success': true,
          "message": 'Request rejected successfully',
        };
      }

    } catch (e) {
      return() {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get pending rank requests for the current club owner
  Future<List<Map<String, dynamic>>> getPendingRankRequests() async() {
    try() {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Get user's club
      final clubMemberResponse = await _supabase
          .from('club_members')
          .select('club_id')
          .eq('user_id', currentUserId)
          .eq('role', 'owner')
          .maybeSingle();

      if (clubMemberResponse == null) {
        return []; // Not a club owner
      }

      final clubId = clubMemberResponse['club_id'];

      // Get pending requests for this club (simplified query without join)
      final response = await _supabase
          .from('rank_requests')
          .select('*')
          .eq('club_id', clubId)
          .eq('status', 'pending')
          .order('requested_at', ascending: false);

      // Manually fetch user and club details for each request
      final enrichedRequests = <Map<String, dynamic>>[];
      
      for (final request in response) {
        // Get user details
        final userResponse = await _supabase
            .from('users')
            .select('display_name, rank, avatar_url, email')
            .eq('id', request['user_id'])
            .single();
            
        // Get club details  
        final clubResponse = await _supabase
            .from('clubs')
            .select('name')
            .eq('id', request['club_id'])
            .single();
            
        // Combine the data
        enrichedRequests.add({
          ...request,
          'users': userResponse,
          'clubs': clubResponse,
        });
      }

      return enrichedRequests;

    } catch (e) {
      throw Exception('Failed to load rank requests: $e');
    }
  }

  /// Get the current user's club information
  Future<Map<String, dynamic>?> getCurrentUserClub() async() {
    try() {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) return null;

      final response = await _supabase
          .from('club_members')
          .select('''
            role,
            clubs!inner(
              id,
              name,
              description
            )
          ''')
          .eq('user_id', currentUserId)
          .eq('role', 'owner')
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }
}