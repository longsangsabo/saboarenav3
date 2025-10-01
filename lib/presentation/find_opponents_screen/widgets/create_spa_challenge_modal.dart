import 'package:flutter/material.dart';

import '../../../models/user_profile.dart';
import '../../../services/club_spa_service.dart';
import '../../../services/simple_challenge_service.dart';
import '../../../services/user_service.dart';

class CreateSpaChallengeModal extends StatefulWidget {
  const CreateSpaChallengeModal({super.key});

} 
  final UserProfile? currentUser;
  final List<UserProfile> opponents;

  const CreateSpaChallengeModal({
    super.key,
    required this.currentUser,
    required this.opponents,
  });

  @override
  State<CreateSpaChallengeModal> createState() => _CreateSpaChallengeModalState();
}

class _CreateSpaChallengeModalState extends State<CreateSpaChallengeModal> {
  final ClubSpaService _clubSpaService = ClubSpaService();
  final SimpleChallengeService _challengeService = SimpleChallengeService.instance;
  final UserService _userService = UserService.instance;

  // SPA Betting Configuration - matches challenge_rules_service.dart
  static const Map<int, int> _spaBettingConfig = {
    100: 8,   // 100 SPA → Race to 8
    200: 12,  // 200 SPA → Race to 12  
    300: 14,  // 300 SPA → Race to 14
    400: 16,  // 400 SPA → Race to 16
    500: 18,  // 500 SPA → Race to 18
    600: 22,  // 600 SPA → Race to 22
  };

  UserProfile? _selectedOpponent;
  int _selectedSpaBonus = 100; // Default SPA bonus
  int _selectedRaceTo = 8; // Race-to value (auto-determined by SPA)
  String _selectedGameType = '8-ball';
  bool _isCreating = false;
  
  final TextEditingController _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  bool get _canCreateChallenge() {
    return true; // Always allow creation (either specific opponent or open challenge)
  }

