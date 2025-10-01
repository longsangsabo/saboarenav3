// Test Referral System - SABO Arena
// Chạy file này để test hệ thống referral trước khi phát hành app

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'services/basic_referral_service.dart';
import 'services/auth_service.dart';

class ReferralTestScreen extends StatefulWidget {
  @override
  _ReferralTestScreenState createState() => _ReferralTestScreenState();
}

class _ReferralTestScreenState extends State<ReferralTestScreen> {
  final _testEmailController = TextEditingController();
  final _testPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  
  String _testLog = '';
  bool _isTestingReferral = false;
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _addLog('🚀 Referral Test Environment Ready');
    _addLog('📝 Tạo 2 tài khoản test để thử nghiệm referral system');
  }

  void _addLog(String message) {
    setState(() {
      _testLog += '${DateTime.now().toString().substring(11, 19)} - $message\n';
    });
  }

  // Tạo tài khoản test
  Future<void> _createTestAccount() async {
    final email = _testEmailController.text.trim();
    final password = _testPasswordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      _addLog('❌ Vui lòng nhập email và password');
      return;
    }

    _addLog('🔧 Đang tạo tài khoản test: $email');
    
    try {
      // Tạo tài khoản mới
      await AuthService.instance.signUpWithEmail(
        email: email,
        password: password,
        username: 'testuser_${DateTime.now().millisecondsSinceEpoch}',
        fullName: 'Test User ${email.split('@')[0]}',
      );
      
      _addLog('✅ Tài khoản đã được tạo thành công!');
      
      // Lấy user info
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        setState(() {
          _currentUser = {
            'id': user.id,
            'email': user.email,
          };
        });
        _addLog('👤 Đang đăng nhập với tài khoản: ${user.email}');
        
        // Tạo mã referral cho user này
        await _generateReferralCode();
      }
      
    } catch (e) {
      _addLog('❌ Lỗi tạo tài khoản: $e');
    }
  }

  // Tạo mã referral
  Future<void> _generateReferralCode() async {
    if (_currentUser == null) return;
    
    _addLog('🎫 Đang tạo mã referral cho user...');
    
    try {
      final userId = _currentUser!['id'];
      final referralCode = 'SABO-TEST${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await BasicReferralService.createReferralCode(
        userId: userId,
        code: referralCode,
        maxUses: 5,
        referrerReward: 100,
        referredReward: 50,
      );
      
      if (result != null) {
        _addLog('✅ Mã referral đã tạo: $referralCode');
        _addLog('💰 Phần thưởng: Referrer +100 SPA, Referred +50 SPA');
        setState(() {
          _referralCodeController.text = referralCode;
        });
      } else {
        _addLog('❌ Không thể tạo mã referral');
      }
      
    } catch (e) {
      _addLog('❌ Lỗi tạo mã referral: $e');
    }
  }

  // Test áp dụng mã referral
  Future<void> _testApplyReferral() async {
    final referralCode = _referralCodeController.text.trim();
    
    if (referralCode.isEmpty) {
      _addLog('❌ Vui lòng nhập mã referral để test');
      return;
    }
    
    if (_currentUser == null) {
      _addLog('❌ Vui lòng đăng nhập trước khi test');
      return;
    }

    setState(() {
      _isTestingReferral = true;
    });
    
    _addLog('🧪 Đang test áp dụng mã referral: $referralCode');
    
    try {
      // Tạo user giả lập để test
      final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      
      final result = await BasicReferralService.applyReferralCode(
        code: referralCode,
        newUserId: testUserId,
      );
      
      if (result != null && result['success'] == true) {
        _addLog('✅ Mã referral hoạt động tốt!');
        _addLog('💰 Referrer reward: ${result['referrer_reward']} SPA');
        _addLog('💰 Referred reward: ${result['referred_reward']} SPA');
        _addLog('📝 Message: ${result['message']}');
      } else {
        _addLog('❌ Mã referral không hợp lệ hoặc có lỗi');
        _addLog('📝 Error: ${result?['message'] ?? 'Unknown error'}');
      }
      
    } catch (e) {
      _addLog('❌ Lỗi test referral: $e');
    } finally {
      setState(() {
        _isTestingReferral = false;
      });
    }
  }

  // Kiểm tra stats referral
  Future<void> _checkReferralStats() async {
    if (_currentUser == null) return;
    
    _addLog('📊 Đang kiểm tra referral stats...');
    
    try {
      final userId = _currentUser!['id'];
      final stats = await BasicReferralService.getReferralStats(userId);
      
      _addLog('📈 Referral Statistics:');
      _addLog('   - Tổng số lượt giới thiệu: ${stats['total_referrals']}');
      _addLog('   - Tổng SPA nhận được: ${stats['total_spa_earned']}');
      _addLog('   - Số mã đang hoạt động: ${stats['active_codes']}');
      
    } catch (e) {
      _addLog('❌ Lỗi kiểm tra stats: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🧪 Referral System Test'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Account Creation
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('1️⃣ Tạo Tài Khoản Test', 
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 12),
                    
                    TextField(
                      controller: _testEmailController,
                      decoration: InputDecoration(
                        labelText: 'Test Email',
                        hintText: 'test1@example.com',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8),
                    
                    TextField(
                      controller: _testPasswordController,
                      decoration: InputDecoration(
                        labelText: 'Test Password',
                        hintText: 'test123456',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                    ),
                    SizedBox(height: 12),
                    
                    ElevatedButton(
                      onPressed: _createTestAccount,
                      child: Text('Tạo Tài Khoản Test'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Referral Code Testing
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('2️⃣ Test Mã Referral', 
                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 12),
                    
                    TextField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        labelText: 'Referral Code',
                        hintText: 'SABO-TEST12345',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isTestingReferral ? null : _testApplyReferral,
                            child: _isTestingReferral 
                                ? CircularProgressIndicator(color: Colors.white)
                                : Text('Test Referral'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _checkReferralStats,
                            child: Text('Check Stats'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Test Log
            Expanded(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📋 Test Log', 
                           style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            child: Text(
                              _testLog,
                              style: TextStyle(
                                color: Colors.green,
                                fontFamily: 'monospace',
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => setState(() => _testLog = ''),
                        child: Text('Clear Log'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _testEmailController.dispose();
    _testPasswordController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }
}

// Test Scenarios để chạy
class ReferralTestScenarios {
  static void runAllTests() {
    print('🧪 REFERRAL SYSTEM TEST SCENARIOS');
    print('================================');
    
    // Scenario 1: User A tạo mã, User B sử dụng
    print('\n📋 Scenario 1: Basic Referral Flow');
    print('1. User A đăng ký → tự động có mã referral');
    print('2. User A share mã cho User B');
    print('3. User B đăng ký với mã của A');
    print('4. Check: A nhận +100 SPA, B nhận +50 SPA');
    
    // Scenario 2: Invalid codes
    print('\n📋 Scenario 2: Invalid Code Handling');
    print('1. User C nhập mã không tồn tại');
    print('2. User D nhập mã của chính mình');
    print('3. User E nhập mã đã hết hạn');
    print('4. Check: Tất cả trả về error message');
    
    // Scenario 3: Usage limits
    print('\n📋 Scenario 3: Usage Limits');
    print('1. Tạo mã với max_uses = 2');
    print('2. 2 user đầu sử dụng → thành công');
    print('3. User thứ 3 sử dụng → báo lỗi limit');
    print('4. Check: Mã không thể sử dụng thêm');
    
    print('\n✅ Chạy ReferralTestScreen để test thực tế!');
  }
}