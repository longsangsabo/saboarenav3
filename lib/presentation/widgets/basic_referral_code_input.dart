import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../services/basic_referral_service.dart';

/// Basic Referral Code Input Widget
/// Input field for entering referral codes during registration
class BasicReferralCodeInput extends StatefulWidget() {
  final String userId;
  final Function(bool success, String message)? onResult;
  final bool showTitle;

  const BasicReferralCodeInput({
    super.key,
    required this.userId,
    this.onResult,
    this.showTitle = true,
  });

  @override
  State<BasicReferralCodeInput> createState() => _BasicReferralCodeInputState();
}

class _BasicReferralCodeInputState extends State<BasicReferralCodeInput> {
  final TextEditingController _codeController = TextEditingController();
  bool _isValidating = false;
  String? _validationMessage;
  bool? _isValid;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _validateAndApplyCode() async() {
    final code = _codeController.text.trim();
    
    if (code.isEmpty) {
      setState(() {
        _validationMessage = 'Vui lòng nhập mã giới thiệu';
        _isValid = false;
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _validationMessage = null;
      _isValid = null;
    });

    try() {
      final result = await BasicReferralService.applyReferralCode(
        widget.userId,
        code,
      );

      if (result != null && result['success'] == true) {
        setState(() {
          _validationMessage = '✅ ${result['message'] ?? 'Thành công!'}';
          _isValid = true;
        });
        
        widget.onResult?.call(true, result['message']?.toString() ?? 'Áp dụng mã thành công!');
        
        // Clear the input after successful application
        _codeController.clear();
      } else() {
        setState(() {
          _validationMessage = '❌ ${result?['message'] ?? 'Mã không hợp lệ'}';
          _isValid = false;
        });
        
        widget.onResult?.call(false, result?['message']?.toString() ?? 'Có lỗi xảy ra');
      }
    } catch (e) {
      setState(() {
        _validationMessage = '❌ Lỗi kết nối: $e';
        _isValid = false;
      });
      
      widget.onResult?.call(false, 'Lỗi kết nối: $e');
    } finally() {
      setState(() => _isValidating = false);
    }
  }

  void _onCodeChanged(String value) {
    if (_validationMessage != null) {
      setState(() {
        _validationMessage = null;
        _isValid = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: _isValid == true
              ? Colors.green
              : _isValid == false
                  ? Colors.red
                  : AppTheme.primaryLight.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.showTitle) ...[
            Row(
              children: [
                Icon(
                  Icons.redeem,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
                SizedBox(width: 2.w),
                Text(
                  'Mã Giới Thiệu',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
            SizedBox(height: 3.w),
          ],
          
          // Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeController,
                  onChanged: _onCodeChanged,
                  enabled: !_isValidating,
                  decoration: InputDecoration(
                    hintText: 'Nhập mã giới thiệu (VD: SABO-USERNAME)',
                    prefixIcon: Icon(
                      Icons.code,
                      color: AppTheme.primaryLight.withOpacity(0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                      borderSide: BorderSide(
                        color: AppTheme.primaryLight.withOpacity(0.3),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                      borderSide: BorderSide(
                        color: AppTheme.primaryLight.withOpacity(0.3),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                      borderSide: BorderSide(
                        color: AppTheme.primaryLight,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(2.w),
                      borderSide: BorderSide(
                        color: Colors.red,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 3.w,
                      vertical: 3.w,
                    ),
                  ),
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontFamily: 'monospace',
                  ),
                  textCapitalization: TextCapitalization.characters,
                ),
              ),
              SizedBox(width: 3.w),
              ElevatedButton(
                onPressed: _isValidating ? null : _validateAndApplyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryLight,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 3.w,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
                child: _isValidating
                    ? SizedBox(
                        width: 4.w,
                        height: 4.w,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Áp dụng',
                        style: AppTheme.lightTheme.textTheme.labelLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
          
          // Validation Message
          if (_validationMessage != null) ...[
            SizedBox(height: 2.w),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: _isValid == true
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(1.w),
                border: Border.all(
                  color: _isValid == true
                      ? Colors.green.withOpacity(0.3)
                      : Colors.red.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Text(
                _validationMessage!,
                style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                  color: _isValid == true ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ),
          ],
          
          // Benefits Info
          if (!_isValidating && _validationMessage == null) ...[
            SizedBox(height: 3.w),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(1.w),
                border: Border.all(
                  color: Colors.blue.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue.shade700,
                    size: 4.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Nhận +50 điểm SPA khi sử dụng mã giới thiệu hợp lệ',
                      style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact version for inline use
class CompactReferralCodeInput extends StatelessWidget() {
  final String userId;
  final Function(bool success, String message)? onResult;

  const CompactReferralCodeInput({
    super.key,
    required this.userId,
    this.onResult,
  });

  @override
  Widget build(BuildContext context) {
    return BasicReferralCodeInput(
      userId: userId,
      onResult: onResult,
      showTitle: false,
    );
  }
}