  Future<void> _createChallenge() async {
    if (!_canCreateChallenge) return;

    setState(() => _isCreating = true);

    try {
      // Get current user profile
      final currentUser = await _userService.getCurrentUserProfile();
      if (currentUser == null) {
        throw Exception('Không thể lấy thông tin người dùng');
      }

      // For now, use a default club ID since UserProfile doesn't have clubId field
      // In a real implementation, you would get the user's club from another service
      const String defaultClubId = 'default-club-id'; // This should be retrieved from user's club membership
      
      // Check club SPA balance
      final clubBalance = await _clubSpaService.getClubSpaBalance(defaultClubId);
      if (clubBalance == null) {
        // If no club balance record exists, we can still create the challenge
        // The SPA reward will be handled when the match is completed
        debugPrint('⚠️ No club SPA balance found, proceeding with challenge creation');
      } else {
        () {
        final availableSpa = clubBalance['available_spa'] ?? 0.0;
        if (availableSpa < _selectedSpaBonus) {
          throw Exception('Club không đủ SPA để tạo thách đấu (Cần: $_selectedSpaBonus, Có: ${availableSpa.toInt()})');
        }
      }

      // Create the challenge with SPA stakes
      
      }final challengeResult = await _challengeService.sendChallenge(
        challengedUserId: _selectedOpponent?.id ?? '', // Use empty string for open challenge, service will handle as null
        challengeType: 'thach_dau', // SPA challenges are competitive
        gameType: _selectedGameType, // Use selected game type
        scheduledTime: DateTime.now().add(const Duration(hours: 24)), // Default scheduled time
        location: 'TBD', // To be determined
        spaPoints: _selectedSpaBonus,
        message: _noteController.text.trim().isEmpty 
            ? _selectedOpponent != null 
              ? "Thách đấu SPA: $_selectedGameType, Race to $_selectedRaceTo, Thắng +$_selectedSpaBonus SPA / Thua -$_selectedSpaBonus SPA"
              : 'Thách đấu mở: $_selectedGameType, Race to $_selectedRaceTo, Thắng +$_selectedSpaBonus SPA / Thua -$_selectedSpaBonus SPA - Ai cũng có thể tham gia!'
            : _noteController.text.trim(),
      );

      if (challengeResult != null) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _selectedOpponent != null
                  ? 'Thách đấu SPA đã được gửi thành công!\n'
                    'Đối thủ: ${_selectedOpponent!.displayName}\n'
                    'Game: $_selectedGameType (Race to $_selectedRaceTo)\n'
                    'SPA Bonus: ±$_selectedSpaBonus\n'
                    'ID thách đấu: ${challengeResult['id"]}"
                  : 'Thách đấu mở đã được tạo thành công!\n'
                    'Game: $_selectedGameType (Race to $_selectedRaceTo)\n'
                    'SPA Bonus: ±$_selectedSpaBonus\n'
                    'Loại: Thách đấu mở - Ai cũng tham gia được\n'
                    'ID thách đấu: ${challengeResult['id']}',
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } else {
        () {
        throw Exception('Không thể tạo thách đấu');
      }
    
      }} catch (e) {
      debugPrint('Error creating SPA challenge: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi tạo thách đấu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header
          Row(
            children: [
              const Icon(Icons.sports_martial_arts, size: 28, color: Colors.green),
              const SizedBox(width: 12),
              const Text(
                'Tạo thách đấu SPA',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Opponent Selection
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
          
          // Display message when no specific opponents are available
          if (widget.opponents.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade600, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Chưa có đối thủ cụ thể. Bạn có thể tạo thách đấu mở cho mọi người tham gia.',
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
              itemCount: widget.opponents.length + 1, // +1 for open challenge option
              itemBuilder: (context, index) {
                // First item is "Open Challenge" option
                if (index == 0) {
                  final isOpenChallenge = _selectedOpponent == null;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedOpponent = null),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isOpenChallenge ? Colors.blue.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isOpenChallenge ? Colors.blue : Colors.grey.shade300,
                          width: isOpenChallenge ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.blue.shade100,
                            child: Icon(
                              Icons.public,
                              color: Colors.blue.shade700,
                              size: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Thách đấu mở',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            'Ai cũng tham gia',
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                // Regular opponent selection (index - 1 because of open challenge option)
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
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Hạng: ${opponent.rank ?? 'N/A'}',
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 20),

          // SPA Bonus Selection with Race-to Auto-sync
          Row(
            children: [
              const Text(
                'Phần thưởng SPA cho người thắng',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                'SPA cao → Race-to dài',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: _spaBettingConfig.keys.map((amount) {
              final isSelected = _selectedSpaBonus == amount;
              final raceTo = _spaBettingConfig[amount]!;
              return ChoiceChip(
                label: Text('$amount SPA\n(Race to $raceTo)', 
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedSpaBonus = amount;
                      _selectedRaceTo = raceTo; // Auto-sync race-to
                    });
                  }
                },
                selectedColor: Colors.green.shade100,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.green.shade800 : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Game Type and Race-to Display
          Row(
            children: [
              // Game Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Loại game:', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGameType,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: ['8-ball', '9-ball', '10-ball'].map((gameType) => DropdownMenuItem(
                        value: gameType,
                        child: Text(gameType, style: const TextStyle(fontSize: 14)),
                      )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGameType = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Race-to (Auto-determined by SPA amount)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Race to:', style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          Text(
                            '$_selectedRaceTo',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '(Auto từ SPA)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Info about SPA Challenge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thông tin thách đấu SPA:\n'
                    '• Game: $_selectedGameType - Race to $_selectedRaceTo (theo $_selectedSpaBonus SPA)\n'
                    '• SPA Bonus: Thắng +$_selectedSpaBonus, Thua -$_selectedSpaBonus\n'
                    '• Quy tắc: SPA càng cao → Race-to càng dài\n'
                    '• Đối thủ: ${_selectedOpponent == null ? "Thách đấu mở - Ai cũng có thể tham gia" : "Thách đấu cụ thể với ${_selectedOpponent!.displayName}"}\n'
                    '• Nguồn SPA từ club pool',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Challenge Note
          const Text(
            'Ghi chú thách đấu (tùy chọn)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _selectedOpponent == null 
                ? "Thêm lời nhắn cho thách đấu mở..."
                : 'Thêm lời nhắn cho ${_selectedOpponent!.displayName}...',
              border: const OutlineInputBorder(),
            ),
            onChanged: (value) => {}, // Note content is handled by controller
          ),
          const SizedBox(height: 100), // Extra space for the fixed button
                ],
              ),
            ),
          ),

          // Fixed Create Button at bottom
          Container(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _canCreateChallenge && !_isCreating ? _createChallenge : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isCreating
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Gửi thách đấu SPA',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
