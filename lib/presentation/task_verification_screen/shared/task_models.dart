import 'dart:convert';

// Task Template Model
class TaskTemplate() {
  final String id;
  final String clubId;
  final String taskType;
  final String taskName;
  final String description;
  final bool requiresPhoto;
  final bool requiresLocation;
  final bool requiresTimestamp;
  final int? estimatedDuration; // minutes
  final int? deadlineHours;
  final Map<String, dynamic> instructions;
  final String? verificationNotes;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskTemplate({
    required this.id,
    required this.clubId,
    required this.taskType,
    required this.taskName,
    required this.description,
    this.requiresPhoto = true,
    this.requiresLocation = true,
    this.requiresTimestamp = true,
    this.estimatedDuration,
    this.deadlineHours,
    this.instructions = const {},
    this.verificationNotes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskTemplate.fromJson(Map<String, dynamic> json) {
    return TaskTemplate(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      taskType: json['task_type'] ?? '',
      taskName: json['task_name'] ?? '',
      description: json['description'] ?? '',
      requiresPhoto: json['requires_photo'] ?? true,
      requiresLocation: json['requires_location'] ?? true,
      requiresTimestamp: json['requires_timestamp'] ?? true,
      estimatedDuration: json['estimated_duration'],
      deadlineHours: json['deadline_hours'],
      instructions: json['instructions'] ?? {},
      verificationNotes: json['verification_notes'],
      isActive: json['is_active'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
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
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

// Staff Task Model
class StaffTask() {
  final String id;
  final String clubId;
  final String templateId;
  final String assignedTo;
  final String? assignedBy;
  final String taskType;
  final String taskName;
  final String description;
  final String priority;
  final DateTime assignedAt;
  final DateTime? dueAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String status;
  final int completionPercentage;
  final Map<String, dynamic>? requiredLocation;
  final String? assignmentNotes;
  final String? completionNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  StaffTask({
    required this.id,
    required this.clubId,
    required this.templateId,
    required this.assignedTo,
    this.assignedBy,
    required this.taskType,
    required this.taskName,
    required this.description,
    this.priority = 'normal',
    required this.assignedAt,
    this.dueAt,
    this.startedAt,
    this.completedAt,
    this.status = 'assigned',
    this.completionPercentage = 0,
    this.requiredLocation,
    this.assignmentNotes,
    this.completionNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StaffTask.fromJson(Map<String, dynamic> json) {
    return StaffTask(
      id: json['id'] ?? '',
      clubId: json['club_id'] ?? '',
      templateId: json['template_id'] ?? '',
      assignedTo: json['assigned_to'] ?? '',
      assignedBy: json['assigned_by'],
      taskType: json['task_type'] ?? '',
      taskName: json['task_name'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? 'normal',
      assignedAt: DateTime.parse(json['assigned_at']),
      dueAt: json['due_at'] != null ? DateTime.parse(json['due_at']) : null,
      startedAt: json['started_at'] != null ? DateTime.parse(json['started_at']) : null,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      status: json['status'] ?? 'assigned',
      completionPercentage: json['completion_percentage'] ?? 0,
      requiredLocation: json['required_location'],
      assignmentNotes: json['assignment_notes'],
      completionNotes: json['completion_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'club_id': clubId,
      'template_id': templateId,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'task_type': taskType,
      'task_name': taskName,
      'description': description,
      'priority': priority,
      'assigned_at': assignedAt.toIso8601String(),
      'due_at': dueAt?.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status,
      'completion_percentage': completionPercentage,
      'required_location': requiredLocation,
      'assignment_notes': assignmentNotes,
      'completion_notes': completionNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isOverdue => dueAt != null && DateTime.now().isAfter(dueAt!);
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed' || status == 'verified';
  bool get requiresVerification => status == 'completed';
  
  Duration? get timeRemaining() {
    if (dueAt == null) return null;
    final now = DateTime.now();
    if (now.isAfter(dueAt!)) return null;
    return dueAt!.difference(now);
  }

  String get priorityDisplayName() {
    switch (priority) {
      case 'urgent': return 'Khẩn cấp';
      case 'high': return 'Cao';
      case 'normal': return 'Bình thường';
      case 'low': return 'Thấp';
      default: return 'Bình thường';
    }
  }

  String get statusDisplayName() {
    switch (status) {
      case 'assigned': return 'Được giao';
      case 'in_progress': return 'Đang thực hiện';
      case 'completed': return 'Hoàn thành';
      case 'verified': return 'Đã xác minh';
      case 'rejected': return 'Bị từ chối';
      default: return 'Không xác định';
    }
  }
}

// Task Verification Model
class TaskVerification() {
  final String id;
  final String taskId;
  final String clubId;
  final String staffId;
  final String photoUrl;
  final String photoHash;
  final int? photoSize;
  final String photoMimeType;
  final double? capturedLatitude;
  final double? capturedLongitude;
  final double? locationAccuracy;
  final bool locationVerified;
  final double? distanceFromRequired;
  final DateTime capturedAt;
  final DateTime serverReceivedAt;
  final bool timestampVerified;
  final int? timeDriftSeconds;
  final Map<String, dynamic> deviceInfo;
  final Map<String, dynamic> cameraMetadata;
  final String verificationStatus;
  final double? autoVerificationScore;
  final bool manualReviewRequired;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? reviewNotes;
  final String? rejectionReason;
  final Map<String, dynamic> fraudFlags;
  final double? confidenceScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  TaskVerification({
    required this.id,
    required this.taskId,
    required this.clubId,
    required this.staffId,
    required this.photoUrl,
    required this.photoHash,
    this.photoSize,
    this.photoMimeType = 'image/jpeg',
    this.capturedLatitude,
    this.capturedLongitude,
    this.locationAccuracy,
    this.locationVerified = false,
    this.distanceFromRequired,
    required this.capturedAt,
    required this.serverReceivedAt,
    this.timestampVerified = false,
    this.timeDriftSeconds,
    this.deviceInfo = const {},
    this.cameraMetadata = const {},
    this.verificationStatus = 'pending',
    this.autoVerificationScore,
    this.manualReviewRequired = false,
    this.reviewedBy,
    this.reviewedAt,
    this.reviewNotes,
    this.rejectionReason,
    this.fraudFlags = const {},
    this.confidenceScore,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TaskVerification.fromJson(Map<String, dynamic> json) {
    return TaskVerification(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      clubId: json['club_id'] ?? '',
      staffId: json['staff_id'] ?? '',
      photoUrl: json['photo_url'] ?? '',
      photoHash: json['photo_hash'] ?? '',
      photoSize: json['photo_size'],
      photoMimeType: json['photo_mime_type'] ?? 'image/jpeg',
      capturedLatitude: json['captured_latitude']?.toDouble(),
      capturedLongitude: json['captured_longitude']?.toDouble(),
      locationAccuracy: json['location_accuracy']?.toDouble(),
      locationVerified: json['location_verified'] ?? false,
      distanceFromRequired: json['distance_from_required']?.toDouble(),
      capturedAt: DateTime.parse(json['captured_at']),
      serverReceivedAt: DateTime.parse(json['server_received_at']),
      timestampVerified: json['timestamp_verified'] ?? false,
      timeDriftSeconds: json['time_drift_seconds'],
      deviceInfo: json['device_info'] ?? {},
      cameraMetadata: json['camera_metadata'] ?? {},
      verificationStatus: json['verification_status'] ?? 'pending',
      autoVerificationScore: json['auto_verification_score']?.toDouble(),
      manualReviewRequired: json['manual_review_required'] ?? false,
      reviewedBy: json['reviewed_by'],
      reviewedAt: json['reviewed_at'] != null ? DateTime.parse(json['reviewed_at']) : null,
      reviewNotes: json['review_notes'],
      rejectionReason: json['rejection_reason'],
      fraudFlags: json['fraud_flags'] ?? {},
      confidenceScore: json['confidence_score']?.toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
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
      'location_verified': locationVerified,
      'distance_from_required': distanceFromRequired,
      'captured_at': capturedAt.toIso8601String(),
      'server_received_at': serverReceivedAt.toIso8601String(),
      'timestamp_verified': timestampVerified,
      'time_drift_seconds': timeDriftSeconds,
      'device_info': deviceInfo,
      'camera_metadata': cameraMetadata,
      'verification_status': verificationStatus,
      'auto_verification_score': autoVerificationScore,
      'manual_review_required': manualReviewRequired,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'review_notes': reviewNotes,
      'rejection_reason': rejectionReason,
      'fraud_flags': fraudFlags,
      'confidence_score': confidenceScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isVerified => verificationStatus == 'verified';
  bool get isPending => verificationStatus == 'pending';
  bool get isRejected => verificationStatus == 'rejected';
  bool get isSuspicious => verificationStatus == 'suspicious';
  
  bool get hasLocationIssues => fraudFlags['location_mismatch'] == true;
  bool get hasTimestampIssues => fraudFlags['timestamp_suspicious'] == true;
  bool get hasPhotoIntegrityIssues => fraudFlags['photo_integrity_failed'] == true;
  
  String get verificationStatusDisplayName() {
    switch (verificationStatus) {
      case 'pending': return 'Đang xử lý';
      case 'verified': return 'Đã xác minh';
      case 'rejected': return 'Bị từ chối';
      case 'suspicious': return 'Nghi vấn';
      default: return 'Không xác định';
    }
  }

  List<String> get fraudWarnings() {
    List<String> warnings = [];
    if (hasLocationIssues) warnings.add('Vị trí không khớp');
    if (hasTimestampIssues) warnings.add('Thời gian nghi vấn');
    if (hasPhotoIntegrityIssues) warnings.add('Ảnh có vấn đề');
    return warnings;
  }
}

// Verification Audit Log Model
class VerificationAuditLog() {
  final String id;
  final String verificationId;
  final String action;
  final String? performedBy;
  final DateTime performedAt;
  final String? oldStatus;
  final String? newStatus;
  final String? reason;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  VerificationAuditLog({
    required this.id,
    required this.verificationId,
    required this.action,
    this.performedBy,
    required this.performedAt,
    this.oldStatus,
    this.newStatus,
    this.reason,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory VerificationAuditLog.fromJson(Map<String, dynamic> json) {
    return VerificationAuditLog(
      id: json['id'] ?? '',
      verificationId: json['verification_id'] ?? '',
      action: json['action'] ?? '',
      performedBy: json['performed_by'],
      performedAt: DateTime.parse(json['performed_at']),
      oldStatus: json['old_status'],
      newStatus: json['new_status'],
      reason: json['reason'],
      ipAddress: json['ip_address'],
      userAgent: json['user_agent'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'id': id,
      'verification_id': verificationId,
      'action': action,
      'performed_by': performedBy,
      'performed_at': performedAt.toIso8601String(),
      'old_status': oldStatus,
      'new_status': newStatus,
      'reason': reason,
      'ip_address': ipAddress,
      'user_agent': userAgent,
      'created_at': createdAt.toIso8601String(),
    };
  }

  String get actionDisplayName() {
    switch (action) {
      case 'created': return 'Tạo mới';
      case 'verified': return 'Xác minh';
      case 'rejected': return 'Từ chối';
      case 'flagged': return 'Đánh dấu';
      case 'auto_verified': return 'Tự động xác minh';
      default: return action;
    }
  }
}

// Task Statistics Model
class TaskStatistics() {
  final int totalTasks;
  final int assignedTasks;
  final int inProgressTasks;
  final int completedTasks;
  final int verifiedTasks;
  final int rejectedTasks;
  final double completionRate;
  final double verificationRate;
  final int averageCompletionTime; // minutes
  final Map<String, int> tasksByType;
  final Map<String, int> tasksByPriority;

  TaskStatistics({
    required this.totalTasks,
    required this.assignedTasks,
    required this.inProgressTasks,
    required this.completedTasks,
    required this.verifiedTasks,
    required this.rejectedTasks,
    required this.completionRate,
    required this.verificationRate,
    required this.averageCompletionTime,
    required this.tasksByType,
    required this.tasksByPriority,
  });

  factory TaskStatistics.fromJson(Map<String, dynamic> json) {
    return TaskStatistics(
      totalTasks: json['total_tasks'] ?? 0,
      assignedTasks: json['assigned_tasks'] ?? 0,
      inProgressTasks: json['in_progress_tasks'] ?? 0,
      completedTasks: json['completed_tasks'] ?? 0,
      verifiedTasks: json['verified_tasks'] ?? 0,
      rejectedTasks: json['rejected_tasks'] ?? 0,
      completionRate: (json['completion_rate'] ?? 0.0).toDouble(),
      verificationRate: (json['verification_rate'] ?? 0.0).toDouble(),
      averageCompletionTime: json['average_completion_time'] ?? 0,
      tasksByType: Map<String, int>.from(json['tasks_by_type'] ?? {}),
      tasksByPriority: Map<String, int>.from(json['tasks_by_priority'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'total_tasks': totalTasks,
      'assigned_tasks': assignedTasks,
      'in_progress_tasks': inProgressTasks,
      'completed_tasks': completedTasks,
      'verified_tasks': verifiedTasks,
      'rejected_tasks': rejectedTasks,
      'completion_rate': completionRate,
      'verification_rate': verificationRate,
      'average_completion_time': averageCompletionTime,
      'tasks_by_type': tasksByType,
      'tasks_by_priority': tasksByPriority,
    };
  }
}