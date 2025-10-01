import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import 'club_registration_screen/club_registration_screen.dart';
import '../../widgets/player_welcome_guide.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

enum _RegisterMethod { email, phone }

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailFormKey = GlobalKey<FormState>();
  final _phoneFormKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _phonePasswordController = TextEditingController();
  final _confirmPhonePasswordController = TextEditingController();
  final _otpController = TextEditingController();
  _RegisterMethod _registerMethod = _RegisterMethod.email;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isPhonePasswordVisible = false;
  bool _isConfirmPhonePasswordVisible = false;
  bool _isSendingOtp = false;
  bool _isOtpSent = false;
  bool _isVerifyingOtp = false;
  int _secondsRemaining = 0;
  Timer? _otpTimer;
  String _selectedRole = 'player';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _phonePasswordController.dispose();
    _confirmPhonePasswordController.dispose();
    _otpController.dispose();
    _otpTimer?.cancel();
    super.dispose();
  }

  Future<void> _signUpWithEmail() async {
    if (!_emailFormKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthService.instance.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole,
      );

      if (mounted) {
        // Check if user is immediately confirmed (no email confirmation needed)
        if (response.session != null && response.user != null) {
          // Check role and redirect accordingly
          if (_selectedRole == 'club_owner') {
            _showClubOwnerWelcomeDialog();
          } else {
            () {
            // Show player welcome guide first
            _showPlayerWelcomeGuide();
          }
        
          }} else {
          () {
          // Email confirmation required
          _showEmailConfirmationDialog();
        }
      
        }}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng ký thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _switchRegisterMethod(_RegisterMethod method) {
    if (_registerMethod == method) return;

    setState(() {
      _registerMethod = method;

      if (method == _RegisterMethod.email) {
        _phoneController.clear();
        _phonePasswordController.clear();
        _confirmPhonePasswordController.clear();
        _otpController.clear();
        _isPhonePasswordVisible = false;
        _isConfirmPhonePasswordVisible = false;
        _isSendingOtp = false;
        _isOtpSent = false;
        _isVerifyingOtp = false;
        _secondsRemaining = 0;
        _otpTimer?.cancel();
      } else {
        () {
        _emailController.clear();
        _passwordController.clear();
        _confirmPasswordController.clear();
        _isPasswordVisible = false;
        _isConfirmPasswordVisible = false;
      }
    
      }});
  }

  String _normalizePhoneNumber(String input) {
    var phone = input.trim().replaceAll(RegExp(r'\s+'), '');
    if (phone.isEmpty) return phone;

    if (phone.startsWith('+')) {
      return phone;
    }

    if (phone.startsWith('0')) {
      return '+84${phone.substring(1)}';
    }

    if (!phone.startsWith('+')) {
      return '+$phone';
    }

    return phone;
  }

  void _startOtpTimer() {
    _otpTimer?.cancel();
    setState(() {
      _secondsRemaining = 60;
    });

    _otpTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 1) {
        timer.cancel();
        setState(() {
          _secondsRemaining = 0;
        });
      } else {
        () {
        setState(() {
          _secondsRemaining--;
        });
      }
    
      }});
  }

  Future<void> _requestPhoneOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
    if (normalizedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại hợp lệ')),
      );
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      if (_isOtpSent) {
        await AuthService.instance.sendPhoneOtp(
          phone: normalizedPhone,
          createUserIfNeeded: false,
        );
      } else {
        () {
        await AuthService.instance.signUpWithPhone(
          phone: normalizedPhone,
          password: _phonePasswordController.text,
          fullName: _nameController.text.trim(),
          role: _selectedRole,
        );
      }

      
      }if (mounted) {
        setState(() {
          _isOtpSent = true;
        });
        _startOtpTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mã OTP đã được gửi đến $normalizedPhone'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gửi mã OTP thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingOtp = false);
      }
    }
  }

  Future<void> _verifyPhoneOtp() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    if (_otpController.text.trim().length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng nhập mã OTP hợp lệ (tối thiểu 4 chữ số)')),
      );
      return;
    }

    final normalizedPhone = _normalizePhoneNumber(_phoneController.text);

    setState(() => _isVerifyingOtp = true);

    try {
      await AuthService.instance.verifyPhoneOtp(
        phone: normalizedPhone,
        token: _otpController.text.trim(),
      );

      await AuthService.instance.updateUserMetadata(
        fullName: _nameController.text.trim(),
        role: _selectedRole,
      );

      await AuthService.instance.upsertUserRecord(
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        phone: normalizedPhone,
      );

      if (mounted) {
        _otpTimer?.cancel();
        setState(() {
          _secondsRemaining = 0;
        });

        // Check role and redirect accordingly
        if (_selectedRole == 'club_owner') {
          _showClubOwnerWelcomeDialog();
        } else {
          () {
          // Show player welcome guide first
          _showPlayerWelcomeGuide();
        }
      
        }}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Xác thực thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isVerifyingOtp = false);
      }
    }
  }

  void _showEmailConfirmationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.mark_email_unread,
                color: Theme.of(context).primaryColor,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Xác nhận Email',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Đăng ký thành công! 🎉',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'Chúng tôi đã gửi email xác nhận đến:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 8),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email, size: 20, color: Colors.grey[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _emailController.text.trim(),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                '📧 Vui lòng kiểm tra hộp thư và nhấn vào liên kết xác nhận để hoàn tất quá trình đăng ký.',
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, size: 20, color: Colors.blue[600]),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Không thấy email? Hãy kiểm tra thư mục Spam/Junk.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to login
              },
              child: Text('OK, đã hiểu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title
              Center(
                child: Column(
                  children: [
                    Text(
                      'Tạo tài khoản mới',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Tham gia cộng đồng SABO Arena',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 4.h),

              _buildRegisterMethodToggle(theme),

              SizedBox(height: 3.h),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _registerMethod == _RegisterMethod.email
                    ? KeyedSubtree(
                        key: const ValueKey('email_register'),
                        child: _buildEmailRegisterForm(theme),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('phone_register'),
                        child: _buildPhoneRegisterForm(theme),
                      ),
              ),

              SizedBox(height: 4.h),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản? '),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisterMethodToggle(ThemeData theme) {
    Widget buildOption(String label, IconData icon, _RegisterMethod method) {
      final isActive = _registerMethod == method;

      return InkWell(
        onTap: () => _switchRegisterMethod(method),
        borderRadius: BorderRadius.circular(2.w),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 1.4.h, horizontal: 2.w),
          decoration: BoxDecoration(
            color: isActive ? theme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 6.w,
                color: isActive ? Colors.white : theme.primaryColor,
              ),
              SizedBox(height: 1.h),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 12.sp,
                  color: isActive ? Colors.white : theme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: theme.primaryColor.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Expanded(
            child: buildOption('Email & mật khẩu', Icons.email_outlined, _RegisterMethod.email),
          ),
          SizedBox(width: 1.2.w),
          Expanded(
            child: buildOption('Số điện thoại', Icons.phone_android_outlined, _RegisterMethod.phone),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailRegisterForm(ThemeData theme) {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              hintText: 'Nhập họ và tên của bạn',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập họ và tên';
              }
              if (value.trim().length < 2) {
                return 'Họ và tên phải có ít nhất 2 ký tự';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Nhập email của bạn',
              prefixIcon: const Icon(Icons.email_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Email không hợp lệ';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          // Role selection
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Vai trò',
              prefixIcon: const Icon(Icons.assignment_ind_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'player', child: Text('Người chơi')),
              DropdownMenuItem(value: 'club_owner', child: Text('Chủ câu lạc bộ')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
          SizedBox(height: 3.h),
          // Password field
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            obscureText: !_isPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          // Confirm password field
          TextFormField(
            controller: _confirmPasswordController,
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isConfirmPasswordVisible = !_isConfirmPasswordVisible),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            obscureText: !_isConfirmPasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu';
              }
              if (value != _passwordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
          SizedBox(height: 6.h),
          // Signup button
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signUpWithEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRegisterForm(ThemeData theme) {
    return Form(
      key: _phoneFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              hintText: 'Nhập họ và tên của bạn',
              prefixIcon: const Icon(Icons.person_outline),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập họ và tên';
              }
              if (value.trim().length < 2) {
                return 'Họ và tên phải có ít nhất 2 ký tự';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              hintText: 'Ví dụ: 0901 234 567',
              prefixIcon: const Icon(Icons.phone_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Vui lòng nhập số điện thoại';
              }
              final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
              if (digits.length < 9) {
                return 'Số điện thoại phải có ít nhất 9 chữ số';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          // Role selection
          DropdownButtonFormField<String>(
            initialValue: _selectedRole,
            decoration: InputDecoration(
              labelText: 'Vai trò',
              prefixIcon: const Icon(Icons.assignment_ind_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            items: const [
              DropdownMenuItem(value: 'player', child: Text('Người chơi')),
              DropdownMenuItem(value: 'club_owner', child: Text('Chủ câu lạc bộ')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedRole = value);
              }
            },
          ),
          SizedBox(height: 3.h),
          // Password field
          TextFormField(
            controller: _phonePasswordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isPhonePasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isPhonePasswordVisible = !_isPhonePasswordVisible),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            obscureText: !_isPhonePasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng nhập mật khẩu';
              }
              if (value.length < 6) {
                return 'Mật khẩu phải có ít nhất 6 ký tự';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          // Confirm password field
          TextFormField(
            controller: _confirmPhonePasswordController,
            decoration: InputDecoration(
              labelText: 'Xác nhận mật khẩu',
              hintText: 'Nhập lại mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_isConfirmPhonePasswordVisible ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _isConfirmPhonePasswordVisible = !_isConfirmPhonePasswordVisible),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
            obscureText: !_isConfirmPhonePasswordVisible,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Vui lòng xác nhận mật khẩu';
              }
              if (value != _phonePasswordController.text) {
                return 'Mật khẩu xác nhận không khớp';
              }
              return null;
            },
          ),
          SizedBox(height: 3.h),
          if (_isOtpSent) ...[
            TextFormField(
              controller: _otpController,
              decoration: InputDecoration(
                labelText: 'Mã OTP',
                hintText: 'Nhập mã gồm 6 chữ số',
                prefixIcon: const Icon(Icons.shield_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              maxLength: 6,
              buildCounter: (context, {int? currentLength, bool? isFocused, int? maxLength}) => null,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (!_isOtpSent) return null;
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng nhập mã OTP';
                }
                if (value.trim().length < 4) {
                  return 'Mã OTP phải có ít nhất 4 chữ số';
                }
                return null;
              },
            ),
            SizedBox(height: 1.h),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                _secondsRemaining > 0
                    ? "Gửi lại mã sau ${_secondsRemaining}s"
                    : 'Bạn có thể gửi lại mã mới.',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 3.h),
          ],
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isOtpSent
                  ? (_isVerifyingOtp ? null : _verifyPhoneOtp)
                  : (_isSendingOtp ? null : _requestPhoneOtp),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: _isOtpSent
                  ? (_isVerifyingOtp
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Xác thực và hoàn tất đăng ký',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ))
                  : (_isSendingOtp
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Gửi mã OTP',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        )),
            ),
          ),
          if (_isOtpSent) ...[
            SizedBox(height: 1.5.h),
            Align(
              alignment: Alignment.center,
              child: TextButton(
                onPressed: (_secondsRemaining > 0 || _isSendingOtp) ? null : () => _requestPhoneOtp(),
                child: Text(
                  'Gửi lại mã OTP',
                  style: TextStyle(fontSize: 12.sp),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPlayerWelcomeGuide() {
    // Navigate to home feed first
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.homeFeedScreen,
      (route) => false,
    );
    
    // Then show welcome guide
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) => const PlayerWelcomeGuide(),
      );
    });
  }

  void _showClubOwnerWelcomeDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.sports_soccer,
              color: Theme.of(context).primaryColor,
              size: 28,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Chào mừng Chủ CLB!',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Chúc mừng bạn đã tạo tài khoản thành công với vai trò Chủ câu lạc bộ!',
              style: TextStyle(fontSize: 14.sp, height: 1.4),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bước tiếp theo:',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade800,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '📝 Đăng ký thông tin câu lạc bộ của bạn\n'
                    '⏳ Chờ admin phê duyệt (24-48 giờ)\n'
                    '🎯 Bắt đầu quản lý và tổ chức giải đấu',
                    style: TextStyle(
                      fontSize: 12.sp,
                      height: 1.5,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil(
                AppRoutes.homeFeedScreen,
                (route) => false,
              );
            },
            child: Text(
              'Để sau',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.sp,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ClubRegistrationScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
            ),
            child: Text(
              'Đăng ký CLB ngay',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
