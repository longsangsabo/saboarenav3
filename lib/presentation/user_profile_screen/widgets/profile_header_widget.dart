import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'dart:io';

import '../../../core/app_export.dart';
import '../../../core/utils/sabo_rank_system.dart';
import '../../../core/constants/ranking_constants.dart';
import '../../../widgets/privacy_status_widget.dart';


import './rank_registration_info_modal.dart';

class ProfileHeaderWidget extends StatelessWidget {
  const ProfileHeaderWidget({super.key});

} 
  final Map<String, dynamic> userData;
  final VoidCallback? onEditProfile;
  final VoidCallback? onCoverPhotoTap;
  final VoidCallback? onAvatarTap;

  const ProfileHeaderWidget({
    super.key,
    required this.userData,
    this.onEditProfile,
    this.onCoverPhotoTap,
    this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Cover Photo Section
          _buildCoverPhotoSection(context),

          // Profile Info Section
          _buildProfileInfoSection(context),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildCoverPhotoSection(BuildContext context) {
    return SizedBox(
      height: 25.h,
      width: double.infinity,
      child: Stack(
        children: [
          // Cover Photo
          GestureDetector(
            onTap: onCoverPhotoTap,
            child: Container(
              height: 20.h,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: _buildImageWidget(
                  imageUrl: userData["coverPhoto"] as String? ??
                      "https://images.pexels.com/photos/1040473/pexels-photo-1040473.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
                  width: double.infinity,
                  height: 20.h,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Cover Photo Edit Button Only
          Positioned(
            top: 2.h,
            right: 4.w,
            child: GestureDetector(
              onTap: onCoverPhotoTap,
              child: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface
                      .withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
              ),
            ),
          ),

          // Avatar Section
          Positioned(
            bottom: 0,
            left: 6.w,
            child: _buildAvatarSection(context),
          ),

          // Edit Action Button Only
          Positioned(
            bottom: 1.h,
            right: 4.w,
            child: _buildEditButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarSection(BuildContext context) {
    return GestureDetector(
      onTap: onAvatarTap,
      child: Container(
        width: 20.w,
        height: 20.w,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.surface,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.2),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            ClipOval(
              child: _buildImageWidget(
                imageUrl: userData["avatar"] as String? ??
                    "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
                width: 20.w,
                height: 20.w,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.lightTheme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: CustomIconWidget(
                  iconName: 'camera_alt',
                  color: AppTheme.lightTheme.colorScheme.onPrimary,
                  size: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditButton(BuildContext context) {
    return _buildActionButton(
      context: context,
      icon: 'edit',
      label: 'Sửa',
      onTap: onEditProfile,
      backgroundColor: AppTheme.lightTheme.colorScheme.primary,
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback? onTap,
    required Color backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: backgroundColor.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomIconWidget(
              iconName: icon,
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 16,
            ),
            SizedBox(width: 1.w),
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileInfoSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name and Rank
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userData["displayName"] as String? ?? "Nguyễn Văn An",
                      style:
                          AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      userData["bio"] as String? ??
                          "Billiards enthusiast • Tournament player",
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    // Privacy Status Widget
                    if (userData["id"] != null)
                      PrivacyStatusWidget(
                        userId: userData["id"] as String,
                        isOwnProfile: true,
                      ),
                  ],
                ),
              ),
              SizedBox(width: 4.w),
              _buildRankBadge(context),
            ],
          ),

          SizedBox(height: 2.h),

          // ELO Rating with Progress
          _buildEloSection(context),

          SizedBox(height: 2.h),

          // SPA Points and Prize Pool Section
          _buildSpaAndPrizeSection(context),
        ],
      ),
    );
  }

  Widget _buildRankBadge(BuildContext context) {
    final userRank = userData["rank"] as String?;
    final hasRank = userRank != null && userRank.isNotEmpty && userRank != 'unranked';

    // Bọc toàn bộ widget bằng GestureDetector để có thể nhấn vào
    return GestureDetector(
      onTap: () {
        if (hasRank) {
          // Người dùng đã có rank, có thể hiển thị thông tin chi tiết về rank
          _showRankDetails(context);
        } else {
          // Người dùng chưa có rank, hiển thị modal đăng ký
          _showRankInfoModal(context);
        }
      },
      child: _buildRankContent(context, hasRank, userRank),
    );
  }

  // Tách riêng nội dung của rank badge để dễ quản lý
  Widget _buildRankContent(BuildContext context, bool hasRank, String? userRank) {
    if (!hasRank) {
      // Giao diện khi người dùng CHƯA CÓ RANK
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.7), 
            width: 1.5,
          ),
           boxShadow: [
            BoxShadow(
              color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'RANK',
                  style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(width: 1.w),
                GestureDetector(
                  onTap: () => _showRankExplanationDialog(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 12,
                    color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Text(
              '?',
              style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    // Giao diện khi người dùng ĐÃ CÓ RANK
    final currentElo = userData["elo_rating"] as int? ?? 1200;
    final rank = RankingConstants.getRankFromElo(currentElo);
    final rankColor = SaboRankSystem.getRankColor(rank);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
      decoration: BoxDecoration(
        color: rankColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'RANK',
                style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                  color: rankColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(width: 1.w),
              GestureDetector(
                onTap: () => _showRankExplanationDialog(context),
                child: Icon(
                  Icons.info_outline,
                  size: 12,
                  color: rankColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            rank, // Hiển thị rank code (K, I+, etc.)
            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
              color: rankColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 0.3.h),
          Text(
            SaboRankSystem.getRankDisplayName(rank), // Mô tả rank (Người mới, Thợ 3, etc.)
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: rankColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showRankInfoModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => RankRegistrationInfoModal(
        onStartRegistration: () {
          Navigator.pop(context); // Đóng modal trước khi điều hướng
          Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
        },
      ),
    );
  }

  void _showRankDetails(BuildContext context) {
    // Sẽ triển khai sau nếu cần
    debugPrint("TODO: Show Rank Details");
  }

  Widget _buildEloSection(BuildContext context) {
    // Lấy ELO từ elo_rating
    final currentElo = userData["elo_rating"] as int? ?? 1200;
    final nextRankInfo = SaboRankSystem.getNextRankInfo(currentElo);
    final progress = SaboRankSystem.getRankProgress(currentElo);
    final currentRank = RankingConstants.getRankFromElo(currentElo);
    final skillDescription = SaboRankSystem.getRankSkillDescription(currentRank);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'ELO Rating',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 1.w),
                  GestureDetector(
                    onTap: () => _showEloExplanationDialog(context),
                    child: Icon(
                      Icons.info_outline,
                      size: 16,
                      color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              Text(
                SaboRankSystem.formatElo(currentElo),
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          SizedBox(height: 0.5.h),

          // Skill description
          Text(
            skillDescription,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          SizedBox(height: 1.h),

          // Progress Bar
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          SizedBox(height: 0.5.h),

          Text(
            nextRankInfo['pointsNeeded'] > 0 
              ? 'Next rank ${nextRankInfo['nextRank']}: ${nextRankInfo['pointsNeeded"]} points to go"
              : 'Đã đạt rank cao nhất!',
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaAndPrizeSection(BuildContext context) {
    final spaPoints = userData["spa_points"] as int? ?? 0;
    final totalPrizePool = userData["total_prize_pool"] as double? ?? 0.0;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // SPA Points
          Expanded(
            child: _buildStatItem(
              context,
              icon: 'star',
              label: 'SPA Points',
              value: _formatNumber(spaPoints),
              iconColor: Colors.amber[600]!,
            ),
          ),
          
          SizedBox(width: 4.w),
          
          // Prize Pool
          Expanded(
            child: _buildStatItem(
              context,
              icon: 'monetization_on',
              label: 'Prize Pool',
              value: '\$${_formatCurrency(totalPrizePool)}',
              iconColor: Colors.green[600]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String icon,
    required String label,
    required String value,
    required Color iconColor,
  }) {
    return Column(
      children: [
        CustomIconWidget(
          iconName: icon,
          color: iconColor,
          size: 24,
        ),
        SizedBox(height: 0.5.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(width: 1.w),
            GestureDetector(
              onTap: () => _showStatExplanationDialog(context, label),
              child: Icon(
                Icons.info_outline,
                size: 12,
                color: AppTheme.lightTheme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ),
        SizedBox(height: 0.2.h),
        Text(
          value,
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toString();
    }
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    } else if (amount == amount.toInt()) {
      return amount.toInt().toString();
    } else {
      return amount.toStringAsFixed(2);
    }
  }

  Widget _buildImageWidget({
    required String imageUrl,
    required double width,
    required double height,
    BoxFit fit = BoxFit.cover,
  }) {
    // Check if it's a local file path
    if (imageUrl.startsWith('/') || imageUrl.contains('\\')) {
      // Local file path
      return Image.file(
        File(imageUrl),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to network image if file doesn't exist
          return CustomImageWidget(
            imageUrl: "https://images.pexels.com/photos/1040473/pexels-photo-1040473.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1",
            width: width,
            height: height,
            fit: fit,
          );
        },
      );
    } else {
      // Network URL
      return CustomImageWidget(
        imageUrl: imageUrl,
        width: width,
        height: height,
        fit: fit,
      );
    }
  }

  // Hiển thị dialog giải thích ELO Rating
  void _showEloExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.trending_up, color: AppTheme.lightTheme.colorScheme.primary),
            SizedBox(width: 2.w),
            Text('ELO Rating System'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ELO Rating đánh giá trình độ chơi bida dựa trên kết quả tournament.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text(
                '🏆 Thưởng ELO Tournament (Fixed Rewards):',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 1.h),
              _buildEloReward('🥇 1st Place', '+75 ELO', 'Vô địch', Colors.amber),
              _buildEloReward('🥈 2nd Place', '+60 ELO', 'Á quân', Colors.grey[400]!),
              _buildEloReward('🥉 3rd Place', '+45 ELO', 'Hạng 3', Colors.orange),
              _buildEloReward('4th Place', '+35 ELO', 'Hạng 4', Colors.blue),
              _buildEloReward('Top 25%', '+25 ELO', 'Tier trên', Colors.green),
              _buildEloReward('Top 50%', '+15 ELO', 'Tier giữa', Colors.teal),
              _buildEloReward('Top 75%', '+10 ELO', 'Tier dưới', Colors.indigo),
              _buildEloReward('Bottom 25%', '-5 ELO', 'Penalty nhẹ', Colors.red),
              SizedBox(height: 1.h),
              Text(
                '💡 Range: 1000-3000 điểm. Hệ thống Fixed Rewards đảm bảo công bằng!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildEloReward(String position, String reward, String description, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              position,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          Container(
            width: 15.w,
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              reward,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              description,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  // Hiển thị dialog giải thích cho SPA Points và Prize Pool
  void _showStatExplanationDialog(BuildContext context, String statType) {
    String title;
    String description;
    List<String> details;
    IconData icon;
    
    if (statType == 'SPA Points') {
      title = 'SPA Points System';
      icon = Icons.star;
      description = 'SPA Points là điểm thưởng tích lũy được từ các hoạt động trên nền tảng SABO Arena.';
      details = [
        '🎯 Cách kiếm SPA Points:',
        '• Referral Code: +100 SPA (người giới thiệu), +50 SPA (người được giới thiệu)',
        '• Tournament tham gia: 50-150 SPA base (x multiplier theo vị trí)',
        '  - 1st place: x3.0, 2nd: x2.5, 3rd: x2.0',
        '  - Top 25%: x1.5, Top 50%: x1.2, Others: x1.0',
        '• Daily challenges và achievements',
        '',
        '💰 Sử dụng SPA Points:',
        '• SPA Shop: Đổi quà tặng và items',
        '• Premium features và benefits',
        '• Tournament entry fees (tùy chọn)',
      ];
    } else {
      title = 'Prize Pool System';
      icon = Icons.monetization_on;
      description = 'Tổng giá trị tiền thưởng (VNĐ) bạn đã giành được từ tournaments.';
      details = [
        '🏆 Tournament Prize Distribution Templates:',
        '• Standard: 40% / 25% / 15% / 10% / 5% / 5%',
        '• Winner Takes All: 100% cho vô địch',
        '• Top Heavy: 60% / 25% / 15%',
        '• Flat Distribution: 25% / 25% / 25% / 25%',
        '',
        '💰 Prize Pool Sources:',
        '• Entry fees từ participants',
        '• Sponsorship và tài trợ',
        '• Platform contribution',
        '',
        '💳 Prize Withdrawal:',
        '• Rút về tài khoản ngân hàng',
        '• Phí giao dịch: 2% (minimum 10K VNĐ)',
        '• Xử lý trong 1-3 ngày làm việc',
      ];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(icon, color: statType == 'SPA Points' ? Colors.amber : Colors.green),
            SizedBox(width: 2.w),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 2.h),
            ...details.map((detail) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Text(detail),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  // Hiển thị dialog giải thích Rank System
  void _showRankExplanationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.military_tech, color: Colors.purple),
            SizedBox(width: 2.w),
            Text('Vietnamese Billiards Ranking'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Hệ thống rank bida Việt Nam dựa trên điểm ELO và trình độ thực tế.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 2.h),
              Text('🎱 Hệ thống rank K → E+:'),
              SizedBox(height: 1.h),
              _buildRankInfo('K', '1000-1099', 'Người mới (2-4 bi khi hình dễ)', Color(0xFF8B4513)),
              _buildRankInfo('K+', '1100-1199', 'Học việc (sắt ngưỡng lên I)', Color(0xFFA0522D)),
              _buildRankInfo('I', '1200-1299', 'Thợ 3 (5-7 bi khi có hình)', Color(0xFF795548)),
              _buildRankInfo('I+', '1300-1399', 'Thợ 2 (sắt ngưỡng lên H)', Color(0xFF6D4C41)),
              _buildRankInfo('H', '1400-1499', 'Thợ 1 (8-10 bi khi có hình)', Color(0xFF5D4037)),
              _buildRankInfo('H+', '1500-1599', 'Thợ chính (sắt ngưỡng lên G)', Color(0xFF4E342E)),
              _buildRankInfo('G', '1600-1699', 'Thợ giỏi (11-13 bi đẹp)', Color(0xFF3E2723)),
              _buildRankInfo('G+', '1700-1799', 'Cao thủ (sắt ngưỡng lên F)', Color(0xFF2E1916)),
              _buildRankInfo('F', '1800-1899', 'Chuyên gia (14-15 bi clear)', Color(0xFF1B0E0A)),
              _buildRankInfo('F+', '1900-1999', 'Đại cao thủ (sắt ngưỡng lên E)', Color(0xFF000000)),
              _buildRankInfo('E', '2000-2099', 'Huyền thoại (an toàn chủ động)', Color(0xFFB22222)),
              _buildRankInfo('E+', '2100+', 'Vô địch (sắt ngưỡng lên D)', Color(0xFF8B0000)),
              SizedBox(height: 1.h),
              Text(
                '💡 Rank up cần verification, rank down tự động. Hệ thống dựa trên kỹ thuật bida Việt Nam thực tế!',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue[600],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Widget _buildRankInfo(String rank, String range, String description, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Row(
        children: [
          Container(
            width: 8.w,
            padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: color, width: 1),
            ),
            child: Text(
              rank,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              '$range: $description',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
