// 🏆 SABO ARENA - Match Result Entry Widget  
// Widget for entering match results with automatic bracket progression

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../services/match_progression_service.dart';

class MatchResultEntryWidget extends StatefulWidget {
  const MatchResultEntryWidget({super.key});

} 
  final String matchId;
  final String tournamentId;
  final Map<String, dynamic> matchData;
  final Function? onResultSubmitted;

  const MatchResultEntryWidget({
    super.key,
    required this.matchId,
    required this.tournamentId,
    required this.matchData,
    this.onResultSubmitted,
  });

  @override
  State<MatchResultEntryWidget> createState() => _MatchResultEntryWidgetState();
}

class _MatchResultEntryWidgetState extends State<MatchResultEntryWidget> {
  final MatchProgressionService _progressionService = MatchProgressionService.instance;
  
  bool _isSubmitting = false;
  int _player1Score = 0;
  int _player2Score = 0;
  String? _selectedWinner;
  final TextEditingController _notesController = TextEditingController();

  String get _player1Name => widget.matchData['player1']?['name'] ?? 'Player 1';
  String get _player2Name => widget.matchData['player2']?['name'] ?? 'Player 2';
  String? get _player1Id => widget.matchData['player1']?['id'];
  String? get _player2Id => widget.matchData['player2']?['id'];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.sp),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.sports_tennis, color: AppTheme.primaryLight),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  'Nhập kết quả trận đấu',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: AppTheme.textSecondaryLight),
              ),
            ],
          ),
          
          SizedBox(height: 20.sp),
          
          // Match info
          Container(
            padding: EdgeInsets.all(16.sp),
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.sp),
              border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
            ),
            child: Column(
              children: [
                Text(
                  '${widget.matchData['round'] ?? 'Round'} - Match ${widget.matchData['matchNumber'] ?? ''}',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryLight,
                  ),
                ),
                SizedBox(height: 8.sp),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _player1Name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.sp),
                      child: Text(
                        'VS',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _player2Name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24.sp),
          
          // Score input
          Text(
            'Điểm số',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          
          SizedBox(height: 12.sp),
          
          Row(
            children: [
              // Player 1 score
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _player1Name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.sp),
                    Container(
                      height: 60.sp,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerLight),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                _player1Score.toString(),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _player1Score++),
                                  child: Container(
                                    width: 40.sp,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(8.sp),
                                      ),
                                    ),
                                    child: Icon(Icons.add, color: Colors.white, size: 16.sp),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    if (_player1Score > 0) _player1Score--;
                                  }),
                                  child: Container(
                                    width: 40.sp,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSecondaryLight,
                                      borderRadius: BorderRadius.only(
                                        bottomRight: Radius.circular(8.sp),
                                      ),
                                    ),
                                    child: Icon(Icons.remove, color: Colors.white, size: 16.sp),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              SizedBox(width: 16.sp),
              
              // VS separator
              Container(
                padding: EdgeInsets.all(8.sp),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
              
              SizedBox(width: 16.sp),
              
              // Player 2 score
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _player2Name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8.sp),
                    Container(
                      height: 60.sp,
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.dividerLight),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Row(
                        children: [
                          Column(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _player2Score++),
                                  child: Container(
                                    width: 40.sp,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryLight,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(8.sp),
                                      ),
                                    ),
                                    child: Icon(Icons.add, color: Colors.white, size: 16.sp),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() {
                                    if (_player2Score > 0) _player2Score--;
                                  }),
                                  child: Container(
                                    width: 40.sp,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: AppTheme.textSecondaryLight,
                                      borderRadius: BorderRadius.only(
                                        bottomLeft: Radius.circular(8.sp),
                                      ),
                                    ),
                                    child: Icon(Icons.remove, color: Colors.white, size: 16.sp),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                _player2Score.toString(),
                                style: TextStyle(
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
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
          
          SizedBox(height: 24.sp),
          
          // Winner selection
          Text(
            'Người thắng',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          
          SizedBox(height: 12.sp),
          
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedWinner = _player1Id),
                  child: Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: _selectedWinner == _player1Id 
                          ? AppTheme.successLight.withOpacity(0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.sp),
                      border: Border.all(
                        color: _selectedWinner == _player1Id 
                            ? AppTheme.successLight 
                            : AppTheme.dividerLight,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedWinner == _player1Id 
                              ? Icons.radio_button_checked 
                              : Icons.radio_button_unchecked,
                          color: _selectedWinner == _player1Id 
                              ? AppTheme.successLight 
                              : AppTheme.textSecondaryLight,
                        ),
                        SizedBox(width: 8.sp),
                        Expanded(
                          child: Text(
                            _player1Name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: _selectedWinner == _player1Id 
                                  ? AppTheme.successLight 
                                  : AppTheme.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              SizedBox(width: 12.sp),
              
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _selectedWinner = _player2Id),
                  child: Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: _selectedWinner == _player2Id 
                          ? AppTheme.successLight.withOpacity(0.1) 
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.sp),
                      border: Border.all(
                        color: _selectedWinner == _player2Id 
                            ? AppTheme.successLight 
                            : AppTheme.dividerLight,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedWinner == _player2Id 
                              ? Icons.radio_button_checked 
                              : Icons.radio_button_unchecked,
                          color: _selectedWinner == _player2Id 
                              ? AppTheme.successLight 
                              : AppTheme.textSecondaryLight,
                        ),
                        SizedBox(width: 8.sp),
                        Expanded(
                          child: Text(
                            _player2Name,
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: _selectedWinner == _player2Id 
                                  ? AppTheme.successLight 
                                  : AppTheme.textPrimaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 24.sp),
          
          // Notes (optional)
          Text(
            'Ghi chú (tùy chọn)',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          
          SizedBox(height: 8.sp),
          
          TextField(
            controller: _notesController,
            decoration: InputDecoration(
              hintText: 'Thêm ghi chú về trận đấu...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.sp),
                borderSide: BorderSide(color: AppTheme.dividerLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.sp),
                borderSide: BorderSide(color: AppTheme.primaryLight),
              ),
            ),
            maxLines: 2,
          ),
          
          SizedBox(height: 24.sp),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _canSubmit && !_isSubmitting ? _submitResult : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.sp),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.sp),
                ),
              ),
              child: _isSubmitting
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20.sp,
                          height: 20.sp,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        Text('Đang cập nhật kết quả...'),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 20.sp),
                        SizedBox(width: 8.sp),
                        Text(
                          'Cập nhật kết quả',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _canSubmit() {
    return _selectedWinner != null && 
           (_player1Score > 0 || _player2Score > 0) &&
           _player1Id != null && _player2Id != null;
  }

  Future<void> _submitResult() async {
    if (!_canSubmit) return;

    setState(() => _isSubmitting = true);

    try {
      final loserId = _selectedWinner == _player1Id ? _player2Id! : _player1Id!;
      
      final result = await _progressionService.updateMatchResult(
        matchId: widget.matchId,
        tournamentId: widget.tournamentId,
        winnerId: _selectedWinner!,
        loserId: loserId,
        scores: {
          'player1': _player1Score,
          'player2': _player2Score,
        },
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (result['success']) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Kết quả đã được cập nhật!\n'
              '${result['progression_completed'] ? "🏃‍♂️ Bracket đã được cập nhật" : ""}'
              '${result['tournament_complete'] ? "\n🏆 Giải đấu đã hoàn thành!" : ""}'
            ),
            backgroundColor: AppTheme.successLight,
            duration: Duration(seconds: 3),
          ),
        );

        // Call callback if provided
        widget.onResultSubmitted?.call();

        // Close dialog
        Navigator.pop(context, result);

      } else {
        () {
        throw Exception(result['error'] ?? 'Unknown error');
      }

    
      }} catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi cập nhật kết quả: ${e.toString()}'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }
}
