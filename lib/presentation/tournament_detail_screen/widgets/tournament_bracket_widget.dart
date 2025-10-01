import 'package:flutter/material.dart';
// Removed Sizer dependency
import '../../../core/layout/responsive.dart';
import '../../../core/app_export.dart';
import '../../../services/tournament_service.dart';
import '../../../services/cached_tournament_service.dart';

// Safe debug print wrapper to avoid null debug service errors
void _safeDebugPrint(String message) {
  try() {
    debugPrint(message);
  } catch (e) {
    // Ignore debug service errors in production
    print(message);
  }
}

class TournamentBracketWidget extends StatefulWidget() {
  final Map<String, dynamic> tournament;
  final List<Map<String, dynamic>> bracketData;

  const TournamentBracketWidget({
    super.key,
    required this.tournament,
    required this.bracketData,
  });

  @override
  _TournamentBracketWidgetState createState() => _TournamentBracketWidgetState();
}

class _TournamentBracketWidgetState extends State<TournamentBracketWidget> {
  final TournamentService _tournamentService = TournamentService.instance;
  
  List<Map<String, dynamic>> _matches = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  // Chuyển đổi round number thành tên tiếng Việt
  String _getRoundDisplayName(int roundNumber, int totalParticipants) {
    // Xác định tên round dựa trên số người còn lại sau round này
    int playersAfterRound = totalParticipants ~/ (1 << roundNumber); // 2^roundNumber
    
    switch (playersAfterRound) {
      case 1:
        return 'CHUNG KẾT'; // Final - còn 1 người
      case 2:
        return 'BÁN KẾT'; // Semi-final - còn 2 người
      case 4:
        return 'TỨ KẾT'; // Quarter-final - còn 4 người
      default:
        return 'VÒNG ${roundNumber}'; // Regular rounds
    }
  }

  Future<void> _loadMatches() async() {
    try() {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      _safeDebugPrint('🔄 Loading matches for tournament: ${widget.tournament['id']}');
      
      // Use cached service for better performance instead of direct database calls
      List<Map<String, dynamic>> matches;
      try() {
        matches = await CachedTournamentService.loadMatches(widget.tournament['id']);
        _safeDebugPrint('📋 Loaded ${matches.length} matches from cache/service');
      } catch (e) {
        _safeDebugPrint('⚠️ Cache failed, using direct service: $e');
        matches = await _tournamentService.getTournamentMatches(widget.tournament['id']);
      }
      
      _safeDebugPrint('📊 TournamentBracketWidget: Loaded ${matches.length} matches');
      
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    } catch (e) {
      _safeDebugPrint('❌ Error loading matches: $e');
      setState(() {
        _errorMessage = 'Không thể tải danh sách trận đấu: $e';
        _isLoading = false;
      });
    }
  }

