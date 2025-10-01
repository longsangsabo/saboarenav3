import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/tournament_service.dart';
import 'widgets/tournament_status_panel.dart';
import 'widgets/match_management_tab.dart';
import 'widgets/tournament_rankings_widget.dart';

class SingleTournamentManagementScreen extends StatefulWidget() {
  final String tournamentId;
  final String tournamentName;
  final bool canManage;

  const SingleTournamentManagementScreen({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.canManage = false,
  });

  @override
  State<SingleTournamentManagementScreen> createState() => _SingleTournamentManagementScreenState();
}

class _SingleTournamentManagementScreenState extends State<SingleTournamentManagementScreen>
    with SingleTickerProviderStateMixin() {
  late TabController _tabController;
  final TournamentService _tournamentService = TournamentService.instance;
  
  Map<String, dynamic>? _tournamentData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTournamentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTournamentData() async() {
    try() {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final tournamentData = await _tournamentService.getTournamentById(widget.tournamentId);
      
      if (mounted) {
        setState(() {
          _tournamentData = tournamentData.toJson();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quản lý giải đấu',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.tournamentName,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.normal,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(
              icon: Icon(Icons.dashboard),
              text: 'Tổng quan',
            ),
            Tab(
              icon: Icon(Icons.sports_esports),
              text: 'Trận đấu',
            ),
            Tab(
              icon: Icon(Icons.leaderboard),
              text: 'Bảng xếp hạng',
            ),
          ],
        ),
      ),
      body: _isLoading 
          ? _buildLoadingState()
          : _error != null
              ? _buildErrorState()
              : _buildContent(),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 16.sp),
          Text(
            'Đang tải dữ liệu giải đấu...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64.sp,
              color: Colors.red[300],
            ),
            SizedBox(height: 24.sp),
            Text(
              'Lỗi khi tải dữ liệu',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            SizedBox(height: 12.sp),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.sp),
            ElevatedButton.icon(
              onPressed: _loadTournamentData,
              icon: Icon(Icons.refresh),
              label: Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.sp,
                  vertical: 12.sp,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final tournamentStatus = _tournamentData?['status'] ?? 'recruiting';

    return TabBarView(
      controller: _tabController,
      children: [
        // Overview Tab
        _buildOverviewTab(tournamentStatus),
        
        // Matches Tab  
        _buildMatchesTab(tournamentStatus),
        
        // Rankings Tab
        _buildRankingsTab(tournamentStatus),
      ],
    );
  }

  Widget _buildOverviewTab(String tournamentStatus) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tournament Status Panel
          TournamentStatusPanel(
            tournamentId: widget.tournamentId,
            currentStatus: tournamentStatus,
            canManage: widget.canManage,
            onStatusChanged: _loadTournamentData,
          ),
          
          // Tournament Information Card
          _buildTournamentInfoCard(),
          
          // Participants Summary
          _buildParticipantsSummaryCard(),
          
          SizedBox(height: 16.sp),
        ],
      ),
    );
  }

  Widget _buildMatchesTab(String tournamentStatus) {
    return MatchManagementTab(
      tournamentId: widget.tournamentId,
    );
  }

  Widget _buildRankingsTab(String tournamentStatus) {
    return SingleChildScrollView(
      child: TournamentRankingsWidget(
        tournamentId: widget.tournamentId,
        tournamentStatus: tournamentStatus,
      ),
    );
  }

  Widget _buildTournamentInfoCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue[600],
                size: 20.sp,
              ),
              SizedBox(width: 8.sp),
              Text(
                'Thông tin giải đấu',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          _buildInfoRow('Format', _tournamentData?['tournament_type'] ?? 'N/A'),
          _buildInfoRow('Ngày bắt đầu', _formatDate(_tournamentData?['start_date'])),
          _buildInfoRow('Ngày kết thúc', _formatDate(_tournamentData?['end_date'])),
          _buildInfoRow('Phí tham gia', '${_tournamentData?['entry_fee'] ?? 0} coins'),
          _buildInfoRow('Giải thưởng', '${_tournamentData?['prize_pool'] ?? 0} coins'),
        ],
      ),
    );
  }

  Widget _buildParticipantsSummaryCard() {
    final currentParticipants = _tournamentData?['current_participants'] ?? 0;
    final maxParticipants = _tournamentData?['max_participants'] ?? 0;
    final percentage = maxParticipants > 0 ? (currentParticipants / maxParticipants) : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.group,
                color: Colors.green[600],
                size: 20.sp,
              ),
              SizedBox(width: 8.sp),
              Text(
                'Người tham gia',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          Row(
            children: [
              Text(
                '$currentParticipants',
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[600],
                ),
              ),
              Text(
                ' / $maxParticipants',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: 8.sp),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green[600]!),
          ),
          SizedBox(height: 8.sp),
          Text(
            '${(percentage * 100).toStringAsFixed(1)}% đã đăng ký',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.sp),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.sp,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12.sp,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try() {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}