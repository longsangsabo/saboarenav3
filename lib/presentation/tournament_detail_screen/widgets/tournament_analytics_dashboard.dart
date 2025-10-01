// 📈 SABO ARENA - Tournament Analytics Dashboard Widget
// Phase 2: Comprehensive analytics dashboard for tournament statistics
// Real-time charts, performance metrics, and engagement tracking

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../services/tournament_statistics_service.dart';
import '../../../core/constants/tournament_constants.dart';

class TournamentAnalyticsDashboard extends StatefulWidget() {
  final String tournamentId;
  final bool showRealTimeUpdates;

  const TournamentAnalyticsDashboard({
    super.key,
    required this.tournamentId,
    this.showRealTimeUpdates = true,
  });

  @override
  State<TournamentAnalyticsDashboard> createState() => _TournamentAnalyticsDashboardState();
}

class _TournamentAnalyticsDashboardState extends State<TournamentAnalyticsDashboard>
    with TickerProviderStateMixin() {
  final TournamentStatisticsService _statisticsService = TournamentStatisticsService.instance;
  
  Map<String, dynamic>? _analyticsData;
  bool _isLoading = true;
  String? _error;
  
  late TabController _tabController;
  late AnimationController _chartAnimationController;
  late Animation<double> _chartAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeAnimations();
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartAnimationController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _chartAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _chartAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _chartAnimationController,
      curve: Curves.easeOutCubic,
    ));
  }

  Future<void> _loadAnalyticsData() async() {
    try() {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final analytics = await _statisticsService.getTournamentAnalytics(widget.tournamentId);
      
      if (mounted) {
        setState(() {
          _analyticsData = analytics;
          _isLoading = false;
        });
        _chartAnimationController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[50]!,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          
          // Content
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _error != null
                    ? _buildErrorState()
                    : _buildAnalyticsTabs(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.blue[600],
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(16.sp),
          bottomRight: Radius.circular(16.sp),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.analytics,
            color: Colors.white,
            size: 24.sp,
          ),
          SizedBox(width: 8.sp),
          Text(
            'Tournament Analytics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Spacer(),
          if (!_isLoading)
            IconButton(
              onPressed: _loadAnalyticsData,
              icon: Icon(Icons.refresh, color: Colors.white),
              tooltip: 'Refresh Data',
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
          ),
          SizedBox(height: 16.sp),
          Text(
            'Analyzing tournament data...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 48.sp,
            color: Colors.red[300],
          ),
          SizedBox(height: 16.sp),
          Text(
            'Failed to load analytics',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          SizedBox(height: 8.sp),
          Text(
            _error!,
            style: TextStyle(color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.sp),
          ElevatedButton.icon(
            onPressed: _loadAnalyticsData,
            icon: Icon(Icons.refresh),
            label: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTabs() {
    return Column(
      children: [
        // Tab Bar
        TabBar(
          controller: _tabController,
          labelColor: Colors.blue[700],
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Colors.blue[600],
          tabs: [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard, size: 16.sp)),
            Tab(text: 'Participants', icon: Icon(Icons.people, size: 16.sp)),
            Tab(text: 'Matches', icon: Icon(Icons.sports_esports, size: 16.sp)),
            Tab(text: 'Performance', icon: Icon(Icons.trending_up, size: 16.sp)),
          ],
        ),
        
        // Tab Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildParticipantsTab(),
              _buildMatchesTab(),
              _buildPerformanceTab(),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== OVERVIEW TAB ====================

  Widget _buildOverviewTab() {
    final basicStats = _analyticsData?['basic_stats'] ?? {};
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Metrics Cards
          _buildKeyMetricsGrid(basicStats),
          SizedBox(height: 24.sp),
          
          // Tournament Status Chart
          _buildTournamentStatusCard(basicStats),
          SizedBox(height: 24.sp),
          
          // Prize Pool Information
          _buildPrizePoolCard(basicStats),
        ],
      ),
    );
  }

  Widget _buildKeyMetricsGrid(Map<String, dynamic> basicStats) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12.sp,
      mainAxisSpacing: 12.sp,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          title: 'Participants',
          value: '${basicStats['total_participants'] ?? 0}',
          subtitle: '/${basicStats['max_participants'] ?? 0}',
          icon: Icons.group,
          color: Colors.blue,
          percentage: basicStats['fill_rate'],
        ),
        _buildMetricCard(
          title: 'Matches',
          value: '${basicStats['completed_matches'] ?? 0}',
          subtitle: '/${basicStats['total_matches'] ?? 0}',
          icon: Icons.sports_esports,
          color: Colors.green,
          percentage: basicStats['completion_rate'],
        ),
        _buildMetricCard(
          title: 'Duration',
          value: '${basicStats['duration_hours'] ?? 0}',
          subtitle: 'hours',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        _buildMetricCard(
          title: 'Prize Pool',
          value: '${basicStats['prize_pool'] ?? 0}',
          subtitle: 'coins',
          icon: Icons.emoji_events,
          color: Colors.amber,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    double? percentage,
  }) {
    return AnimatedBuilder(
      animation: _chartAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _chartAnimation.value,
          child: Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.sp),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: color, size: 20.sp),
                    SizedBox(width: 8.sp),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.sp),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (percentage != null) ...[
                  SizedBox(height: 4.sp),
                  LinearProgressIndicator(
                    value: percentage / 100,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                  SizedBox(height: 4.sp),
                  Text(
                    '${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTournamentStatusCard(Map<String, dynamic> basicStats) {
    final status = basicStats['status'] ?? 'unknown';
    final statusDetails = TournamentStatus.statusDetails[status];
    
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tournament Status',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.sp),
          Row(
            children: [
              Icon(
                statusDetails?['icon'] ?? Icons.help,
                color: statusDetails?['color'] ?? Colors.grey,
                size: 32.sp,
              ),
              SizedBox(width: 16.sp),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusDetails?['nameVi'] ?? status,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: statusDetails?['color'] ?? Colors.grey,
                      ),
                    ),
                    Text(
                      statusDetails?['descriptionVi'] ?? '',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrizePoolCard(Map<String, dynamic> basicStats) {
    final prizePool = basicStats['prize_pool'] ?? 0;
    final entryFee = basicStats['entry_fee'] ?? 0;
    final participants = basicStats['total_participants'] ?? 0;
    final totalCollected = entryFee * participants;
    
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber[400]!, Colors.amber[600]!],
        ),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.white, size: 24.sp),
              SizedBox(width: 8.sp),
              Text(
                'Prize Pool Analysis',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.sp),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPrizePoolItem('Entry Fee', '$entryFee coins'),
              _buildPrizePoolItem('Collected', '$totalCollected coins'),
              _buildPrizePoolItem('Prize Pool', '$prizePool coins'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrizePoolItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 11.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ==================== PARTICIPANTS TAB ====================

  Widget _buildParticipantsTab() {
    final participantAnalytics = _analyticsData?['participant_analytics'] ?? {};
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // Skill Level Distribution Pie Chart
          _buildSkillDistributionChart(participantAnalytics),
          SizedBox(height: 24.sp),
          
          // ELO Distribution
          _buildEloDistributionChart(participantAnalytics),
          SizedBox(height: 24.sp),
          
          // Club Distribution
          _buildClubDistributionChart(participantAnalytics),
          SizedBox(height: 24.sp),
          
          // Registration Timeline
          _buildRegistrationTimelineChart(participantAnalytics),
        ],
      ),
    );
  }

  Widget _buildSkillDistributionChart(Map<String, dynamic> data) {
    final distribution = Map<String, int>.from(data['skill_level_distribution'] ?? {});
    
    return _buildChartCard(
      title: 'Skill Level Distribution',
      child: SizedBox(
        height: 200.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return PieChart(
              PieChartData(
                sections: distribution.entries.map((entry) {
                  final color = _getSkillLevelColor(entry.key);
                  return PieChartSectionData(
                    value: entry.value.toDouble() * _chartAnimation.value,
                    title: '${entry.key}\n${entry.value}',
                    color: color,
                    radius: 60.sp,
                    titleStyle: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 2,
                centerSpaceRadius: 40.sp,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEloDistributionChart(Map<String, dynamic> data) {
    final distribution = Map<String, int>.from(data['elo_distribution'] ?? {});
    final avgElo = data['average_elo'] ?? 0;
    
    return _buildChartCard(
      title: 'ELO Rating Distribution (Avg: $avgElo)',
      child: SizedBox(
        height: 200.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return BarChart(
              BarChartData(
                maxY: distribution.values.isEmpty ? 10 : distribution.values.reduce((a, b) => a > b ? a : b).toDouble(),
                barGroups: distribution.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value.toDouble() * _chartAnimation.value,
                        color: Colors.blue[600],
                        width: 20.sp,
                        borderRadius: BorderRadius.circular(4.sp),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < distribution.length) {
                          final key = distribution.keys.elementAt(value.toInt());
                          return Text(
                            key,
                            style: TextStyle(fontSize: 10.sp),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildClubDistributionChart(Map<String, dynamic> data) {
    final distribution = Map<String, int>.from(data['club_distribution'] ?? {});
    
    return _buildChartCard(
      title: 'Club Distribution',
      child: SizedBox(
        height: 200.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return PieChart(
              PieChartData(
                sections: distribution.entries.take(8).map((entry) {
                  final color = _getClubColor(entry.key);
                  return PieChartSectionData(
                    value: entry.value.toDouble() * _chartAnimation.value,
                    title: '${entry.key}\n${entry.value}',
                    color: color,
                    radius: 50.sp,
                    titleStyle: TextStyle(
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
                sectionsSpace: 1,
                centerSpaceRadius: 30.sp,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRegistrationTimelineChart(Map<String, dynamic> data) {
    final timeline = Map<String, int>.from(data['registration_timeline'] ?? {});
    
    return _buildChartCard(
      title: 'Registration Timeline',
      child: SizedBox(
        height: 150.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < timeline.length) {
                          final date = timeline.keys.elementAt(value.toInt());
                          final parts = date.split('-');
                          return Text('${parts[2]}/${parts[1]}', style: TextStyle(fontSize: 9.sp));
                        }
                        return Text('');
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: timeline.entries.toList().asMap().entries.map((entry) {
                      final index = entry.key.toDouble();
                      final value = entry.value.value.toDouble() * _chartAnimation.value;
                      return FlSpot(index, value);
                    }).toList(),
                    isCurved: true,
                    color: Colors.green[600],
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== MATCHES TAB ====================

  Widget _buildMatchesTab() {
    final matchAnalytics = _analyticsData?['match_analytics'] ?? {};
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // Match Completion Progress
          _buildMatchCompletionChart(matchAnalytics),
          SizedBox(height: 24.sp),
          
          // Score Patterns
          _buildScorePatternsChart(matchAnalytics),
          SizedBox(height: 24.sp),
          
          // Match Duration Distribution
          _buildDurationDistributionChart(matchAnalytics),
        ],
      ),
    );
  }

  Widget _buildMatchCompletionChart(Map<String, dynamic> data) {
    final totalMatches = data['total_matches'] ?? 0;
    final completedMatches = data['completed_matches'] ?? 0;
    final pendingMatches = totalMatches - completedMatches;
    
    return _buildChartCard(
      title: 'Match Progress',
      child: SizedBox(
        height: 200.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: completedMatches.toDouble() * _chartAnimation.value,
                    title: 'Completed\n$completedMatches',
                    color: Colors.green[600],
                    radius: 60.sp,
                  ),
                  PieChartSectionData(
                    value: pendingMatches.toDouble() * _chartAnimation.value,
                    title: 'Pending\n$pendingMatches',
                    color: Colors.orange[600],
                    radius: 60.sp,
                  ),
                ],
                centerSpaceRadius: 40.sp,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildScorePatternsChart(Map<String, dynamic> data) {
    final patterns = Map<String, int>.from(data['score_patterns'] ?? {});
    
    return _buildChartCard(
      title: 'Common Score Patterns',
      child: SizedBox(
        height: 200.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return BarChart(
              BarChartData(
                maxY: patterns.values.isEmpty ? 10 : patterns.values.reduce((a, b) => a > b ? a : b).toDouble(),
                barGroups: patterns.entries.take(8).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value.toDouble() * _chartAnimation.value,
                        color: Colors.purple[600],
                        width: 16.sp,
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDurationDistributionChart(Map<String, dynamic> data) {
    final distribution = Map<String, int>.from(data['duration_distribution'] ?? {});
    final avgDuration = data['average_match_duration_minutes'] ?? 0;
    
    return _buildChartCard(
      title: 'Match Duration Distribution (Avg: ${avgDuration}min)',
      child: SizedBox(
        height: 150.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return BarChart(
              BarChartData(
                barGroups: distribution.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data.value.toDouble() * _chartAnimation.value,
                        color: Colors.teal[600],
                        width: 20.sp,
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== PERFORMANCE TAB ====================

  Widget _buildPerformanceTab() {
    final performanceMetrics = _analyticsData?['performance_metrics'] ?? {};
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.sp),
      child: Column(
        children: [
          // Top Performers List
          _buildTopPerformersList(performanceMetrics),
          SizedBox(height: 24.sp),
          
          // Performance by Skill Level
          _buildSkillLevelPerformanceChart(performanceMetrics),
        ],
      ),
    );
  }

  Widget _buildTopPerformersList(Map<String, dynamic> data) {
    final topPerformers = List<Map<String, dynamic>>.from(data['top_performers'] ?? []);
    
    return _buildChartCard(
      title: 'Top Performers',
      child: Column(
        children: topPerformers.take(10).map((performer) {
          final position = performer['final_position'] ?? 0;
          final username = performer['username'] ?? 'Unknown';
          final winRate = performer['win_rate'] ?? 0.0;
          
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getPositionColor(position),
              child: Text(
                position.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(username),
            subtitle: Text('Win Rate: ${winRate.toStringAsFixed(1)}%'),
            trailing: _getPositionIcon(position),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSkillLevelPerformanceChart(Map<String, dynamic> data) {
    final performanceBySkill = Map<String, dynamic>.from(data['performance_by_skill_level'] ?? {});
    
    return _buildChartCard(
      title: 'Performance by Skill Level',
      child: SizedBox(
        height: 200.sp,
        child: AnimatedBuilder(
          animation: _chartAnimation,
          builder: (context, child) {
            return BarChart(
              BarChartData(
                barGroups: performanceBySkill.entries.toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final skillData = entry.value;
                  final avgWinRate = skillData['average_win_rate'] ?? 0.0;
                  
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: avgWinRate * _chartAnimation.value,
                        color: _getSkillLevelColor(entry.value.key),
                        width: 20.sp,
                      ),
                    ],
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  // ==================== HELPER WIDGETS ====================

  Widget _buildChartCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 16.sp),
          child,
        ],
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  Color _getSkillLevelColor(String skillLevel) {
    switch (skillLevel.toLowerCase()) {
      case 'beginner':
        return Colors.green[400]!;
      case 'intermediate':
        return Colors.blue[400]!;
      case 'advanced':
        return Colors.orange[400]!;
      case 'expert':
        return Colors.red[400]!;
      case 'master':
        return Colors.purple[400]!;
      default:
        return Colors.grey[400]!;
    }
  }

  Color _getClubColor(String clubName) {
    final hash = clubName.hashCode;
    final colors = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.orange[400]!,
      Colors.purple[400]!,
      Colors.teal[400]!,
      Colors.indigo[400]!,
      Colors.pink[400]!,
      Colors.brown[400]!,
    ];
    return colors[hash.abs() % colors.length];
  }

  Color _getPositionColor(int position) {
    if (position == 1) return Colors.amber[600]!;
    if (position == 2) return Colors.grey[600]!;
    if (position == 3) return Colors.brown[400]!;
    return Colors.blue[600]!;
  }

  Widget _getPositionIcon(int position) {
    if (position == 1) return Icon(Icons.emoji_events, color: Colors.amber[600]);
    if (position == 2) return Icon(Icons.military_tech, color: Colors.grey[600]);
    if (position == 3) return Icon(Icons.military_tech, color: Colors.brown[400]);
    return Icon(Icons.sports, color: Colors.blue[600]);
  }
}