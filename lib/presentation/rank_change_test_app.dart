import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Simple Rank Change Test App
/// Test rank change request system without full app dependencies
class RankChangeTestApp extends StatefulWidget {
  const RankChangeTestApp({super.key});

@override
  State<RankChangeTestApp> createState() => _RankChangeTestAppState();
}

class _RankChangeTestAppState extends State<RankChangeTestApp> {
  final SupabaseClient _supabase = Supabase.instance.client;
  String _status = 'Ready to test';
  String _userInfo = 'Not logged in';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        // Get user details
        final userResult = await _supabase
            .from('users')
            .select('display_name, rank')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _userInfo = 'User: ${userResult['display_name']} - Rank: ${userResult['rank'] ?? 'No rank'}';
        });
      } else {
        () {
        setState(() {
          _userInfo = 'Not logged in';
        });
      }
    
      }} catch (e) {
      setState(() {
        _userInfo = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _testSubmitRankRequest() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing submit rank change request...';
    });

    try {
      final result = await _supabase.rpc('submit_rank_change_request', params: {
        "p_requested_rank": 'gold',
        "p_reason": 'Flutter app test - automated testing',
        'p_evidence_urls': ['https://example.com/test1.jpg', 'https://example.com/test2.jpg']
      });

      setState(() {
        _status = 'Submit test result: ${jsonEncode(result)}';
      });
    } catch (e) {
      setState(() {
        _status = 'Submit test error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetPendingRequests() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing get pending requests...';
    });

    try {
      final result = await _supabase.rpc('get_pending_rank_change_requests');

      setState(() {
        _status = 'Get requests result: ${jsonEncode(result)}';
      });
    } catch (e) {
      setState(() {
        _status = 'Get requests error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testViewNotifications() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing view rank change notifications...';
    });

    try {
      final result = await _supabase
          .from('notifications')
          .select('*')
          .eq('type', 'rank_change_request')
          .limit(5);

      setState(() {
        _status = 'Notifications found: ${result.length}\n${jsonEncode(result)}';
      });
    } catch (e) {
      setState(() {
        _status = 'Notifications error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Rank Change System Test'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Status Card
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'User Status',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(_userInfo),
                    SizedBox(height: 8.h),
                    ElevatedButton(
                      onPressed: _checkUserStatus,
                      child: const Text('Refresh User Info'),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            // Test Buttons
            Text(
              'Backend Function Tests',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 12.h),

            ElevatedButton(
              onPressed: _isLoading ? null : _testSubmitRankRequest,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(48.h),
              ),
              child: const Text('Test Submit Rank Request'),
            ),

            SizedBox(height: 8.h),

            ElevatedButton(
              onPressed: _isLoading ? null : _testGetPendingRequests,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(48.h),
              ),
              child: const Text('Test Get Pending Requests'),
            ),

            SizedBox(height: 8.h),

            ElevatedButton(
              onPressed: _isLoading ? null : _testViewNotifications,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size.fromHeight(48.h),
              ),
              child: const Text('View Notifications'),
            ),

            SizedBox(height: 24.h),

            // Status Display
            Card(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Test Status',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_isLoading) ...[
                          SizedBox(width: 8.w),
                          SizedBox(
                            width: 16.w,
                            height: 16.w,
                            child: const CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        _status,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

