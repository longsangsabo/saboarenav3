// 🎯 SABO ARENA - Bracket Management Tab
// Real tournament bracket management with live participant data
// Integrates bracket generation, visualization and progression

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/tournament.dart';
import '../../../services/correct_bracket_logic_service.dart';
// import '../../../services/tournament_progress_service.dart'; // Currently unused
import '../../../services/bracket_visualization_service.dart';
import '../../../services/tournament_service.dart';

class BracketManagementTab extends StatefulWidget {
  const BracketManagementTab({super.key});

} 
  final Tournament tournament;

  const BracketManagementTab({
    super.key,
    required this.tournament,
  });

  @override
  State<BracketManagementTab> createState() => _BracketManagementTabState();
}

class _BracketManagementTabState extends State<BracketManagementTab> {
  final CorrectBracketLogicService _bracketService = CorrectBracketLogicService.instance;
  final TournamentService _tournamentService = TournamentService.instance;
  // final TournamentProgressService _progressService = TournamentProgressService.instance; // Currently unused
  final BracketVisualizationService _visualizationService = BracketVisualizationService.instance;

  bool _isLoading = false;
  bool _hasBracket = false;
  Map<String, dynamic>? _bracketData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBracketData();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: 2.h),
          
          if (_isLoading)
            _buildLoadingState()
          else if (_errorMessage != null)
            _buildErrorState()
          else if (!_hasBracket)
            _buildNoBracketState()
          else
            _buildBracketView(),
        ],
      ),
    );
  }

  /// Header with bracket controls
  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E86AB), Color(0xFF1B5E7D)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.account_tree,
              color: Colors.white,
              size: 6.w,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bracket Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.tournament.title,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (_hasBracket)
            _buildBracketActions(),
        ],
      ),
    );
  }

  /// Bracket action buttons
  Widget _buildBracketActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _refreshBracket,
          icon: const Icon(Icons.refresh, color: Colors.white),
          tooltip: 'Refresh Bracket',
        ),
        IconButton(
          onPressed: _regenerateBracket,
          icon: const Icon(Icons.autorenew, color: Colors.white),
          tooltip: 'Regenerate Bracket',
        ),
      ],
    );
  }

  /// Loading state
  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFF2E86AB),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Loading bracket data...',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error state
  Widget _buildErrorState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 15.w,
            ),
            SizedBox(height: 2.h),
            Text(
              'Error loading bracket',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: _loadBracketData,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E86AB),
                foregroundColor: Colors.white,
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  /// No bracket state
  Widget _buildNoBracketState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_tree_outlined,
              color: Colors.grey[400],
              size: 20.w,
            ),
            SizedBox(height: 3.h),
            Text(
              'Chưa có sơ đồ bảng đấu',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Hãy tạo bảng đấu để bắt đầu giải',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey[500],
              ),
            ),
            SizedBox(height: 3.h),
            _buildTournamentInfo(),
          ],
        ),
      ),
    );
  }

  /// Tournament info card
  Widget _buildTournamentInfo() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          _buildInfoRow('Format • Status', '${_formatTournamentType(widget.tournament.bracketFormat)} • ${widget.tournament.status.toUpperCase()}'),
          SizedBox(height: 1.h),
          _buildInfoRow('Participants', '${widget.tournament.currentParticipants}/${widget.tournament.maxParticipants}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12.sp,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF2E86AB),
          ),
        ),
      ],
    );
  }

  /// Bracket view
  Widget _buildBracketView() {
    return Expanded(
      child: SizedBox(
        width: double.infinity,
        child: FutureBuilder<Widget>(
          future: _visualizationService.buildTournamentBracket(
            tournamentId: widget.tournament.id,
            bracketData: _bracketData!,
            onMatchTap: _handleMatchTap,
            showLiveUpdates: true,
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: EdgeInsets.all(16.sp),
                  child: Text(
                    'Error rendering bracket: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              );
            }
            
            return Container(
              child: snapshot.data ?? const SizedBox(),
            );
          },
        ),
      ),
    );
  }

  // ==================== DATA METHODS ====================

  /// Load existing bracket data
  Future<void> _loadBracketData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Load matches from database to check if bracket exists
      final matches = await Supabase.instance.client
          .from('matches')
          .select('''
            id,
            round_number,
            bracket_position,
            player1_id,
            player2_id,
            winner_id,
            status,
            scheduled_time,
            player1_score,
            player2_score,
            player1:users!player1_id(id, full_name, username),
            player2:users!player2_id(id, full_name, username),
            winner:users!winner_id(id, full_name, username)
          ''')
          .eq('tournament_id', widget.tournament.id)
          .order('round_number')
          .order('bracket_position');

      if (matches.isNotEmpty) {
        // Create bracket data from matches
        final bracketData = {
          'tournament_id': widget.tournament.id,
          'matches': matches,
          'format': widget.tournament.bracketFormat,
          'total_participants': widget.tournament.currentParticipants,
        };
        
        debugPrint('🎯 Bracket data loaded: ${matches.length} matches found');
        debugPrint('📊 Sample match: ${matches.first}');
        
        setState(() {
          _bracketData = bracketData;
          _hasBracket = true;
          _isLoading = false;
        });
      } else {
        () {
        // No matches found - no bracket exists yet
        setState(() {
          _hasBracket = false;
          _isLoading = false;
        });
      }

    
      }} catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Generate new bracket using proper single elimination logic
  Future<void> _generateBracket() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get participants for bracket generation
      final participants = await _tournamentService.getTournamentParticipants(widget.tournament.id);
      
      if (participants.isEmpty) {
        throw Exception('Không có thành viên tham gia giải đấu');
      }

      // Convert to Map format
      final participantMaps = participants.map((profile) => {
        'user_id': profile.id,
        'full_name': profile.fullName.isNotEmpty ? profile.fullName : profile.username,
        'username': profile.username,
        'avatar_url': profile.avatarUrl,
      }).toList();

      final result = await _bracketService.generateSingleEliminationBracket(
        tournamentId: widget.tournament.id,
        participants: participantMaps,
      );

      if (result['success'] == true) {
        // Reload bracket data from database to get fresh matches
        setState(() {
          _hasBracket = true;
          _isLoading = false;
        });
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Bracket generated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        () {
        setState(() {
          _errorMessage = result['error'] ?? 'Failed to generate bracket';
          _isLoading = false;
        });
      }

    
      }} catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Refresh bracket data
  Future<void> _refreshBracket() async {
    await _loadBracketData();
  }

  /// Regenerate bracket
  Future<void> _regenerateBracket() async {
    final confirm = await _showConfirmationDialog(
      'Regenerate Bracket',
      'This will create a new bracket and overwrite the existing one. Continue?',
    );

    if (confirm == true) {
      await _generateBracket();
    }
  }

  /// Handle match tap
  void _handleMatchTap() {
    // TODO: Navigate to match detail or show match management dialog
    debugPrint('Match tapped - implement match management');
  }

  // ==================== UTILITY METHODS ====================

  String _formatTournamentType(String type) {
    switch (type.toLowerCase()) {
      case 'single_elimination':
        return 'Single Elimination';
      case 'double_elimination':
        return 'Double Elimination';
      case 'sabo_de16':
        return 'SABO DE16';
      case 'sabo_de32':
        return 'SABO DE32';
      case 'round_robin':
        return 'Round Robin';
      case 'swiss_system':
        return 'Swiss System';
      default:
        return type.toUpperCase();
    }
  }

  Future<bool?> _showConfirmationDialog(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E86AB),
              foregroundColor: Colors.white,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
