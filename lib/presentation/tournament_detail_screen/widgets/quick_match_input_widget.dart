// 🚀 SABO ARENA - Quick Match Input Widget
// Cho phép CLB nhập tỷ số nhanh và tự động advance tournament

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class QuickMatchInputWidget extends StatefulWidget() {
  final String tournamentId;
  final List<Map<String, dynamic>> pendingMatches;
  final VoidCallback onMatchUpdated;

  const QuickMatchInputWidget({
    super.key,
    required this.tournamentId,
    required this.pendingMatches,
    required this.onMatchUpdated,
  });

  @override
  State<QuickMatchInputWidget> createState() => _QuickMatchInputWidgetState();
}

class _QuickMatchInputWidgetState extends State<QuickMatchInputWidget> {
  final SupabaseClient supabase = Supabase.instance.client;
  bool _isUpdating = false;
  final Map<String, String?> _selectedWinners = {};
  final Map<String, TextEditingController> _scoreControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    for (final match in widget.pendingMatches) {
      final matchId = match['id'] as String;
      _scoreControllers['${matchId}_p1'] = TextEditingController();
      _scoreControllers['${matchId}_p2'] = TextEditingController();
    }
  }

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pendingMatches.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12.sp),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600, size: 24.sp),
            SizedBox(width: 12.sp),
            Expanded(
              child: Text(
                '🎉 All matches completed! Tournament will advance automatically.',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.indigo.shade50],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sports_esports, color: Colors.blue.shade700, size: 24.sp),
              SizedBox(width: 12.sp),
              Expanded(
                child: Text(
                  '⚡ Quick Match Input',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
              ),
              if (_isUpdating)
                SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.blue.shade700),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.sp),
          Text(
            'Nhập kết quả trận đấu. Hệ thống sẽ tự động tạo vòng tiếp theo khi hoàn thành.',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.blue.shade600,
            ),
          ),
          SizedBox(height: 16.sp),
          
          // Match input list
          ...widget.pendingMatches.map((match) => _buildMatchInputCard(match)),
          
          SizedBox(height: 16.sp),
          
          // Quick actions
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUpdating ? null : _saveAllResults,
                  icon: Icon(Icons.save, size: 16.sp),
                  label: Text('Save All Results'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.sp),
                  ),
                ),
              ),
              SizedBox(width: 12.sp),
              ElevatedButton.icon(
                onPressed: _isUpdating ? null : _clearAll,
                icon: Icon(Icons.clear, size: 16.sp),
                label: Text('Clear'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12.sp),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMatchInputCard(Map<String, dynamic> match) {
    final matchId = match['id'] as String;
    final player1Name = match['player1_name'] ?? 'Player 1';
    final player2Name = match['player2_name'] ?? 'Player 2';
    final roundNumber = match['round_number'] ?? 1;
    final matchNumber = match['match_number'] ?? 1;

    return Card(
      margin: EdgeInsets.only(bottom: 12.sp),
      child: Padding(
        padding: EdgeInsets.all(12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Match header
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(6.sp),
                  ),
                  child: Text(
                    'R$roundNumber M$matchNumber',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ),
                Spacer(),
                Text(
                  'Select Winner:',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.sp),
            
            // Players and scores
            Row(
              children: [
                // Player 1
                Expanded(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          player1Name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: match['player1_id'],
                        groupValue: _selectedWinners[matchId],
                        onChanged: (value) {
                          setState(() {
                            _selectedWinners[matchId] = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: 40.sp,
                        child: TextField(
                          controller: _scoreControllers['${matchId}_p1'],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Score',
                            hintStyle: TextStyle(fontSize: 10.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(width: 16.sp),
                
                // VS
                Text(
                  'VS',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                  ),
                ),
                
                SizedBox(width: 16.sp),
                
                // Player 2
                Expanded(
                  child: Column(
                    children: [
                      RadioListTile<String>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          player2Name,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        value: match['player2_id'],
                        groupValue: _selectedWinners[matchId],
                        onChanged: (value) {
                          setState(() {
                            _selectedWinners[matchId] = value;
                          });
                        },
                      ),
                      SizedBox(
                        height: 40.sp,
                        child: TextField(
                          controller: _scoreControllers['${matchId}_p2'],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            hintText: 'Score',
                            hintStyle: TextStyle(fontSize: 10.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6.sp),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 8.sp),
                          ),
                          style: TextStyle(fontSize: 14.sp),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Quick save button for individual match
            SizedBox(height: 8.sp),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectedWinners[matchId] != null 
                    ? () => _saveMatchResult(match)
                    : null,
                icon: Icon(Icons.check, size: 14.sp),
                label: Text('Save Match', style: TextStyle(fontSize: 11.sp)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 8.sp),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMatchResult(Map<String, dynamic> match) async() {
    final matchId = match['id'] as String;
    final winnerId = _selectedWinners[matchId];
    
    if (winnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a winner'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try() {
      final player1Score = _scoreControllers['${matchId}_p1']?.text ?? '0';
      final player2Score = _scoreControllers['${matchId}_p2']?.text ?? '0';

      await supabase
          .from('matches')
          .update({
            'winner_id': winnerId,
            'player1_score': int.tryParse(player1Score) ?? 0,
            'player2_score': int.tryParse(player2Score) ?? 0,
            "status": 'completed',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', matchId);

      // Show success
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Match result saved!'),
            backgroundColor: Colors.green,
          ),
        );
      }

      // Trigger refresh
      widget.onMatchUpdated();

    } catch (e) {
      debugPrint('❌ Error saving match result: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error saving result: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally() {
      setState(() => _isUpdating = false);
    }
  }

  Future<void> _saveAllResults() async() {
    final matchesToSave = widget.pendingMatches
        .where((match) => _selectedWinners[match['id']] != null)
        .toList();

    if (matchesToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No winners selected'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUpdating = true);

    try() {
      for (final match in matchesToSave) {
        await _saveMatchResult(match);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 All results saved! Tournament advancing...'),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      debugPrint('❌ Error saving all results: $e');
    } finally() {
      setState(() => _isUpdating = false);
    }
  }

  void _clearAll() {
    setState(() {
      _selectedWinners.clear();
      for (final controller in _scoreControllers.values) {
        controller.clear();
      }
    });
  }
}