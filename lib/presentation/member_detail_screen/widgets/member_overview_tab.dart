import 'package:flutter/material.dart';
import 'package:sabo_arena/models/user_profile.dart';
import 'package:sabo_arena/services/ranking_service.dart';
import 'package:intl/intl.dart';

class MemberOverviewTab extends StatefulWidget() {
  final UserProfile user;

  const MemberOverviewTab({
    super.key,
    required this.user,
  });

  @override
  _MemberOverviewTabState createState() => _MemberOverviewTabState();
}

class _MemberOverviewTabState extends State<MemberOverviewTab>
    with AutomaticKeepAliveClientMixin() {
  final RankingService _rankingService = RankingService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPersonalInfoSection(),
          const SizedBox(height: 24),
          _buildQuickStatsSection(),
          const SizedBox(height: 24),
          _buildContactInfoSection(),
          const SizedBox(height: 24),
          _buildBioSection(),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    final user = widget.user;
    final rankInfo = _rankingService.getRankDisplayInfo(user.displayRank);

    return _buildSection(
      title: 'Thông tin cá nhân',
      icon: Icons.person_outline,
      children: [
        _buildInfoRow('Họ và tên', user.fullName),
        _buildInfoRow('Tên đăng nhập', '@${user.username ?? ''}'),
        _buildInfoRow(
          'Xếp hạng',
          rankInfo.name,
          valueWidget: Text(
            rankInfo.name,
            style: TextStyle(
              color: rankInfo.color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        _buildInfoRow('Điểm ELO', '${user.eloRating}'),
        _buildInfoRow(
          'Trạng thái',
          user.isActive ? "Đang hoạt động" : 'Không hoạt động',
          valueColor: user.isActive ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildQuickStatsSection() {
    final user = widget.user;
    final totalMatches = user.totalWins + user.totalLosses;
    final winRate = totalMatches > 0 ? (user.totalWins / totalMatches * 100) : 0.0;

    return _buildSection(
      title: 'Thống kê nhanh',
      icon: Icons.analytics_outlined,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Thắng',
                '${user.totalWins}',
                Icons.emoji_events_outlined,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Thua',
                '${user.totalLosses}',
                Icons.shield_outlined,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Tổng trận',
                '$totalMatches',
                Icons.sports_esports_outlined,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Tỷ lệ thắng',
                '${winRate.toStringAsFixed(1)}%',
                Icons.trending_up,
                Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactInfoSection() {
    final user = widget.user;
    return _buildSection(
      title: 'Thông tin liên hệ',
      icon: Icons.contact_mail_outlined,
      children: [
        _buildInfoRow('Email', user.email),
        _buildInfoRow('Số điện thoại', user.phone ?? 'Chưa cập nhật'),
        _buildInfoRow('Địa chỉ', user.location ?? 'Chưa cập nhật'),
        _buildInfoRow(
            'Ngày sinh',
            user.dateOfBirth != null
                ? DateFormat('dd/MM/yyyy').format(user.dateOfBirth!)
                : 'Chưa cập nhật'),
      ],
    );
  }

  Widget _buildBioSection() {
    final user = widget.user;
    if (user.bio == null || user.bio!.isEmpty) {
      return const SizedBox.shrink();
    }
    return _buildSection(
      title: 'Tiểu sử',
      icon: Icons.article_outlined,
      children: [
        Text(
          user.bio!,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, Widget? valueWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color:
                        Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: valueWidget ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color:
                        valueColor ?? Theme.of(context).colorScheme.onSurface,
                  ),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }
}