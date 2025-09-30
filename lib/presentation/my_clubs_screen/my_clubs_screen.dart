import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/club_service.dart';
import '../../models/club.dart';
import '../../widgets/custom_app_bar.dart';

class MyClubsScreen extends StatefulWidget {
  const MyClubsScreen({super.key});

  @override
  State<MyClubsScreen> createState() => _MyClubsScreenState();
}

class _MyClubsScreenState extends State<MyClubsScreen> {
  final ClubService _clubService = ClubService.instance;
  
  List<Club> _myClubs = [];
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMyClubs();
    
    // Auto-refresh every 30 seconds to check for status updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadMyClubs();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadMyClubs() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final clubs = await _clubService.getMyClubs();

      setState(() {
        _myClubs = clubs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Lỗi tải danh sách CLB: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/club_registration_screen')
              .then((_) => _loadMyClubs());
        },
        tooltip: 'Đăng ký CLB mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return CustomAppBar(
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      ),
      centerTitle: true,
      title: 'CLB của tôi',
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: _loadMyClubs,
          tooltip: 'Làm mới',
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMyClubs,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    if (_myClubs.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadMyClubs,
      child: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: _myClubs.length,
        itemBuilder: (context, index) {
          return _buildClubCard(_myClubs[index]);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Bạn chưa đăng ký CLB nào',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Hãy đăng ký CLB đầu tiên của bạn!',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[500],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/club_registration_screen')
                  .then((_) => _loadMyClubs());
            },
            icon: Icon(Icons.add),
            label: Text('Đăng ký CLB'),
          ),
        ],
      ),
    );
  }

  Widget _buildClubCard(Club club) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with name and status
            Row(
              children: [
                Expanded(
                  child: Text(
                    club.name,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                _buildStatusChip(club.approvalStatus),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Address
            if (club.address != null)
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      club.address!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ],
              ),
            
            SizedBox(height: 8),
            
            // Description
            if (club.description != null)
              Text(
                club.description!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey[700],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            
            SizedBox(height: 12),
            
            // Created at
            Text(
              'Đăng ký: ${_formatDate(club.createdAt)}',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
            
            // Approval info
            if (club.approvalStatus == 'approved' && club.approvedAt != null)
              Text(
                'Được duyệt: ${_formatDate(club.approvedAt!)}',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.green[600],
                ),
              ),
            
            // Rejection reason
            if (club.approvalStatus == 'rejected' && club.rejectionReason != null)
              Container(
                margin: EdgeInsets.only(top: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lý do từ chối:',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      club.rejectionReason!,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.red[600],
                      ),
                    ),
                  ],
                ),
              ),
            
            // Action buttons
            Container(
              margin: EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  if (club.approvalStatus == 'approved') ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(
                            context, 
                            '/club_staff_management',
                            arguments: {'clubId': club.id},
                          );
                        },
                        icon: Icon(Icons.people_alt, size: 16),
                        label: Text('Quản lý nhân viên'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Navigate to club dashboard
                          Navigator.pushNamed(
                            context, 
                            '/club_dashboard',
                            arguments: {'clubId': club.id},
                          );
                        },
                        icon: Icon(Icons.dashboard, size: 16),
                        label: Text('Dashboard'),
                      ),
                    ),
                  ] else if (club.approvalStatus == 'rejected') ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/club_registration_screen')
                              .then((_) => _loadMyClubs());
                        },
                        child: Text('Đăng ký lại'),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Đang chờ duyệt...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String statusText;
    IconData icon;

    switch (status) {
      case 'approved':
        backgroundColor = Colors.green[100]!;
        textColor = Colors.green[700]!;
        statusText = 'Đã duyệt';
        icon = Icons.check_circle;
        break;
      case 'rejected':
        backgroundColor = Colors.red[100]!;
        textColor = Colors.red[700]!;
        statusText = 'Từ chối';
        icon = Icons.cancel;
        break;
      case 'pending':
      default:
        backgroundColor = Colors.orange[100]!;
        textColor = Colors.orange[700]!;
        statusText = 'Chờ duyệt';
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}