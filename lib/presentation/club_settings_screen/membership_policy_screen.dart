import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class MembershipPolicyScreen extends StatefulWidget {
  const MembershipPolicyScreen({super.key});

} 
  final String clubId;

  const MembershipPolicyScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<MembershipPolicyScreen> createState() => _MembershipPolicyScreenState();
}

class _MembershipPolicyScreenState extends State<MembershipPolicyScreen> {
  bool requiresApproval = true;
  bool allowGuestAccess = false;
  bool requiresDeposit = true;
  bool enableAutoRenewal = true;
  int maxMembersLimit = 500;
  int minAge = 16;
  double depositAmount = 500000;

  final List<String> membershipTypes = [
    'Thành viên VIP',
    'Thành viên thường',
    'Thành viên học sinh',
    'Thành viên ngày',
  ];

  final List<String> memberBenefits = [
    'Ưu đãi 20% cho giải đấu',
    'Ưu tiên đặt bàn',
    'Tham gia sự kiện đặc biệt',
    'Hỗ trợ kỹ thuật miễn phí',
  ];

  final List<String> registrationRequirements = [
    'CMND/CCCD',
    'Số điện thoại',
    'Email',
    'Ảnh đại diện',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Chính sách thành viên'),
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildRegistrationSettings(),
            const SizedBox(height: 24),
            _buildMembershipLimits(),
            const SizedBox(height: 24),
            _buildMembershipTypes(),
            const SizedBox(height: 24),
            _buildMemberBenefits(),
            const SizedBox(height: 24),
            _buildRegistrationRequirements(),
            const SizedBox(height: 32),
            _buildSaveButton(),
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
            child: const Icon(Icons.policy, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chính sách thành viên',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Cấu hình quy định và chính sách cho thành viên CLB',
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

  Widget _buildRegistrationSettings() {
    return _buildSection(
      title: 'Cài đặt đăng ký',
      icon: Icons.person_add,
      children: [
        _buildSwitchTile(
          title: 'Yêu cầu phê duyệt',
          subtitle: 'Thành viên mới cần được admin phê duyệt',
          value: requiresApproval,
          onChanged: (value) {
            setState(() {
              requiresApproval = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Cho phép khách vãng lai',
          subtitle: 'Khách có thể tham gia mà không cần đăng ký',
          value: allowGuestAccess,
          onChanged: (value) {
            setState(() {
              allowGuestAccess = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Yêu cầu đặt cọc',
          subtitle: 'Thành viên mới cần đặt cọc khi đăng ký',
          value: requiresDeposit,
          onChanged: (value) {
            setState(() {
              requiresDeposit = value;
            });
          },
        ),
        _buildSwitchTile(
          title: 'Tự động gia hạn',
          subtitle: 'Tự động gia hạn thành viên khi hết hạn',
          value: enableAutoRenewal,
          onChanged: (value) {
            setState(() {
              enableAutoRenewal = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMembershipLimits() {
    return _buildSection(
      title: 'Giới hạn thành viên',
      icon: Icons.groups,
      children: [
        _buildNumberInputTile(
          title: 'Số lượng thành viên tối đa',
          subtitle: 'Giới hạn tổng số thành viên trong CLB',
          value: maxMembersLimit,
          onChanged: (value) {
            setState(() {
              maxMembersLimit = value;
            });
          },
        ),
        _buildNumberInputTile(
          title: 'Độ tuổi tối thiểu',
          subtitle: 'Tuổi tối thiểu để trở thành thành viên',
          value: minAge,
          onChanged: (value) {
            setState(() {
              minAge = value;
            });
          },
        ),
        if (requiresDeposit)
          _buildCurrencyInputTile(
            title: 'Số tiền đặt cọc',
            subtitle: 'Số tiền cọc thành viên mới cần đặt',
            value: depositAmount,
            onChanged: (value) {
              setState(() {
                depositAmount = value;
              });
            },
          ),
      ],
    );
  }

  Widget _buildMembershipTypes() {
    return _buildSection(
      title: 'Loại thành viên',
      icon: Icons.card_membership,
      children: [
        ...membershipTypes.asMap().entries.map((entry) {
          int index = entry.key;
          String type = entry.value;
          
          return _buildEditableListItem(
            title: type,
            onEdit: () => _editMembershipType(index),
            onDelete: () => _deleteMembershipType(index),
          );
        }),
        _buildAddButton(
          title: 'Thêm loại thành viên',
          onTap: _addMembershipType,
        ),
      ],
    );
  }

  Widget _buildMemberBenefits() {
    return _buildSection(
      title: 'Quyền lợi thành viên',
      icon: Icons.star,
      children: [
        ...memberBenefits.asMap().entries.map((entry) {
          int index = entry.key;
          String benefit = entry.value;
          
          return _buildEditableListItem(
            title: benefit,
            onEdit: () => _editMemberBenefit(index),
            onDelete: () => _deleteMemberBenefit(index),
          );
        }),
        _buildAddButton(
          title: 'Thêm quyền lợi',
          onTap: _addMemberBenefit,
        ),
      ],
    );
  }

  Widget _buildRegistrationRequirements() {
    return _buildSection(
      title: 'Yêu cầu đăng ký',
      icon: Icons.checklist,
      children: [
        ...registrationRequirements.asMap().entries.map((entry) {
          int index = entry.key;
          String requirement = entry.value;
          
          return _buildEditableListItem(
            title: requirement,
            onEdit: () => _editRegistrationRequirement(index),
            onDelete: () => _deleteRegistrationRequirement(index),
          );
        }),
        _buildAddButton(
          title: 'Thêm yêu cầu',
          onTap: _addRegistrationRequirement,
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AppTheme.primaryLight, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberInputTile({
    required String title,
    required String subtitle,
    required int value,
    required Function(int) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showNumberDialog(title, value, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                value.toString(),
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyInputTile({
    required String title,
    required String subtitle,
    required double value,
    required Function(double) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _showCurrencyDialog(title, value, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: AppTheme.primaryLight),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${value.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} VNĐ',
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableListItem({
    required String title,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppTheme.dividerLight.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: AppTheme.textPrimaryLight,
                fontSize: 16,
              ),
            ),
          ),
          IconButton(
            onPressed: onEdit,
            icon: Icon(Icons.edit, color: AppTheme.primaryLight, size: 20),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(Icons.delete, color: Colors.red, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: AppTheme.primaryLight,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, color: AppTheme.primaryLight),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saveMembershipPolicy,
          child: const Center(
            child: Text(
              'Lưu chính sách thành viên',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNumberDialog(String title, int value, Function(int) onChanged) {
    TextEditingController controller = TextEditingController(text: value.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: title,
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              int? newValue = int.tryParse(controller.text);
              if (newValue != null && newValue > 0) {
                onChanged(newValue);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showCurrencyDialog(String title, double value, Function(double) onChanged) {
    TextEditingController controller = TextEditingController(text: value.toStringAsFixed(0));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Nhập $title'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: '$title (VNĐ)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              double? newValue = double.tryParse(controller.text);
              if (newValue != null && newValue >= 0) {
                onChanged(newValue);
                Navigator.pop(context);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _addMembershipType() {
    _showTextDialog('Thêm loại thành viên', '', (text) {
      if (text.isNotEmpty) {
        setState(() {
          membershipTypes.add(text);
        });
      }
    });
  }

  void _editMembershipType(int index) {
    _showTextDialog('Sửa loại thành viên', membershipTypes[index], (text) {
      if (text.isNotEmpty) {
        setState(() {
          membershipTypes[index] = text;
        });
      }
    });
  }

  void _deleteMembershipType(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa loại thành viên'),
        content: Text('Bạn có chắc muốn xóa "${membershipTypes[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                membershipTypes.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _addMemberBenefit() {
    _showTextDialog('Thêm quyền lợi', '', (text) {
      if (text.isNotEmpty) {
        setState(() {
          memberBenefits.add(text);
        });
      }
    });
  }

  void _editMemberBenefit(int index) {
    _showTextDialog('Sửa quyền lợi', memberBenefits[index], (text) {
      if (text.isNotEmpty) {
        setState(() {
          memberBenefits[index] = text;
        });
      }
    });
  }

  void _deleteMemberBenefit(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa quyền lợi'),
        content: Text('Bạn có chắc muốn xóa "${memberBenefits[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                memberBenefits.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _addRegistrationRequirement() {
    _showTextDialog('Thêm yêu cầu đăng ký', '', (text) {
      if (text.isNotEmpty) {
        setState(() {
          registrationRequirements.add(text);
        });
      }
    });
  }

  void _editRegistrationRequirement(int index) {
    _showTextDialog('Sửa yêu cầu đăng ký', registrationRequirements[index], (text) {
      if (text.isNotEmpty) {
        setState(() {
          registrationRequirements[index] = text;
        });
      }
    });
  }

  void _deleteRegistrationRequirement(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa yêu cầu đăng ký'),
        content: Text('Bạn có chắc muốn xóa "${registrationRequirements[index]}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                registrationRequirements.removeAt(index);
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
  }

  void _showTextDialog(String title, String initialValue, Function(String) onSave) {
    TextEditingController controller = TextEditingController(text: initialValue);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
          ),
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              onSave(controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _saveMembershipPolicy() {
    // TODO: Save to database
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('✅ Đã lưu chính sách thành viên'),
        backgroundColor: AppTheme.primaryLight,
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}
