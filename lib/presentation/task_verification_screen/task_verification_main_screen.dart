import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../../models/task_models.dart';
import '../../services/live_photo_verification_service.dart';
import '../../services/task_verification_service.dart';
import 'task_detail_screen.dart';
import 'live_photo_verification_screen.dart';

class TaskVerificationMainScreen extends StatefulWidget {
  const TaskVerificationMainScreen({super.key});

} 
  final String clubId;
  final String staffId;

  const TaskVerificationMainScreen({
    Key? key,
    required this.clubId,
    required this.staffId,
  }) : super(key: key);

  @override
  State<TaskVerificationMainScreen> createState() => _TaskVerificationMainScreenState();
}

class _TaskVerificationMainScreenState extends State<TaskVerificationMainScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TaskVerificationService _taskService = TaskVerificationService();
  
  List<StaffTask> _tasks = [];
  Map<String, int> _taskCounts = {
    'assigned': 0,
    'in_progress': 0,
    'completed': 0,
    'verified': 0,
  };
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final tasks = await _taskService.getStaffTasks(
        clubId: widget.clubId,
        staffId: widget.staffId,
      );
      
      _updateTaskCounts(tasks);
      
      setState(() {
        _tasks = tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi tải danh sách nhiệm vụ: $e');
    }
  }

  void _updateTaskCounts(List<StaffTask> tasks) {
    _taskCounts = {
      'assigned': tasks.where((t) => t.status == 'assigned').length,
      'in_progress': tasks.where((t) => t.status == 'in_progress').length,
      'completed': tasks.where((t) => t.status == 'completed').length,
      'verified': tasks.where((t) => t.status == 'verified').length,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Nhiệm vụ & Xác minh',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadTasks,
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showHelpDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              _buildStatsCards(),
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Theme.of(context).primaryColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                tabs: [
                  Tab(text: 'Được giao (${_taskCounts['assigned']})'),
                  Tab(text: 'Đang làm (${_taskCounts['in_progress']})'),
                  Tab(text: 'Hoàn thành (${_taskCounts['completed']})'),
                  Tab(text: 'Đã xác minh (${_taskCounts['verified']})'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTaskList('assigned'),
                _buildTaskList('in_progress'),
                _buildTaskList('completed'),
                _buildTaskList('verified'),
              ],
            ),
    );
  }

  Widget _buildStatsCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tổng nhiệm vụ',
              '${_tasks.length}',
              Icons.assignment_outlined,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Hoàn thành',
              '${_taskCounts['verified']}',
              Icons.check_circle_outline,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Đang xử lý',
              '${_taskCounts['in_progress']}',
              Icons.access_time,
              Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList(String status) {
    final filteredTasks = _tasks.where((task) => task.status == status).toList();
    
    if (filteredTasks.isEmpty) {
      return _buildEmptyState(status);
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredTasks.length,
        itemBuilder: (context, index) {
          final task = filteredTasks[index];
          return TaskCard(
            task: task,
            onTaskTap: () => _handleTaskTap(task),
            onActionTap: (action) => _handleTaskAction(task, action),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String status) {
    String message;
    IconData icon;
    
    switch (status) {
      case 'assigned':
        message = 'Không có nhiệm vụ được giao';
        icon = Icons.assignment_outlined;
        break;
      case 'in_progress':
        message = 'Không có nhiệm vụ đang thực hiện';
        icon = Icons.access_time;
        break;
      case 'completed':
        message = 'Không có nhiệm vụ hoàn thành';
        icon = Icons.done_outline;
        break;
      case 'verified':
        message = 'Chưa có nhiệm vụ được xác minh';
        icon = Icons.verified_outlined;
        break;
      default:
        message = 'Không có dữ liệu';
        icon = Icons.inbox_outlined;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  void _handleTaskTap(StaffTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  void _handleTaskAction(StaffTask task, String action) {
    switch (action) {
      case 'start':
        _startTask(task);
        break;
      case 'complete':
        _completeTask(task);
        break;
      case 'verify':
        _verifyTask(task);
        break;
    }
  }

  Future<void> _startTask(StaffTask task) async {
    try {
      await _taskService.startTask(task.id);
      _loadTasks();
      _showSuccessSnackBar('Đã bắt đầu nhiệm vụ');
    } catch (e) {
      _showErrorSnackBar('Lỗi khi bắt đầu nhiệm vụ: $e');
    }
  }

  Future<void> _completeTask(StaffTask task) async {
    // Navigate to photo verification screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LivePhotoVerificationScreen(task: task),
      ),
    );
    
    if (result == true) {
      _loadTasks();
    }
  }

  Future<void> _verifyTask(StaffTask task) async {
    // For admin to manually verify
    showDialog(
      context: context,
      builder: (context) => VerificationReviewDialog(task: task),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Text('Hướng dẫn sử dụng'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '📋 Quy trình thực hiện nhiệm vụ:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('1. Nhận nhiệm vụ được giao'),
              Text('2. Bấm "Bắt đầu" để chuyển sang trạng thái thực hiện'),
              Text('3. Hoàn thành công việc tại địa điểm yêu cầu'),
              Text('4. Chụp ảnh xác minh bằng camera trực tiếp'),
              Text('5. Hệ thống tự động xác minh và cập nhật trạng thái'),
              SizedBox(height: 12),
              Text(
                '📷 Lưu ý khi chụp ảnh:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Bắt buộc chụp trực tiếp từ camera'),
              Text('• Đảm bảo GPS được bật để xác minh vị trí'),
              Text('• Chụp ảnh rõ nét, đủ ánh sáng'),
              Text('• Không được sử dụng ảnh có sẵn trong máy'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đã hiểu'),
          ),
        ],
      ),
    );
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

// Task Card Widget
class TaskCard extends StatelessWidget {
  const TaskCard({super.key});

} 
  final StaffTask task;
  final VoidCallback onTaskTap;
  final Function(String) onActionTap;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskTap,
    required this.onActionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTaskTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityColor(task.priority).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.priorityDisplayName,
                      style: TextStyle(
                        color: _getPriorityColor(task.priority),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(task.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      task.statusDisplayName,
                      style: TextStyle(
                        color: _getStatusColor(task.status),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                task.taskName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                task.description,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(
                    task.dueAt != null 
                        ? 'Hạn: ${DateFormat('dd/MM HH:mm").format(task.dueAt!)}"
                        : 'Không có hạn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  if (task.requiredLocation != null) ...[
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      'Yêu cầu vị trí',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ],
              ),
              if (task.isOverdue) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 16, color: Colors.red),
                      SizedBox(width: 4),
                      Text(
                        'Quá hạn',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    switch (task.status) {
      case 'assigned':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onActionTap('start'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Bắt đầu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
      case 'in_progress':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onActionTap('complete'),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Chụp ảnh xác minh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
      case 'completed':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hourglass_empty, color: Colors.orange),
              SizedBox(width: 8),
              Text(
                'Đang chờ xác minh...',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      case 'verified':
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified, color: Colors.green),
              SizedBox(width: 8),
              Text(
                'Đã xác minh',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
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
}
