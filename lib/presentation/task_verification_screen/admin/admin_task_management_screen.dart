import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../shared/task_models.dart';
import '../shared/task_verification_service.dart';
import 'admin_task_detail_screen.dart';

class AdminTaskManagementScreen extends StatefulWidget() {
  final String clubId;

  const AdminTaskManagementScreen({
    Key? key,
    required this.clubId,
  }) : super(key: key);

  @override
  State<AdminTaskManagementScreen> createState() => _AdminTaskManagementScreenState();
}

class _AdminTaskManagementScreenState extends State<AdminTaskManagementScreen>
    with TickerProviderStateMixin() {
  late TabController _tabController;
  final TaskVerificationService _taskService = TaskVerificationService();
  
  List<StaffTask> _allTasks = [];
  List<TaskVerification> _pendingVerifications = [];
  TaskStatistics? _statistics;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async() {
    setState(() => _isLoading = true);
    try() {
      final futures = await Future.wait([
        _taskService.getAllClubTasks(widget.clubId),
        _taskService.getPendingVerifications(widget.clubId),
        _taskService.getTaskStatistics(widget.clubId),
      ]);

      setState(() {
        _allTasks = futures[0] as List<StaffTask>;
        _pendingVerifications = futures[1] as List<TaskVerification>;
        _statistics = futures[2] as TaskStatistics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Lỗi tải dữ liệu: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Quản lý nhiệm vụ',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateTaskDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Column(
            children: [
              if (_statistics != null) _buildStatsOverview(),
              TabBar(
                controller: _tabController,
                labelColor: Theme.of(context).primaryColor,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Theme.of(context).primaryColor,
                tabs: [
                  Tab(text: 'Tất cả nhiệm vụ (${_allTasks.length})'),
                  Tab(text: 'Chờ xác minh (${_pendingVerifications.length})'),
                  Tab(text: 'Thống kê'),
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
                _buildAllTasksTab(),
                _buildVerificationTab(),
                _buildStatisticsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateTaskDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatsOverview() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Tổng số',
              '${_statistics!.totalTasks}',
              Icons.assignment_outlined,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Hoàn thành',
              '${_statistics!.verifiedTasks}',
              Icons.check_circle_outline,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Đang xử lý',
              '${_statistics!.inProgressTasks}',
              Icons.access_time,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Chờ xác minh',
              '${_pendingVerifications.length}',
              Icons.pending_actions,
              Colors.purple,
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
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
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
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllTasksTab() {
    if (_allTasks.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Chưa có nhiệm vụ nào',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _allTasks.length,
        itemBuilder: (context, index) {
          final task = _allTasks[index];
          return AdminTaskCard(
            task: task,
            onTaskTap: () => _viewTaskDetail(task),
            onStatusChange: (newStatus) => _updateTaskStatus(task, newStatus),
          );
        },
      ),
    );
  }

  Widget _buildVerificationTab() {
    if (_pendingVerifications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có xác minh nào cần xem xét',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _pendingVerifications.length,
        itemBuilder: (context, index) {
          final verification = _pendingVerifications[index];
          return VerificationReviewCard(
            verification: verification,
            onReview: (action) => _reviewVerification(verification, action),
          );
        },
      ),
    );
  }

  Widget _buildStatisticsTab() {
    if (_statistics == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatisticsCard(
            'Tổng quan hiệu suất',
            [
              _buildStatRow('Tỷ lệ hoàn thành', '${_statistics!.completionRate.toStringAsFixed(1)}%'),
              _buildStatRow('Tỷ lệ xác minh', '${_statistics!.verificationRate.toStringAsFixed(1)}%'),
              _buildStatRow('Thời gian trung bình', '${_statistics!.averageCompletionTime} phút'),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatisticsCard(
            'Phân loại theo loại',
            _statistics!.tasksByType.entries.map((entry) {
              return _buildStatRow(entry.key, '${entry.value} nhiệm vụ');
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildStatisticsCard(
            'Phân loại theo độ ưu tiên',
            _statistics!.tasksByPriority.entries.map((entry) {
              return _buildStatRow(entry.key, '${entry.value} nhiệm vụ');
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _viewTaskDetail(StaffTask task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdminTaskDetailScreen(task: task),
      ),
    );
  }

  Future<void> _updateTaskStatus(StaffTask task, String newStatus) async() {
    try() {
      await _taskService.updateTaskStatus(task.id, newStatus);
      _loadData();
      _showSuccessSnackBar('Đã cập nhật trạng thái nhiệm vụ');
    } catch (e) {
      _showErrorSnackBar('Lỗi cập nhật trạng thái: $e');
    }
  }

  Future<void> _reviewVerification(TaskVerification verification, String action) async() {
    try() {
      await _taskService.reviewVerification(verification.id, action);
      _loadData();
      _showSuccessSnackBar('Đã $action xác minh');
    } catch (e) {
      _showErrorSnackBar('Lỗi xem xét xác minh: $e');
    }
  }

  void _showCreateTaskDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateTaskDialog(
        clubId: widget.clubId,
        onTaskCreated: _loadData,
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

// Admin Task Card Widget
class AdminTaskCard extends StatelessWidget() {
  final StaffTask task;
  final VoidCallback onTaskTap;
  final Function(String) onStatusChange;

  const AdminTaskCard({
    Key? key,
    required this.task,
    required this.onTaskTap,
    required this.onStatusChange,
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
                  Expanded(
                    child: Text(
                      task.taskName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: onStatusChange,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'assigned',
                        child: Text('Giao nhiệm vụ'),
                      ),
                      const PopupMenuItem(
                        value: 'in_progress',
                        child: Text('Đang thực hiện'),
                      ),
                      const PopupMenuItem(
                        value: 'completed',
                        child: Text('Hoàn thành'),
                      ),
                      const PopupMenuItem(
                        value: 'verified',
                        child: Text('Đã xác minh'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                  const Spacer(),
                  Text(
                    DateFormat('dd/MM HH:mm').format(task.assignedAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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

// Verification Review Card Widget
class VerificationReviewCard extends StatelessWidget() {
  final TaskVerification verification;
  final Function(String) onReview;

  const VerificationReviewCard({
    Key? key,
    required this.verification,
    required this.onReview,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Xác minh #${verification.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    verification.verificationStatusDisplayName,
                    style: const TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
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
                  Text('Điểm AI: ${verification.autoVerificationScore}/100'),
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
              const SizedBox(height: 12),
            ],
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onReview('verified'),
                    icon: const Icon(Icons.check),
                    label: const Text('Chấp nhận'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => onReview('rejected'),
                    icon: const Icon(Icons.close),
                    label: const Text('Từ chối'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Create Task Dialog
class CreateTaskDialog extends StatefulWidget() {
  final String clubId;
  final VoidCallback onTaskCreated;

  const CreateTaskDialog({
    Key? key,
    required this.clubId,
    required this.onTaskCreated,
  }) : super(key: key);

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _taskType = 'cleaning';
  String _priority = 'normal';
  
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tạo nhiệm vụ mới'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên nhiệm vụ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên nhiệm vụ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mô tả';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _taskType,
                decoration: const InputDecoration(
                  labelText: 'Loại nhiệm vụ',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'cleaning', child: Text('Vệ sinh')),
                  DropdownMenuItem(value: 'maintenance', child: Text('Bảo trì')),
                  DropdownMenuItem(value: 'inspection', child: Text('Kiểm tra')),
                  DropdownMenuItem(value: 'setup', child: Text('Chuẩn bị')),
                ],
                onChanged: (value) => setState(() => _taskType = value!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _priority,
                decoration: const InputDecoration(
                  labelText: 'Độ ưu tiên',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Thấp')),
                  DropdownMenuItem(value: 'normal', child: Text('Bình thường')),
                  DropdownMenuItem(value: 'high', child: Text('Cao')),
                  DropdownMenuItem(value: 'urgent', child: Text('Khẩn cấp')),
                ],
                onChanged: (value) => setState(() => _priority = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _createTask,
          child: const Text('Tạo'),
        ),
      ],
    );
  }

  void _createTask() {
    if (_formKey.currentState!.validate()) {
      // TODO: Implement task creation
      Navigator.pop(context);
      widget.onTaskCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tạo nhiệm vụ thành công'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}