import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import 'basic_referral_card.dart';
import 'basic_referral_code_input.dart';
import 'basic_referral_stats_widget.dart';

/// Complete Basic Referral Dashboard
/// Combines all referral widgets into a comprehensive dashboard
class BasicReferralDashboard extends StatefulWidget {
  const BasicReferralDashboard({super.key});

} 
  final String userId;
  final bool allowCodeInput;
  final bool showStats;

  const BasicReferralDashboard({
    super.key,
    required this.userId,
    this.allowCodeInput = true,
    this.showStats = true,
  });

  @override
  State<BasicReferralDashboard> createState() => _BasicReferralDashboardState();
}

class _BasicReferralDashboardState extends State<BasicReferralDashboard> {
  final GlobalKey<State<BasicReferralStatsWidget>> _statsKey = GlobalKey();

  void _onStatsUpdate() {
    // Refresh stats when user generates new code or applies code
    // Force widget rebuild to refresh stats
    setState(() {});
  }

  void _onCodeApplied(bool success, String message) {
    // Show result and refresh stats
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
    
    if (success) {
      _onStatsUpdate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🎁 Hệ Thống Giới Thiệu',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(height: 1.w),
                Text(
                  'Giới thiệu bạn bè và nhận thưởng SPA',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // My Referral Code Card
          BasicReferralCard(
            userId: widget.userId,
            onStatsUpdate: _onStatsUpdate,
          ),
          
          // Code Input Section (if allowed)
          if (widget.allowCodeInput) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              child: Divider(
                color: AppTheme.primaryLight.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            BasicReferralCodeInput(
              userId: widget.userId,
              onResult: _onCodeApplied,
            ),
          ],
          
          // Stats Section (if enabled)
          if (widget.showStats) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
              child: Divider(
                color: AppTheme.primaryLight.withOpacity(0.3),
                thickness: 1,
              ),
            ),
            BasicReferralStatsWidget(
              key: _statsKey,
              userId: widget.userId,
            ),
          ],
          
          // How It Works Section
          _buildHowItWorksSection(),
          
          // Footer spacing
          SizedBox(height: 5.w),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection() {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.withOpacity(0.05),
            Colors.indigo.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.help_outline,
                color: Colors.blue.shade700,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Text(
                'Cách Thức Hoạt Động',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 4.w),
          
          _buildStep(
            step: '1',
            title: 'Tạo mã giới thiệu',
            description: 'Nhấn "Tạo Mã Giới Thiệu" để có mã riêng của bạn',
            icon: Icons.add_circle,
            color: Colors.green,
          ),
          
          SizedBox(height: 3.w),
          
          _buildStep(
            step: '2',
            title: 'Chia sẻ với bạn bè',
            description: 'Gửi mã cho bạn bè qua tin nhắn hoặc mạng xã hội',
            icon: Icons.share,
            color: Colors.blue,
          ),
          
          SizedBox(height: 3.w),
          
          _buildStep(
            step: '3',
            title: 'Nhận thưởng SPA',
            description: 'Bạn nhận +100 SPA, bạn bè nhận +50 SPA khi đăng ký',
            icon: Icons.monetization_on,
            color: Colors.orange,
          ),
          
          SizedBox(height: 4.w),
          
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2.w),
              border: Border.all(
                color: Colors.amber.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.amber.shade700,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    'Mẹo: Chia sẻ mã trong các nhóm bida hoặc khi gặp bạn bè mới để tăng cơ hội nhận thưởng!',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.amber.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep({
    required String step,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step,
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      title,
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.w),
              Text(
                description,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Mini referral widget for quick access
class MiniReferralWidget extends StatelessWidget {
  const MiniReferralWidget({super.key});

} 
  final String userId;
  final VoidCallback? onTapExpand;

  const MiniReferralWidget({
    super.key,
    required this.userId,
    this.onTapExpand,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withOpacity(0.1),
            AppTheme.secondaryLight.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTapExpand,
        borderRadius: BorderRadius.circular(2.w),
        child: Row(
          children: [
            Icon(
              Icons.card_giftcard,
              color: AppTheme.primaryLight,
              size: 6.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Giới thiệu bạn bè',
                    style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                  Text(
                    'Nhận +100 SPA mỗi lần giới thiệu',
                    style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.primaryLight.withOpacity(0.7),
              size: 4.w,
            ),
          ],
        ),
      ),
    );
  }
}
