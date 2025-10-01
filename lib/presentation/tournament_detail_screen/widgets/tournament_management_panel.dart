import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'tournament_overview_tab.dart';
import 'participant_management_tab.dart';
import 'match_management_tab.dart';
import 'tournament_settings_tab.dart';

class TournamentManagementPanel extends StatefulWidget() {
  final String tournamentId;
  final String tournamentStatus;
  final VoidCallback? onStatusChanged;

  const TournamentManagementPanel({
    super.key,
    required this.tournamentId,
    required this.tournamentStatus,
    this.onStatusChanged,
  });

  @override
  _TournamentManagementPanelState createState() => _TournamentManagementPanelState();
}

class _TournamentManagementPanelState extends State<TournamentManagementPanel>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  int _selectedTab = 0;
  final List<String> _tabs = ['Tổng quan', 'Người chơi', 'Bảng đấu', 'Trận đấu', 'Cài đặt'];
  
  // Callback to refresh bracket when match scores are updated
  void _onMatchScoreUpdated() {
    // Force rebuild to trigger bracket data refresh
    if (mounted) {
      setState(() {
        // This will trigger a rebuild which will refresh the bracket tab
      });
    }
  }

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _slideAnimation.value)),
          child: Opacity(
            opacity: _slideAnimation.value,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.9,
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.sp)),
              ),
              child: Column(
                children: [
                  _buildTabBar(),
                  Expanded(child: _buildTabContent()),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.dividerLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header với title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quản lý giải đấu',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Icon(Icons.close, color: AppTheme.textSecondaryLight),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          // Tab buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _tabs.asMap().entries.map((entry) {
                final index = entry.key;
                final tab = entry.value;
                final isSelected = _selectedTab == index;

                return InkWell(
                  onTap: () {
                    setState(() => _selectedTab = index);
                    _animationController.forward(from: 0);
                  },
                  borderRadius: BorderRadius.circular(20.sp),
                  child: Container(
                    margin: EdgeInsets.only(right: 8.sp),
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? AppTheme.primaryLight 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                        color: isSelected 
                            ? AppTheme.primaryLight 
                            : AppTheme.dividerLight,
                      ),
                    ),
                    child: Text(
                      tab,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? Colors.white 
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return TournamentOverviewTab(
          tournamentId: widget.tournamentId,
          tournamentStatus: widget.tournamentStatus,
          onStatusChanged: widget.onStatusChanged,
        );
      case 1:
        return ParticipantManagementTab(tournamentId: widget.tournamentId);
      case 2:
        // TODO: Replace with proper Tournament object when available
        return Center(
          child: Text(
            'Bracket Management Tab\n(Chuyển đổi sang Tournament Management Center)',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.sp),
          ),
        );
      case 3:
        return MatchManagementTab(
          tournamentId: widget.tournamentId,
          onMatchScoreUpdated: _onMatchScoreUpdated,
        );
      case 4:
        return TournamentSettingsTab(
          tournamentId: widget.tournamentId,
          onStatusChanged: widget.onStatusChanged,
        );
      default:
        return Container();
    }
  }
}