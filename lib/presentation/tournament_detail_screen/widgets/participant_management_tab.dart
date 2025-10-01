import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:sabo_arena/core/app_export.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/services/tournament_service.dart';

class ParticipantManagementTab extends StatefulWidget {
  const ParticipantManagementTab({super.key});

} 
  final String tournamentId;

  const ParticipantManagementTab({super.key, required this.tournamentId});

  @override
  _ParticipantManagementTabState createState() => _ParticipantManagementTabState();
}

class _ParticipantManagementTabState extends State<ParticipantManagementTab> {
  final TournamentService _tournamentService = TournamentService.instance;
  List<Map<String, dynamic>> _participants = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final participants = await _tournamentService
          .getTournamentParticipantsWithPaymentStatus(widget.tournamentId);
      debugPrint('🎯 UI: Loaded ${participants.length} participants');
      for (int i = 0; i < participants.length; i++) {
        final user = participants[i]['user'];
        debugPrint('   ${i + 1}. ${user?['full_name'] ?? 'Unknown'} - ${participants[i]['payment_status']}');
      }
      setState(() {
        _participants = participants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
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
            Text('Đang tải danh sách người chơi...'),
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
              onPressed: _loadParticipants,
              child: Text('Thử lại'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header with stats
        Container(
          padding: EdgeInsets.all(12.sp),
          margin: EdgeInsets.all(12.sp),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.sp),
            border: Border.all(color: AppTheme.primaryLight.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('Tổng cộng', _participants.length.toString(), Icons.people),
              _buildStatColumn('Đã thanh toán', 
                _participants.where((p) => p['payment_status'] == 'confirmed' || p['payment_status'] == 'completed').length.toString(), 
                Icons.check_circle),
              _buildStatColumn('Chưa thanh toán', 
                _participants.where((p) => p['payment_status'] == 'pending').length.toString(), 
                Icons.pending),
              // Quick actions
              Column(
                children: [
                  IconButton(
                    onPressed: _confirmAllPayments,
                    icon: Icon(Icons.done_all, color: AppTheme.successLight),
                    tooltip: 'Xác nhận tất cả',
                  ),
                  Text('Xác nhận\ntất cả', 
                       textAlign: TextAlign.center,
                       style: TextStyle(fontSize: 9.sp)),
                ],
              ),

            ],
          ),
        ),

        // Participants list
        Expanded(
          child: _participants.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 12.sp),
                  itemCount: _participants.length,
                  itemBuilder: (context, index) {
                    return _buildParticipantCard(_participants[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryLight, size: 18.sp),
        SizedBox(height: 4.sp),
        Text(value, 
             style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold)),
        Text(label, 
             textAlign: TextAlign.center,
             style: TextStyle(fontSize: 9.sp, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 40.sp, color: AppTheme.dividerLight),
          SizedBox(height: 10.sp),
          Text("Chưa có người chơi nào đăng ký", 
               style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600)),
          SizedBox(height: 4.sp),
          Text("Hãy chờ đợi hoặc mời thêm người chơi tham gia",
               style: TextStyle(fontSize: 11.sp, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Map<String, dynamic> participant) {
    final user = participant['user'];
    final paymentStatus = participant['payment_status'] ?? 'pending';
    final registeredAt = participant['registered_at'];
    final notes = participant['notes'];

    return Container(
      margin: EdgeInsets.only(bottom: 6.sp),
      padding: EdgeInsets.all(10.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: AppTheme.dividerLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main info row
          Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 20.sp,
                backgroundColor: AppTheme.primaryLight.withOpacity(0.1),
                child: user?['avatar_url'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(20.sp),
                        child: Image.network(
                          user['avatar_url'],
                          width: 40.sp,
                          height: 40.sp,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person,
                            color: AppTheme.primaryLight,
                            size: 20.sp,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.person,
                        color: AppTheme.primaryLight,
                        size: 20.sp,
                      ),
              ),
              SizedBox(width: 12.sp),
              
              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?['full_name'] ?? user?['email'] ?? 'Unknown User',
                      style: TextStyle(
                        fontSize: 13.sp,
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
                    if (_formatRegistrationDate(registeredAt).isNotEmpty)
                      Text(
                        _formatRegistrationDate(registeredAt),
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: Colors.grey[500],
                        ),
                      ),
                  ],
                ),
              ),
              
              // Payment status
              _buildPaymentStatusBadge(paymentStatus),
              
              // Actions menu
              PopupMenuButton<String>(
                onSelected: (action) => _handleParticipantAction(action, participant),
                itemBuilder: (context) => [
                  if (paymentStatus != 'confirmed')
                    PopupMenuItem(
                      value: 'confirm_payment',
                      child: Row(
                        children: [
                          Icon(Icons.check, color: AppTheme.successLight, size: 16.sp),
                          SizedBox(width: 8.sp),
                          Text('Xác nhận thanh toán'),
                        ],
                      ),
                    ),
                  if (paymentStatus == 'confirmed')
                    PopupMenuItem(
                      value: 'reset_payment',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: AppTheme.warningLight, size: 16.sp),
                          SizedBox(width: 8.sp),
                          Text('Đặt lại thanh toán'),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'add_note',
                    child: Row(
                      children: [
                        Icon(Icons.note_add, color: AppTheme.primaryLight, size: 16.sp),
                        SizedBox(width: 8.sp),
                        Text('Thêm ghi chú'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: AppTheme.errorLight, size: 16.sp),
                        SizedBox(width: 8.sp),
                        Text('Loại bỏ'),
                      ],
                    ),
                  ),
                ],
                child: Icon(Icons.more_vert, color: Colors.grey[600]),
              ),
            ],
          ),
          
