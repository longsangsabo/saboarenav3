import '../models/task_models.dart';

class TaskVerificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  // =====================================================
  // TASK TEMPLATES MANAGEMENT
  // =====================================================

  /// Tạo mẫu công việc mới
  static Future<TaskTemplate> createTaskTemplate({
    required String clubId,
    required String taskType,
    required String taskName,
    required String description,
    bool requiresPhoto = true,
    bool requiresLocation = true,
    bool requiresTimestamp = true,
    int? estimatedDuration,
    int? deadlineHours,
    Map<String, dynamic> instructions = const {},
    String? verificationNotes,
  }) async {
    try {
      final response = await _client.from('task_templates').insert({
        'club_id': clubId,
        'task_type': taskType,
        'task_name': taskName,
        'description': description,
        'requires_photo': requiresPhoto,
        'requires_location': requiresLocation,
        'requires_timestamp': requiresTimestamp,
        'estimated_duration': estimatedDuration,
        'deadline_hours': deadlineHours,
        'instructions': instructions,
        'verification_notes': verificationNotes,
        'is_active': true,
      }).select().single();

      return TaskTemplate.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create task template: $e');
    }
  }

  /// Lấy danh sách mẫu công việc của club
  static Future<List<TaskTemplate>> getTaskTemplates(String clubId) async {
    try {
      final response = await _client
          .from('task_templates')
          .select()
          .eq('club_id', clubId)
          .eq('is_active', true)
          .order('task_type')
          .order('task_name');

      return response.map((json) => TaskTemplate.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch task templates: $e');
    }
  }

  // =====================================================
  // STAFF TASKS MANAGEMENT
  // =====================================================

  /// Giao việc cho nhân viên
  static Future<StaffTask> assignTask({
    required String clubId,
    required String templateId,
    required String assignedTo,
    String? assignedBy,
    String priority = 'normal',
    DateTime? dueAt,
    Map<String, dynamic>? requiredLocation,
    String? assignmentNotes,
  }) async {
    try {
      // Get template details
      final template = await _client
          .from('task_templates')
          .select()
          .eq('id', templateId)
          .single();

      final response = await _client.from('staff_tasks').insert({
        'club_id': clubId,
        'template_id': templateId,
        'assigned_to': assignedTo,
        'assigned_by': assignedBy,
        'task_type': template['task_type'],
        'task_name': template['task_name'],
        'description': template['description'],
        'priority': priority,
        'assigned_at': DateTime.now().toIso8601String(),
        'due_at': dueAt?.toIso8601String(),
        "status": 'assigned',
        'completion_percentage': 0,
        'required_location': requiredLocation,
        'assignment_notes': assignmentNotes,
      }).select().single();

      return StaffTask.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign task: $e');
    }
  }

  /// Lấy danh sách công việc của nhân viên
  static Future<List<StaffTask>> getStaffTasks(String staffId, {String? status}) async {
    try {
      var query = _client
          .from('staff_tasks')
          .select()
          .eq('assigned_to', staffId)
          .order('due_at', nullsFirst: false)
          .order('priority');

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return response.map((json) => StaffTask.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch staff tasks: $e');
    }
  }

  /// Lấy danh sách công việc của club (cho manager)
  static Future<List<StaffTask>> getClubTasks(String clubId, {String? status}) async {
    try {
      var query = _client
          .from('staff_tasks')
          .select('''
            *,
            assigned_staff:club_staff!assigned_to(id, user_id, full_name),
            assigner:club_staff!assigned_by(id, user_id, full_name)
          ''')
          .eq('club_id', clubId)
          .order('assigned_at', ascending: false);

      if (status != null) {
        query = query.eq('status', status);
      }

      final response = await query;
      return response.map((json) => StaffTask.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch club tasks: $e');
    }
  }

  /// Cập nhật trạng thái công việc
  static Future<StaffTask> updateTaskStatus({
    required String taskId,
    required String status,
    int? completionPercentage,
    String? completionNotes,
  }) async {
    try {
      final Map<String, dynamic> updates = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status == 'in_progress' && completionPercentage == null) {
        updates['started_at'] = DateTime.now().toIso8601String();
      }

      if (completionPercentage != null) {
        updates['completion_percentage'] = completionPercentage;
      }

      if (completionNotes != null) {
        updates['completion_notes'] = completionNotes;
      }

      if (status == 'completed') {
        updates['completed_at'] = DateTime.now().toIso8601String();
        updates['completion_percentage'] = 100;
      }

      final response = await _client
          .from('staff_tasks')
          .update(updates)
          .eq('id', taskId)
          .select()
          .single();

      return StaffTask.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update task status: $e');
    }
  }

  // =====================================================
  // TASK VERIFICATION MANAGEMENT
  // =====================================================

  /// Tạo xác minh công việc với ảnh
  static Future<TaskVerification> createTaskVerification({
    required String taskId,
    required String clubId,
    required String staffId,
    required String photoUrl,
    required String photoHash,
    int? photoSize,
    String photoMimeType = 'image/jpeg',
    double? capturedLatitude,
    double? capturedLongitude,
    double? locationAccuracy,
    required DateTime capturedAt,
    Map<String, dynamic> deviceInfo = const {},
    Map<String, dynamic> cameraMetadata = const {},
  }) async {
    try {
      final response = await _client.from('task_verifications').insert({
        'task_id': taskId,
        'club_id': clubId,
        'staff_id': staffId,
        'photo_url': photoUrl,
        'photo_hash': photoHash,
        'photo_size': photoSize,
        'photo_mime_type': photoMimeType,
        'captured_latitude': capturedLatitude,
        'captured_longitude': capturedLongitude,
        'location_accuracy': locationAccuracy,
        'captured_at': capturedAt.toIso8601String(),
        'server_received_at': DateTime.now().toIso8601String(),
        'device_info': deviceInfo,
        'camera_metadata': cameraMetadata,
        "verification_status": 'pending',
        'manual_review_required': false,
      }).select().single();

      // Trigger auto-verification
      final verification = TaskVerification.fromJson(response);
      await _triggerAutoVerification(verification.id);

      return verification;
    } catch (e) {
      throw Exception('Failed to create task verification: $e');
    }
  }

  /// Lấy xác minh của một công việc
  static Future<TaskVerification?> getTaskVerification(String taskId) async {
    try {
      final response = await _client
          .from('task_verifications')
          .select()
          .eq('task_id', taskId)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) return null;
      return TaskVerification.fromJson(response.first);
    } catch (e) {
      throw Exception('Failed to fetch task verification: $e');
    }
  }

  /// Lấy danh sách xác minh cần review
  static Future<List<TaskVerification>> getVerificationsForReview(String clubId) async {
    try {
      final response = await _client
          .from('task_verifications')
          .select('''
            *,
            staff_task:staff_tasks(id, task_name, description),
            staff:club_staff!staff_id(id, full_name)
          ''')
          .eq('club_id', clubId)
          .eq('manual_review_required', true)
          .in_('verification_status', ['pending', 'suspicious'])
          .order('created_at', ascending: false);

      return response.map((json) => TaskVerification.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch verifications for review: $e');
    }
  }

  /// Xem xét và phê duyệt/từ chối xác minh
  static Future<TaskVerification> reviewVerification({
    required String verificationId,
    required String reviewerId,
    required String status, // 'verified' or 'rejected'
    String? reviewNotes,
    String? rejectionReason,
  }) async {
    try {
      final response = await _client
          .from('task_verifications')
          .update({
            'verification_status': status,
            'reviewed_by': reviewerId,
            'reviewed_at': DateTime.now().toIso8601String(),
            'review_notes': reviewNotes,
            'rejection_reason': rejectionReason,
            'manual_review_required': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId)
          .select()
          .single();

      // Update task status if verified
      if (status == 'verified') {
        final verification = TaskVerification.fromJson(response);
        await updateTaskStatus(
          taskId: verification.taskId,
          status: 'verified',
          completionPercentage: 100,
        );
      }

      // Log audit entry
      await _client.from('verification_audit_log').insert({
        'verification_id': verificationId,
        'action': status == 'verified' ? "verified" : 'rejected',
        'performed_by': reviewerId,
        "old_status": 'pending',
        'new_status': status,
        'reason': reviewNotes ?? rejectionReason,
      });

      return TaskVerification.fromJson(response);
    } catch (e) {
      throw Exception('Failed to review verification: $e');
    }
  }

  // =====================================================
  // STATISTICS & ANALYTICS
  // =====================================================

  /// Lấy thống kê công việc của club
  static Future<TaskStatistics> getTaskStatistics(String clubId, {DateTime? fromDate, DateTime? toDate}) async {
    try {
      // Get basic task counts
      var query = _client
          .from('staff_tasks')
          .select('status, task_type, priority, assigned_at, completed_at')
          .eq('club_id', clubId);

      if (fromDate != null) {
        query = query.gte('assigned_at', fromDate.toIso8601String());
      }
      if (toDate != null) {
        query = query.lte('assigned_at', toDate.toIso8601String());
      }

      final tasks = await query;

      int totalTasks = tasks.length;
      int assignedTasks = tasks.where((t) => t['status'] == 'assigned').length;
      int inProgressTasks = tasks.where((t) => t['status'] == 'in_progress').length;
      int completedTasks = tasks.where((t) => t['status'] == 'completed').length;
      int verifiedTasks = tasks.where((t) => t['status'] == 'verified').length;
      int rejectedTasks = tasks.where((t) => t['status'] == 'rejected').length;

      // Calculate rates
      double completionRate = totalTasks > 0 ? (completedTasks + verifiedTasks) / totalTasks : 0.0;
      double verificationRate = completedTasks > 0 ? verifiedTasks / (completedTasks + verifiedTasks) : 0.0;

      // Calculate average completion time
      final completedTasksWithTime = tasks.where((t) => 
        t['status'] == 'completed' || t['status'] == 'verified' && 
        t['assigned_at'] != null && t['completed_at'] != null
      ).toList();

      int averageCompletionTime = 0;
      if (completedTasksWithTime.isNotEmpty) {
        int totalMinutes = 0;
        for (var task in completedTasksWithTime) {
          final assigned = DateTime.parse(task['assigned_at']);
          final completed = DateTime.parse(task['completed_at']);
          totalMinutes += completed.difference(assigned).inMinutes;
        }
        averageCompletionTime = totalMinutes ~/ completedTasksWithTime.length;
      }

      // Group by type and priority
      Map<String, int> tasksByType = {};
      Map<String, int> tasksByPriority = {};

      for (var task in tasks) {
        final type = task['task_type'] as String;
        final priority = task['priority'] as String;
        
        tasksByType[type] = (tasksByType[type] ?? 0) + 1;
        tasksByPriority[priority] = (tasksByPriority[priority] ?? 0) + 1;
      }

      return TaskStatistics(
        totalTasks: totalTasks,
        assignedTasks: assignedTasks,
        inProgressTasks: inProgressTasks,
        completedTasks: completedTasks,
        verifiedTasks: verifiedTasks,
        rejectedTasks: rejectedTasks,
        completionRate: completionRate,
        verificationRate: verificationRate,
        averageCompletionTime: averageCompletionTime,
        tasksByType: tasksByType,
        tasksByPriority: tasksByPriority,
      );
    } catch (e) {
      throw Exception('Failed to get task statistics: $e');
    }
  }

  // =====================================================
  // HELPER FUNCTIONS
  // =====================================================

  /// Trigger auto-verification (simulate RPC call)
  static Future<void> _triggerAutoVerification(String verificationId) async {
    try {
      // For now, we'll implement basic auto-verification logic
      // In a real implementation, this would be handled by database functions
      
      final verification = await _client
          .from('task_verifications')
          .select('*, staff_tasks!inner(*)')
          .eq('id', verificationId)
          .single();

      double score = 0.0;
      Map<String, dynamic> fraudFlags = {};

      // Location check (if required location is set)
      final task = verification['staff_tasks'];
      if (task['required_location'] != null && 
          verification['captured_latitude'] != null && 
          verification['captured_longitude'] != null) {
        
        final requiredLat = task['required_location']['latitude'];
        final requiredLng = task['required_location']['longitude'];
        final radius = task['required_location']['radius'] ?? 50.0;
        
        // Simple distance calculation (not perfectly accurate but good enough)
        final distance = _calculateDistance(
          verification['captured_latitude'], 
          verification['captured_longitude'],
          requiredLat, 
          requiredLng
        );
        
        if (distance <= radius) {
          score += 0.4; // 40% for location
        } else {
          fraudFlags['location_mismatch'] = true;
        }
      } else {
        score += 0.4; // No location requirement
      }

      // Photo integrity check
      if (verification['photo_hash'] != null && verification['photo_hash'].length == 64) {
        score += 0.3; // 30% for photo
      } else {
        fraudFlags['photo_integrity_failed'] = true;
      }

      // Timestamp check
      final capturedAt = DateTime.parse(verification['captured_at']);
      final receivedAt = DateTime.parse(verification['server_received_at']);
      final timeDrift = receivedAt.difference(capturedAt).inSeconds.abs();
      
      if (timeDrift < 300) { // 5 minutes tolerance
        score += 0.3; // 30% for timestamp
      } else {
        fraudFlags['timestamp_suspicious'] = true;
      }

      // Determine verification status
      String newStatus;
      bool requiresReview = false;

      if (score >= 0.8) {
        newStatus = 'verified';
      } else if (score >= 0.6) {
        newStatus = 'pending';
        requiresReview = true;
      } else {
        newStatus = 'suspicious';
        requiresReview = true;
      }

      // Update verification
      await _client
          .from('task_verifications')
          .update({
            'auto_verification_score': score,
            'fraud_flags': fraudFlags,
            'verification_status': newStatus,
            'manual_review_required': requiresReview,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', verificationId);

      // Update task if auto-verified
      if (newStatus == 'verified') {
        await updateTaskStatus(
          taskId: verification['task_id'],
          status: 'verified',
          completionPercentage: 100,
        );
      }

    } catch (e) {
      print('Auto-verification failed: $e');
      // Don't throw error as this is a background process
    }
  }

  /// Calculate distance between two coordinates (simplified)
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // meters
    final double dLat = (lat2 - lat1) * (3.14159 / 180);
    final double dLng = (lng2 - lng1) * (3.14159 / 180);
    
    final double a = 
        (dLat / 2) * (dLat / 2) +
        (dLng / 2) * (dLng / 2) * 4.0 * lat1 * lat2;
    final double c = 2 * (a.abs().clamp(0.0, 1.0));
    
    return earthRadius * c;
  }
}
