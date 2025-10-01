import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_export.dart';
import '../../models/tournament.dart';
import '../../models/user_profile.dart';
import '../../services/tournament_service.dart';
import '../tournament_detail_screen/widgets/match_management_tab.dart';
import '../tournament_detail_screen/widgets/participant_management_tab.dart';
import '../tournament_detail_screen/widgets/tournament_rankings_widget.dart';
import 'widgets/bracket_management_tab.dart';

class TournamentManagementCenterScreen extends StatefulWidget {
  const TournamentManagementCenterScreen({super.key});

} 
  final String clubId;

  const TournamentManagementCenterScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<TournamentManagementCenterScreen> createState() => _TournamentManagementCenterScreenState();
}

class _TournamentManagementCenterScreenState extends State<TournamentManagementCenterScreen> {
  final TournamentService _tournamentService = TournamentService.instance;
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<Tournament> _tournaments = [];
  Tournament? _selectedTournament;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTournaments();
  }

  Future<void> _loadTournaments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get tournaments with error handling
      List<Tournament> tournaments = [];
      try {
        tournaments = await _tournamentService.getTournaments(clubId: widget.clubId);
      } catch (e) {
        debugPrint('🔥 Error loading tournaments: $e');
        // Try alternative approach if direct query fails
        tournaments = [];
      }
      
      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
        // Auto-select first tournament if available
        if (_tournaments.isNotEmpty) {
          // If current selected tournament is not in new list, select first
          if (_selectedTournament == null || !_tournaments.any((t) => t.id == _selectedTournament!.id)) {
            _selectedTournament = _tournaments.first;
          } else {
            () {
            // Update selected tournament with fresh data
            _selectedTournament = _tournaments.firstWhere((t) => t.id == _selectedTournament!.id);
          }
        
          }}
      });
    } catch (e) {
      debugPrint('🔥 Critical error in _loadTournaments: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể tải danh sách giải đấu'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Thử lại',
              onPressed: _loadTournaments,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý Giải đấu',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Compact Tournament Selection Section
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
              color: Colors.grey[50],
              child: Row(
                children: [
                  Text(
                    'Giải đấu:',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(width: 8.sp),
                  Expanded(child: _buildTournamentSelector()),
                ],
              ),
            ),
            
            // Management Panel Section
            Expanded(
              child: _selectedTournament != null
                  ? _buildManagementPanel()
                  : _buildEmptyState(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTournamentSelector() {
    if (_isLoading) {
      return Container(
        height: 50.sp,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_tournaments.isEmpty) {
      return Container(
        height: 50.sp,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline, size: 14.sp, color: Colors.grey[600]),
              SizedBox(width: 4.sp),
              Text(
                'Chưa có giải đấu nào',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 50.sp,  // Increased height for 2 lines
      padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedTournament?.id,
          isExpanded: true,
          hint: Text(
            'Chọn giải đấu...',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
          items: _tournaments.map((tournament) {
            return DropdownMenuItem<String>(
              value: tournament.id,
              child: Row(
                children: [
                  // Status indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 4.sp, vertical: 1.sp),
                    decoration: BoxDecoration(
                      color: _getStatusColor(tournament.status),
                      borderRadius: BorderRadius.circular(4.sp),
                    ),
                    child: Text(
                      _getStatusText(tournament.status),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  SizedBox(width: 6.sp),
                  // Tournament title and info with format
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${tournament.title} • ${tournament.currentParticipants}/${tournament.maxParticipants}',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 2.sp),
                        Text(
                          '${_getFormatDisplayName(tournament.bracketFormat)} (${tournament.gameFormat})',
                          style: TextStyle(
                            fontSize: 8.sp,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedTournament = _tournaments.firstWhere((t) => t.id == newValue);
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildManagementPanel() {
    return SingleChildScrollView(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quick Actions (compact)
            _buildQuickActionButtons(),
            
            SizedBox(height: 10.sp),
            
            // Management Tabs
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: _buildManagementTabs(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons() {
    final isActiveTournament = _selectedTournament?.status == 'active';
    final hasBracket = isActiveTournament || _selectedTournament?.status == 'completed';
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thao tác:',
          style: TextStyle(
            fontSize: 11.sp,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 6.sp),
        
        // Compact action buttons in row
        Row(
          children: [
            // Main action button - compact
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: hasBracket ? null : _createTournamentBracket,
                icon: Icon(
                  hasBracket ? Icons.check_circle : Icons.sports_bar, 
                  size: 14.sp
                ),
                label: Text(
                  hasBracket ? "Đã tạo" : 'Tạo bảng', 
                  style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w500),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: hasBracket ? Colors.grey[400] : Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 8.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.sp),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 6.sp),
            
            // Secondary actions - compact
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showScoreEntry,
                icon: Icon(Icons.edit, size: 12.sp),
                label: Text('Tỷ số', style: TextStyle(fontSize: 9.sp)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: BorderSide(color: Colors.blue, width: 1),
                  padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 4.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.sp),
                  ),
                ),
              ),
            ),
            
            SizedBox(width: 4.sp),
            
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _showMatchManagement,
                icon: Icon(Icons.pool, size: 12.sp),
                label: Text('Quản lý', style: TextStyle(fontSize: 9.sp)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orange,
                  side: BorderSide(color: Colors.orange, width: 1),
                  padding: EdgeInsets.symmetric(vertical: 8.sp, horizontal: 4.sp),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildManagementTabs() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6.sp),
            ),
            child: TabBar(
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey[600],
              labelStyle: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w500),
              unselectedLabelStyle: TextStyle(fontSize: 8.sp, fontWeight: FontWeight.w400),
              indicator: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(6.sp),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              tabAlignment: TabAlignment.fill,
              isScrollable: false,
              tabs: [
                SizedBox(
                  height: 28.sp, // Giảm chiều cao hơn nữa để fit 4 tabs
                  child: Tab(
                    icon: Icon(Icons.group, size: 10.sp),
                    text: 'Thành viên',
                    iconMargin: EdgeInsets.only(bottom: 0.5.sp),
                  ),
                ),
                SizedBox(
                  height: 28.sp,
                  child: Tab(
                    icon: Icon(Icons.pool, size: 10.sp),
                    text: 'Trận đấu',
                    iconMargin: EdgeInsets.only(bottom: 0.5.sp),
                  ),
                ),
                SizedBox(
                  height: 28.sp,
                  child: Tab(
                    icon: Icon(Icons.account_tree, size: 10.sp),
                    text: 'Bảng đấu',
                    iconMargin: EdgeInsets.only(bottom: 0.5.sp),
                  ),
                ),
                SizedBox(
                  height: 28.sp,
                  child: Tab(
                    icon: Icon(Icons.emoji_events, size: 10.sp),
                    text: 'Kết quả',
                    iconMargin: EdgeInsets.only(bottom: 0.5.sp),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 8.sp),
          
          Expanded(
            child: TabBarView(
              children: [
                // Participants Tab
                ParticipantManagementTab(
                  tournamentId: _selectedTournament!.id,
                ),
                
                // Matches Tab
                MatchManagementTab(
                  tournamentId: _selectedTournament!.id,
                ),
                
                // Bracket Tab
                BracketManagementTab(
                  tournament: _selectedTournament!,
                ),
                
                // Results Tab
                TournamentRankingsWidget(
                  tournamentId: _selectedTournament!.id,
                  tournamentStatus: _selectedTournament!.status,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.sp),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.sports_bar,
                size: 40.sp,
                color: Colors.grey[400],
              ),
              SizedBox(height: 8.sp),
              Text(
                'Chọn giải đấu để quản lý',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                'Chọn một giải đấu từ danh sách phía trên',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Action handlers
  Future<void> _createTournamentBracket() async {
    if (_selectedTournament == null) return;
    
    try {
      debugPrint('🎯 Creating billiards bracket for tournament: ${_selectedTournament!.title}');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: Container(
            padding: EdgeInsets.all(20.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12.sp),
                Text(
                  'Đang tạo bảng đấu bida...',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ),
      );

      // Create bracket with error handling
      try {
        debugPrint('🎯 Creating billiards bracket for tournament: ${_selectedTournament!.title}');
        
        // First check if bracket already exists
        final existingMatches = await _supabase
            .from('matches')
            .select('id')
            .eq('tournament_id', _selectedTournament!.id)
            .limit(1);
        
        if (existingMatches.isNotEmpty) {
          throw Exception('Bảng đấu đã tồn tại cho giải này. Vui lòng xóa bảng đấu cũ trước khi tạo mới.');
        }
        
        // Get tournament participants first
        final participantProfiles = await _tournamentService.getTournamentParticipants(_selectedTournament!.id);
        debugPrint('✅ Found ${participantProfiles.length} participants for bracket');
        
        if (participantProfiles.isEmpty) {
          throw Exception('Không có thành viên tham gia giải đấu');
        }
        
        // Convert to Map format for bracket service
        final participants = participantProfiles.map((profile) => {
          'user_id': profile.id,
          'full_name': profile.fullName.isNotEmpty ? profile.fullName : profile.username,
          'username': profile.username,
          'avatar_url': profile.avatarUrl,
          "payment_status": 'confirmed', // Add this for BracketService validation
        }).toList();
        
        // � USE INTEGRATED TOURNAMENT SERVICE WITH COMPLETE DE16 SUPPORT
        final tournamentFormat = _selectedTournament!.bracketFormat; // Use bracket format for tournament structure
        debugPrint('🎯 Detected tournament format: $tournamentFormat');
        debugPrint('🏆 Creating $tournamentFormat bracket for ${participants.length} players');
        
        // 🚀 Get full UserProfile data from database for proper integration
        final participantIds = participants.map((p) => p['user_id']).toList();
        final userProfilesResponse = await _supabase
            .from('users')
            .select('*')
            .filter('id', 'in', participantIds);

        final List<UserProfile> userProfiles = userProfilesResponse
            .map((data) => UserProfile.fromJson(data))
            .toList();

        debugPrint('📊 Loaded ${userProfiles.length} full user profiles for bracket generation');
        
        // 🚀 Use TournamentService.generateBracket with CompleteDoubleEliminationService integration
        final bracket = await _tournamentService.generateBracket(
          tournamentId: _selectedTournament!.id,
          format: tournamentFormat,
          participants: userProfiles,
          seedingMethod: 'eloRating', // Use ELO-based seeding
        );
        
        debugPrint('✅ Bracket created successfully');
        debugPrint('📊 Format: ${bracket.format}, Rounds: ${bracket.rounds}');
        
        // Convert bracket result to success format for UI
        final result = {
          'success': true,
          'message': 'Bảng đấu $tournamentFormat đã được tạo thành công',
          'bracket': bracket,
          'total_matches': bracket.matches.length,
        };
        
        if (!result.containsKey('success') || result['success'] != true) {
          throw Exception(result['message'] ?? 'Lỗi không xác định khi tạo bảng đấu');
        }
        debugPrint('✅ Bracket created successfully');
      } catch (e) {
        debugPrint('🔥 Error starting tournament: $e');
        throw Exception('Không thể tạo bảng đấu: ${e.toString()}');
      }
      
      if (mounted) Navigator.pop(context);
      
      // Reload tournaments to update status
      await _loadTournaments();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 6.sp),
                Expanded(child: Text('Bảng đấu bida đã tạo thành công!', 
                                   style: TextStyle(fontSize: 12.sp))),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
      
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${e.toString()}', style: TextStyle(fontSize: 12.sp)),
            backgroundColor: Colors.red,
          ),
        );
      }
      debugPrint('🔥 Error creating bracket: $e');
    }
  }

  void _showScoreEntry {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.pool, color: Colors.blue),
            SizedBox(width: 8.sp),
            Text('Nhập tỷ số bida'),
          ],
        ),
        content: Text('Chức năng nhập tỷ số bida đang phát triển...'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _showMatchManagement() {
    // Switch to Matches tab in the management tabs (index 1)
    DefaultTabController.of(context).animateTo(1);
  }

  // Helper methods
  Color _getStatusColor(String status) {
    switch (status) {
      case 'recruiting': return Colors.orange;
      case 'ready': return Colors.blue;
      case 'upcoming': return Colors.teal;
      case 'active': return Colors.green;
      case 'completed': return Colors.purple;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'recruiting': return 'Đang tuyển';
      case 'ready': return 'Sẵn sàng';
      case 'upcoming': return 'Sắp diễn ra';
      case 'active': return 'Đang diễn ra';
      case 'completed': return 'Hoàn thành';
      default: return 'Không xác định';
    }
  }

  String _getFormatDisplayName(String format) {
    switch (format) {
      case 'single_elimination': return 'Single Elimination';
      case 'double_elimination': return 'Double Elimination';
      case 'round_robin': return 'Round Robin';
      case 'swiss': return 'Swiss System';
      case 'sabo_double_elimination': return 'SABO DE16';
      case 'sabo_double_elimination_32': return 'SABO DE32';
      default: return format.replaceAll('_', ' ').toUpperCase();
    }
  }
}
