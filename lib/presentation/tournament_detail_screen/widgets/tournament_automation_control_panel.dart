// 🎛️ SABO ARENA - Tournament Automation Control Panel
// Phase 3: Advanced automation controls and monitoring
// Real-time automation management with manual overrides

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/tournament_automation_service.dart';
import '../../../services/realtime_tournament_service.dart';
import '../../../core/constants/tournament_constants.dart';
import '../../../models/tournament.dart';

class TournamentAutomationControlPanel extends StatefulWidget {
  const TournamentAutomationControlPanel({super.key});

} 
  final Tournament tournament;

  const TournamentAutomationControlPanel({
    super.key,
    required this.tournament,
  });

  @override
  State<TournamentAutomationControlPanel> createState() => _TournamentAutomationControlPanelState();
}

class _TournamentAutomationControlPanelState extends State<TournamentAutomationControlPanel>
    with TickerProviderStateMixin {
  final TournamentAutomationService _automationService = TournamentAutomationService.instance;
  final RealTimeTournamentService _realtimeService = RealTimeTournamentService.instance;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _isAutomationActive = false;
  bool _isLoading = false;
  Map<String, dynamic> _automationStatus = {};
  final List<Map<String, dynamic>> _automationLogs = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAutomationStatus();
    _setupRealtimeUpdates();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  void _setupRealtimeUpdates() {
    _realtimeService.subscribeToTournamentUpdates(widget.tournament.id).listen((update) {
      if (update['type'] == 'automation_update') {
        _loadAutomationStatus();
      }
    });
  }

  Future<void> _loadAutomationStatus() async {
    try {
      setState(() => _isLoading = true);

      // Check if automation is active (this would be tracked in your service)
      _isAutomationActive = true; // Placeholder - implement actual check
      
      // Load automation logs and status
      _automationStatus = {
        'registration_automation': _shouldShowRegistrationAutomation(),
        'pairing_automation': _shouldShowPairingAutomation(),
        'notification_automation': _shouldShowNotificationAutomation(),
        'progression_automation': _shouldShowProgressionAutomation(),
      };

      setState(() => _isLoading = false);

    } catch (e) {
      debugPrint('❌ Error loading automation status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[50]!,
            Colors.indigo[50]!,
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading 
                ? _buildLoadingState() 
                : _buildControlsContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isAutomationActive ? _pulseAnimation.value : 1.0,
                child: Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: _isAutomationActive ? Colors.green[100] : Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.precision_manufacturing,
                    size: 6.w,
                    color: _isAutomationActive ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              );
            },
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Automation Control 🤖',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _isAutomationActive ? "Active monitoring" : 'Manual control',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: _isAutomationActive ? Colors.green[600] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isAutomationActive,
            onChanged: _toggleAutomation,
            thumbColor: Colors.green[600],
          ),
          SizedBox(width: 2.w),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, size: 6.w),
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
          SizedBox(height: 4.w),
          Text(
            'Loading automation status...',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlsContent() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActions(),
          SizedBox(height: 4.w),
          _buildAutomationToggles(),
          SizedBox(height: 4.w),
          _buildScheduledActions(),
          SizedBox(height: 4.w),
          _buildAutomationLogs(),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions ⚡',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 3.w),
            Wrap(
              spacing: 3.w,
              runSpacing: 2.w,
              children: [
                _buildActionChip(
                  'Start Tournament',
                  Icons.play_arrow,
                  Colors.green,
                  _canStartTournament(),
                  () => _performQuickAction('start'),
                ),
                _buildActionChip(
                  'Force Pairing',
                  Icons.group_work,
                  Colors.blue,
                  _canForcePairing(),
                  () => _performQuickAction('force_pairing'),
                ),
                _buildActionChip(
                  'Send Notifications',
                  Icons.notifications,
                  Colors.orange,
                  true,
                  () => _performQuickAction('notifications'),
                ),
                _buildActionChip(
                  'Update Brackets',
                  Icons.account_tree,
                  Colors.purple,
                  _canUpdateBrackets(),
                  () => _performQuickAction('brackets'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionChip(
    String label,
    IconData icon,
    Color color,
    bool enabled,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 2.w),
        decoration: BoxDecoration(
          color: enabled ? color.withOpacity(0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(2.w),
          border: Border.all(
            color: enabled ? color.withOpacity(0.3) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 4.w,
              color: enabled ? color[600] : Colors.grey[400],
            ),
            SizedBox(width: 2.w),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                color: enabled ? color[700] : Colors.grey[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationToggles() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Automation Settings ⚙️',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 3.w),
            _buildToggleItem(
              'Registration Management',
              'Auto open/close registration based on schedule',
              Icons.how_to_reg,
              _automationStatus['registration_automation'] ?? false,
              (value) => _updateAutomationSetting('registration', value),
            ),
            _buildToggleItem(
              'Match Pairing',
              'Automatically create pairings for next rounds',
              Icons.group_work,
              _automationStatus['pairing_automation'] ?? false,
              (value) => _updateAutomationSetting('pairing', value),
            ),
            _buildToggleItem(
              'Smart Notifications',
              'Send reminders and updates to participants',
              Icons.notifications_active,
              _automationStatus['notification_automation'] ?? false,
              (value) => _updateAutomationSetting('notifications', value),
            ),
            _buildToggleItem(
              'Bracket Progression',
              'Auto-advance winners and update brackets',
              Icons.trending_up,
              _automationStatus['progression_automation'] ?? false,
              (value) => _updateAutomationSetting('progression', value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleItem(
    String title,
    String description,
    IconData icon,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 3.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: value ? Colors.blue[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: value ? Colors.blue[200]! : Colors.grey[200]!,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: value ? Colors.blue[100] : Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 5.w,
              color: value ? Colors.blue[600] : Colors.grey[400],
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: Colors.blue[600],
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  Widget _buildScheduledActions() {
    final scheduledActions = _getScheduledActions();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Scheduled Actions 📅',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 3.w),
            if (scheduledActions.isEmpty)
              Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Icon(Icons.schedule, size: 8.w, color: Colors.grey[400]),
                    SizedBox(height: 2.w),
                    Text(
                      'No scheduled actions',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              )
            else
              ...scheduledActions.map((action) => _buildScheduledActionItem(action)),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduledActionItem(Map<String, dynamic> action) {
    final timeLeft = DateTime.parse(action['scheduled_time']).difference(DateTime.now());
    final isOverdue = timeLeft.isNegative;
    
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isOverdue ? Colors.red[50] : Colors.blue[50],
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: isOverdue ? Colors.red[200]! : Colors.blue[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getActionIcon(action['type']),
            size: 5.w,
            color: isOverdue ? Colors.red[600] : Colors.blue[600],
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action['title'],
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  isOverdue 
                      ? "Overdue by ${timeLeft.abs().inMinutes} minutes"
                      : 'In ${timeLeft.inMinutes} minutes',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isOverdue ? Colors.red[600] : Colors.blue[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _cancelScheduledAction(action['id']),
            icon: Icon(Icons.cancel, size: 5.w, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildAutomationLogs() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3.w)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Activity Log 📋',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Spacer(),
                TextButton(
                  onPressed: _clearLogs,
                  child: Text(
                    'Clear',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
            SizedBox(
              height: 30.h,
              child: _automationLogs.isEmpty
                  ? Center(
                      child: Text(
                        'No automation activity yet',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _automationLogs.length,
                      itemBuilder: (context, index) => _buildLogItem(_automationLogs[index]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final timestamp = DateTime.parse(log['timestamp']);
    final isError = log['type'] == 'error';
    
    return Container(
      margin: EdgeInsets.only(bottom: 2.w),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isError ? Colors.red[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error : Icons.check_circle,
            size: 4.w,
            color: isError ? Colors.red[600] : Colors.green[600],
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log['message'],
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[800],
                  ),
                ),
                Text(
                  _formatTimestamp(timestamp),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  bool _shouldShowRegistrationAutomation() {
    return [TournamentStatus.scheduled, TournamentStatus.registration].contains(widget.tournament.status);
  }

  bool _shouldShowPairingAutomation() {
    return [TournamentStatus.ready, TournamentStatus.inProgress].contains(widget.tournament.status);
  }

  bool _shouldShowNotificationAutomation() {
    return widget.tournament.status != TournamentStatus.completed;
  }

  bool _shouldShowProgressionAutomation() {
    return widget.tournament.status == TournamentStatus.inProgress;
  }

  bool _canStartTournament() {
    return widget.tournament.status == TournamentStatus.ready;
  }

  bool _canForcePairing() {
    return widget.tournament.status == TournamentStatus.inProgress;
  }

  bool _canUpdateBrackets() {
    return widget.tournament.status == TournamentStatus.inProgress;
  }

  List<Map<String, dynamic>> _getScheduledActions() {
    // Placeholder - implement actual scheduled actions retrieval
    return [
      {
        "id": '1',
        "type": 'registration_close',
        "title": 'Close Registration',
        'scheduled_time': DateTime.now().add(Duration(hours: 2)).toIso8601String(),
      },
      {
        "id": '2', 
        "type": 'tournament_start',
        "title": 'Start Tournament',
        'scheduled_time': DateTime.now().add(Duration(hours: 6)).toIso8601String(),
      },
    ];
  }

  IconData _getActionIcon(String type) {
    switch (type) {
      case 'registration_close':
        return Icons.how_to_reg;
      case 'tournament_start':
        return Icons.play_arrow;
      case 'pairing':
        return Icons.group_work;
      case 'notification':
        return Icons.notifications;
      default:
        return Icons.schedule;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  // Action handlers
  Future<void> _toggleAutomation(bool value) async {
    try {
      setState(() => _isAutomationActive = value);

      if (value) {
        await _automationService.startTournamentAutomation(widget.tournament.id);
        _addLog('Automation started', 'success');
      } else {
        await _automationService.stopTournamentAutomation(widget.tournament.id);
        _addLog('Automation stopped', 'success');
      }
    } catch (e) {
      _addLog('Failed to toggle automation: $e', 'error');
    }
  }

  Future<void> _performQuickAction(String action) async {
    try {
      switch (action) {
        case 'start':
          // Implement tournament start
          _addLog('Tournament started manually', 'success');
          break;
        case 'force_pairing':
          // Implement force pairing
          _addLog('Force pairing executed', 'success');
          break;
        case 'notifications':
          // Implement send notifications
          _addLog('Notifications sent', 'success');
          break;
        case 'brackets':
          // Implement bracket update
          _addLog('Brackets updated', 'success');
          break;
      }
    } catch (e) {
      _addLog('Failed to execute $action: $e', 'error');
    }
  }

  void _updateAutomationSetting(String setting, bool value) {
    setState(() {
      _automationStatus['${setting}_automation'] = value;
    });
    _addLog('${setting.toUpperCase()} automation ${value ? "enabled" : 'disabled'}', 'success');
  }

  void _cancelScheduledAction(String actionId) {
    _addLog('Scheduled action cancelled', 'success');
  }

  void _clearLogs() {
    setState(() {
      _automationLogs.clear();
    });
  }

  void _addLog(String message, String type) {
    setState(() {
      _automationLogs.insert(0, {
        'message': message,
        'type': type,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
      // Keep only last 50 logs
      if (_automationLogs.length > 50) {
        _automationLogs.removeRange(50, _automationLogs.length);
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}
