import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/simple_challenge_service.dart';
import 'package:flutter/foundation.dart';
// import '../../../services/challenge_service.dart';
// import '../../../services/challenge_service_extensions.dart';
// import '../../../services/challenge_rules_service.dart';

class ChallengeModalWidget extends StatefulWidget {
  const ChallengeModalWidget({super.key});

} 
  final Map<String, dynamic> player;
  final String challengeType; // 'thach_dau' or 'giao_luu'
  final VoidCallback? onSendChallenge;

  const ChallengeModalWidget({
    super.key,
    required this.player,
    required this.challengeType,
    this.onSendChallenge,
  });

  @override
  State<ChallengeModalWidget> createState() => _ChallengeModalWidgetState();
}

class _ChallengeModalWidgetState extends State<ChallengeModalWidget> {
  String _selectedGameType = '8-ball';
  final int _handicapValue = 0;
  int _spaPoints = 0;
  DateTime _selectedDate = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _selectedTime = TimeOfDay.now();
  String _selectedLocation = '';
  
  // Challenge validation and handicap info
  // ChallengeHandicapResult? _handicapPreview;

  final List<String> _gameTypes = ['8-ball', '9-ball', '10-ball'];
  final List<String> _locations = [
    'Billiards Club Sài Gòn',
    'Pool House Thủ Đức',
    'Champion Billiards',
    'Golden Ball Club',
    'Khác (ghi chú)',
  ];

  @override
  void initState() {
    super.initState();
    _selectedLocation = _locations.first;
  }

