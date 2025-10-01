import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sabo_arena/services/real_payment_service.dart';
import 'package:sabo_arena/services/qr_payment_service.dart';
import 'package:sabo_arena/theme/app_theme.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/widgets/payment_qr_widget.dart';

class PaymentSetupScreen extends StatefulWidget {
  const PaymentSetupScreen({super.key});

} 
  final String clubId;

  const PaymentSetupScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<PaymentSetupScreen> createState() => _PaymentSetupScreenState();
}

class _PaymentSetupScreenState extends State<PaymentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isSaving = false;
  
  // Settings
  bool cashEnabled = true;
  bool bankEnabled = true;
  bool ewalletEnabled = true;

  // Bank account info
  final _bankNameController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();

  // E-wallet info
  final _momoPhoneController = TextEditingController();
  final _zalopayPhoneController = TextEditingController();
  final _ownerNameController = TextEditingController();

  List<String> supportedBanks = [];
  String? selectedBank;

  @override
  void initState() {
    super.initState();
    _loadSupportedBanks();
    _loadCurrentSettings();
  }

  void _loadSupportedBanks() {
    supportedBanks = QRPaymentService.getSupportedBanks();
    setState(() {});
  }

  Future<void> _loadCurrentSettings() async {
    setState(() => isLoading = true);
    
    try {
      final settings = await RealPaymentService.getClubPaymentSettings(widget.clubId);
      if (settings != null) {
        setState(() {
          cashEnabled = settings['cash_enabled'] ?? true;
          bankEnabled = settings['bank_enabled'] ?? true;
          ewalletEnabled = settings['ewallet_enabled'] ?? true;
          
          // Load bank info
          if (settings['bank_info'] != null) {
            final bankInfo = settings['bank_info'];
            selectedBank = bankInfo['bankName'];
            _bankNameController.text = bankInfo['bankName'] ?? '';
            _accountNumberController.text = bankInfo['accountNumber'] ?? '';
            _accountNameController.text = bankInfo['accountName'] ?? '';
          }
          
          // Load ewallet info
          if (settings['ewallet_info'] != null) {
            final ewalletInfo = settings['ewallet_info'];
            _momoPhoneController.text = ewalletInfo['momo_phone'] ?? '';
            _zalopayPhoneController.text = ewalletInfo['zalopay_phone'] ?? '';
            _ownerNameController.text = ewalletInfo['owner_name'] ?? '';
          }
        });
      }
    } catch (e) {
      _showError('Không thể tải cài đặt: $e');
    }
    
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: CustomAppBar(title: 'Cài đặt thanh toán'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: CustomAppBar(title: 'Cài đặt thanh toán'),
      backgroundColor: AppTheme.backgroundLight,
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeCard(),
              const SizedBox(height: 24),
              _buildPaymentMethodsSection(),
              const SizedBox(height: 24),
              if (bankEnabled) ...[
                _buildBankAccountSection(),
                const SizedBox(height: 24),
              ],
              if (ewalletEnabled) ...[
                _buildEWalletSection(),
                const SizedBox(height: 24),
              ],
              _buildTestSection(),
              const SizedBox(height: 24),
              _buildSaveButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight.withOpacity(0.1),
            AppTheme.primaryLight.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryLight.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.payment, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thiết lập thanh toán QR',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Nhập thông tin 1 lần, khách hàng thanh toán tự động',
                      style: TextStyle(
                        color: AppTheme.textSecondaryLight,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tự động tạo QR Code cho mọi giao dịch',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 16),
          _buildPaymentToggle(
            icon: Icons.money,
            title: 'Tiền mặt',
            subtitle: 'Thanh toán trực tiếp tại quầy',
            value: cashEnabled,
            onChanged: (value) => setState(() => cashEnabled = value),
          ),
          _buildPaymentToggle(
            icon: Icons.account_balance,
            title: 'Chuyển khoản ngân hàng',
            subtitle: 'QR Code VietQR tự động',
            value: bankEnabled,
            onChanged: (value) => setState(() => bankEnabled = value),
          ),
          _buildPaymentToggle(
            icon: Icons.phone_android,
            title: 'Ví điện tử',
            subtitle: 'MoMo, ZaloPay QR Code',
            value: ewalletEnabled,
            onChanged: (value) => setState(() => ewalletEnabled = value),
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentToggle({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
    bool isLast = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: !isLast
            ? Border(bottom: BorderSide(color: AppTheme.dividerLight.withOpacity(0.3)))
            : null,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: value 
                  ? AppTheme.primaryLight.withOpacity(0.12)
                  : Colors.grey.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: value ? AppTheme.primaryLight : Colors.grey,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            thumbColor: WidgetStateProperty.all(AppTheme.primaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildBankAccountSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thông tin tài khoản ngân hàng',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bank selection
          Text(
            'Chọn ngân hàng *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: selectedBank,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            hint: const Text('Chọn ngân hàng'),
            items: supportedBanks.map((bank) => DropdownMenuItem(
              value: bank,
              child: Text(bank),
            )).toList(),
            onChanged: (value) {
              setState(() {
                selectedBank = value;
                _bankNameController.text = value ?? '';
              });
            },
            validator: (value) => value == null ? 'Vui lòng chọn ngân hàng' : null,
          ),
          const SizedBox(height: 16),

          // Account number
          Text(
            'Số tài khoản *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountNumberController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'Nhập số tài khoản',
            ),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Vui lòng nhập số tài khoản';
              if (value!.length < 6) return 'Số tài khoản tối thiểu 6 số';
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Account name
          Text(
            'Tên chủ tài khoản *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _accountNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'VD: NGUYEN VAN A',
            ),
            textCapitalization: TextCapitalization.characters,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Vui lòng nhập tên chủ tài khoản';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEWalletSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.shadowLight,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, color: AppTheme.primaryLight, size: 24),
              const SizedBox(width: 12),
              Text(
                'Thông tin ví điện tử',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Owner name
          Text(
            'Tên chủ ví *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ownerNameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: 'VD: Nguyễn Văn A',
            ),
            validator: (value) {
              if (ewalletEnabled && (value?.isEmpty ?? true)) {
                return 'Vui lòng nhập tên chủ ví';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // MoMo phone
          Text(
            'Số điện thoại MoMo',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _momoPhoneController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: '0901234567',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD82D8B).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.phone_android, color: Color(0xFFD82D8B), size: 20),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),

          // ZaloPay phone
          Text(
            'Số điện thoại ZaloPay',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _zalopayPhoneController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              hintText: '0901234567',
              prefixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF0068FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.payment, color: Color(0xFF0068FF), size: 20),
              ),
            ),
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTestSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_scanner, color: Colors.blue[600], size: 24),
              const SizedBox(width: 12),
              Text(
                'Test QR Code',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nhập thông tin xong? Hãy test QR Code ngay!',
            style: TextStyle(
              color: Colors.blue[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (bankEnabled && selectedBank != null && _accountNumberController.text.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testBankQR(),
                    icon: const Icon(Icons.account_balance),
                    label: const Text('Test Bank'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              if (bankEnabled && ewalletEnabled && 
                  selectedBank != null && _accountNumberController.text.isNotEmpty &&
                  _ownerNameController.text.isNotEmpty)
                const SizedBox(width: 12),
              if (ewalletEnabled && _ownerNameController.text.isNotEmpty)
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _testEWalletQR(),
                    icon: const Icon(Icons.phone_android),
                    label: const Text('Test E-Wallet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isSaving ? null : _saveSettings,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 2,
        ),
        child: isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    'Lưu cài đặt và kích hoạt',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
      ),
    );
  }

  void _testBankQR() {
    if (selectedBank == null || _accountNumberController.text.isEmpty) {
      _showError('Vui lòng nhập đầy đủ thông tin ngân hàng');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: PaymentQRWidget(
            paymentMethod: 'bank',
            paymentInfo: {
              'bankName': selectedBank!,
              'accountNumber': _accountNumberController.text,
              'accountName': _accountNameController.text.isEmpty 
                  ? 'TEST ACCOUNT' 
                  : _accountNameController.text,
            },
            amount: 50000,
            description: 'Test thanh toán - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      ),
    );
  }

  void _testEWalletQR() {
    if (_ownerNameController.text.isEmpty) {
      _showError('Vui lòng nhập tên chủ ví');
      return;
    }

    String phone = _momoPhoneController.text.isNotEmpty 
        ? _momoPhoneController.text 
        : _zalopayPhoneController.text;
    
    if (phone.isEmpty) {
      _showError('Vui lòng nhập ít nhất một số điện thoại ví');
      return;
    }

    String walletType = _momoPhoneController.text.isNotEmpty ? "momo" : 'zalobây';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: PaymentQRWidget(
            paymentMethod: walletType,
            paymentInfo: {
              'phoneNumber': phone,
              'receiverName': _ownerNameController.text,
            },
            amount: 50000,
            description: 'Test thanh toán - ${DateTime.now().millisecondsSinceEpoch}',
          ),
        ),
      ),
    );
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      // Prepare settings data
      Map<String, dynamic> settings = {
        'cash_enabled': cashEnabled,
        'bank_enabled': bankEnabled,
        'ewallet_enabled': ewalletEnabled,
        'payment_timeout': 600, // 10 minutes
        "currency": 'VND',
        'auto_confirm': false,
      };

      if (bankEnabled && selectedBank != null && _accountNumberController.text.isNotEmpty) {
        settings['bank_info'] = {
          'bankName': selectedBank!,
          'accountNumber': _accountNumberController.text,
          'accountName': _accountNameController.text,
        };
      }

      if (ewalletEnabled && _ownerNameController.text.isNotEmpty) {
        settings['ewallet_info'] = {
          'owner_name': _ownerNameController.text,
          'momo_phone': _momoPhoneController.text,
          'zalopay_phone': _zalopayPhoneController.text,
        };
      }

      // Save to database
      await RealPaymentService.saveClubPaymentSettings(
        clubId: widget.clubId,
        paymentSettings: settings,
      );

      _showSuccess();

    } catch (e) {
      _showError('Không thể lưu cài đặt: $e');
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, color: Colors.green, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              'Thiết lập thành công!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Hệ thống thanh toán đã sẵn sàng.\nKhách hàng có thể thanh toán qua QR Code ngay bây giờ!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  Navigator.of(context).pop(true); // Return success
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Hoàn thành', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ $message'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _momoPhoneController.dispose();
    _zalopayPhoneController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }
}
