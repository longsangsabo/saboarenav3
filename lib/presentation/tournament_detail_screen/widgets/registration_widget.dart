import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/layout/responsive.dart';
import 'payment_options_dialog.dart';

class RegistrationWidget extends StatefulWidget {
  const RegistrationWidget({super.key});

} 
  final Map<String, dynamic> tournament;
  final bool isRegistered;
  final VoidCallback? onRegisterTap;
  final VoidCallback? onWithdrawTap;

  const RegistrationWidget({
    super.key,
    required this.tournament,
    required this.isRegistered,
    this.onRegisterTap,
    this.onWithdrawTap,
  });

  @override
  State<RegistrationWidget> createState() => _RegistrationWidgetState();
}

class _RegistrationWidgetState extends State<RegistrationWidget> {

  @override
  Widget build(BuildContext context) {
    final registrationDeadline = widget.tournament["registrationDeadline"] as String;
    final isDeadlinePassed = _isDeadlinePassed(registrationDeadline);
    final canRegister = !isDeadlinePassed &&
        (widget.tournament["currentParticipants"] as int) <
            (widget.tournament["maxParticipants"] as int);

    return Container(
      margin: const EdgeInsets.all(Gaps.xl),
      padding: const EdgeInsets.all(Gaps.xl),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                AppTheme.lightTheme.colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'how_to_reg',
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: Gaps.md),
              Text(
                'Đăng ký tham gia',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: Gaps.lg),
      _buildRequirementItem('Hạn đăng ký', registrationDeadline, 'schedule'),
      const SizedBox(height: Gaps.sm),
      _buildRequirementItem('Yêu cầu rank', widget.tournament["rankRequirement"] as String, 'military_tech'),
      const SizedBox(height: Gaps.sm),
      _buildRequirementItem('Lệ phí', widget.tournament["entryFee"] as String, 'payments'),
      const SizedBox(height: Gaps.lg),
          if (!isDeadlinePassed)
            Container(
              padding: const EdgeInsets.all(Gaps.lg),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'timer',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: Gaps.md),
                  Expanded(
                    child: Text(
                      _getTimeRemaining(registrationDeadline),
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: Gaps.lg),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: _buildActionButton(context, canRegister, isDeadlinePassed),
          ),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String label, String value, String iconName) {
    return Row(
      children: [
        CustomIconWidget(
          iconName: iconName,
          color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          size: 18,
        ),
  const SizedBox(width: Gaps.md),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTheme.lightTheme.textTheme.bodyMedium,
              ),
              Text(
                value,
                style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context, bool canRegister, bool isDeadlinePassed) {
    if (isDeadlinePassed) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Hết hạn đăng ký',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    if (widget.isRegistered) {
      return OutlinedButton(
        onPressed: widget.onWithdrawTap,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: AppTheme.lightTheme.colorScheme.error,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'check_circle',
              color: AppTheme.lightTheme.colorScheme.error,
              size: 20,
            ),
            const SizedBox(width: Gaps.md),
            Text(
              'Đã đăng ký - Rút lui',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                color: AppTheme.lightTheme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (!canRegister) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          'Đã đầy',
          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
            color: AppTheme.lightTheme.colorScheme.surface,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: () => _showPaymentOptions(context),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'how_to_reg',
            color: AppTheme.lightTheme.colorScheme.onPrimary,
            size: 20,
          ),
          const SizedBox(width: Gaps.md),
          Text(
            'Đăng ký ngay',
            style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentOptions(BuildContext context) {
    final entryFeeText = widget.tournament["entryFee"] as String;
    final entryFee = double.tryParse(entryFeeText.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    
    showDialog(
      context: context,
      builder: (context) => PaymentOptionsDialog(
        tournamentId: widget.tournament["id"] as String,
        tournamentName: widget.tournament["title"] as String,
        entryFee: entryFee,
        onPaymentConfirmed: (paymentMethod) {
          // Handle payment confirmation with payment method
          widget.onRegisterTap?.call();
        },
      ),
    );
  }

  bool _isDeadlinePassed(String deadline) {
    try {
      final deadlineDate =
          DateTime.parse(deadline.split(' ')[0].split('/').reversed.join('-'));
      return DateTime.now().isAfter(deadlineDate);
    } catch (e) {
      return false;
    }
  }

  String _getTimeRemaining(String deadline) {
    try {
      final deadlineDate =
          DateTime.parse(deadline.split(' ')[0].split('/').reversed.join('-'));
      final now = DateTime.now();
      final difference = deadlineDate.difference(now);

      if (difference.inDays > 0) {
        return 'Còn ${difference.inDays} ngày để đăng ký';
      } else if (difference.inHours > 0) {
        return 'Còn ${difference.inHours} giờ để đăng ký';
      } else if (difference.inMinutes > 0) {
        return 'Còn ${difference.inMinutes} phút để đăng ký';
      } else {
        return 'Sắp hết hạn đăng ký';
      }
    } catch (e) {
      return 'Kiểm tra thời gian đăng ký';
    }
  }
}