          // Notes if any
          if (notes != null && notes.toString().isNotEmpty) ...[
            SizedBox(height: 8.sp),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(8.sp),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(6.sp),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                'Ghi chú: $notes',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentStatusBadge(String status) {
    Color backgroundColor;
    Color textColor;
    String text;
    IconData icon;

    switch (status) {
      case 'completed':
      case 'confirmed':
        backgroundColor = AppTheme.successLight.withOpacity(0.1);
        textColor = AppTheme.successLight;
        text = 'Đã thanh toán';
        icon = Icons.check_circle;
        break;
      case 'pending':
      default:
        backgroundColor = AppTheme.warningLight.withOpacity(0.1);
        textColor = AppTheme.warningLight;
        text = 'Chưa thanh toán';
        icon = Icons.pending;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 12.sp),
          SizedBox(width: 4.sp),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatRegistrationDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      return 'Đăng ký: ${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return '';
    }
  }

  Future<void> _confirmAllPayments() async {
    final unconfirmedParticipants = _participants
        .where((p) => p['payment_status'] != 'confirmed')
        .toList();

    if (unconfirmedParticipants.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tất cả người chơi đã được xác nhận thanh toán'),
          backgroundColor: AppTheme.primaryLight,
        ),
      );
      return;
    }

    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Xác nhận thanh toán hàng loạt'),
        content: Text('Bạn có chắc chắn muốn xác nhận thanh toán cho ${unconfirmedParticipants.length} người chơi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.sp),
            Text('Đang xác nhận thanh toán...'),
          ],
        ),
      ),
    );

    try {
      int successCount = 0;
      int errorCount = 0;

      for (final participant in unconfirmedParticipants) {
        try {
          await _tournamentService.updateParticipantPaymentStatus(
            tournamentId: widget.tournamentId,
            userId: participant['user_id'],
            paymentStatus: 'confirmed',
            notes: 'Xác nhận hàng loạt bởi quản lý CLB - ${DateTime.now().toString().substring(0, 19)}',
          );
          successCount++;
        } catch (e) {
          errorCount++;
        }
      }

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hoàn thành: $successCount thành công, $errorCount lỗi'),
          backgroundColor: successCount > errorCount ? AppTheme.successLight : AppTheme.warningLight,
          duration: Duration(seconds: 4),
        ),
      );

      _loadParticipants(); // Refresh list
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xác nhận thanh toán: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }



  Future<void> _confirmPayment(Map<String, dynamic> participant) async {
    try {
      // Show confirmation dialog first
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Xác nhận thanh toán'),
          content: Text('Xác nhận thanh toán cho ${participant['user']['full_name']}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Xác nhận'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      await _tournamentService.updateParticipantPaymentStatus(
        tournamentId: widget.tournamentId,
        userId: participant['user_id'],
        paymentStatus: 'confirmed',
        notes: 'Đã xác nhận thanh toán bởi quản lý CLB - ${DateTime.now().toString().substring(0, 19)}',
      );

      Navigator.of(context).pop(); // Close loading dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xác nhận thanh toán cho ${participant['user']['full_name']}'),
          backgroundColor: AppTheme.successLight,
          duration: Duration(seconds: 3),
        ),
      );

      _loadParticipants(); // Refresh list
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog if open
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xác nhận thanh toán: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
          duration: Duration(seconds: 4),
        ),
      );
    }
  }

  void _handleParticipantAction(String action, Map<String, dynamic> participant) {
    switch (action) {
      case 'confirm_payment':
        _confirmPayment(participant);
        break;
      case 'reset_payment':
        _resetPaymentStatus(participant);
        break;
      case 'add_note':
        _showAddNoteDialog(participant);
        break;
      case 'remove':
        _showRemoveParticipantDialog(participant);
        break;
    }
  }

  Future<void> _resetPaymentStatus(Map<String, dynamic> participant) async {
    try {
      await _tournamentService.updateParticipantPaymentStatus(
        tournamentId: widget.tournamentId,
        userId: participant['user_id'],
        paymentStatus: 'pending',
        notes: 'Đặt lại trạng thái thanh toán bởi quản lý CLB',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã đặt lại trạng thái thanh toán'),
          backgroundColor: AppTheme.warningLight,
        ),
      );

      _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi đặt lại trạng thái: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }

  void _showAddNoteDialog(Map<String, dynamic> participant) {
    final noteController = TextEditingController(text: participant['notes'] ?? '');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ghi chú cho ${participant['user']['full_name']}'),
        content: TextField(
          controller: noteController,
          decoration: InputDecoration(
            hintText: 'Nhập ghi chú...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await _tournamentService.updateParticipantPaymentStatus(
                  tournamentId: widget.tournamentId,
                  userId: participant['user_id'],
                  paymentStatus: participant['payment_status'],
                  notes: noteController.text,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Đã cập nhật ghi chú')),
                );
                _loadParticipants();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi cập nhật ghi chú: ${e.toString()}'),
                    backgroundColor: AppTheme.errorLight,
                  ),
                );
              }
            },
            child: Text('Lưu'),
          ),
        ],
      ),
    );
  }

  void _showRemoveParticipantDialog(Map<String, dynamic> participant) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Loại bỏ người chơi'),
        content: Text('Bạn có chắc chắn muốn loại bỏ ${participant['user']['full_name']} khỏi giải đấu?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Implementation for removing participant
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Tính năng loại bỏ người chơi đang được phát triển'),
                    backgroundColor: AppTheme.warningLight,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Lỗi loại bỏ người chơi: ${e.toString()}'),
                    backgroundColor: AppTheme.errorLight,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorLight),
            child: Text('Loại bỏ'),
          ),
        ],
      ),
    );
  }
}
