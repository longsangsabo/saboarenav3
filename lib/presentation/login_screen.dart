import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _rememberLogin = false;

  @override
  void initState() {
    super.initState();
    _loadSavedLoginInfo();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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
          Navigator.of(context).pushReplacementNamed(AppRoutes.userProfileScreen);
        }
      }
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
                    Container(
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

              // Login form
              Form(
                key: _formKey,
                child: Column(
                  children: [
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

                    // Password field
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Mật khẩu',
                        hintText: 'Nhập mật khẩu của bạn',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () => setState(
                              () => _isPasswordVisible = !_isPasswordVisible),
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

                    // Remember login checkbox
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
                          child: Text('Quên mật khẩu?'),
                        ),
                      ],
                    ),

                    SizedBox(height: 4.h),

                    // Login button
                    SizedBox(
                      width: double.infinity,
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
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: SvgPicture.asset(
                                  'assets/images/logo.svg',
                                  width: 20,
                                  height: 20,
                                  fit: BoxFit.contain,
                                  colorFilter: const ColorFilter.mode(
                                    Colors.white,
                                    BlendMode.srcIn,
                                  ),
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

                    SizedBox(height: 4.h),

                    // Sign up link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Chưa có tài khoản? '),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRoutes.registerScreen);
                          },
                          child: Text('Đăng ký ngay'),
                        ),
                      ],
                    ),

                    SizedBox(height: 6.h),

                    // Demo credentials section
                    Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(2.w),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.info_outline,
                                  color: Colors.blue[700], size: 5.w),
                              SizedBox(width: 2.w),
                              Text(
                                'Tài khoản demo:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[700],
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
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
