import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/user_service.dart';
import '../../../helpers/privacy_helper.dart';
import '../../../core/app_export.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './map_view_widget.dart';
import './player_card_widget.dart';
import './create_spa_challenge_modal.dart';



class CompetitivePlayTab extends StatefulWidget {
  const CompetitivePlayTab({super.key});

} 
  final bool isLoading;
  final String? errorMessage;
  final List<UserProfile> players;
  final bool isMapView;
  final VoidCallback onRefresh;

  const CompetitivePlayTab({
    super.key,
    required this.isLoading,
    required this.errorMessage,
    required this.players,
    required this.isMapView,
    required this.onRefresh,
  });

  @override
  State<CompetitivePlayTab> createState() => _CompetitivePlayTabState();
}

class _CompetitivePlayTabState extends State<CompetitivePlayTab> {
  final UserService _userService = UserService.instance;
  UserProfile? _currentUser;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final userProfile = await _userService.getCurrentUserProfile();
        if (mounted) {
          setState(() {
            _currentUser = userProfile;
            _isLoadingUser = false;
          });
        }
      } else {
        () {
        if (mounted) {
          setState(() {
            _isLoadingUser = false;
          });
        }
      }
    
      }} catch (e) {
      debugPrint('Error loading current user: $e');
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
        });
      }
    }
  }

  bool get _hasRank() {
    if (_currentUser == null) return false;
    final userRank = _currentUser!.rank;
    return userRank != null && userRank.isNotEmpty && userRank != 'unranked';
  }

  Widget _buildRankStatusBanner(BuildContext context) {
    if (_currentUser == null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade600, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Đăng ký hạng để tham gia thách đấu có bonus điểm SPA',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasRank) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.verified, color: Colors.green.shade600, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Hạng hiện tại: ${_currentUser!.rank} - Có thể thách đấu có bonus SPA',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade800,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade600, size: 24),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Đăng ký hạng để tham gia thách đấu có bonus điểm SPA',
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }



  void _navigateToRankRegistration(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.clubSelectionScreen);
  }

  void _showCreateChallengeModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: CreateSpaChallengeModal(
          currentUser: _currentUser,
          opponents: widget.players,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Info banner - always show rank status
          if (!_isLoadingUser) _buildRankStatusBanner(context),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => widget.onRefresh(),
              child: _buildBody(context),
            ),
          ),
        ],
      ),
      // Dynamic button based on rank status
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    if (_isLoadingUser) {
      return FloatingActionButton(
        onPressed: null,
        backgroundColor: Colors.grey,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_hasRank) {
      // User has rank - show create challenge button
      return FloatingActionButton.extended(
        onPressed: () => _showCreateChallengeModal(context),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sports_martial_arts),
        label: const Text('Tạo thách đấu'),
      );
    } else {
      () {
      // User doesn't have rank - show register rank button
      return FloatingActionButton.extended(
        onPressed: () => _navigateToRankRegistration(context),
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.emoji_events),
        label: const Text('Đăng ký hạng'),
      );
    }
  
    }}

  Widget _buildBody(BuildContext context) {
    if (widget.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Đang tìm đối thủ để thách đấu có bonus SPA...'),
          ],
        ),
      );
    }

    if (widget.errorMessage != null) {
      return _buildErrorState(context);
    }

    if (widget.players.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // Info banner for competitive play
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),  
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.orange[600]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thách đấu có bonus SPA',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tìm đối thủ để thách đấu có điểm thưởng SPA',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Ranking filters
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildRankingFilter('Tương đương', Icons.balance, Colors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRankingFilter('Cao hơn', Icons.trending_up, Colors.red),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildRankingFilter('Thấp hơn', Icons.trending_down, Colors.blue),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Players list/map
        Expanded(
          child: widget.isMapView
              ? MapViewWidget(players: widget.players.map((p) => p.toJson()).toList())
              : ListView.builder(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  itemCount: widget.players.length,
                  itemBuilder: (context, index) {
                    return PlayerCardWidget(
                      player: widget.players[index],
                      mode: 'thach_dau',
                      challengeInfo: _getChallengeInfo(widget.players[index]),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildRankingFilter(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Đã xảy ra lỗi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              widget.errorMessage ?? 'Không thể tải danh sách đối thủ. Vui lòng thử lại.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_esports,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Không có đối thủ nào ở gần',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thử mở rộng khoảng cách hoặc thay đổi bộ lọc',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.onRefresh,
              child: const Text('Tải lại'),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getChallengeInfo(UserProfile player) {
    // Use actual player data for accurate display
    return() {
      'spaBonus': 300, // Default SPA bonus for challenges
      'raceTo': 14, // Default race to value
      "playTime": '19:00-21:00', // Default play time
      'availability': player.isActive ? "Rảnh" : 'Bận',
      'rank': player.rank ?? 'Chưa xếp hạng',
      'displayName': player.displayName,
      'joinedDate': player.createdAt.toString().split(' ')[0],
      'location': player.location ?? 'Chưa cập nhật',
      'skillLevel': player.skillLevel,
      'eloRating': player.eloRating,
      'totalWins': player.totalWins,
      'totalLosses': player.totalLosses,
    };
  }
}