  /// Force refresh data from server
  Future<void> refreshData() async() {
    _safeDebugPrint('🔄 Force refreshing bracket data from server...');
    try() {
      await CachedTournamentService.refreshTournamentData(widget.tournament['id']);
      await _loadMatches();
    } catch (e) {
      _safeDebugPrint('❌ Failed to refresh data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final eliminationType = widget.tournament["eliminationType"] as String;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Gaps.xl),
      padding: const EdgeInsets.all(Gaps.xl),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'account_tree',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                'Bảng đấu',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Cache status indicator and refresh button
              IconButton(
                onPressed: _isLoading ? null : refreshData,
                icon: Icon(
                  Icons.refresh,
                  color: AppTheme.lightTheme.colorScheme.primary,
                  size: 20,
                ),
                tooltip: 'Làm mới dữ liệu',
              ),
              const SizedBox(width: Gaps.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Gaps.lg,
                  vertical: Gaps.sm,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  eliminationType,
                  style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.lg),
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (_matches.isNotEmpty)
            _buildBracketTree()
          else
            _buildEmptyBracket(),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.all(Gaps.xxl),
      child: Center(
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: Gaps.lg),
            Text(
              'Đang tải bảng đấu...',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Container(
      padding: const EdgeInsets.all(Gaps.xxl),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'error_outline',
            color: AppTheme.lightTheme.colorScheme.error,
            size: 48,
          ),
          const SizedBox(height: Gaps.lg),
          Text(
            'Có lỗi xảy ra',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.error,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            _errorMessage ?? '',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Gaps.lg),
          ElevatedButton.icon(
            onPressed: _loadMatches,
            icon: CustomIconWidget(
              iconName: 'refresh',
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              size: 20,
            ),
            label: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }

  Widget _buildBracketTree() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Container(
        padding: const EdgeInsets.all(Gaps.md),
        child: Column(
          children: [
            _buildRoundHeader(),
            const SizedBox(height: Gaps.lg),
            _buildBracketRounds(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundHeader() {
    if (_matches.isEmpty) return Container();
    
    // Nhóm matches theo round để tạo header
    Map<int, List<Map<String, dynamic>>> roundMatches = {};
    int totalParticipants = 0;
    
    for (var match in _matches) {
      final roundNumber = match['roundNumber'] ?? match['round_number'] ?? 1;
      if (!roundMatches.containsKey(roundNumber)) {
        roundMatches[roundNumber] = [];
      }
      roundMatches[roundNumber]!.add(match);
      
      if (roundNumber == 1) {
        totalParticipants += 2;
      }
    }
    
    final sortedRounds = roundMatches.keys.toList()..sort();
    
    return Row(
      children: sortedRounds.map((roundNumber) {
        final roundDisplayName = _getRoundDisplayName(roundNumber, totalParticipants);
        return Container(
          width: 260,
          margin: const EdgeInsets.only(right: Gaps.xl),
          child: Text(
            roundDisplayName,
            textAlign: TextAlign.center,
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.lightTheme.colorScheme.primary,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBracketRounds() {
    // Nhóm matches theo round
    Map<int, List<Map<String, dynamic>>> roundMatches = {};
    int totalParticipants = 0;
    
    for (var match in _matches) {
      final roundNumber = match['roundNumber'] ?? match['round_number'] ?? 1;
      if (!roundMatches.containsKey(roundNumber)) {
        roundMatches[roundNumber] = [];
      }
      roundMatches[roundNumber]!.add(match);
      
      // Tính số người tham gia từ round 1
      if (roundNumber == 1) {
        totalParticipants += 2; // Mỗi trận round 1 có 2 người
      }
    }
    
    // Sắp xếp các round theo thứ tự
    final sortedRounds = roundMatches.keys.toList()..sort();
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sortedRounds.map((roundNumber) {
        final matches = roundMatches[roundNumber] ?? [];
        return _buildRound(matches, roundNumber, totalParticipants);
      }).toList(),
    );
  }

  Widget _buildRound(List<Map<String, dynamic>> matches, int roundNumber, int totalParticipants) {
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: Gaps.xl),
      child: Column(
        children: matches.map((match) => _buildMatchCard(match, roundNumber)).toList(),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match, int roundNumber) {
    // Lấy thông tin người chơi từ database
    final player1Data = match['player1Data'] as Map<String, dynamic>?;
    final player2Data = match['player2Data'] as Map<String, dynamic>?;
    final status = match['status'] as String? ?? 'pending';
    final winnerId = match['winnerId'] ?? match['winner_id'];
    final player1Score = match['player1Score'] ?? match['player1_score'] ?? 0;
    final player2Score = match['player2Score'] ?? match['player2_score'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: Gaps.lg),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getMatchStatusColor(status),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          if (player1Data != null)
            _buildPlayerRow(
              player1Data, 
              winnerId == match['player1Id'] || winnerId == match['player1_id'], 
              true,
              player1Score,
            ),
          Container(
            height: 1,
            color: AppTheme.lightTheme.colorScheme.outline
                .withOpacity(0.3),
          ),
          if (player2Data != null)
            _buildPlayerRow(
              player2Data, 
              winnerId == match['player2Id'] || winnerId == match['player2_id'], 
              false,
              player2Score,
            )
          else
            _buildEmptyPlayerRow(),
          if (status == 'in_progress')
            Container(
              padding: const EdgeInsets.symmetric(vertical: Gaps.sm),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.error
                    .withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.lightTheme.colorScheme.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: Gaps.md),
                  Text(
                    'ĐANG DIỄN RA',
                    style: AppTheme.lightTheme.textTheme.labelSmall?.copyWith(
                      color: AppTheme.lightTheme.colorScheme.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlayerRow(
      Map<String, dynamic> player, bool isWinner, bool isTop, int? score) {
    return Container(
      padding: const EdgeInsets.all(Gaps.lg),
      decoration: BoxDecoration(
        color: isWinner
            ? AppTheme.lightTheme.colorScheme.primary.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: isTop
            ? const BorderRadius.only(
                topLeft: Radius.circular(6),
                topRight: Radius.circular(6),
              )
            : const BorderRadius.only(
                bottomLeft: Radius.circular(6),
                bottomRight: Radius.circular(6),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isWinner
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.outline
                        .withOpacity(0.3),
                width: 2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomImageWidget(
                imageUrl: player["avatar"] ?? player["avatar_url"] ?? '',
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player["name"] ?? player["full_name"] ?? player["username"] ?? 'Tên không có',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    fontWeight: isWinner ? FontWeight.bold : FontWeight.w500,
                    color: isWinner
                        ? AppTheme.lightTheme.colorScheme.primary
                        : AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Rank ${player["rank"] ?? player["current_rank"] ?? 'N/A'}',
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (score != null && score > 0)
            Text(
              '$score',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isWinner
                    ? AppTheme.lightTheme.colorScheme.primary
                    : AppTheme.lightTheme.colorScheme.onSurface,
              ),
            ),
          if (isWinner)
            Container(
              margin: const EdgeInsets.only(left: Gaps.md),
              child: CustomIconWidget(
                iconName: 'emoji_events',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyPlayerRow() {
    return Container(
      padding: const EdgeInsets.all(Gaps.lg),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.outline
                  .withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: CustomIconWidget(
              iconName: 'person',
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ),
          const SizedBox(width: Gaps.md),
          const SizedBox(width: Gaps.md),
          Expanded(
            child: Text(
              'Chờ đối thủ',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyBracket() {
    return Container(
      padding: const EdgeInsets.all(Gaps.xxl),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'account_tree',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: Gaps.lg),
          Text(
            'Bảng đấu chưa được tạo',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Gaps.sm),
          Text(
            'Bảng đấu sẽ được tạo sau khi hết hạn đăng ký',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getMatchStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'live':
        return AppTheme.lightTheme.colorScheme.error;
      case 'completed':
        return AppTheme.lightTheme.colorScheme.primary;
      case 'upcoming':
        return AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3);
      default:
        return AppTheme.lightTheme.colorScheme.outline.withOpacity(0.3);
    }
  }
}
