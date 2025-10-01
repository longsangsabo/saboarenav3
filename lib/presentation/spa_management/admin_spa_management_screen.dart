import 'package:flutter/material.dart';
import '../../../services/club_spa_service.dart';

/// Screen for admins to manage SPA allocation to clubs
class AdminSpaManagementScreen extends StatefulWidget() {
  const AdminSpaManagementScreen({super.key});

  @override
  State<AdminSpaManagementScreen> createState() => _AdminSpaManagementScreenState();
}

class _AdminSpaManagementScreenState extends State<AdminSpaManagementScreen>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final ClubSpaService _spaService = ClubSpaService();

  List<Map<String, dynamic>> _clubs = [];
  List<Map<String, dynamic>> _allTransactions = [];
  Map<String, dynamic> _systemStats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async() {
    setState(() => _isLoading = true);
    
    try() {
      final results = await Future.wait([
        _spaService.getAllClubsWithSpaBalance(),
        _spaService.getAllSpaTransactions(),
        _spaService.getSystemSpaStats(),
      ]);
      
      setState(() {
        _clubs = results[0] as List<Map<String, dynamic>>;
        _allTransactions = results[1] as List<Map<String, dynamic>>;
        _systemStats = results[2] as Map<String, dynamic>;
      });
    } catch (e) {
      debugPrint('Error loading admin data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: $e')),
        );
      }
    } finally() {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showAllocateSpaDialog(String clubId, String clubName) async() {
    final formKey = GlobalKey<FormState>();
    double spaAmount = 0;
    String description = '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cấp SPA cho $clubName'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Số lượng SPA *',
                  border: OutlineInputBorder(),
                  suffixText: 'SPA',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Vui lòng nhập số lượng SPA';
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) return 'Vui lòng nhập số hợp lệ (> 0)';
                  return null;
                },
                onSaved: (value) => spaAmount = double.tryParse(value!) ?? 0,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Mô tả (tùy chọn)',
                  border: OutlineInputBorder(),
                  hintText: 'VD: Ngân sách tháng 9/2024',
                ),
                maxLines: 2,
                onSaved: (value) => description = value ?? '',
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
            onPressed: () async() {
              if (formKey.currentState?.validate() == true) {
                formKey.currentState?.save();
                Navigator.pop(context);
                
                // Allocate SPA
                final success = await _spaService.allocateSpaToClub(
                  clubId: clubId,
                  spaAmount: spaAmount,
                  description: description.isEmpty 
                      ? 'Cấp SPA cho $clubName' 
                      : description,
                );
                
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Đã cấp ${spaAmount.toStringAsFixed(0)} SPA cho $clubName')),
                  );
                  _loadAdminData();
                } else() {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Lỗi khi cấp SPA')),
                  );
                }
              }
            },
            child: const Text('Cấp SPA'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý SPA hệ thống'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Câu lạc bộ'),
            Tab(icon: Icon(Icons.analytics), text: 'Thống kê'),
            Tab(icon: Icon(Icons.history), text: 'Lịch sử'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildClubsTab(),
                _buildAnalyticsTab(),
                _buildHistoryTab(),
              ],
            ),
    );
  }

  Widget _buildClubsTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: _clubs.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có câu lạc bộ nào'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _clubs.length,
              itemBuilder: (context, index) {
                final club = _clubs[index];
                final spaBalance = club['club_spa_balance'];
                final totalAllocated = spaBalance?['total_spa_allocated'] ?? 0.0;
                final availableSpa = spaBalance?['available_spa'] ?? 0.0;
                final spentSpa = spaBalance?['spent_spa'] ?? 0.0;
                final reservedSpa = spaBalance?['reserved_spa'] ?? 0.0;

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue.shade100,
                      child: Text(
                        club['name']?[0]?.toUpperCase() ?? 'C',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      club['name'] ?? 'Chưa có tên',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: ${club['id']}'),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _buildStatusChip('Tổng: ${totalAllocated.toStringAsFixed(0)} SPA', Colors.blue),
                            const SizedBox(width: 8),
                            _buildStatusChip('Còn: ${availableSpa.toStringAsFixed(0)} SPA', Colors.green),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_card),
                      onPressed: () => _showAllocateSpaDialog(club['id'], club['name'] ?? 'Câu lạc bộ'),
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildBalanceRow('Tổng được cấp', totalAllocated, Colors.blue),
                            const Divider(),
                            _buildBalanceRow('Còn lại', availableSpa, Colors.green),
                            const Divider(),
                            _buildBalanceRow('Đã sử dụng', spentSpa, Colors.orange),
                            const Divider(),
                            _buildBalanceRow('Đã giữ trước', reservedSpa, Colors.purple),
                            const SizedBox(height: 16),
                            
                            // Club stats
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    'Phần thưởng',
                                    '${club['rewards_count'] ?? 0}',
                                    Icons.card_giftcard,
                                    Colors.purple,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _buildStatCard(
                                    'Lượt đổi',
                                    '${club['redemptions_count'] ?? 0}',
                                    Icons.redeem,
                                    Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    final totalAllocated = _systemStats['total_spa_allocated'] ?? 0.0;
    final totalSpent = _systemStats['total_spa_spent'] ?? 0.0;
    final totalAvailable = _systemStats['total_spa_available'] ?? 0.0;
    final totalRewards = _systemStats['total_rewards'] ?? 0;
    final activeClubs = _systemStats['active_clubs'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // System Overview Cards
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildSystemStatCard(
                  'Tổng SPA đã cấp',
                  '${totalAllocated.toStringAsFixed(0)}',
                  Icons.account_balance,
                  Colors.blue,
                ),
                _buildSystemStatCard(
                  'SPA còn sử dụng',
                  '${totalAvailable.toStringAsFixed(0)}',
                  Icons.savings,
                  Colors.green,
                ),
                _buildSystemStatCard(
                  'SPA đã dùng',
                  '${totalSpent.toStringAsFixed(0)}',
                  Icons.shopping_cart,
                  Colors.orange,
                ),
                _buildSystemStatCard(
                  'Tỷ lệ sử dụng',
                  totalAllocated > 0 
                      ? "${(totalSpent / totalAllocated * 100).toStringAsFixed(1)}%"
                      : '0%',
                  Icons.trending_up,
                  Colors.purple,
                ),
                _buildSystemStatCard(
                  'Câu lạc bộ',
                  '$activeClubs',
                  Icons.business,
                  Colors.teal,
                ),
                _buildSystemStatCard(
                  'Phần thưởng',
                  '$totalRewards',
                  Icons.card_giftcard,
                  Colors.pink,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Top Performers
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top câu lạc bộ hoạt động',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    ...(() {
                      final sortedClubs = List<Map<String, dynamic>>.from(_clubs);
                      sortedClubs.sort((a, b) {
                        final aRedemptions = a['redemptions_count'] ?? 0;
                        final bRedemptions = b['redemptions_count'] ?? 0;
                        return bRedemptions.compareTo(aRedemptions);
                      });
                      return sortedClubs.take(5).map((club) {
                        final redemptions = club['redemptions_count'] ?? 0;
                        final rewards = club['rewards_count'] ?? 0;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              club['name']?[0]?.toUpperCase() ?? 'C',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(club['name'] ?? 'Chưa có tên'),
                          subtitle: Text('$rewards phần thưởng'),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '$redemptions',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const Text(
                                'lượt đổi',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      }).toList();
                    })(),
                    if (_clubs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                          child: Text('Chưa có dữ liệu'),
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

  Widget _buildHistoryTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminData,
      child: _allTransactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có giao dịch nào'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _allTransactions.length,
              itemBuilder: (context, index) {
                final transaction = _allTransactions[index];
                final isPositive = (transaction['spa_amount'] as double? ?? 0) > 0;
                final clubName = transaction['club_name'] ?? 'Không xác định';
                final userName = transaction['user_name'];
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isPositive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        _getTransactionIcon(transaction['transaction_type']),
                        color: isPositive ? Colors.green.shade800 : Colors.red.shade800,
                      ),
                    ),
                    title: Text(
                      transaction['description'] ?? 'Giao dịch SPA',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('CLB: $clubName'),
                        if (userName != null) Text('Người dùng: $userName'),
                        Text(
                          DateTime.parse(transaction['created_at'])
                              .toString()
                              .substring(0, 16),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${isPositive ? "+" : ''}${transaction['spa_amount']}',
                          style: TextStyle(
                            color: isPositive ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Text(
                          'SPA',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    isThreeLine: userName != null,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildBalanceRow(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 14)),
          Text(
            '${amount.toStringAsFixed(0)} SPA',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.blue.shade800,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSystemStatCard(String title, String value, IconData icon, Color color) {
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
                fontSize: 20,
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

  IconData _getTransactionIcon(String type) {
    switch (type) {
      case 'admin_allocation':
        return Icons.account_balance;
      case 'challenge_bonus':
        return Icons.emoji_events;
      case 'reward_redemption':
        return Icons.redeem;
      case 'bonus_adjustment':
        return Icons.tune;
      case 'refund':
        return Icons.refresh;
      default:
        return Icons.swap_horiz;
    }
  }
}