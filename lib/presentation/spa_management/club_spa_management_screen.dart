import 'package:flutter/material.dart';
import '../../../services/club_spa_service.dart';

/// Screen for club owners to manage SPA rewards and monitor usage  
class ClubSpaManagementScreen extends StatefulWidget {
  const ClubSpaManagementScreen({super.key});

} 
  final String clubId;
  final String clubName;

  const ClubSpaManagementScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<ClubSpaManagementScreen> createState() => _ClubSpaManagementScreenState();
}

class _ClubSpaManagementScreenState extends State<ClubSpaManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClubSpaService _spaService = ClubSpaService();

  Map<String, dynamic>? _clubSpaBalance;
  List<Map<String, dynamic>> _clubRewards = [];
  List<Map<String, dynamic>> _clubTransactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadClubData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadClubData() async {
    setState(() => _isLoading = true);
    
    try {
      final results = await Future.wait([
        _spaService.getClubSpaBalance(widget.clubId),
        _spaService.getClubRewards(widget.clubId),
        _spaService.getClubSpaTransactions(widget.clubId),
      ]);
      
      setState(() {
        _clubSpaBalance = results[0] as Map<String, dynamic>?;
        _clubRewards = results[1] as List<Map<String, dynamic>>;
        _clubTransactions = results[2] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      debugPrint('Error loading club data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCreateRewardDialog() async {
    final formKey = GlobalKey<FormState>();
    String rewardName = '';
    String rewardDescription = '';
    String rewardType = 'discount_code';
    double spaCost = 0;
    String rewardValue = '';
    int? quantityAvailable;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tạo phần thưởng mới'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Tên phần thưởng *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập tên' : null,
                  onSaved: (value) => rewardName = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  onSaved: (value) => rewardDescription = value ?? '',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Loại phần thưởng',
                    border: OutlineInputBorder(),
                  ),
                  value: rewardType,
                  items: const [
                    DropdownMenuItem(value: 'discount_code', child: Text('Mã giảm giá')),
                    DropdownMenuItem(value: 'physical_item', child: Text('Hiện vật')),
                    DropdownMenuItem(value: 'service', child: Text('Dịch vụ')),
                    DropdownMenuItem(value: 'merchandise', child: Text('Hàng hóa')),
                    DropdownMenuItem(value: 'other', child: Text('Khác')),
                  ],
                  onChanged: (value) => rewardType = value ?? 'discount_code',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Chi phí SPA *',
                    border: OutlineInputBorder(),
                    suffixText: 'SPA',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty == true) return 'Vui lòng nhập chi phí';
                    if (double.tryParse(value!) == null) return 'Vui lòng nhập số hợp lệ';
                    return null;
                  },
                  onSaved: (value) => spaCost = double.tryParse(value!) ?? 0,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Giá trị phần thưởng *',
                    border: OutlineInputBorder(),
                    hintText: 'VD: Giảm 10%, Áo thun size M, ...',
                  ),
                  validator: (value) => value?.isEmpty == true ? 'Vui lòng nhập giá trị' : null,
                  onSaved: (value) => rewardValue = value ?? '',
                ),
                const SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Số lượng (để trống = không giới hạn)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onSaved: (value) => quantityAvailable = int.tryParse(value ?? ''),
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
            onPressed: () async {
              if (formKey.currentState?.validate() == true) {
                formKey.currentState?.save();
                Navigator.pop(context);
                
                // Create reward
                final success = await _spaService.createReward(
                  clubId: widget.clubId,
                  rewardName: rewardName,
                  rewardDescription: rewardDescription,
                  rewardType: rewardType,
                  spaCost: spaCost,
                  rewardValue: rewardValue,
                  quantityAvailable: quantityAvailable,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tạo phần thưởng thành công!')),
                  );
                  _loadClubData();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi khi tạo phần thưởng')),
                  );
                }
              }
            },
            child: const Text('Tạo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Quản lý SPA - ${widget.clubName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance), text: 'Tổng quan'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Phần thưởng'),
            Tab(icon: Icon(Icons.analytics), text: 'Thống kê'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildRewardsTab(),
                _buildAnalyticsTab(),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton(
              onPressed: _showCreateRewardDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildOverviewTab() {
    final balance = _clubSpaBalance;
    
    return RefreshIndicator(
      onRefresh: _loadClubData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // SPA Balance Overview
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Số dư SPA của câu lạc bộ',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    if (balance != null) ...[
                      _buildBalanceRow('Tổng được cấp', balance['total_spa_allocated'] ?? 0),
                      const Divider(),
                      _buildBalanceRow('Còn lại', balance['available_spa'] ?? 0, Colors.green),
                      const Divider(),
                      _buildBalanceRow('Đã sử dụng', balance['spent_spa'] ?? 0, Colors.orange),
                      const Divider(),
                      _buildBalanceRow('Đã giữ trước', balance['reserved_spa'] ?? 0, Colors.blue),
                    ] else ...[
                      const Text('Chưa có ngân sách SPA'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng liên hệ admin để được cấp ngân sách SPA'),
                            ),
                          );
                        },
                        child: const Text('Yêu cầu ngân sách SPA'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick Stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.card_giftcard, color: Colors.purple),
                          const SizedBox(height: 8),
                          Text('Tổng phần thưởng'),
                          Text(
                            '${_clubRewards.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('Giao dịch'),
                          Text(
                            '${_clubTransactions.length}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Recent Activity
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoạt động gần đây',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ..._clubTransactions.take(5).map((transaction) {
                      final isPositive = transaction['spa_amount'] > 0;
                      return ListTile(
                        leading: Icon(
                          isPositive ? Icons.add_circle : Icons.remove_circle,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction['description'] ?? 'Giao dịch SPA'),
                        subtitle: Text(
                          '${DateTime.parse(transaction['created_at']).toString().substring(0, 16)}\n'
                          'Loại: ${_getTransactionTypeText(transaction['transaction_type'])}',
                        ),
                        trailing: Text(
                          '${isPositive ? "+" : ''}${transaction['spa_amount']} SPA',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        isThreeLine: true,
                      );
                    }),
                    if (_clubTransactions.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Chưa có giao dịch nào'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceRow(String label, double amount, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '${amount.toStringAsFixed(0)} SPA',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    return RefreshIndicator(
      onRefresh: _loadClubData,
      child: _clubRewards.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có phần thưởng nào'),
                  SizedBox(height: 8),
                  Text('Nhấn nút + để tạo phần thưởng đầu tiên'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clubRewards.length,
              itemBuilder: (context, index) {
                final reward = _clubRewards[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _getRewardIcon(reward['reward_type']),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reward['reward_name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (reward['reward_description'] != null &&
                                      reward['reward_description'].isNotEmpty)
                                    Text(
                                      reward['reward_description'],
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
                            ),
                            Switch(
                              value: reward['is_active'] ?? false,
                              onChanged: (value) async {
                                // TODO: Implement toggle reward active status
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tính năng sẽ được cập nhật')),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${reward['spa_cost']} SPA',
                                style: TextStyle(
                                  color: Colors.blue.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (reward['quantity_available'] != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Còn: ${reward['quantity_available'] - reward['quantity_claimed']}',
                                  style: TextStyle(
                                    color: Colors.green.shade800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const Spacer(),
                            Text(
                              'Đã đổi: ${reward['quantity_claimed']}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Giá trị: ${reward['reward_value']}',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    // Calculate some basic analytics
    final totalRewardsCreated = _clubRewards.length;
    final totalRewardsRedeemed = _clubRewards.fold<int>(
      0, (sum, reward) => sum + (reward['quantity_claimed'] as int? ?? 0)
    );
    final totalSpentOnRewards = _clubTransactions
        .where((t) => t['transaction_type'] == 'reward_redemption')
        .fold<double>(0, (sum, t) => sum + (t['spa_amount'] as double? ?? 0).abs());

    return RefreshIndicator(
      onRefresh: _loadClubData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Analytics Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              children: [
                _buildAnalyticsCard(
                  'Phần thưởng đã tạo',
                  '$totalRewardsCreated',
                  Icons.add_box,
                  Colors.blue,
                ),
                _buildAnalyticsCard(
                  'Lượt đổi thưởng',
                  '$totalRewardsRedeemed',
                  Icons.redeem,
                  Colors.green,
                ),
                _buildAnalyticsCard(
                  'SPA đã chi',
                  totalSpentOnRewards.toStringAsFixed(0),
                  Icons.payments,
                  Colors.orange,
                ),
                _buildAnalyticsCard(
                  'Hiệu quả',
                  totalRewardsCreated > 0 
                      ? "${(totalRewardsRedeemed / totalRewardsCreated * 100).toStringAsFixed(1)}%"
                      : '0%',
                  Icons.trending_up,
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Popular Rewards
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Phần thưởng phổ biến',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...(() {
                      final popularRewards = _clubRewards
                          .where((r) => (r['quantity_claimed'] as int? ?? 0) > 0)
                          .toList();
                      popularRewards.sort((a, b) => (b['quantity_claimed'] as int? ?? 0)
                          .compareTo(a['quantity_claimed'] as int? ?? 0));
                      return popularRewards.take(5).map((reward) => ListTile(
                            leading: _getRewardIcon(reward['reward_type']),
                            title: Text(reward['reward_name']),
                            subtitle: Text('${reward['spa_cost']} SPA'),
                            trailing: Text(
                              '${reward['quantity_claimed']} lượt',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ));
                    })(),
                    if (_clubRewards.every((r) => (r['quantity_claimed'] as int? ?? 0) == 0))
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Chưa có phần thưởng nào được đổi'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case 'discount_code':
        return const Icon(Icons.discount, color: Colors.orange);
      case 'physical_item':
        return const Icon(Icons.inventory, color: Colors.brown);
      case 'service':
        return const Icon(Icons.room_service, color: Colors.purple);
      case 'merchandise':
        return const Icon(Icons.shopping_bag, color: Colors.green);
      default:
        return const Icon(Icons.card_giftcard, color: Colors.blue);
    }
  }

  String _getTransactionTypeText(String type) {
    switch (type) {
      case 'admin_allocation':
        return 'Cấp ngân sách';
      case 'challenge_bonus':
        return 'Thưởng thách đấu';
      case 'reward_redemption':
        return 'Đổi thưởng';
      case 'bonus_adjustment':
        return 'Điều chỉnh';
      case 'refund':
        return 'Hoàn trả';
      default:
        return type;
    }
  }
}
