import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sizer/sizer.dart';
import '../../services/admin_service.dart';

class AdminTournamentManagementScreen extends StatefulWidget {
  const AdminTournamentManagementScreen({super.key});

@override
  State<AdminTournamentManagementScreen> createState() => _AdminTournamentManagementScreenState();
}

class _AdminTournamentManagementScreenState extends State<AdminTournamentManagementScreen> {
  final AdminService _adminService = AdminService.instance;
  
  List<Map<String, dynamic>> _tournaments = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _operationMessage;
  bool _isOperationInProgress = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      final isAdmin = await _adminService.isCurrentUserAdmin();
      setState(() {
        _isAdmin = isAdmin;
      });
      
      if (isAdmin) {
        await _loadTournaments();
      } else {
        () {
        setState(() {
          _isLoading = false;
        });
      }
    
      }} catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadTournaments() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final tournaments = await _adminService.getTournamentsForAdmin(
        limit: 20,
      );

      setState(() {
        _tournaments = tournaments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Failed to load tournaments: $e');
    }
  }

  Future<void> _addAllUsersToTournament(String tournamentId, String tournamentTitle) async {
    try {
      setState(() {
        _isOperationInProgress = true;
        _operationMessage = null;
      });

      final result = await _adminService.addAllUsersToTournament(tournamentId);

      setState(() {
        _operationMessage = '🎉 Success! Added ${result['users_added']} users to "$tournamentTitle". '
            'Total participants: ${result['total_participants']}/${result['max_participants']}';
      });

      // Reload tournaments to show updated participant counts  
      await _loadTournaments();

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Successfully added ${result['users_added']} users to tournament!'),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      setState(() {
        // More user-friendly error messages for adding users
        String errorMsg = e.toString();
        if (errorMsg.contains('PostgrestException')) {
          _operationMessage = '❌ Database error: Please try again or contact support.';
        } else if (errorMsg.contains('Access denied')) {
          _operationMessage = '❌ Access denied: You do not have permission to perform this action.';
        } else if (errorMsg.contains('Tournament not found')) {
          _operationMessage = '❌ Tournament not found. Please refresh and try again.';
        } else if (errorMsg.contains('Tournament must be in upcoming status')) {
          _operationMessage = '❌ Can only add users to upcoming tournaments.';
        } else {
          _operationMessage = '❌ Failed to add users to tournament. Please try again.';
        }
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to add users: ${_extractErrorMessage(e.toString())}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
      
      // Auto-hide operation message after 5 seconds
      if (_operationMessage != null) {
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _operationMessage = null;
            });
          }
        });
      }
    }
  }

  Future<void> _removeAllUsersFromTournament(String tournamentId, String tournamentTitle) async {
    try {
      setState(() {
        _isOperationInProgress = true;
        _operationMessage = null;
      });

      final result = await _adminService.removeAllUsersFromTournament(tournamentId);

      setState(() {
        _operationMessage = '🗑️ Success! Removed ${result['users_removed']} users from "$tournamentTitle".';
      });

      // Reload tournaments to show updated participant counts
      await _loadTournaments();

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Successfully removed ${result['users_removed']} users from tournament!'),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }

    } catch (e) {
      setState(() {
        _operationMessage = '❌ Failed to remove users from tournament. ${_extractErrorMessage(e.toString())}';
      });

      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to remove users: ${_extractErrorMessage(e.toString())}'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      setState(() {
        _isOperationInProgress = false;
      });
      
      // Auto-hide operation message after 5 seconds
      if (_operationMessage != null) {
        Future.delayed(Duration(seconds: 5), () {
          if (mounted) {
            setState(() {
              _operationMessage = null;
            });
          }
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _extractErrorMessage(String fullError) {
    // Extract user-friendly error message from technical error
    if (fullError.contains('PostgrestException')) {
      if (fullError.contains('row violates row-level security')) {
        return 'Permission denied - RLS policy violation';
      } else if (fullError.contains('column') && fullError.contains('GROUP BY')) {
        return 'Database query error';
      } else {
        return 'Database operation failed';
      }
    } else if (fullError.contains('Access denied')) {
      return 'Insufficient permissions';
    } else if (fullError.contains('Tournament not found')) {
      return 'Tournament no longer exists';
    } else {
      return 'Unexpected error occurred';
    }
  }

  void _showConfirmDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(
              title.contains('Add') ? Icons.group_add : Icons.warning,
              color: title.contains('Add') ? Colors.green : Colors.orange,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          content,
          style: TextStyle(fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: title.contains('Add') ? Colors.green : Colors.orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Confirm',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Tournament Management'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTournaments,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: SvgPicture.asset(
            'assets/images/logo.svg',
            width: 60,
            height: 60,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    if (!_isAdmin) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.admin_panel_settings,
              size: 64,
              color: Colors.grey[400],
            ),
            SizedBox(height: 2.h),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'You need admin permissions to access this screen.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Operation Message
        if (_operationMessage != null)
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(2.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: _operationMessage!.startsWith('Error') 
                  ? Colors.red[50] 
                  : Colors.green[50],
              border: Border.all(
                color: _operationMessage!.startsWith('Error') 
                    ? Colors.red 
                    : Colors.green,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _operationMessage!,
              style: TextStyle(
                color: _operationMessage!.startsWith('Error') 
                    ? Colors.red[800] 
                    : Colors.green[800],
                fontSize: 12.sp,
              ),
            ),
          ),

        // Enhanced Progress Indicator
        if (_isOperationInProgress)
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(2.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              border: Border.all(color: Colors.blue),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing tournament operation...',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.blue[800],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  backgroundColor: Colors.blue[100],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
              ],
            ),
          ),

        // Tournament List
        Expanded(
          child: _tournaments.isEmpty
              ? _buildEmptyState()
              : _buildTournamentList(),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.emoji_events_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 2.h),
          Text(
            'No Tournaments Found',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentList() {
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: _tournaments.length,
      itemBuilder: (context, index) {
        final tournament = _tournaments[index];
        return _buildTournamentCard(tournament);
      },
    );
  }

  Widget _buildTournamentCard(Map<String, dynamic> tournament) {
    final title = tournament['title'] ?? 'Unknown Tournament';
    final status = tournament['status'] ?? 'unknown';
    final currentParticipants = tournament['current_participants'] ?? 0;
    final maxParticipants = tournament['max_participants'] ?? 0;
    final clubName = tournament['club']?['name'] ?? 'No Club';
    
    final canAddUsers = status == 'upcoming' && currentParticipants < maxParticipants;
    final canRemoveUsers = currentParticipants > 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tournament Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        'Club: $clubName',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 1.h),
            
            // Participants Info
            Row(
              children: [
                Icon(Icons.people, size: 16.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  'Participants: $currentParticipants/$maxParticipants',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 1.5.h),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canAddUsers && !_isOperationInProgress
                        ? () => _showConfirmDialog(
                              title: '👥 Add All Users',
                              content: 'Are you sure you want to add all users to "$title"?\n\nThis action will add all registered users to the tournament.',
                              onConfirm: () => _addAllUsersToTournament(
                                tournament['id'],
                                title,
                              ),
                            )
                        : null,
                    icon: Icon(
                      _isOperationInProgress ? Icons.hourglass_empty : Icons.group_add, 
                      size: 16
                    ),
                    label: Text(
                      _isOperationInProgress ? "Processing..." : 'Add All Users',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canAddUsers && !_isOperationInProgress 
                          ? Colors.green 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: canAddUsers && !_isOperationInProgress ? 2 : 0,
                    ),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canRemoveUsers && !_isOperationInProgress
                        ? () => _showConfirmDialog(
                              title: '🗑️ Remove All Users',
                              content: 'Are you sure you want to remove ALL users from "$title"?\n\n⚠️ This action cannot be undone.',
                              onConfirm: () => _removeAllUsersFromTournament(
                                tournament['id'],
                                title,
                              ),
                            )
                        : null,
                    icon: Icon(
                      _isOperationInProgress ? Icons.hourglass_empty : Icons.group_remove, 
                      size: 16
                    ),
                    label: Text(
                      _isOperationInProgress ? "Processing..." : 'Remove All',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canRemoveUsers && !_isOperationInProgress 
                          ? Colors.orange 
                          : Colors.grey,
                      foregroundColor: Colors.white,
                      elevation: canRemoveUsers && !_isOperationInProgress ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'upcoming':
        return Colors.blue;
      case 'ongoing':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

