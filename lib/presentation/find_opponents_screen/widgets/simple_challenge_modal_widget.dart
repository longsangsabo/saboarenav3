import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

// import '../../../core/app_export.dart';
import '../../../services/simple_challenge_service.dart';
import '../../../services/opponent_club_service.dart';

class SimpleChallengeModalWidget extends StatefulWidget() {
  final Map<String, dynamic> player;
  final String challengeType; // 'thach_dau' or 'giao_luu'
  final VoidCallback? onSendChallenge;

  const SimpleChallengeModalWidget({
    super.key,
    required this.player,
    required this.challengeType,
    this.onSendChallenge,
  });

  @override
  State<SimpleChallengeModalWidget> createState() => _SimpleChallengeModalWidgetState();
}

class _SimpleChallengeModalWidgetState extends State<SimpleChallengeModalWidget> {
  String _selectedGameType = '8-ball';
  int _spaPoints = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedLocation = '';
  final TextEditingController _messageController = TextEditingController();
  bool _isLoading = false;
  List<String> _locations = [];

  final List<String> _gameTypes = ['8-ball', '9-ball', '10-ball'];

  @override
  void initState() {
    super.initState();
    debugPrint('🎯 SimpleChallengeModal initState');
    debugPrint('   _isLoading: $_isLoading');
    debugPrint('   _selectedLocation: $_selectedLocation');
    debugPrint('   _selectedGameType: $_selectedGameType');
    _loadLocations();
  }

  Future<void> _loadLocations() async() {
    try() {
      debugPrint('🏢 Loading club locations from Supabase...');
      final clubs = await OpponentClubService.instance.getActiveClubs();
      
      final clubLocations = clubs.map((club) => club.name).toList();
      clubLocations.add('Khác (ghi chú)');
      
      if (mounted) {
        setState(() {
          _locations = clubLocations;
          _selectedLocation = _locations.isNotEmpty ? _locations.first : 'CLB SABO ARENA';
        });
      }
      
      debugPrint('✅ Loaded ${clubLocations.length - 1} club locations');
    } catch (error) {
      debugPrint('❌ Error loading club locations: $error');
      // Fallback to default locations
      final fallbackLocations = [
        'CLB SABO ARENA',
        'CLB BILLIARDS SAIGON', 
        'CLB CUE MASTER',
        'CLB CHAMPION',
        'Khác (ghi chú)',
      ];
      
      if (mounted) {
        setState(() {
          _locations = fallbackLocations;
          _selectedLocation = fallbackLocations.first;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: EdgeInsets.all(20),
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 85.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildPlayerInfo(),
                    SizedBox(height: 16),
                    _buildGameTypeSection(),
                    SizedBox(height: 16),
                    _buildDateTimeSection(),
                    SizedBox(height: 16),
                    _buildLocationSection(),
                    if (widget.challengeType == 'thach_dau') ...[
                      SizedBox(height: 16),
                      _buildSpaBettingSection(),
                    ],
                    SizedBox(height: 16),
                    _buildMessageSection(),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final title = widget.challengeType == 'thach_dau' ? "Gửi Thách Đấu" : 'Gửi Lời Mời Giao Lưu';
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildPlayerInfo() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: widget.player['avatar_url'] != null
                ? NetworkImage(widget.player['avatar_url'])
                : null,
            child: widget.player['avatar_url'] == null
                ? Icon(Icons.person, size: 20)
                : null,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.player['display_name'] ?? 'Người chơi',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'ELO: ${widget.player['elo_rating'] ?? 'N/A'}',
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
    );
  }

  Widget _buildGameTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loại game',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _selectedGameType,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
          items: _gameTypes.map((type) {
            return DropdownMenuItem(value: type, child: Text(type));
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGameType = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thời gian',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDate,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: _selectTime,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(fontSize: 13.sp),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa điểm',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _locations.isEmpty ? null : _selectedLocation,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            hintText: _locations.isEmpty ? 'Đang tải địa điểm...' : null,
            isDense: true,
          ),
          items: _locations.isEmpty 
            ? null
            : _locations.map((location) {
                return DropdownMenuItem(
                  value: location, 
                  child: Text(location),
                );
              }).toList(),
          onChanged: _locations.isEmpty 
            ? null
            : (value) {
                setState(() {
                  _selectedLocation = value!;
                });
              },
        ),
      ],
    );
  }

  Widget _buildSpaBettingSection() {
    final spaBettingOptions = SimpleChallengeService.instance.getSpaBettingOptions();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SPA Betting (Tùy chọn)',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _spaPoints,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            isDense: true,
          ),
          items: [
            DropdownMenuItem(value: 0, child: Text('Không bonus SPA')),
            ...spaBettingOptions.map((option) {
              return DropdownMenuItem(
                value: option['amount'] as int,
                child: Text('${option['amount']} SPA - ${option['description']}'),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _spaPoints = value!;
            });
          },
        ),
      ],
    );
  }

  Widget _buildMessageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lời nhắn (Tùy chọn)',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 6),
        TextField(
          controller: _messageController,
          maxLines: 2,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: 'Nhập lời nhắn cho đối thủ...',
            hintStyle: TextStyle(fontSize: 13.sp),
            contentPadding: EdgeInsets.all(12),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons() {
    debugPrint('🔧 _buildButtons called - _isLoading: $_isLoading, locations count: ${_locations.length}');
    return Row(
      children: [
        Expanded(
          child: TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: Text('Hủy', style: TextStyle(fontSize: 14.sp)),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : () {
              debugPrint('🔥 Button pressed! Calling _sendChallenge()');
              _sendChallenge();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : Text(
                    'Gửi',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  void _selectDate() async() {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectTime() async() {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _sendChallenge() async() {
    debugPrint('🎯 _sendChallenge() called!');
    
    if (_isLoading) {
      debugPrint('⚠️ Already loading, returning...');
      return;
    }

    // Validate required fields
    if (_selectedLocation.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Vui lòng chọn địa điểm!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try() {
      debugPrint('📝 Preparing challenge data...');
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      debugPrint('🎮 Sending challenge with data:');
      debugPrint('   - Player ID: ${widget.player['id']}');
      debugPrint('   - Challenge Type: ${widget.challengeType}');
      debugPrint('   - Game Type: $_selectedGameType');
      debugPrint('   - Location: $_selectedLocation');
      debugPrint('   - Scheduled: $scheduledDateTime');
      debugPrint('   - SPA Points: $_spaPoints');
      debugPrint('   - Message: ${_messageController.text.trim()}');

      await SimpleChallengeService.instance.sendChallenge(
        challengedUserId: widget.player['id'],
        challengeType: widget.challengeType,
        gameType: _selectedGameType,
        scheduledTime: scheduledDateTime,
        location: _selectedLocation,
        spaPoints: _spaPoints,
        message: _messageController.text.trim(),
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Đã gửi ${widget.challengeType == 'thach_dau' ? "thách đấu" : 'lời mời giao lưu'} thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onSendChallenge?.call();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Lỗi: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally() {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}