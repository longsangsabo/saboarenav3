import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/integrated_registration_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

@override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _referralCodeController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isRegistering = false;
  String? _detectedReferralCode;
  Map<String, dynamic>? _referralPreview;

  @override
  void initState() {
    super.initState();
    _checkForQRReferral();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _displayNameController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _checkForQRReferral() async {
    // Check if this registration comes from a QR scan with referral
    // In a real app, this would check app state or navigation parameters
    // For demo, we'll check if there's a passed referral code
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    
    if (args != null && args['referralCode'] != null) {
      final referralCode = args['referralCode'] as String;
      
      try {
        final preview = await IntegratedRegistrationService.previewReferralBenefits(referralCode);
        if (preview != null && preview['valid'] == true) {
          setState(() {
            _detectedReferralCode = referralCode;
            _referralCodeController.text = referralCode;
            _referralPreview = preview;
          });
        }
      } catch (e) {
        debugPrint('Error loading referral preview: $e');
      }
    }
  }

  Future<void> _loadReferralPreview(String referralCode) async {
    try {
      final preview = await IntegratedRegistrationService.previewReferralBenefits(referralCode);
      if (mounted) {
        setState(() {
          _referralPreview = preview;
        });
      }
    } catch (e) {
      debugPrint('Error loading referral preview: $e');
      if (mounted) {
        setState(() {
          _referralPreview = null;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isRegistering = true;
    });

    try {
      final referralCode = _referralCodeController.text.trim();
      
      Map<String, dynamic> result;
      
      if (referralCode.isNotEmpty) {
        // Register with referral code
        result = await IntegratedRegistrationService.registerWithQRReferral(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          username: _usernameController.text.trim(),
          fullName: _displayNameController.text.trim(),
          scannedQRData: 'https://saboarena.com/user/DEMO?ref=$referralCode', // Reconstruct QR data
        );
      } else {
        () {
        // Regular registration (implement normal auth here)
        result = {'success': false, "error": 'Normal registration not implemented yet'};
      }
      
      
      }if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Đăng ký thành công!'),
              backgroundColor: Colors.green,
            ),
          );
          
          Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
        }
      } else {
        () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['error'] ?? 'Đăng ký thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    
      }} catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi đăng ký: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRegistering = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                // Logo Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.sports_basketball,
                          size: 40,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'SABO ARENA',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tạo tài khoản mới',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Tên đăng nhập',
                    hintText: 'Nhập tên đăng nhập',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 16
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập tên đăng nhập';
                    if (value!.length < 3) return 'Tên đăng nhập ít nhất 3 ký tự';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Display Name Field
                TextFormField(
                  controller: _displayNameController,
                  decoration: InputDecoration(
                    labelText: 'Tên hiển thị',
                    hintText: 'Nhập tên hiển thị',
                    prefixIcon: const Icon(Icons.person_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 16
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập tên hiển thị';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    hintText: 'Nhập email của bạn',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 16
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập email';
                    if (!value!.contains('@')) return 'Email không hợp lệ';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    hintText: 'Nhập mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 16
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng nhập mật khẩu';
                    if (value!.length < 6) return 'Mật khẩu ít nhất 6 ký tự';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Confirm Password Field
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  decoration: InputDecoration(
                    labelText: 'Xác nhận mật khẩu',
                    hintText: 'Nhập lại mật khẩu',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, 
                      vertical: 16
                    ),
                  ),
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Vui lòng xác nhận mật khẩu';
                    if (value != _passwordController.text) return 'Mật khẩu không khớp';
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Referral Code Field (with bonus preview)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _referralCodeController,
                      decoration: InputDecoration(
                        labelText: 'Mã giới thiệu (tùy chọn)',
                        hintText: 'Nhập mã giới thiệu để nhận SPA',
                        prefixIcon: const Icon(Icons.card_giftcard_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, 
                          vertical: 16
                        ),
                      ),
                      onChanged: (value) {
                        // Auto-preview referral benefits when typing
                        if (value.isNotEmpty && value.length >= 5) {
                          _loadReferralPreview(value);
                        } else {
                          () {
                          setState(() {
                            _referralPreview = null;
                          });
                        }
                      
                        }},
                    ),
                    
                    // Referral Bonus Preview
                    if (_referralPreview != null && _referralPreview!['valid'] == true) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.star, color: Colors.green, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _referralPreview!['message'] ?? 'Bạn sẽ nhận SPA bonus!',
                                style: TextStyle(
                                  color: Colors.green[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    // QR Detected Message
                    if (_detectedReferralCode != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_2, color: Colors.blue, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Mã giới thiệu từ QR đã được áp dụng!',
                                style: TextStyle(
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 24),

                // Register Button
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _isRegistering ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isRegistering 
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                      'Đăng ký',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Login Link
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Đã có tài khoản? ',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                        ),
                      ),
                      TextButton(
                        onPressed: _navigateToLogin,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Đăng nhập ngay',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

