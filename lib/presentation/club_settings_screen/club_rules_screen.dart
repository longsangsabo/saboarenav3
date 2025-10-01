import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class ClubRulesScreen extends StatefulWidget {
  const ClubRulesScreen({super.key});

} 
  final String clubId;

  const ClubRulesScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<ClubRulesScreen> createState() => _ClubRulesScreenState();
}

class _ClubRulesScreenState extends State<ClubRulesScreen> {
  final List<Map<String, dynamic>> rules = [
    {
      "id": '1',
      "title": 'Quy định chung',
      "content": 'Thành viên phải tuân thủ quy định chung của câu lạc bộ và tôn trọng các thành viên khác.',
      'isActive': true,
    },
    {
      "id": '2', 
      "title": 'Giờ hoạt động',
      "content": 'CLB hoạt động từ 8:00 - 22:00 hàng ngày. Thành viên cần tuân thủ giờ giấc và không gây ồn ào sau 21:30.',
      'isActive': true,
    },
    {
      "id": '3',
      "title": 'Thanh toán',
      "content": 'Thành viên thanh toán trước khi chơi. Chấp nhận thanh toán tiền mặt, chuyển khoản và ví điện tử.',
      'isActive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Quy định CLB'),
      backgroundColor: AppTheme.backgroundLight,
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewRule,
        backgroundColor: AppTheme.primaryLight,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRulesList(),
            const SizedBox(height: 32),
            _buildPresetRules(),
            const SizedBox(height: 80), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withOpacity(0.1),
            AppTheme.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.rule, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quy định câu lạc bộ',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Quản lý các quy định và điều khoản của CLB',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Danh sách quy định',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (rules.isEmpty)
          _buildEmptyState()
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: rules.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> rule = entry.value;
                
                return _buildRuleItem(rule, index);
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.dividerLight.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(Icons.rule, color: AppTheme.textSecondaryLight, size: 64),
          const SizedBox(height: 16),
          Text(
            'Chưa có quy định nào',
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm quy định mới',
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(Map<String, dynamic> rule, int index) {
    return Container(
      decoration: BoxDecoration(
        border: index < rules.length - 1
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.dividerLight.withOpacity(0.3),
                  width: 1,
                ),
              )
            : null,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: rule['isActive'] 
                ? AppTheme.primaryLight.withOpacity(0.12)
                : Colors.grey.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.article,
            color: rule['isActive'] ? AppTheme.primaryLight : Colors.grey,
            size: 20,
          ),
        ),
        title: Text(
          rule['title'],
          style: TextStyle(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          rule['content'].length > 100 
              ? '${rule['content'].substring(0, 100)}...'
              : rule['content'],
          style: TextStyle(
            color: AppTheme.textSecondaryLight,
            fontSize: 14,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: rule['isActive'],
              onChanged: (value) {
                setState(() {
                  rule['isActive'] = value;
                });
              },
              thumbColor: WidgetStateProperty.all(AppTheme.primaryLight),
            ),
            PopupMenuButton(
              icon: Icon(Icons.more_vert, color: AppTheme.textSecondaryLight),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: AppTheme.primaryLight),
                      const SizedBox(width: 12),
                      const Text('Chỉnh sửa'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete, color: Colors.red),
                      const SizedBox(width: 12),
                      Text('Xóa', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editRule(rule, index);
                } else if (value == 'delete') {
                  _deleteRule(index);
                }
              },
            ),
          ],
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.backgroundLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rule['content'],
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetRules() {
    final presetRules = [
      {
        "title": 'Quy định về thời gian',
        "content": 'CLB hoạt động từ [giờ mở] đến [giờ đóng]. Thành viên cần đến đúng giờ hẹn và thông báo nếu muốn hủy lịch.',
      },
      {
        "title": 'Quy định về thanh toán',
        "content": 'Thanh toán trước khi sử dụng dịch vụ. Chấp nhận tiền mặt, chuyển khoản ngân hàng và ví điện tử.',
      },
      {
        "title": 'Quy định về an toàn',
        "content": 'Thành viên cần tuân thủ các quy định an toàn, không mang vũ khí hay chất cấm vào CLB.',
      },
      {
        "title": 'Quy định về hành vi',
        "content": 'Tôn trọng nhân viên và thành viên khác, không sử dụng ngôn từ thô tục hay có hành vi bạo lực.',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quy định mẫu',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Chọn các quy định mẫu để thêm nhanh',
          style: TextStyle(
            color: AppTheme.textSecondaryLight,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: presetRules.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> preset = entry.value;
              
              return Container(
                decoration: BoxDecoration(
                  border: index < presetRules.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: AppTheme.dividerLight.withOpacity(0.3),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.lightbulb, color: AppTheme.primaryLight, size: 20),
                  ),
                  title: Text(
                    preset['title'],
                    style: TextStyle(
                      color: AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    preset['content'],
                    style: TextStyle(
                      color: AppTheme.textSecondaryLight,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    onPressed: () => _addPresetRule(preset),
                    icon: Icon(Icons.add_circle, color: AppTheme.primaryLight),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  void _addNewRule() {
    _showRuleDialog();
  }

  void _editRule(Map<String, dynamic> rule, int index) {
    _showRuleDialog(rule: rule, index: index);
  }

  void _deleteRule(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa quy định này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                rules.removeAt(index);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã xóa quy định'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _addPresetRule(Map<String, dynamic> preset) {
    setState(() {
      rules.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': preset['title'],
        'content': preset['content'],
        'isActive': true,
      });
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã thêm quy định mẫu'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showRuleDialog({Map<String, dynamic>? rule, int? index}) {
    final titleController = TextEditingController(text: rule?['title'] ?? '');
    final contentController = TextEditingController(text: rule?['content'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(rule == null ? "Thêm quy định mới" : 'Chỉnh sửa quy định'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Tiêu đề quy định',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung quy định',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty && contentController.text.isNotEmpty) {
                setState(() {
                  if (rule == null) {
                    // Add new rule
                    rules.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleController.text,
                      'content': contentController.text,
                      'isActive': true,
                    });
                  } else {
                    () {
                    // Edit existing rule
                    rules[index!]['title'] = titleController.text;
                    rules[index]['content'] = contentController.text;
                  }
                
                  }});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(rule == null ? "✅ Đã thêm quy định mới" : '✅ Đã cập nhật quy định'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(rule == null ? "Thêm" : 'Cập nhật'),
          ),
        ],
      ),
    );
  }
}
