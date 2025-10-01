import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/preferences_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _LoginMethod { email, phone }

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneFormKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _phonePasswordController = TextEditingController();
  _LoginMethod _loginMethod = _LoginMethod.email;
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isPhonePasswordVisible = false;
  bool _rememberLogin = false;
  bool _isPhoneLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _phonePasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLoginInfo() async {
    final loginInfo = await PreferencesService.instance.getValidLoginInfo();
    if (mounted) {
      setState(() {
        _rememberLogin = loginInfo['remember'] ?? false;
        if (loginInfo['isValid'] == true && loginInfo['email'] != null) {
          _emailController.text = loginInfo['email'];
        }
      });
    }
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await AuthService.instance.signInWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Save login info if user chose to remember
      await PreferencesService.instance.saveLoginInfo(
        email: _emailController.text.trim(),
        rememberLogin: _rememberLogin,
      );

      // Check if user is admin and redirect accordingly
      if (mounted) {
        final isAdmin = await AuthService.instance.isCurrentUserAdmin();
        if (isAdmin) {
          Navigator.of(context).pushReplacementNamed(AppRoutes.adminDashboardScreen);
        } else {
          () {
          Navigator.of(context).pushReplacementNamed(AppRoutes.userProfileScreen);
        }
      
        }}
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${e.toString()}'),
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

  void _switchLoginMethod(_LoginMethod method) {
    if (_loginMethod == method) return;

    setState(() {
      _loginMethod = method;
      if (method == _LoginMethod.email) {
        _phoneController.clear();
        _phonePasswordController.clear();
        _isPhonePasswordVisible = false;
      } else {
        () {
        _emailController.clear();
        _passwordController.clear();
        _isPasswordVisible = false;
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

  Future<void> _signInWithPhone() async {
    if (!_phoneFormKey.currentState!.validate()) return;

    final normalizedPhone = _normalizePhoneNumber(_phoneController.text);
    if (normalizedPhone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số điện thoại hợp lệ')),
      );
      return;
    }

    setState(() => _isPhoneLoading = true);

    try {
      await AuthService.instance.signInWithPhone(
        phone: normalizedPhone,
        password: _phonePasswordController.text,
      );

      if (!mounted) return;

      final isAdmin = await AuthService.instance.isCurrentUserAdmin();
      if (isAdmin) {
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.adminDashboardScreen);
      } else {
        () {
        if (!mounted) return;
        Navigator.of(context)
            .pushReplacementNamed(AppRoutes.userProfileScreen);
      }
    
      }} catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đăng nhập thất bại: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPhoneLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(6.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 8.h),

              // Logo and title
              Center(
                child: Column(
                  children: [
                    SizedBox(
                      width: 24.w,
                      height: 24.w,
                      child: Image.asset(
                        'assets/images/sabo_arena_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 24.w,
                            height: 24.w,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(2.w),
                            ),
                            child: Icon(
                              Icons.sports_esports,
                              size: 12.w,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(height: 3.h),
                    Text(
                      'SABO Arena',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Chào mừng trở lại!',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 6.h),

              _buildLoginMethodToggle(theme),
              SizedBox(height: 3.h),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _loginMethod == _LoginMethod.email
                    ? KeyedSubtree(
                        key: const ValueKey('email_login'),
                        child: _buildEmailLoginForm(theme),
                      )
                    : KeyedSubtree(
                        key: const ValueKey('phone_login'),
                        child: _buildPhoneLoginForm(theme),
                      ),
              ),

              SizedBox(height: 4.h),
              _buildSignUpPrompt(),
              SizedBox(height: 4.h),
              _buildDemoCredentialsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginMethodToggle(ThemeData theme) {
    Widget buildOption(String label, IconData icon, _LoginMethod method) {
      final isActive = _loginMethod == method;

      return InkWell(
        onTap: () => _switchLoginMethod(method),
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
            child: buildOption('Email & mật khẩu', Icons.email_outlined, _LoginMethod.email),
          ),
          SizedBox(width: 1.2.w),
          Expanded(
            child: buildOption('Số điện thoại', Icons.phone_android_outlined, _LoginMethod.phone),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailLoginForm(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          TextFormField(
            controller: _passwordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() {
                  _isPasswordVisible = !_isPasswordVisible;
                }),
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
          SizedBox(height: 2.h),
          Row(
            children: [
              Checkbox(
                value: _rememberLogin,
                onChanged: (value) {
                  setState(() {
                    _rememberLogin = value ?? false;
                  });
                },
                activeColor: theme.primaryColor,
              ),
              Expanded(
                child: Text(
                  'Ghi nhớ đăng nhập',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.sp,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.forgotPasswordScreen);
                },
                child: const Text('Quên mật khẩu?'),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _signIn,
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
                      'Đăng nhập',
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

  Widget _buildPhoneLoginForm(ThemeData theme) {
    return Form(
      key: _phoneFormKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          TextFormField(
            controller: _phonePasswordController,
            decoration: InputDecoration(
              labelText: 'Mật khẩu',
              hintText: 'Nhập mật khẩu của bạn',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _isPhonePasswordVisible
                      ? Icons.visibility_off
                      : Icons.visibility,
                ),
                onPressed: () => setState(() {
                  _isPhonePasswordVisible = !_isPhonePasswordVisible;
                }),
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
          SizedBox(height: 4.h),
          SizedBox(
            height: 6.h,
            child: ElevatedButton(
              onPressed: _isPhoneLoading ? null : _signInWithPhone,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2.w),
                ),
              ),
              child: _isPhoneLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Đăng nhập',
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

  Widget _buildSignUpPrompt() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(fontSize: 12.sp),
        ),
        TextButton(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.registerScreen);
          },
          child: const Text('Đăng ký ngay'),
        ),
      ],
    );
  }

  Widget _buildDemoCredentialsSection() {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.primaryColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(color: theme.primaryColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.primaryColor, size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Tài khoản demo:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.primaryColor,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildDemoCredential(
            'Admin',
            'admin@saboarena.com',
            'admin123',
            Icons.admin_panel_settings,
            Colors.red[700]!,
          ),
          SizedBox(height: 1.h),
          _buildDemoCredential(
            'Người chơi 1',
            'player1@example.com',
            'player123',
            Icons.person,
            Colors.green[700]!,
          ),
          SizedBox(height: 1.h),
          _buildDemoCredential(
            'Người chơi 2',
            'player2@example.com',
            'player123',
            Icons.person_outline,
            Colors.blue[700]!,
          ),
          SizedBox(height: 1.h),
          _buildDemoCredential(
            'Chủ câu lạc bộ',
            'owner@club.com',
            'owner123',
            Icons.business,
            Colors.orange[700]!,
          ),
        ],
      ),
    );
  }

  Widget _buildDemoCredential(
      String role, String email, String password, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        _emailController.text = email;
        _passwordController.text = password;
        setState(() {});
      },
      borderRadius: BorderRadius.circular(1.w),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 1.h, horizontal: 2.w),
        child: Row(
          children: [
            Icon(icon, color: color, size: 4.w),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    role,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: color,
                      fontSize: 12.sp,
                    ),
                  ),
                  Text(
                    '$email / $password',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.touch_app, color: Colors.grey[400], size: 4.w),
          ],
        ),
      ),
    );
  }
}
