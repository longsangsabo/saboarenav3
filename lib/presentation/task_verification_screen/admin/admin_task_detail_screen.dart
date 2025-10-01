import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../shared/task_models.dart';
import '../shared/task_verification_service.dart';
import '../staff/live_photo_verification_screen.dart';

class AdminTaskDetailScreen extends StatefulWidget() {
  final StaffTask task;

  const AdminTaskDetailScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<AdminTaskDetailScreen> createState() => _AdminTaskDetailScreenState();
}

class _AdminTaskDetailScreenState extends State<AdminTaskDetailScreen> {
  final TaskVerificationService _taskService = TaskVerificationService();
  List<TaskVerification> _verifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadVerifications();
  }

  Future<void> _loadVerifications() async() {
    setState(() => _isLoading = true);
    try() {
      final verifications = await _taskService.getTaskVerifications(widget.task.id);
      setState(() {
        _verifications = verifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi tải dữ liệu xác minh: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Chi tiết nhiệm vụ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVerifications,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTaskInfoCard(),
            const SizedBox(height: 16),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildLocationCard(),
            const SizedBox(height: 16),
            _buildInstructionsCard(),
            const SizedBox(height: 16),
            _buildVerificationSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildActionBar(),
    );
  }

  Widget _buildTaskInfoCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getTaskTypeColor(widget.task.taskType).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.task.taskType.toUpperCase(),
                    style: TextStyle(
                      color: _getTaskTypeColor(widget.task.taskType),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(widget.task.priority).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.task.priorityDisplayName,
                    style: TextStyle(
                      color: _getPriorityColor(widget.task.priority),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              widget.task.taskName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.access_time, size: 20, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'Được giao: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.task.assignedAt)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            if (widget.task.dueAt != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 20,
                    color: widget.task.isOverdue ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hạn hoàn thành: ${DateFormat('dd/MM/yyyy HH:mm').format(widget.task.dueAt!)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: widget.task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: widget.task.isOverdue ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.trending_up, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Tiến độ thực hiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trạng thái hiện tại',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _getStatusColor(widget.task.status).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getStatusIcon(widget.task.status),
                              color: _getStatusColor(widget.task.status),
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              widget.task.statusDisplayName,
                              style: TextStyle(
                                color: _getStatusColor(widget.task.status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hoàn thành',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: widget.task.completionPercentage / 100,
                        backgroundColor: Colors.grey[300],
                        color: Colors.green,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${widget.task.completionPercentage}%',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildTimeline(),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline() {
    return Column(
      children: [
        _buildTimelineItem(
          'Được giao',
          DateFormat('dd/MM HH:mm').format(widget.task.assignedAt),
          Icons.assignment,
          Colors.blue,
          true,
        ),
        if (widget.task.startedAt != null)
          _buildTimelineItem(
            'Bắt đầu',
            DateFormat('dd/MM HH:mm').format(widget.task.startedAt!),
            Icons.play_arrow,
            Colors.orange,
            true,
          ),
        if (widget.task.completedAt != null)
          _buildTimelineItem(
            'Hoàn thành',
            DateFormat('dd/MM HH:mm').format(widget.task.completedAt!),
            Icons.done,
            Colors.green,
            true,
          ),
        if (widget.task.status == 'verified' && _verifications.isNotEmpty)
          _buildTimelineItem(
            'Xác minh',
            DateFormat('dd/MM HH:mm').format(_verifications.first.createdAt),
            Icons.verified,
            Colors.purple,
            true,
          ),
      ],
    );
  }

  Widget _buildTimelineItem(
    String title,
    String time,
    IconData icon,
    Color color,
    bool isCompleted,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isCompleted ? color : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.black87 : Colors.grey[600],
                  ),
                ),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    if (widget.task.requiredLocation == null) {
      return const SizedBox.shrink();
    }

    final location = widget.task.requiredLocation!;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on, color: Colors.red),
                SizedBox(width: 8),
                Text(
                  'Vị trí yêu cầu',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (location['address'] != null) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.place, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      location['address'],
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Icon(Icons.my_location, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Tọa độ: ${location['lat']?.toStringAsFixed(6)}, ${location['lng']?.toStringAsFixed(6)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (location['radius'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.radio_button_unchecked, color: Colors.grey[600], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Bán kính cho phép: ${location['radius']}m',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.list_alt, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Hướng dẫn thực hiện',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '📋 Các bước thực hiện:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('1. Đến đúng vị trí yêu cầu'),
            const Text('2. Thực hiện công việc theo mô tả'),
            const Text('3. Chụp ảnh xác minh bằng camera trực tiếp'),
            const Text('4. Chờ hệ thống tự động xác minh'),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Lưu ý quan trọng:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Bắt buộc bật GPS để xác minh vị trí\n• Chỉ được chụp trực tiếp từ camera\n• Không được sử dụng ảnh có sẵn\n• Đảm bảo ảnh rõ nét và đủ ánh sáng',
              style: TextStyle(color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationSection() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified_user, color: Colors.purple),
                SizedBox(width: 8),
                Text(
                  'Lịch sử xác minh',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_verifications.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey),
                    SizedBox(width: 8),
                    Text(
                      'Chưa có dữ liệu xác minh',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            else
              ..._verifications.map((verification) => _buildVerificationItem(verification)),
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationItem(TaskVerification verification) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getVerificationStatusColor(verification.verificationStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  verification.verificationStatusDisplayName,
                  style: TextStyle(
                    color: _getVerificationStatusColor(verification.verificationStatus),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM HH:mm').format(verification.capturedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (verification.autoVerificationScore != null) ...[
            Row(
              children: [
                const Icon(Icons.score, size: 16),
                const SizedBox(width: 6),
                Text('Điểm tự động: ${verification.autoVerificationScore}/100'),
                const Spacer(),
                if (verification.manualReviewRequired)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Cần xem xét',
                      style: TextStyle(
                        color: Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          if (verification.fraudWarnings.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: verification.fraudWarnings.map((warning) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    warning,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 10,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                verification.locationVerified ? "Vị trí chính xác" : 'Vị trí không chính xác',
                style: TextStyle(
                  fontSize: 12,
                  color: verification.locationVerified ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                verification.timestampVerified ? "Thời gian hợp lệ" : 'Thời gian nghi vấn',
                style: TextStyle(
                  fontSize: 12,
                  color: verification.timestampVerified ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar() {
    if (widget.task.status == 'assigned') {
      return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _startTask,
          icon: const Icon(Icons.play_arrow),
          label: const Text('Bắt đầu nhiệm vụ'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      );
    } else if (widget.task.status == 'in_progress') {
      return Container(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: _completeTask,
          icon: const Icon(Icons.camera_alt),
          label: const Text('Chụp ảnh xác minh'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _startTask() async() {
    try() {
      await _taskService.startTask(widget.task.id);
      _showSuccessSnackBar('Đã bắt đầu nhiệm vụ');
      Navigator.pop(context, true); // Return to main screen to refresh
    } catch (e) {
      _showErrorSnackBar('Lỗi khi bắt đầu nhiệm vụ: $e');
    }
  }

  Future<void> _completeTask() async() {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivePhotoVerificationScreen(task: widget.task),
      ),
    );
    
    if (result == true) {
      Navigator.pop(context, true); // Return to main screen to refresh
    }
  }

  // Helper methods
  Color _getTaskTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'cleaning': return Colors.blue;
      case 'maintenance': return Colors.orange;
      case 'inspection': return Colors.purple;
      case 'setup': return Colors.green;
      default: return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return Colors.red;
      case 'high': return Colors.orange;
      case 'normal': return Colors.blue;
      case 'low': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'assigned': return Colors.blue;
      case 'in_progress': return Colors.orange;
      case 'completed': return Colors.purple;
      case 'verified': return Colors.green;
      case 'rejected': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'assigned': return Icons.assignment;
      case 'in_progress': return Icons.play_arrow;
      case 'completed': return Icons.done;
      case 'verified': return Icons.verified;
      case 'rejected': return Icons.close;
      default: return Icons.help;
    }
  }

  Color _getVerificationStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'verified': return Colors.green;
      case 'rejected': return Colors.red;
      case 'suspicious': return Colors.purple;
      default: return Colors.grey;
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
      ),
    );
  }
}