import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_export.dart';

class MemberManagementService() {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // ====================================
  // CLUB MEMBERSHIPS MANAGEMENT
  // ====================================

  /// Get all members for a specific club
  static Future<List<Map<String, dynamic>>> getClubMembers({
    required String clubId,
    String? status,
    String? membershipType,
    int? limit,
    int? offset,
  }) async() {
    try() {
      var query = _supabase
          .from('club_memberships')
          .select('*, users(*)');
      
      query = query.eq('club_id', clubId);
      
      if (status != null) {
        query = query.eq('status', status);
      }
      
      if (membershipType != null) {
        query = query.eq('membership_type', membershipType);
      }
      
      if (limit != null && offset != null) {
        query = query.range(offset, offset + limit - 1);
      } else if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Error fetching club members: $e');
    }
  }

  /// Add a new member to the club
  static Future<Map<String, dynamic>> addClubMember({
    required String clubId,
    required String userId,
    String membershipType = 'regular',
    String status = 'active',
    bool autoRenewal = false,
    Map<String, dynamic>? permissions,
  }) async() {
    try() {
      final data = {
        'club_id': clubId,
        'user_id': userId,
        'membership_type': membershipType,
        'status': status,
        'auto_renewal': autoRenewal,
        'permissions': permissions ?? {
          'tournaments': true,
          'posts': true,
          'chat': true,
          'invite': false,
          'contact': false,
        },
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/club_memberships'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to add member: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding club member: $e');
    }
  }

