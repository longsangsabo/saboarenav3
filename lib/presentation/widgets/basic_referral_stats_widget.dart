import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/basic_referral_service.dart';

/// Basic Referral Stats Widget
/// Simple dashboard showing referral statistics and SPA earned
class BasicReferralStatsWidget extends StatefulWidget {
  const BasicReferralStatsWidget({super.key});

} 
  final String userId;
  final bool showTitle;

  const BasicReferralStatsWidget({
    super.key,
    required this.userId,
    this.showTitle = true,
  });

  @override
  State<BasicReferralStatsWidget> createState() => _BasicReferralStatsWidgetState();
}

class _BasicReferralStatsWidgetState extends State<BasicReferralStatsWidget> {
  Map<String, dynamic>? _stats;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    
    try {
      final stats = await BasicReferralService.getUserReferralStats(widget.userId);
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading referral stats: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshStats() async {
    await _loadStats();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: AppTheme.primaryLight,
                  size: 6.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Thống Kê Giới Thiệu',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isLoading ? null : _refreshStats,
                  icon: Icon(
                    Icons.refresh,
                    color: AppTheme.primaryLight,
                    size: 5.w,
                  ),
                  tooltip: 'Làm mới thống kê',
                ),
              ],
            ),
            SizedBox(height: 4.w),
          ],
          
          if (_isLoading)
            _buildLoadingState()
          else if (_stats != null)
            _buildStatsContent()
          else
            _buildErrorState(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 40.w,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
            SizedBox(height: 3.w),
            Text(
              'Đang tải thống kê...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return SizedBox(
      height: 30.w,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.grey,
              size: 10.w,
            ),
            SizedBox(height: 2.w),
            Text(
              'Không thể tải thống kê',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey,
              ),
            ),
            SizedBox(height: 2.w),
            ElevatedButton.icon(
              onPressed: _refreshStats,
              icon: Icon(Icons.refresh, size: 4.w),
              label: Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsContent() {
    final referralCode = _stats?['user_code'] ?? 'Chưa có';
    final totalReferred = _stats?['total_referred'] ?? 0;
    final totalSpaEarned = _stats?['total_spa_earned'] ?? 0;
    final isActive = _stats?['is_active'] ?? false;

    return Column(
      children: [
        // Current Referral Code
        _buildStatCard(
          icon: Icons.code,
          title: 'Mã Giới Thiệu',
          value: referralCode,
          color: AppTheme.primaryLight,
          isCode: true,
        ),
        
        SizedBox(height: 3.w),
        
        // Stats Grid
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.group_add,
                title: 'Số Lượng\nGiới Thiệu',
                value: totalReferred.toString(),
                color: Colors.blue,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                icon: Icons.monetization_on,
                title: 'Tổng SPA\nNhận Được',
                value: totalSpaEarned.toString(),
                color: Colors.orange,
              ),
            ),
          ],
        ),
        
        SizedBox(height: 3.w),
        
        // Status Badge
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(2.w),
            border: Border.all(
              color: isActive ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isActive ? Icons.check_circle : Icons.pause_circle,
                color: isActive ? Colors.green : Colors.grey,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Text(
                isActive ? "Mã đang hoạt động" : 'Mã chưa kích hoạt',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        
        if (totalReferred > 0) ...[
          SizedBox(height: 3.w),
          _buildSpaBreakdown(totalReferred, totalSpaEarned),
        ],
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isCode = false,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 6.w,
          ),
          SizedBox(height: 2.w),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 1.w),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaBreakdown(int totalReferred, int totalSpaEarned) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calculate,
                color: Colors.amber.shade700,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                'Chi Tiết SPA',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.w),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Số người giới thiệu:',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                '$totalReferred người',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPA mỗi lần giới thiệu:',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
              Text(
                '100 SPA',
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Divider(color: Colors.amber.withOpacity(0.3)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tổng SPA đã nhận:',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$totalSpaEarned SPA',
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Compact stats widget for inline display
class CompactReferralStats extends StatelessWidget {
  const CompactReferralStats({super.key});

} 
  final String userId;

  const CompactReferralStats({
    super.key,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return BasicReferralStatsWidget(
      userId: userId,
      showTitle: false,
    );
  }
}
