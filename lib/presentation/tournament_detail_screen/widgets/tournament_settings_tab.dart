import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/tournament_service.dart';
import 'package:sabo_arena/services/bracket_service.dart';
import 'package:sabo_arena/services/tournament_completion_service.dart';

class TournamentSettingsTab extends StatefulWidget() {
  final String tournamentId;
  final VoidCallback? onStatusChanged;

  const TournamentSettingsTab({
    super.key,
    required this.tournamentId,
    this.onStatusChanged,
  });

  @override
  _TournamentSettingsTabState createState() => _TournamentSettingsTabState();
}

class _TournamentSettingsTabState extends State<TournamentSettingsTab> {
  final TournamentService _tournamentService = TournamentService.instance;
  final BracketService _bracketService = BracketService.instance;
  final TournamentCompletionService _completionService = TournamentCompletionService.instance;
  
  bool _isLoading = true;
  bool _isCompleting = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _matches = [];
  List<Map<String, dynamic>> _participants = [];
  List<Map<String, dynamic>>? _standings;

  @override
  void initState() {
    super.initState();
    _loadTournamentData();
  }

  Future<void> _loadTournamentData() async() {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try() {
      // Load tournament matches and participants
      _matches = await _tournamentService.getTournamentMatches(widget.tournamentId);
      
      // Debug: Check both methods
      debugPrint('🔍 Debug: Loading participants for tournament ${widget.tournamentId}');
      final simpleParticipants = await _tournamentService.getTournamentParticipants(widget.tournamentId);
      debugPrint('🔍 Debug: Simple method returned ${simpleParticipants.length} participants');
      
      _participants = await _tournamentService
          .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
      debugPrint('🔍 Debug: WithPaymentStatus method returned ${_participants.length} participants');
      
      // Debug: Check raw database query
      await _debugDirectDatabaseQuery();

      // Calculate standings if possible
      List<Map<String, dynamic>>? standings;
      if (_matches.isNotEmpty && _participants.isNotEmpty) {
        standings = _bracketService.getTournamentStandings(_matches, _participants);
      }

      setState(() {
        _standings = standings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Lỗi tải dữ liệu: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  bool get _canCompleteTournament() {
    if (_matches.isEmpty) return false;
    
    // Check if tournament is complete based on bracket logic
    return _bracketService.isTournamentComplete(_matches);
  }

  Future<void> _debugDirectDatabaseQuery() async() {
    try() {
      debugPrint('🔍 Direct DB Query: Checking tournament_participants table...');
      final response = await Supabase.instance.client
          .from('tournament_participants')
          .select('id, user_id, payment_status, status')
          .eq('tournament_id', widget.tournamentId);
      
      debugPrint('📊 Direct DB Query: Found ${response.length} raw records');
      for (int i = 0; i < response.length; i++) {
        final record = response[i];
        debugPrint('  ${i + 1}. ID: ${record['id']}, User: ${record['user_id']}, Payment: ${record['payment_status']}, Status: ${record['status']}');
      }
    } catch (e) {
      debugPrint('❌ Direct DB Query error: $e');
    }
  }

  int get _completedMatches() {
    return _matches.where((m) => m['status'] == 'completed').length;
  }

  int get _totalMatches() {
    return _matches.length;
  }

  double get _completionProgress() {
    if (_totalMatches == 0) return 0.0;
    return _completedMatches / _totalMatches;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.sp),
            Text('Đang tải dữ liệu...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 40.sp, color: AppTheme.errorLight),
            SizedBox(height: 10.sp),
            Text("Lỗi tải dữ liệu", 
                 style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 4.sp),
            Text(_errorMessage!, 
                 textAlign: TextAlign.center,
                 style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
            SizedBox(height: 12.sp),
            ElevatedButton(
              onPressed: _loadTournamentData,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(),
          SizedBox(height: 16.sp),
          _buildStandingsSection(),
          SizedBox(height: 16.sp),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến độ giải đấu',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          
          // Progress bar
          LinearProgressIndicator(
            value: _completionProgress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
          ),
          SizedBox(height: 8.sp),
          
          // Progress stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Trận đấu: $_completedMatches/$_totalMatches',
                style: TextStyle(fontSize: 12.sp),
              ),
              Text(
                '${(_completionProgress * 100).round()}% hoàn thành',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.sp),
          
          // Additional stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Người chơi', _participants.length.toString(), Icons.people),
              _buildStatItem('Trận hoàn thành', _completedMatches.toString(), Icons.check_circle),
              _buildStatItem('Trận còn lại', (_totalMatches - _completedMatches).toString(), Icons.schedule),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 20.sp),
        SizedBox(height: 4.sp),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildStandingsSection() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bảng xếp hạng hiện tại',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          
          if (_standings == null || _standings!.isEmpty) ...[
            Center(
              child: Padding(
                padding: EdgeInsets.all(20.sp),
                child: Column(
                  children: [
                    Icon(Icons.leaderboard, size: 40.sp, color: Colors.grey[400]),
                    SizedBox(height: 8.sp),
                    Text(
                      'Chưa có dữ liệu xếp hạng',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
            // Standings header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.sp),
              ),
              child: Row(
                children: [
                  SizedBox(width: 40.sp, child: Text('#', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Người chơi', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold))),
                  SizedBox(width: 50.sp, child: Text('T/B', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                  SizedBox(width: 60.sp, child: Text('Điểm', style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                ],
              ),
            ),
            
            // Standings list
            ...(_standings!.take(10).map((standing) => _buildStandingRow(standing)).toList()),
            
            if (_standings!.length > 10) ...[
              SizedBox(height: 8.sp),
              Center(
                child: TextButton(
                  onPressed: () {
                    // Show full standings dialog
                  },
                  child: Text('Xem tất cả ${_standings!.length} người chơi'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildStandingRow(Map<String, dynamic> standing) {
    final position = standing['position'];
    final user = standing['user'];
    final wins = standing['wins'];
    final losses = standing['losses'];
    final points = standing['points'];
    
    Color? backgroundColor;
    if (position == 1) {
      backgroundColor = Colors.amber.withOpacity(0.1);
    } else if (position == 2) {
      backgroundColor = Colors.grey.withOpacity(0.1);
    } else if (position == 3) {
      backgroundColor = Colors.orange.withOpacity(0.1);
    }

    return Container(
      color: backgroundColor,
      child: Padding(
        padding: EdgeInsets.all(12.sp),
        child: Row(
          children: [
            // Position
            SizedBox(
              width: 40.sp,
              child: Row(
                children: [
                  if (position <= 3)
                    Icon(
                      Icons.emoji_events,
                      color: position == 1 ? Colors.amber : position == 2 ? Colors.grey : Colors.orange,
                      size: 16.sp,
                    ),
                  Text(
                    '$position',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            // Player info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['full_name'] ?? user?['email'] ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (user?['email'] != null)
                    Text(
                      user['email'],
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            
            // Win/Loss record
            SizedBox(
              width: 50.sp,
              child: Text(
                '$wins/$losses',
                style: TextStyle(fontSize: 12.sp),
                textAlign: TextAlign.center,
              ),
            ),
            
            // Points
            SizedBox(
              width: 60.sp,
              child: Text(
                '$points',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hành động quản lý',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.sp),
          
          // Tournament completion section
          if (_canCompleteTournament) ...[
            Container(
              padding: EdgeInsets.all(12.sp),
              decoration: BoxDecoration(
                color: AppTheme.successLight.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.sp),
                border: Border.all(color: AppTheme.successLight.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: AppTheme.successLight),
                      SizedBox(width: 8.sp),
                      Text(
                        'Giải đấu có thể hoàn thành',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.sp),
                  Text(
                    'Tất cả trận đấu đã hoàn thành. Bạn có thể chính thức kết thúc giải đấu.',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  SizedBox(height: 12.sp),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isCompleting ? null : _completeTournament,
                      icon: _isCompleting 
                          ? SizedBox(
                              width: 16.sp,
                              height: 16.sp,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(Icons.emoji_events),
                      label: Text(_isCompleting ? "Đang hoàn thành..." : 'Hoàn thành giải đấu'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.successLight,
                        padding: EdgeInsets.symmetric(vertical: 12.sp),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.sp),
          ],
          
          // Other actions
          Wrap(
            spacing: 8.sp,
            runSpacing: 8.sp,
            children: [
              _buildActionButton(
                label: 'Xuất kết quả',
                icon: Icons.download,
                color: AppTheme.primaryLight,
                onTap: _exportResults,
              ),
              _buildActionButton(
                label: 'Gửi thông báo',
                icon: Icons.notifications,
                color: AppTheme.warningLight,
                onTap: _sendNotifications,
              ),
              _buildActionButton(
                label: 'Lưu trữ',
                icon: Icons.archive,
                color: Colors.grey[600]!,
                onTap: _archiveTournament,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.sp),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 8.sp),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8.sp),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14.sp),
            SizedBox(width: 6.sp),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeTournament() async() {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Xác nhận hoàn thành giải đấu"),
        content: Text(
          "Bạn có chắc chắn muốn hoàn thành giải đấu này? Hành động này sẽ:\n\n"
          "• Xác định kết quả cuối cùng\n"
          "• Gửi thông báo cho tất cả người chơi\n"
          "• Cập nhật ELO rating\n"
          "• Chuyển trạng thái thành 'completed'"
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.successLight),
            child: Text('Hoàn thành'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isCompleting = true);

    try() {
      // Use the new TournamentCompletionService for complete workflow
      final result = await _completionService.completeTournament(
        tournamentId: widget.tournamentId,
        sendNotifications: true,
        postToSocial: true,
        updateElo: true,
        distributePrizes: true,
      );

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('🎉 Giải đấu đã hoàn thành thành công!', 
                     style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Đã gửi thông báo và cập nhật kết quả'),
              ],
            ),
            backgroundColor: AppTheme.successLight,
            duration: Duration(seconds: 5),
          ),
        );

        // Call the status changed callback
        widget.onStatusChanged?.call();
        
        // Show completion report dialog
        _showCompletionReport(result['completion_report']);
        
      } else() {
        throw Exception(result['message'] ?? 'Unknown completion error');
      }
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi hoàn thành giải đấu: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    } finally() {
      setState(() => _isCompleting = false);
    }
  }

  void _exportResults() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng xuất kết quả đang được phát triển'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _sendNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng gửi thông báo đang được phát triển'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  void _archiveTournament() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tính năng lưu trữ đang được phát triển'),
        backgroundColor: AppTheme.primaryLight,
      ),
    );
  }

  /// Show tournament completion report
  void _showCompletionReport(Map<String, dynamic>? report) {
    if (report == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.successLight),
            SizedBox(width: 8.sp),
            Text('Báo cáo hoàn thành'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Champion: ${report['champion_name'] ?? 'N/A'}', 
                   style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8.sp),
              Text('Runner-up: ${report['runner_up_name'] ?? 'N/A'}'),
              SizedBox(height: 8.sp),
              Text('Tổng trận đấu: ${report['total_matches'] ?? 0}'),
              SizedBox(height: 8.sp),
              Text('Tổng người chơi: ${report['total_participants'] ?? 0}'),
              SizedBox(height: 8.sp),
              Text('Thời gian hoàn thành: ${DateTime.now().toString().substring(0, 19)}'),
              if (report['notes'] != null) ...[
                SizedBox(height: 8.sp),
                Text('Ghi chú: ${report['notes']}'),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Đóng'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _exportResults();
            },
            child: Text('Xuất báo cáo'),
          ),
        ],
      ),
    );
  }
}