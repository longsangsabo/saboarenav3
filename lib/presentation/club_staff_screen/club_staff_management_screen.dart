import 'package:flutter/material.dart';
import '../../widgets/club_staff_manager.dart';
import '../../widgets/club_staff_commission_demo.dart';
import '../../services/club_staff_service.dart';

class ClubStaffManagementScreen extends StatefulWidget {
  final String clubId;
  
  const ClubStaffManagementScreen({
    Key? key,
    required this.clubId,
  }) : super(key: key);

  @override
  State<ClubStaffManagementScreen> createState() => _ClubStaffManagementScreenState();
}

class _ClubStaffManagementScreenState extends State<ClubStaffManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ClubStaffService _staffService = ClubStaffService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quản lý Nhân viên & Hoa hồng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.people),
              text: 'Nhân viên',
            ),
            Tab(
              icon: Icon(Icons.analytics),
              text: 'Hoa hồng',
            ),
            Tab(
              icon: Icon(Icons.play_circle),
              text: 'Demo',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Staff Management
          ClubStaffManager(clubId: widget.clubId),
          
          // Tab 2: Commission Analytics
          _buildCommissionAnalytics(),
          
          // Tab 3: Demo
          ClubStaffCommissionDemo(),
        ],
      ),
    );
  }

  Widget _buildCommissionAnalytics() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.trending_up, color: Colors.green, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Thống kê Hoa hồng',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  FutureBuilder<Map<String, dynamic>>(
                    future: _getCommissionSummary(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      
                      if (snapshot.hasError) {
                        return Text('Lỗi: ${snapshot.error}');
                      }
                      
                      final data = snapshot.data ?? {};
                      
                      return Column(
                        children: [
                          _buildStatCard(
                            'Tổng Hoa hồng',
                            '${_formatCurrency(data['totalCommissions'] ?? 0)}',
                            Icons.monetization_on,
                            Colors.green,
                          ),
                          SizedBox(height: 12),
                          _buildStatCard(
                            'Số nhân viên',
                            '${data['totalStaff'] ?? 0}',
                            Icons.people,
                            Colors.blue,
                          ),
                          SizedBox(height: 12),
                          _buildStatCard(
                            'Khách hàng giới thiệu',
                            '${data['totalReferrals'] ?? 0}',
                            Icons.person_add,
                            Colors.orange,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top Nhân viên',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _getTopStaff(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Text('Lỗi: ${snapshot.error}');
                          }
                          
                          final staffList = snapshot.data ?? [];
                          
                          if (staffList.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline, size: 48, color: Colors.grey),
                                  SizedBox(height: 8),
                                  Text('Chưa có nhân viên nào'),
                                ],
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: staffList.length,
                            itemBuilder: (context, index) {
                              final staff = staffList[index];
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.deepPurple,
                                  child: Text(
                                    '${index + 1}',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(staff['full_name'] ?? 'N/A'),
                                subtitle: Text('${staff['staff_role'] ?? 'Staff'}'),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${_formatCurrency(staff['total_commissions'] ?? 0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Text(
                                      '${staff['referral_count'] ?? 0} khách',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
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
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _getCommissionSummary() async {
    try {
      // Get club staff analytics
      final analytics = await _staffService.getClubStaffAnalytics(widget.clubId);
      return {
        'totalCommissions': analytics['total_commissions'] ?? 0,
        'totalStaff': analytics['total_staff'] ?? 0,
        'totalReferrals': analytics['total_referrals'] ?? 0,
      };
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> _getTopStaff() async {
    try {
      return await _staffService.getClubStaffList(widget.clubId);
    } catch (e) {
      return [];
    }
  }

  String _formatCurrency(dynamic amount) {
    if (amount == null) return '0đ';
    final value = amount is String ? double.tryParse(amount) ?? 0 : (amount as num).toDouble();
    return '${value.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}đ';
  }
}