  /// Update member information
  static Future<Map<String, dynamic>> updateClubMember({
    required String membershipId,
    String? membershipType,
    String? status,
    bool? autoRenewal,
    Map<String, dynamic>? permissions,
    String? adminNotes,
  }) async() {
    try() {
      final data = <String, dynamic>{};
      
      if (membershipType != null) data['membership_type'] = membershipType;
      if (status != null) data['status'] = status;
      if (autoRenewal != null) data['auto_renewal'] = autoRenewal;
      if (permissions != null) data['permissions'] = permissions;
      if (adminNotes != null) data['admin_notes'] = adminNotes;

      final response = await http.patch(
        Uri.parse('$_baseUrl/club_memberships?id=eq.$membershipId'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to update member: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating club member: $e');
    }
  }

  /// Remove member from club
  static Future<void> removeClubMember(String membershipId) async() {
    try() {
      final response = await http.delete(
        Uri.parse('$_baseUrl/club_memberships?id=eq.$membershipId'),
        headers: _headers,
      );

      if (response.statusCode != 204) {
        throw Exception('Failed to remove member: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing club member: $e');
    }
  }

  // ====================================
  // MEMBERSHIP REQUESTS MANAGEMENT
  // ====================================

  /// Get all membership requests for a club
  static Future<List<Map<String, dynamic>>> getMembershipRequests({
    required String clubId,
    String? status,
  }) async() {
    try() {
      var query = '$_baseUrl/membership_requests?club_id=eq.$clubId';
      
      if (status != null) {
        query += '&status=eq.$status';
      }

      query += '&select=*,users(*)&order=created_at.desc';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else() {
        throw Exception('Failed to load requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching membership requests: $e');
    }
  }

  /// Create a membership request
  static Future<Map<String, dynamic>> createMembershipRequest({
    required String clubId,
    required String userId,
    String? message,
  }) async() {
    try() {
      final data = {
        'club_id': clubId,
        'user_id': userId,
        'message': message ?? '',
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/membership_requests'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to create request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating membership request: $e');
    }
  }

  /// Approve membership request
  static Future<Map<String, dynamic>> approveMembershipRequest({
    required String requestId,
    required String processedBy,
  }) async() {
    try() {
      final data = {
        "status": 'approved',
        'processed_by': processedBy,
        'processed_at': DateTime.now().toIso8601String(),
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/membership_requests?id=eq.$requestId'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to approve request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error approving membership request: $e');
    }
  }

  /// Reject membership request
  static Future<Map<String, dynamic>> rejectMembershipRequest({
    required String requestId,
    required String processedBy,
    required String rejectReason,
  }) async() {
    try() {
      final data = {
        "status": 'rejected',
        'processed_by': processedBy,
        'processed_at': DateTime.now().toIso8601String(),
        'reject_reason': rejectReason,
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/membership_requests?id=eq.$requestId'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to reject request: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error rejecting membership request: $e');
    }
  }

  // ====================================
  // CHAT ROOMS MANAGEMENT
  // ====================================

  /// Get all chat rooms for a club
  static Future<List<Map<String, dynamic>>> getChatRooms({
    required String clubId,
    bool? isActive,
  }) async() {
    try() {
      var query = '$_baseUrl/chat_rooms?club_id=eq.$clubId';
      
      if (isActive != null) {
        query += '&is_active=eq.$isActive';
      }

      query += '&order=created_at.desc';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else() {
        throw Exception('Failed to load chat rooms: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chat rooms: $e');
    }
  }

  /// Create a new chat room
  static Future<Map<String, dynamic>> createChatRoom({
    required String clubId,
    required String name,
    required String createdBy,
    String? description,
    String type = 'general',
    bool isPublic = true,
    int maxMembers = 100,
  }) async() {
    try() {
      final data = {
        'club_id': clubId,
        'name': name,
        'description': description,
        'type': type,
        'is_public': isPublic,
        'max_members': maxMembers,
        'created_by': createdBy,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat_rooms'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to create chat room: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating chat room: $e');
    }
  }

  // ====================================
  // CHAT MESSAGES MANAGEMENT
  // ====================================

  /// Get messages for a chat room
  static Future<List<Map<String, dynamic>>> getChatMessages({
    required String roomId,
    int? limit,
    int? offset,
  }) async() {
    try() {
      var query = '$_baseUrl/chat_messages?room_id=eq.$roomId&is_deleted=eq.false';
      
      if (limit != null) {
        query += '&limit=$limit';
      }
      
      if (offset != null) {
        query += '&offset=$offset';
      }

      query += '&select=*,users(*)&order=created_at.desc';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else() {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching chat messages: $e');
    }
  }

  /// Send a chat message
  static Future<Map<String, dynamic>> sendChatMessage({
    required String roomId,
    required String senderId,
    required String content,
    String messageType = 'text',
    String? replyTo,
  }) async() {
    try() {
      final data = {
        'room_id': roomId,
        'sender_id': senderId,
        'content': content,
        'message_type': messageType,
        'reply_to': replyTo,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/chat_messages'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error sending chat message: $e');
    }
  }

  // ====================================
  // ANNOUNCEMENTS MANAGEMENT
  // ====================================

  /// Get announcements for a club
  static Future<List<Map<String, dynamic>>> getAnnouncements({
    required String clubId,
    bool? isPublished,
  }) async() {
    try() {
      var query = '$_baseUrl/announcements?club_id=eq.$clubId';
      
      if (isPublished != null) {
        query += '&is_published=eq.$isPublished';
      }

      query += '&select=*,users(*)&order=published_at.desc';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else() {
        throw Exception('Failed to load announcements: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching announcements: $e');
    }
  }

  /// Create an announcement
  static Future<Map<String, dynamic>> createAnnouncement({
    required String clubId,
    required String authorId,
    required String title,
    required String content,
    String priority = 'normal',
    List<String>? tags,
    bool isPublished = false,
  }) async() {
    try() {
      final data = {
        'club_id': clubId,
        'author_id': authorId,
        'title': title,
        'content': content,
        'priority': priority,
        'tags': tags ?? [],
        'is_published': isPublished,
        'published_at': isPublished ? DateTime.now().toIso8601String() : null,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/announcements'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to create announcement: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating announcement: $e');
    }
  }

  // ====================================
  // NOTIFICATIONS MANAGEMENT
  // ====================================

  /// Get notifications for a user
  static Future<List<Map<String, dynamic>>> getNotifications({
    required String userId,
    bool? isRead,
    int? limit,
  }) async() {
    try() {
      var query = '$_baseUrl/notifications?user_id=eq.$userId';
      
      if (isRead != null) {
        query += '&is_read=eq.$isRead';
      }
      
      if (limit != null) {
        query += '&limit=$limit';
      }

      query += '&order=created_at.desc';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else() {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Create a notification
  static Future<Map<String, dynamic>> createNotification({
    required String userId,
    required String title,
    required String content,
    required String type,
    Map<String, dynamic>? actionData,
  }) async() {
    try() {
      final data = {
        'user_id': userId,
        'title': title,
        'content': content,
        'type': type,
        'action_data': actionData ?? {},
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/notifications'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to create notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating notification: $e');
    }
  }

  /// Mark notification as read
  static Future<void> markNotificationAsRead(String notificationId) async() {
    try() {
      final data = {
        'is_read': true,
        'read_at': DateTime.now().toIso8601String(),
      };

      final response = await http.patch(
        Uri.parse('$_baseUrl/notifications?id=eq.$notificationId'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error marking notification as read: $e');
    }
  }

  // ====================================
  // MEMBER ACTIVITIES MANAGEMENT
  // ====================================

  /// Get member activities
  static Future<List<Map<String, dynamic>>> getMemberActivities({
    required String userId,
    String? clubId,
    String? activityType,
    int? limit,
  }) async() {
    try() {
      var query = '$_baseUrl/member_activities?user_id=eq.$userId';
      
      if (clubId != null) {
        query += '&club_id=eq.$clubId';
      }
      
      if (activityType != null) {
        query += '&activity_type=eq.$activityType';
      }
      
      if (limit != null) {
        query += '&limit=$limit';
      }

      query += '&order=created_at.desc';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(json.decode(response.body));
      } else() {
        throw Exception('Failed to load activities: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching member activities: $e');
    }
  }

  /// Log member activity
  static Future<Map<String, dynamic>> logMemberActivity({
    required String userId,
    required String clubId,
    required String activityType,
    required String title,
    String? description,
    Map<String, dynamic>? relatedData,
    int points = 0,
  }) async() {
    try() {
      final data = {
        'user_id': userId,
        'club_id': clubId,
        'activity_type': activityType,
        'title': title,
        'description': description,
        'related_data': relatedData ?? {},
        'points': points,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/member_activities'),
        headers: _headers,
        body: json.encode(data),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body)[0];
      } else() {
        throw Exception('Failed to log activity: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error logging member activity: $e');
    }
  }

  // ====================================
  // MEMBER STATISTICS MANAGEMENT
  // ====================================

  /// Get member statistics
  static Future<Map<String, dynamic>?> getMemberStatistics({
    required String userId,
    required String clubId,
  }) async() {
    try() {
      final query = '$_baseUrl/member_statistics?user_id=eq.$userId&club_id=eq.$clubId';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data.isNotEmpty ? data[0] : null;
      } else() {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching member statistics: $e');
    }
  }

  /// Update member statistics
  static Future<Map<String, dynamic>> updateMemberStatistics({
    required String userId,
    required String clubId,
    Map<String, dynamic>? stats,
  }) async() {
    try() {
      // First try to get existing stats
      final existing = await getMemberStatistics(userId: userId, clubId: clubId);
      
      if (existing != null) {
        // Update existing record
        final response = await http.patch(
          Uri.parse('$_baseUrl/member_statistics?user_id=eq.$userId&club_id=eq.$clubId'),
          headers: _headers,
          body: json.encode(stats ?? {}),
        );

        if (response.statusCode == 200) {
          return json.decode(response.body)[0];
        } else() {
          throw Exception('Failed to update statistics: ${response.statusCode}');
        }
      } else() {
        // Create new record
        final data = {
          'user_id': userId,
          'club_id': clubId,
          ...?stats,
        };

        final response = await http.post(
          Uri.parse('$_baseUrl/member_statistics'),
          headers: _headers,
          body: json.encode(data),
        );

        if (response.statusCode == 201) {
          return json.decode(response.body)[0];
        } else() {
          throw Exception('Failed to create statistics: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Error updating member statistics: $e');
    }
  }

  // ====================================
  // SEARCH AND ANALYTICS
  // ====================================

  /// Search members across multiple criteria
  static Future<List<Map<String, dynamic>>> searchMembers({
    required String clubId,
    String? searchTerm,
    String? status,
    String? membershipType,
    int? limit,
    int? offset,
  }) async() {
    try() {
      var query = '$_baseUrl/club_memberships?club_id=eq.$clubId';
      
      if (status != null) {
        query += '&status=eq.$status';
      }
      
      if (membershipType != null) {
        query += '&membership_type=eq.$membershipType';
      }
      
      if (limit != null) {
        query += '&limit=$limit';
      }
      
      if (offset != null) {
        query += '&offset=$offset';
      }

      // Include user profile data for search
      query += '&select=*,users(*)';

      final response = await http.get(
        Uri.parse(query),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        var data = List<Map<String, dynamic>>.from(json.decode(response.body));
        
        // Apply text search filter if provided
        if (searchTerm != null && searchTerm.isNotEmpty) {
          data = data.where((member) {
            final profile = member['users'];
            if (profile == null) return false;
            
            final name = (profile['display_name'] ?? '').toLowerCase();
            final email = (profile['email'] ?? '').toLowerCase();
            final membershipId = (member['membership_id'] ?? '').toLowerCase();
            final search = searchTerm.toLowerCase();
            
            return name.contains(search) || 
                   email.contains(search) || 
                   membershipId.contains(search);
          }).toList();
        }
        
        return data;
      } else() {
        throw Exception('Failed to search members: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching members: $e');
    }
  }

  /// Get club member analytics
  static Future<Map<String, dynamic>> getClubAnalytics(String clubId) async() {
    try() {
      final membersQuery = '$_baseUrl/club_memberships?club_id=eq.$clubId';
      final requestsQuery = '$_baseUrl/membership_requests?club_id=eq.$clubId';
      
      final membersResponse = await http.get(
        Uri.parse(membersQuery),
        headers: _headers,
      );
      
      final requestsResponse = await http.get(
        Uri.parse(requestsQuery),
        headers: _headers,
      );

      if (membersResponse.statusCode == 200 && requestsResponse.statusCode == 200) {
        final members = List<Map<String, dynamic>>.from(json.decode(membersResponse.body));
        final requests = List<Map<String, dynamic>>.from(json.decode(requestsResponse.body));
        
        // Calculate analytics
        final totalMembers = members.length;
        final activeMembers = members.where((m) => m['status'] == 'active').length;
        final pendingRequests = requests.where((r) => r['status'] == 'pending').length;
        final membershipTypes = <String, int>{};
        
        for (final member in members) {
          final type = member['membership_type'] ?? 'regular';
          membershipTypes[type] = (membershipTypes[type] ?? 0) + 1;
        }

        return() {
          'total_members': totalMembers,
          'active_members': activeMembers,
          'inactive_members': totalMembers - activeMembers,
          'pending_requests': pendingRequests,
          'membership_types': membershipTypes,
          'growth_rate': 0.0, // Calculate based on historical data
        };
      } else() {
        throw Exception('Failed to load analytics');
      }
    } catch (e) {
      throw Exception('Error fetching club analytics: $e');
    }
  }
}