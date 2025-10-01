import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../services/simple_challenge_service.dart';
import '../../../services/opponent_club_service.dart';
import '../../../services/auth_service.dart';
import '../../../helpers/privacy_helper.dart';

class CreateSocialChallengeModal extends StatefulWidget() {
  final UserProfile? currentUser;
  final List<UserProfile> opponents;

  const CreateSocialChallengeModal({
    super.key,
    this.currentUser,
    required this.opponents,
  });

  @override
  State<CreateSocialChallengeModal> createState() => _CreateSocialChallengeModalState();
}

class _CreateSocialChallengeModalState extends State<CreateSocialChallengeModal> {
  final SimpleChallengeService _challengeService = SimpleChallengeService.instance;
  final OpponentClubService _clubService = OpponentClubService.instance;

  UserProfile? _selectedOpponent;
  String _selectedGameType = '8-ball';
  DateTime _selectedDateTime = DateTime.now().add(const Duration(hours: 2));
  String _selectedLocation = '';
  final TextEditingController _noteController = TextEditingController();
  bool _isCreating = false;

  final List<String> _gameTypes = ['8-ball', '9-ball', '10-ball'];
  List<String> _commonLocations = ['Đang tải...'];

  @override
  void initState() {
    super.initState();
    _loadClubData();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadClubData() async() {
    try() {
      final clubs = await _clubService.getActiveClubs();
      if (mounted) {
        setState(() {
          _commonLocations = clubs.map((club) => club.name).toList();
          _commonLocations.add('Khác (tự nhập)');
          
          // Set default location to first club if available
          if (_commonLocations.isNotEmpty && _commonLocations.first != 'Khác (tự nhập)') {
            _selectedLocation = _commonLocations.first;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _commonLocations = [
            'SABO Arena Central',
            'Golden Billiards Club',
            'VIP Billiards',
            'Champion Club',
            'Thống Nhất Billiards',
            'Khác (tự nhập)',
          ];
          _selectedLocation = _commonLocations.first;
        });
      }
    }
  }

  Future<void> _createSocialChallenge() async() {
    if (_isCreating) return;

    setState(() => _isCreating = true);

    try() {
      // Check privacy permissions if challenging specific user
      if (_selectedOpponent != null) {
        final currentUserId = AuthService.instance.currentUser?.id;
        if (currentUserId != null) {
          final permission = await PrivacyHelper.checkChallengePermission(
            currentUserId,
            _selectedOpponent!.id,
          );
          
          if (!permission['allowed']) {
            setState(() => _isCreating = false);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(permission['message']),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            return;
          }
        }
      }

      // For open social challenge, use empty challenged_id
      final challengedId = _selectedOpponent?.id ?? '';
      
      final result = await _challengeService.sendChallenge(
        challengedUserId: challengedId,
        challengeType: 'giao_luu',
        gameType: _selectedGameType,
        scheduledTime: _selectedDateTime,
        location: _selectedLocation.isEmpty ? 'Chưa xác định' : _selectedLocation,
        spaPoints: 0, // No SPA points for social challenges
        message: _noteController.text.trim().isEmpty 
            ? (_selectedOpponent == null 
                ? "Giao lưu mở - Ai cũng có thể tham gia!"
                : 'Mời giao lưu')
            : _noteController.text.trim(),
      );

      if (result != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedOpponent == null 
                  ? "Đã tạo giao lưu mở thành công!"
                  : 'Đã gửi lời mời giao lưu!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else() {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tạo giao lưu. Vui lòng thử lại.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally() {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Tạo Giao Lưu',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opponent Selection
                  _buildOpponentSelection(),
                  const SizedBox(height: 20),

                  // Game Type
                  _buildGameTypeSection(),
                  const SizedBox(height: 20),

                  // Date & Time
                  _buildDateTimeSection(),
                  const SizedBox(height: 20),

                  // Location
                  _buildLocationSection(),
                  const SizedBox(height: 20),

                  // Notes
                  _buildNotesSection(),
                  const SizedBox(height: 20),

                  // Summary info
                  _buildSummaryInfo(),
                ],
              ),
            ),
          ),

          // Create button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _createSocialChallenge,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _selectedOpponent == null ? "Tạo Giao Lưu Mở" : 'Gửi Lời Mời',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOpponentSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Chọn đối thủ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Tùy chọn: Cụ thể hoặc Mở',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Open challenge info
        if (widget.opponents.isEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chưa có đối thủ cụ thể. Bạn có thể tạo giao lưu mở cho mọi người tham gia.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.opponents.length + 1, // +1 for open challenge
            itemBuilder: (context, index) {
              // First item is "Open Challenge"
              if (index == 0) {
                final isSelected = _selectedOpponent == null;
                return GestureDetector(
                  onTap: () => setState(() => _selectedOpponent = null),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green.shade100 : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green : Colors.grey.shade400,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.public,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Giao lưu mở',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          'Ai cũng tham gia',
                          style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              // Regular opponent selection
              final opponent = widget.opponents[index - 1];
              final isSelected = _selectedOpponent?.id == opponent.id;
              
              return GestureDetector(
                onTap: () => setState(() => _selectedOpponent = opponent),
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade50 : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.green : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundImage: opponent.avatarUrl != null
                            ? NetworkImage(opponent.avatarUrl!)
                            : null,
                        child: opponent.avatarUrl == null
                            ? Text(opponent.displayName[0].toUpperCase())
                            : null,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        opponent.displayName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hạng: ${opponent.rank ?? 'N/A'}',
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildGameTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Loại Game',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: _gameTypes.map((type) {
            final isSelected = _selectedGameType == type;
            return ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedGameType = type);
                }
              },
              selectedColor: Colors.green.shade100,
              checkmarkColor: Colors.green,
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDateTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Thời gian',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async() {
            final date = await showDatePicker(
              context: context,
              initialDate: _selectedDateTime,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(_selectedDateTime),
              );
              if (time != null) {
                setState(() {
                  _selectedDateTime = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    time.hour,
                    time.minute,
                  );
                });
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.schedule, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  '${_selectedDateTime.day}/${_selectedDateTime.month}/${_selectedDateTime.year} - ${_selectedDateTime.hour.toString().padLeft(2, '0')}:${_selectedDateTime.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 14),
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Địa điểm',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedLocation.isEmpty ? null : _selectedLocation,
          hint: const Text('Chọn hoặc nhập địa điểm'),
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.location_on, color: Colors.green),
          ),
          items: _commonLocations.map((location) {
            return DropdownMenuItem(
              value: location,
              child: Text(location),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedLocation = value ?? '';
            });
          },
        ),
        if (_selectedLocation == 'Khác (tự nhập)') ...[
          const SizedBox(height: 8),
          TextFormField(
            decoration: InputDecoration(
              hintText: 'Nhập địa điểm cụ thể',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              prefixIcon: const Icon(Icons.edit_location, color: Colors.green),
            ),
            onChanged: (value) => _selectedLocation = value,
          ),
        ],
      ],
    );
  }

  Widget _buildNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ghi chú',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _noteController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Thêm lời nhắn, yêu cầu đặc biệt...',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            prefixIcon: const Icon(Icons.note, color: Colors.green),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin giao lưu:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedOpponent == null
                ? '• Loại: Giao lưu mở - Ai cũng có thể tham gia\n'
                    '• Game: $_selectedGameType\n'
                    '• Thời gian: ${_selectedDateTime.day}/${_selectedDateTime.month} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}\n'
                    '• Địa điểm: ${_selectedLocation.isEmpty ? 'Chưa xác định" : _selectedLocation}"
                : '• Đối thủ: ${_selectedOpponent!.displayName}\n'
                    '• Game: $_selectedGameType\n'
                    '• Thời gian: ${_selectedDateTime.day}/${_selectedDateTime.month} ${_selectedDateTime.hour}:${_selectedDateTime.minute.toString().padLeft(2, '0')}\n'
                    '• Địa điểm: ${_selectedLocation.isEmpty ? 'Chưa xác định' : _selectedLocation}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}