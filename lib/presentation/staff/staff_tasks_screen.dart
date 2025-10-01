import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/live_photo_verification_service.dart';
import '../models/task_models.dart';

// Staff Task Management Screen
class StaffTasksScreen extends StatefulWidget {
  const StaffTasksScreen({super.key});

} 
  final String staffId;
  final String clubId;

  const StaffTasksScreen({
    Key? key,
    required this.staffId,
    required this.clubId,
  }) : super(key: key);

  @override
  State<StaffTasksScreen> createState() => _StaffTasksScreenState();
}

class _StaffTasksScreenState extends State<StaffTasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<StaffTask> _assignedTasks = [];
  List<StaffTask> _completedTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTasks();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load tasks from API
      _assignedTasks = await TaskService.getAssignedTasks(widget.staffId);
      _completedTasks = await TaskService.getCompletedTasks(widget.staffId);
    } catch (e) {
      print('Error loading tasks: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Công việc của tôi'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Được giao (${_assignedTasks.length})'),
            Tab(text: 'Hoàn thành (${_completedTasks.length})'),
            Tab(text: 'Thống kê'),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAssignedTasksTab(),
                _buildCompletedTasksTab(),
                _buildStatsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadTasks,
        child: Icon(Icons.refresh),
        tooltip: 'Làm mới',
      ),
    );
  }

  Widget _buildAssignedTasksTab() {
    if (_assignedTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.task_alt, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Không có công việc nào được giao',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,
      child: ListView.builder(
        itemCount: _assignedTasks.length,
        itemBuilder: (context, index) {
          return TaskCard(
            task: _assignedTasks[index],
            onTaskAction: _handleTaskAction,
          );
        },
      ),
    );
  }

  Widget _buildCompletedTasksTab() {
    if (_completedTasks.isEmpty) {
      return Center(child: Text('Chưa hoàn thành công việc nào'));
    }

    return ListView.builder(
      itemCount: _completedTasks.length,
      itemBuilder: (context, index) {
        return CompletedTaskCard(task: _completedTasks[index]);
      },
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildStatCard(
            'Tổng công việc hôm nay',
            '${_assignedTasks.length + _completedTasks.length}',
            Icons.assignment,
            Colors.blue,
          ),
          SizedBox(height: 16),
          _buildStatCard(
            'Đã hoàn thành',
            '${_completedTasks.length}',
            Icons.check_circle,
            Colors.green,
          ),
          SizedBox(height: 16),
          _buildStatCard(
            'Đang thực hiện',
            '${_assignedTasks.where((t) => t.status == 'in_progress').length}',
            Icons.schedule,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleTaskAction(StaffTask task, String action) async {
    switch (action) {
      case 'start':
        await _startTask(task);
        break;
      case 'complete':
        await _completeTask(task);
        break;
      case 'verify':
        await _verifyTask(task);
        break;
    }
    _loadTasks(); // Refresh tasks
  }

  Future<void> _startTask(StaffTask task) async {
    try {
      await TaskService.updateTaskStatus(task.id, 'in_progress');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã bắt đầu công việc: ${task.taskName}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  Future<void> _completeTask(StaffTask task) async {
    // Show completion dialog
    String? notes = await showDialog<String>(
      context: context,
      builder: (context) => TaskCompletionDialog(),
    );

    if (notes != null) {
      try {
        await TaskService.completeTask(task.id, notes);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã đánh dấu hoàn thành: ${task.taskName}')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  Future<void> _verifyTask(StaffTask task) async {
    // Navigate to live photo capture
    TaskVerification? verification = await LivePhotoService().captureTaskVerification(
      taskId: task.id,
      taskType: task.taskType,
      description: task.description,
      clubId: widget.clubId,
    );

    if (verification != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã gửi bằng chứng hoàn thành'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

// Individual Task Card Widget
class TaskCard extends StatelessWidget {
  const TaskCard({super.key});

} 
  final StaffTask task;
  final Function(StaffTask, String) onTaskAction;

  const TaskCard({
    Key? key,
    required this.task,
    required this.onTaskAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                _buildTaskTypeIcon(),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.taskName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        task.taskType.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: _getTaskTypeColor(),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildPriorityBadge(),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Description
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Time info
            Row(
              children: [
                Icon(Icons.access_time, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Hạn: ${_formatDateTime(task.dueAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                Spacer(),
                Text(
                  'Giao lúc: ${_formatDateTime(task.assignedAt)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: _buildActionButtons(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskTypeIcon() {
    IconData icon;
    Color color;
    
    switch (task.taskType) {
      case 'cleaning':
        icon = Icons.cleaning_services;
        color = Colors.blue;
        break;
      case 'maintenance':
        icon = Icons.build;
        color = Colors.orange;
        break;
      case 'setup':
        icon = Icons.settings;
        color = Colors.green;
        break;
      case 'closing':
        icon = Icons.lock;
        color = Colors.red;
        break;
      default:
        icon = Icons.assignment;
        color = Colors.grey;
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Color _getTaskTypeColor() {
    switch (task.taskType) {
      case 'cleaning': return Colors.blue;
      case 'maintenance': return Colors.orange;
      case 'setup': return Colors.green;
      case 'closing': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildPriorityBadge() {
    Color color;
    String text;
    
    switch (task.priority) {
      case 'urgent':
        color = Colors.red;
        text = 'KHẨN';
        break;
      case 'high':
        color = Colors.orange;
        text = 'CAO';
        break;
      case 'normal':
        color = Colors.green;
        text = 'BÌNH THƯỜNG';
        break;
      case 'low':
        color = Colors.grey;
        text = 'THẤP';
        break;
      default:
        color = Colors.grey;
        text = 'BÌNH THƯỜNG';
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    List<Widget> buttons = [];
    
    switch (task.status) {
      case 'assigned':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => onTaskAction(task, 'start'),
            icon: Icon(Icons.play_arrow, size: 16),
            label: Text('Bắt đầu'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        );
        break;
        
      case 'in_progress':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => onTaskAction(task, 'complete'),
            icon: Icon(Icons.check, size: 16),
            label: Text('Hoàn thành'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        );
        break;
        
      case 'completed':
        buttons.add(
          ElevatedButton.icon(
            onPressed: () => onTaskAction(task, 'verify'),
            icon: Icon(Icons.camera_alt, size: 16),
            label: Text('Chụp ảnh xác minh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),
        );
        break;
    }
    
    return buttons;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Chưa xác định';
    return DateFormat('dd/MM HH:mm').format(dateTime);
  }
}

// Completed Task Card (Read-only)
class CompletedTaskCard extends StatelessWidget {
  const CompletedTaskCard({super.key});

} 
  final StaffTask task;

  const CompletedTaskCard({Key? key, required this.task}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  task.status == 'verified' ? Icons.verified : Icons.check_circle,
                  color: task.status == 'verified' ? Colors.green : Colors.blue,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task.taskName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  task.status == 'verified' ? "ĐÃ XÁC MINH" : 'HOÀN THÀNH',
                  style: TextStyle(
                    fontSize: 12,
                    color: task.status == 'verified' ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 8),
            
            Text(
              task.description,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            
            if (task.completedAt != null) ...[
              SizedBox(height: 8),
              Text(
                'Hoàn thành lúc: ${DateFormat('dd/MM/yyyy HH:mm').format(task.completedAt!)}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Task Completion Dialog
class TaskCompletionDialog extends StatefulWidget {
  const TaskCompletionDialog({super.key});

} 
  @override
  State<TaskCompletionDialog> createState() => _TaskCompletionDialogState();
}

class _TaskCompletionDialogState extends State<TaskCompletionDialog> {
  final TextEditingController _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Hoàn thành công việc'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Ghi chú về việc hoàn thành công việc:'),
          SizedBox(height: 16),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Mô tả chi tiết về công việc đã làm...',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _notesController.text),
          child: Text('Hoàn thành'),
        ),
      ],
    );
  }
}
