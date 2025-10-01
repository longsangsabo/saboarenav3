import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../widgets/basic_referral_dashboard.dart';
import '../widgets/basic_referral_card.dart';
import '../widgets/basic_referral_code_input.dart';
import '../widgets/basic_referral_stats_widget.dart';

/// Example page showing how to integrate basic referral components
/// This demonstrates different usage patterns and layouts
class BasicReferralExamplePage extends StatefulWidget {
  const BasicReferralExamplePage({super.key});

} 
  final String userId;

  const BasicReferralExamplePage({
    super.key,
    this.userId = 'demo-user-123', // Default demo user ID
  });

  @override
  State<BasicReferralExamplePage> createState() => _BasicReferralExamplePageState();
}

class _BasicReferralExamplePageState extends State<BasicReferralExamplePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: Text(
          'Referral System Demo',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withOpacity(0.7),
          indicatorColor: Colors.white,
          tabs: [
            Tab(icon: Icon(Icons.dashboard), text: 'Dashboard'),
            Tab(icon: Icon(Icons.card_giftcard), text: 'My Code'),
            Tab(icon: Icon(Icons.code), text: 'Enter Code'),
            Tab(icon: Icon(Icons.analytics), text: 'Stats'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Complete Dashboard
          _buildDashboardTab(),
          
          // My Referral Code Only
          _buildMyCodeTab(),
          
          // Code Input Only
          _buildCodeInputTab(),
          
          // Stats Only
          _buildStatsTab(),
        ],
      ),
    );
  }

  Widget _buildDashboardTab() {
    return BasicReferralDashboard(
      userId: widget.userId,
      allowCodeInput: true,
      showStats: true,
    );
  }

  Widget _buildMyCodeTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 4.w),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Mã Giới Thiệu Của Bạn',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          
          // Referral Card
          BasicReferralCard(
            userId: widget.userId,
          ),
          
          // Mini Widget Example
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            child: Text(
              'Mini Widget Example:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          MiniReferralWidget(
            userId: widget.userId,
            onTapExpand: () {
              _tabController.animateTo(0); // Go to dashboard
            },
          ),
          
          SizedBox(height: 5.w),
        ],
      ),
    );
  }

  Widget _buildCodeInputTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 4.w),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nhập Mã Giới Thiệu',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  'Có mã giới thiệu từ bạn bè? Nhập vào đây để nhận 50 SPA miễn phí!',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Code Input
          BasicReferralCodeInput(
            userId: widget.userId,
            onResult: (success, message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
          ),
          
          // Compact Version Example
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            child: Text(
              'Compact Version:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          CompactReferralCodeInput(
            userId: widget.userId,
            onResult: (success, message) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Compact: $message'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
          ),
          
          SizedBox(height: 5.w),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 4.w),
          
          // Header
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            child: Text(
              'Thống Kê Giới Thiệu',
              style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          
          // Stats Widget
          BasicReferralStatsWidget(
            userId: widget.userId,
          ),
          
          // Compact Version Example
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            child: Text(
              'Compact Version:',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          CompactReferralStats(
            userId: widget.userId,
          ),
          
          SizedBox(height: 5.w),
        ],
      ),
    );
  }
}

/// Quick access floating action button for referrals
class ReferralFloatingActionButton extends StatelessWidget {
  const ReferralFloatingActionButton({super.key});

} 
  final String userId;
  final VoidCallback? onPressed;

  const ReferralFloatingActionButton({
    super.key,
    required this.userId,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed ?? () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BasicReferralExamplePage(userId: userId),
          ),
        );
      },
      backgroundColor: AppTheme.primaryLight,
      foregroundColor: Colors.white,
      icon: Icon(Icons.card_giftcard),
      label: Text('Giới thiệu'),
    );
  }
}

/// Simple referral status indicator
class ReferralStatusIndicator extends StatefulWidget {
  const ReferralStatusIndicator({super.key});

} 
  final String userId;

  const ReferralStatusIndicator({
    super.key,
    required this.userId,
  });

  @override
  State<ReferralStatusIndicator> createState() => _ReferralStatusIndicatorState();
}

class _ReferralStatusIndicatorState extends State<ReferralStatusIndicator> {
  int _totalReferred = 0;
  int _totalSpaEarned = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      // This would load from BasicReferralService
      // For demo purposes, showing sample data
      await Future.delayed(Duration(seconds: 1));
      
      setState(() {
        _totalReferred = 3;
        _totalSpaEarned = 300;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        padding: EdgeInsets.all(2.w),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 4.w,
              height: 4.w,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 2.w),
            Text('Loading...', style: AppTheme.lightTheme.textTheme.bodySmall),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.group_add,
            color: AppTheme.primaryLight,
            size: 4.w,
          ),
          SizedBox(width: 1.w),
          Text(
            '$_totalReferred',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(width: 2.w),
          Icon(
            Icons.monetization_on,
            color: Colors.orange,
            size: 4.w,
          ),
          SizedBox(width: 1.w),
          Text(
            '$_totalSpaEarned',
            style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
        ],
      ),
    );
  }
}
