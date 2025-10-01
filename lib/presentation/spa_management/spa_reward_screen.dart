import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/club_spa_service.dart';
import '../../../services/user_service.dart';

/// Screen for users to view their SPA balance and redeem rewards
class SpaRewardScreen extends StatefulWidget() {
  final String clubId;
  final String clubName;

  const SpaRewardScreen({
    super.key,
    required this.clubId,
    required this.clubName,
  });

  @override
  State<SpaRewardScreen> createState() => _SpaRewardScreenState();
}

class _SpaRewardScreenState extends State<SpaRewardScreen>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final ClubSpaService _spaService = ClubSpaService();
  final UserService _userService = UserService.instance;

  Map<String, dynamic>? _userSpaBalance;
  List<Map<String, dynamic>> _availableRewards = [];
  List<Map<String, dynamic>> _userRedemptions = [];
  List<Map<String, dynamic>> _spaTransactions = [];
  bool _isLoading = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async() {
    setState(() => _isLoading = true);
    
    try() {
      // Get current user
      final user = await _userService.getCurrentUserProfile();
      if (user == null) return;
      
      _userId = user.id;
      
      // Load all data concurrently
      final results = await Future.wait([
        _spaService.getUserSpaBalance(_userId!, widget.clubId),
        _spaService.getClubRewards(widget.clubId),
        _spaService.getUserRedemptions(_userId!, widget.clubId),
        _spaService.getUserSpaTransactions(_userId!, widget.clubId),
      ]);
      
      setState(() {
        _userSpaBalance = results[0] as Map<String, dynamic>?;
        _availableRewards = results[1] as List<Map<String, dynamic>>;
        _userRedemptions = results[2] as List<Map<String, dynamic>>;
        _spaTransactions = results[3] as List<Map<String, dynamic>>;
      });
    } catch (e) {
      debugPrint('Error loading user data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    } finally() {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _redeemReward(Map<String, dynamic> reward) async() {
    if (_userId == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận đổi thưởng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Bạn có chắc muốn đổi phần thưởng này?'),
            const SizedBox(height: 16),
            Text('🎁 ${reward['reward_name']}'),
            Text('💰 Chi phí: ${reward['spa_cost']} SPA'),
            Text('💳 Số dư hiện tại: ${_userSpaBalance?['spa_balance'] ?? 0} SPA'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận đổi'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try() {
      final result = await _spaService.redeemReward(
        reward['id'],
        _userId!,
        widget.clubId,
      );

      Navigator.pop(context); // Close loading dialog

      if (result != null && result['success'] == true) {
        // Show success dialog with redemption code
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('🎉 Đổi thưởng thành công!'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Mã đổi thưởng của bạn:'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          result['redemption_code'],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(
                            ClipboardData(text: result['redemption_code']),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Đã copy mã!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vui lòng đưa mã này cho nhân viên câu lạc bộ để nhận thưởng.',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _loadUserData(); // Refresh data
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else() {
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('❌ Lỗi đổi thưởng'),
            content: Text(result?['error'] ?? 'Có lỗi xảy ra'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SPA Rewards - ${widget.clubName}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.account_balance_wallet), text: 'Số dư'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'Đổi thưởng'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildBalanceTab(),
                _buildRewardsTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildBalanceTab() {
    final balance = _userSpaBalance?['spa_balance'] ?? 0.0;
    final totalEarned = _userSpaBalance?['total_earned'] ?? 0.0;
    final totalSpent = _userSpaBalance?['total_spent'] ?? 0.0;

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Balance Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 48,
                      color: Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Số dư SPA',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${balance.toStringAsFixed(0)} SPA',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistics Cards
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.trending_up, color: Colors.green),
                          const SizedBox(height: 8),
                          Text('Tổng kiếm được'),
                          Text(
                            '${totalEarned.toStringAsFixed(0)} SPA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
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
                          const Icon(Icons.trending_down, color: Colors.orange),
                          const SizedBox(height: 8),
                          Text('Tổng đã dùng'),
                          Text(
                            '${totalSpent.toStringAsFixed(0)} SPA',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent Transactions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Giao dịch gần đây',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ..._spaTransactions.take(5).map((transaction) {
                      final isPositive = transaction['spa_amount'] > 0;
                      return ListTile(
                        leading: Icon(
                          isPositive ? Icons.add_circle : Icons.remove_circle,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                        title: Text(transaction['description'] ?? 'Giao dịch SPA'),
                        subtitle: Text(
                          DateTime.parse(transaction['created_at'])
                              .toString()
                              .substring(0, 16),
                        ),
                        trailing: Text(
                          '${isPositive ? "+" : ''}${transaction['spa_amount']} SPA',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }),
                    if (_spaTransactions.isEmpty)
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

  Widget _buildRewardsTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _availableRewards.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.card_giftcard_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có phần thưởng nào'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _availableRewards.length,
              itemBuilder: (context, index) {
                final reward = _availableRewards[index];
                final userBalance = _userSpaBalance?['spa_balance'] ?? 0.0;
                final canAfford = userBalance >= reward['spa_cost'];
                final isAvailable = reward['quantity_available'] == null ||
                    reward['quantity_claimed'] < reward['quantity_available'];

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
                                  if (reward['reward_description'] != null)
                                    Text(
                                      reward['reward_description'],
                                      style: TextStyle(color: Colors.grey.shade600),
                                    ),
                                ],
                              ),
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
                            if (reward['quantity_available'] != null) ...[
                              const SizedBox(width: 8),
                              Text(
                                'Còn: ${reward['quantity_available'] - reward['quantity_claimed']}',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                            const Spacer(),
                            ElevatedButton(
                              onPressed: canAfford && isAvailable
                                  ? () => _redeemReward(reward)
                                  : null,
                              child: Text(
                                !isAvailable
                                    ? 'Hết hàng'
                                    : !canAfford
                                        ? "Không đủ SPA"
                                        : 'Đổi thưởng',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: _userRedemptions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có lịch sử đổi thưởng'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _userRedemptions.length,
              itemBuilder: (context, index) {
                final redemption = _userRedemptions[index];
                final reward = redemption['spa_rewards'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: _getRewardIcon(reward['reward_type']),
                    title: Text(reward['reward_name'] ?? 'Phần thưởng'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Chi phí: ${redemption['spa_cost']} SPA'),
                        Text(
                          'Ngày: ${DateTime.parse(redemption['redeemed_at']).toString().substring(0, 16)}',
                        ),
                        if (redemption['redemption_code'] != null)
                          Text('Mã: ${redemption['redemption_code']}'),
                      ],
                    ),
                    trailing: _getStatusChip(redemption['redemption_status']),
                    isThreeLine: true,
                  ),
                );
              },
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

  Widget _getStatusChip(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'pending':
        color = Colors.orange;
        text = 'Chờ xử lý';
        break;
      case 'approved':
        color = Colors.blue;
        text = 'Đã duyệt';
        break;
      case 'delivered':
        color = Colors.green;
        text = 'Đã giao';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Đã hủy';
        break;
      default:
        color = Colors.grey;
        text = status;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}