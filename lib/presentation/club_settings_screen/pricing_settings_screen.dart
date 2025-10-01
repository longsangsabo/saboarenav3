import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class PricingSettingsScreen extends StatefulWidget {
  const PricingSettingsScreen({super.key});

} 
  final String clubId;

  const PricingSettingsScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<PricingSettingsScreen> createState() => _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends State<PricingSettingsScreen> {
  List<Map<String, dynamic>> tableRates = [
    {
      "id": '1',
      "name": 'Bàn Pool thường',
      'hourlyRate': 50000,
      "description": 'Bàn pool tiêu chuẩn cho người chơi thông thường',
      'isActive': true,
    },
    {
      "id": '2',
      "name": 'Bàn Pool VIP',
      'hourlyRate': 80000,
      "description": 'Bàn pool cao cấp với không gian riêng tư',
      'isActive': true,
    },
  ];

  List<Map<String, dynamic>> membershipFees = [
    {
      "id": '1',
      "name": 'Thành viên thông thường',
      'monthlyFee': 200000,
      'yearlyFee': 2000000,
      "benefits": 'Giảm 10% giá bàn, ưu tiên đặt bàn',
      'isActive': true,
    },
    {
      "id": '2',
      "name": 'Thành viên VIP',
      'monthlyFee': 500000,
      'yearlyFee': 5000000,
      "benefits": 'Giảm 20% giá bàn, ưu tiên cao, phòng chờ VIP',
      'isActive': true,
    },
  ];

  List<Map<String, dynamic>> additionalServices = [
    {
      "id": '1',
      "name": 'Bàn pool cao cấp với không gian riêng tư',
      'price': 80000,
      "unit": 'giờ',
      "description": 'Bàn pool cao cấp với không gian riêng tư',
      'isActive': true,
    },
    {
      "id": '2',
      "name": 'Đồ uống',
      'price': 25000,
      "unit": 'ly',
      "description": 'Nước uống các loại',
      'isActive': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Bảng giá dịch vụ'),
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildTableRates(),
            const SizedBox(height: 32),
            _buildMembershipFees(),
            const SizedBox(height: 32),
            _buildAdditionalServices(),
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
            child: const Icon(Icons.monetization_on, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quản lý bảng giá',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thiết lập giá cho các dịch vụ và sân chơi',
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

  Widget _buildTableRates() {
    return _buildPricingSection(
      title: 'Giá thuê bàn',
      subtitle: 'Thiết lập giá thuê theo giờ cho các loại bàn',
      icon: Icons.table_restaurant,
      items: tableRates,
      onAdd: () => _showTableRateDialog(),
      onEdit: (item, index) => _showTableRateDialog(item: item, index: index),
      onDelete: (index) => _deleteTableRate(index),
      itemBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'],
            style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCurrency(item['hourlyRate'])}/giờ',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['description'],
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipFees() {
    return _buildPricingSection(
      title: 'Phí thành viên',
      subtitle: 'Thiết lập phí cho các loại thành viên',
      icon: Icons.card_membership,
      items: membershipFees,
      onAdd: () => _showMembershipFeeDialog(),
      onEdit: (item, index) => _showMembershipFeeDialog(item: item, index: index),
      onDelete: (index) => _deleteMembershipFee(index),
      itemBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'],
            style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${_formatCurrency(item['monthlyFee'])}/tháng',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${_formatCurrency(item['yearlyFee'])}/năm',
                  style: TextStyle(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            item['benefits'],
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalServices() {
    return _buildPricingSection(
      title: 'Dịch vụ bổ sung',
      subtitle: 'Thiết lập giá cho các dịch vụ khác',
      icon: Icons.room_service,
      items: additionalServices,
      onAdd: () => _showAdditionalServiceDialog(),
      onEdit: (item, index) => _showAdditionalServiceDialog(item: item, index: index),
      onDelete: (index) => _deleteAdditionalService(index),
      itemBuilder: (item) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['name'],
            style: TextStyle(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            '${_formatCurrency(item['price'])}/${item['unit']}',
            style: TextStyle(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item['description'],
            style: TextStyle(
              color: AppTheme.textSecondaryLight,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Map<String, dynamic>> items,
    required VoidCallback onAdd,
    required Function(Map<String, dynamic>, int) onEdit,
    required Function(int) onDelete,
    required Widget Function(Map<String, dynamic>) itemBuilder,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppTheme.textPrimaryLight,
                    fontWeight: FontWeight.w600,
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
            IconButton(
              onPressed: onAdd,
              icon: Icon(Icons.add, color: AppTheme.primaryLight),
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
          child: Column(
            children: items.asMap().entries.map((entry) {
              int index = entry.key;
              Map<String, dynamic> item = entry.value;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: index < items.length - 1
                      ? Border(
                          bottom: BorderSide(
                            color: AppTheme.dividerLight.withOpacity(0.3),
                            width: 1,
                          ),
                        )
                      : null,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: item['isActive']
                            ? AppTheme.primaryLight.withOpacity(0.12)
                            : Colors.grey.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: item['isActive'] ? AppTheme.primaryLight : Colors.grey,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: itemBuilder(item)),
                    Switch(
                      value: item['isActive'],
                      onChanged: (value) {
                        setState(() {
                          item['isActive'] = value;
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
                          onEdit(item, index);
                        } else if (value == 'delete') {
                          onDelete(index);
                        }
                      },
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
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
          onTap: _savePricingSettings,
          child: const Center(
            child: Text(
              'Lưu bảng giá',
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

  String _formatCurrency(int amount) {
    return '${amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    )} VNĐ';
  }

  void _showTableRateDialog({Map<String, dynamic>? item, int? index}) {
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final rateController = TextEditingController(text: item?['hourlyRate']?.toString() ?? '');
    final descController = TextEditingController(text: item?['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? "Thêm bàn mới" : 'Chỉnh sửa bàn'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên bàn',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: rateController,
                decoration: const InputDecoration(
                  labelText: 'Giá theo giờ (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              if (nameController.text.isNotEmpty && rateController.text.isNotEmpty) {
                setState(() {
                  if (item == null) {
                    tableRates.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameController.text,
                      'hourlyRate': int.parse(rateController.text),
                      'description': descController.text,
                      'isActive': true,
                    });
                  } else {
                    () {
                    tableRates[index!]['name'] = nameController.text;
                    tableRates[index]['hourlyRate'] = int.parse(rateController.text);
                    tableRates[index]['description'] = descController.text;
                  }
                
                  }});
                Navigator.pop(context);
              }
            },
            child: Text(item == null ? "Thêm" : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showMembershipFeeDialog({Map<String, dynamic>? item, int? index}) {
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final monthlyController = TextEditingController(text: item?['monthlyFee']?.toString() ?? '');
    final yearlyController = TextEditingController(text: item?['yearlyFee']?.toString() ?? '');
    final benefitsController = TextEditingController(text: item?['benefits'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? "Thêm gói thành viên" : 'Chỉnh sửa gói thành viên'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên gói',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: monthlyController,
                decoration: const InputDecoration(
                  labelText: 'Phí tháng (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: yearlyController,
                decoration: const InputDecoration(
                  labelText: 'Phí năm (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: benefitsController,
                decoration: const InputDecoration(
                  labelText: 'Quyền lợi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              if (nameController.text.isNotEmpty && monthlyController.text.isNotEmpty) {
                setState(() {
                  if (item == null) {
                    membershipFees.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameController.text,
                      'monthlyFee': int.parse(monthlyController.text),
                      'yearlyFee': int.parse(yearlyController.text.isEmpty ? '0' : yearlyController.text),
                      'benefits': benefitsController.text,
                      'isActive': true,
                    });
                  } else {
                    () {
                    membershipFees[index!]['name'] = nameController.text;
                    membershipFees[index]['monthlyFee'] = int.parse(monthlyController.text);
                    membershipFees[index]['yearlyFee'] = int.parse(yearlyController.text.isEmpty ? '0' : yearlyController.text);
                    membershipFees[index]['benefits'] = benefitsController.text;
                  }
                
                  }});
                Navigator.pop(context);
              }
            },
            child: Text(item == null ? "Thêm" : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _showAdditionalServiceDialog({Map<String, dynamic>? item, int? index}) {
    final nameController = TextEditingController(text: item?['name'] ?? '');
    final priceController = TextEditingController(text: item?['price']?.toString() ?? '');
    final unitController = TextEditingController(text: item?['unit'] ?? '');
    final descController = TextEditingController(text: item?['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item == null ? "Thêm dịch vụ" : 'Chỉnh sửa dịch vụ'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên dịch vụ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Giá (VNĐ)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị (lần, ly, ...)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: 'Mô tả',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
              if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                setState(() {
                  if (item == null) {
                    additionalServices.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'name': nameController.text,
                      'price': int.parse(priceController.text),
                      'unit': unitController.text.isEmpty ? 'lần' : unitController.text,
                      'description': descController.text,
                      'isActive': true,
                    });
                  } else {
                    () {
                    additionalServices[index!]['name'] = nameController.text;
                    additionalServices[index]['price'] = int.parse(priceController.text);
                    additionalServices[index]['unit'] = unitController.text.isEmpty ? 'lần' : unitController.text;
                    additionalServices[index]['description'] = descController.text;
                  }
                
                  }});
                Navigator.pop(context);
              }
            },
            child: Text(item == null ? "Thêm" : 'Cập nhật'),
          ),
        ],
      ),
    );
  }

  void _deleteTableRate(int index) {
    _showDeleteDialog('bàn này', () {
      setState(() {
        tableRates.removeAt(index);
      });
    });
  }

  void _deleteMembershipFee(int index) {
    _showDeleteDialog('gói thành viên này', () {
      setState(() {
        membershipFees.removeAt(index);
      });
    });
  }

  void _deleteAdditionalService(int index) {
    _showDeleteDialog('dịch vụ này', () {
      setState(() {
        additionalServices.removeAt(index);
      });
    });
  }

  void _showDeleteDialog(String itemName, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text('Bạn có chắc chắn muốn xóa $itemName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              onConfirm();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Đã xóa thành công'),
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

  void _savePricingSettings() {
    // TODO: Save to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã lưu bảng giá dịch vụ'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}
