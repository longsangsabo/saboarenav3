import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/app_export.dart';
import '../../services/basic_referral_service.dart';

/// Basic Referral Card Widget
/// Displays user's referral code with sharing functionality
class BasicReferralCard extends StatefulWidget() {
  final String userId;
  final VoidCallback? onStatsUpdate;

  const BasicReferralCard({
    super.key,
    required this.userId,
    this.onStatsUpdate,
  });

  @override
  State<BasicReferralCard> createState() => _BasicReferralCardState();
}

class _BasicReferralCardState extends State<BasicReferralCard> {
  String? _referralCode;
  bool _isLoading = true;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateReferralCode();
  }

  Future<void> _loadOrGenerateReferralCode() async() {
    setState(() => _isLoading = true);
    
    try() {
      // Try to get existing code first
      final stats = await BasicReferralService.getUserReferralStats(widget.userId);
      
      if (stats != null && stats['user_code'] != null) {
        setState(() {
          _referralCode = stats['user_code'];
          _isLoading = false;
        });
      } else() {
        // Generate new code if doesn't exist
        await _generateNewCode();
      }
    } catch (e) {
      debugPrint('Error loading referral code: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _generateNewCode() async() {
    setState(() => _isGenerating = true);
    
    try() {
      final newCode = await BasicReferralService.generateReferralCode(widget.userId);
      
      if (newCode != null) {
        setState(() {
          _referralCode = newCode;
          _isGenerating = false;
          _isLoading = false;
        });
        
        widget.onStatsUpdate?.call();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Mã giới thiệu đã được tạo: $newCode'),
            backgroundColor: Colors.green,
          ),
        );
      } else() {
        throw Exception('Failed to generate code');
      }
    } catch (e) {
      setState(() {
        _isGenerating = false;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Lỗi tạo mã giới thiệu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _copyToClipboard() async() {
    if (_referralCode != null) {
      await Clipboard.setData(ClipboardData(text: _referralCode!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('📋 Đã sao chép mã: $_referralCode'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareReferralCode() async() {
    if (_referralCode != null) {
      final shareText = '''
🏆 Tham gia SABO Arena cùng tôi!

🎯 Sử dụng mã giới thiệu: $_referralCode
💰 Nhận ngay 50 điểm SPA miễn phí!

📱 Tải app SABO Arena và bắt đầu chinh phục bàn bida ngay hôm nay!

#SABOArena #BidaOnline #GioiThieu
''';

      await Share.share(
        shareText,
        subject: 'Tham gia SABO Arena với mã $_referralCode',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight.withOpacity(0.1),
            AppTheme.secondaryLight.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(4.w),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.card_giftcard,
                color: AppTheme.primaryLight,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Mã Giới Thiệu Của Bạn',
                  style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 4.w),
          
          // Referral Code Display
          if (_isLoading)
            _buildLoadingState()
          else if (_referralCode != null)
            _buildCodeDisplay()
          else
            _buildGenerateButton(),
          
          SizedBox(height: 4.w),
          
          // Benefits Info
          _buildBenefitsInfo(),
          
          if (_referralCode != null) ...[
            SizedBox(height: 4.w),
            _buildActionButtons(),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 5.w,
            height: 5.w,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 3.w),
          Text(
            'Đang tải mã giới thiệu...',
            style: AppTheme.lightTheme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildCodeDisplay() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: AppTheme.primaryLight.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.code,
            color: AppTheme.primaryLight,
            size: 6.w,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(
              _referralCode!,
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                color: AppTheme.primaryLight,
              ),
            ),
          ),
          IconButton(
            onPressed: _copyToClipboard,
            icon: Icon(
              Icons.copy,
              color: AppTheme.primaryLight,
            ),
            tooltip: 'Sao chép mã',
          ),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isGenerating ? null : _generateNewCode,
        icon: _isGenerating 
            ? SizedBox(
                width: 4.w,
                height: 4.w,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(Icons.add_circle_outline),
        label: Text(
          _isGenerating ? "Đang tạo mã..." : 'Tạo Mã Giới Thiệu',
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryLight,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 3.w),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2.w),
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitsInfo() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🎁 Phần thưởng giới thiệu:',
            style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          SizedBox(height: 2.w),
          Row(
            children: [
              Icon(Icons.monetization_on, color: Colors.orange, size: 4.w),
              SizedBox(width: 2.w),
              Text(
                'Bạn nhận +100 SPA khi bạn bè sử dụng mã',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
          SizedBox(height: 1.w),
          Row(
            children: [
              Icon(Icons.card_giftcard, color: Colors.green, size: 4.w),
              SizedBox(width: 2.w),
              Text(
                'Bạn bè nhận +50 SPA khi đăng ký',
                style: AppTheme.lightTheme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyToClipboard,
            icon: Icon(Icons.copy, size: 4.w),
            label: Text('Sao chép'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryLight,
              side: BorderSide(color: AppTheme.primaryLight),
              padding: EdgeInsets.symmetric(vertical: 2.5.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareReferralCode,
            icon: Icon(Icons.share, size: 4.w),
            label: Text('Chia sẻ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.5.w),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2.w),
              ),
            ),
          ),
        ),
      ],
    );
  }
}