  /// Update handicap preview when SPA points change
  Future<void> _updateHandicapPreview() async {
    if (_spaPoints == 0 || widget.challengeType != 'thach_dau') {
      _handicapPreview = null;
      return;
    }

    try {
      final playerId = widget.player['user_id'] as String?;
      if (playerId == null) return;

      final handicapResult = await ChallengeService.instance.previewChallengeHandicap(
        challengerId: '', // Will be filled by service from current user
        challengedId: playerId,
        spaBetAmount: _spaPoints,
      );

      _handicapPreview = handicapResult;
    } catch (error) {
      debugPrint('❌ Error updating handicap preview: $error');
      _handicapPreview = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.bottomSheetTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: EdgeInsets.only(top: 1.h),
            width: 12.w,
            height: 0.5.h,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.challengeType == 'thach_dau'
                          ? "Thách đấu"
                          : 'Giao lưu',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'với ${widget.player["name"]}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: CustomIconWidget(
                    iconName: 'close',
                    color: colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outline.withOpacity(0.2)),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGameTypeSelection(),
                  SizedBox(height: 3.h),
                  if (widget.challengeType == 'thach_dau') ...[
                    _buildHandicapSelection(),
                    SizedBox(height: 3.h),
                    _buildSpaPointsSelection(),
                    SizedBox(height: 3.h),
                  ],
                  _buildDateTimeSelection(),
                  SizedBox(height: 3.h),
                  _buildLocationSelection(),
                  SizedBox(height: 3.h),
                  _buildNotesSection(),
                  SizedBox(height: 4.h),
                ],
              ),
            ),
          ),

          // Send challenge button
          Container(
            padding: EdgeInsets.all(4.w),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendChallenge,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: Text(
                  widget.challengeType == 'thach_dau'
                      ? "Gửi thách đấu"
                      : 'Gửi lời mời giao lưu',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _buildGameTypeSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Loại game',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          children: _gameTypes.map((gameType) {
            final isSelected = _selectedGameType == gameType;
            return ChoiceChip(
              label: Text(gameType),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedGameType = gameType;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildHandicapSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Handicap (Tự động tính)',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            // Show handicap preview if available
            if (_handicapPreview != null && _handicapPreview!.isValid) ...[
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _handicapPreview!.explanation.isNotEmpty
                      ? _getHandicapDisplayText()
                      : 'Không handicap',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ] else ...[
              Text(
                'Chọn SPA để tính',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ],
        ),
        if (_handicapPreview != null && _handicapPreview!.isValid && _handicapPreview!.explanation.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _handicapPreview!.explanation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getHandicapDisplayText() {
    if (_handicapPreview == null || !_handicapPreview!.isValid) return 'Không handicap';
    
    if (_handicapPreview!.challengerHandicap > 0) {
      return '+${_handicapPreview!.challengerHandicap} bàn';
    } else if (_handicapPreview!.challengedHandicap > 0) {
      return 'Đối thủ +${_handicapPreview!.challengedHandicap} bàn';
    } else {
      return 'Không handicap';
    }
  }

  Widget _buildSpaPointsSelection() {
    final theme = Theme.of(context);
    final spaBettingOptions = ChallengeService.instance.getSpaBettingOptions();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Điểm SPA cược',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              _spaPoints == 0 ? "Không cược" : '$_spaPoints điểm',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: [
            // No bet option
            ChoiceChip(
              label: const Text('Không cược'),
              selected: _spaPoints == 0,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _spaPoints = 0;
                    _handicapPreview = null;
                  });
                }
              },
            ),
            // SPA betting options from rules service
            ...spaBettingOptions.map((option) {
              final points = option['amount'] as int;
              final raceTo = option['raceTo'] as int;
              final isSelected = _spaPoints == points;
              
              return ChoiceChip(
                label: Text('$points (R-$raceTo)'),
                selected: isSelected,
                onSelected: (selected) async {
                  if (selected) {
                    setState(() {
                      _spaPoints = points;
                    });
                    
                    // Calculate handicap preview
                    await _updateHandicapPreview();
                  }
                },
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Thời gian',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectDate,
                icon: CustomIconWidget(
                  iconName: 'calendar_today',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                ),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _selectTime,
                icon: CustomIconWidget(
                  iconName: 'access_time',
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                label: Text(
                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLocationSelection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Địa điểm',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        DropdownButtonFormField<String>(
          initialValue: _selectedLocation,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding:
                EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          ),
          items: _locations.map((location) {
            return DropdownMenuItem(
              value: location,
              child: Text(location),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedLocation = value;
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ghi chú',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 1.h),
        TextField(
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Thêm ghi chú cho trận đấu...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: EdgeInsets.all(3.w),
          ),
          
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  void _sendChallenge() async {
    try {
      final challengeService = ChallengeService.instance;
      final playerId = widget.player['id'] ?? widget.player['user_id'] ?? '';
      
      // 🔍 STEP 1: Validate challenge before sending
      if (widget.challengeType == 'thach_dau' && _spaPoints > 0) {
        final validationResult = await challengeService.validateChallengeBeforeSending(
          challengedId: playerId,
          challengeType: widget.challengeType,
          spaBetAmount: _spaPoints,
        );

        if (!validationResult.isValid) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ ${validationResult.errorMessage}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
          return;
        }
      }
      
      // Combine date and time for scheduled time
      final scheduledDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      // 🚀 STEP 2: Send challenge with validation passed
      await challengeService.sendChallenge(
        challengedUserId: playerId,
        challengeType: widget.challengeType,
        gameType: _selectedGameType,
        scheduledTime: scheduledDateTime,
        location: _selectedLocation,
        handicap: _handicapValue,
        spaPoints: _spaPoints,
        message: 'Thách đấu từ ứng dụng SABO ARENA',
      );

      if (widget.onSendChallenge != null) {
        widget.onSendChallenge!();
      }
      
      if (mounted) {
        Navigator.of(context).pop();

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.challengeType == 'thach_dau'
                  ? "Đã gửi thách đấu đến ${widget.player["name"]} thành công! 🎯"
                  : 'Đã gửi lời mời giao lưu đến ${widget.player["name"]} thành công! 🎱',
            ),
            backgroundColor: AppTheme.successLight,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: ${error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}
