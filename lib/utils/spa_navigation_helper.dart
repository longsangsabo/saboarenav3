
/// Navigation utilities for SPA management system
class SpaNavigationHelper {
  /// Navigate to user SPA rewards screen
  static void navigateToUserSpaRewards(
    BuildContext context, {
    required String clubId,
    required String clubName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SpaRewardScreen(
          clubId: clubId,
          clubName: clubName,
        ),
      ),
    );
  }

  /// Navigate to club SPA management screen (for club owners)
  static void navigateToClubSpaManagement(
    BuildContext context, {
    required String clubId,
    required String clubName,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ClubSpaManagementScreen(
          clubId: clubId,
          clubName: clubName,
        ),
      ),
    );
  }

  /// Navigate to admin SPA management screen (for admins)
  static void navigateToAdminSpaManagement(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AdminSpaManagementScreen(),
      ),
    );
  }

  /// Show SPA balance as bottom sheet
  static void showSpaBalanceBottomSheet(
    BuildContext context, {
    required double spaBalance,
    required String clubId,
    required String clubName,
    VoidCallback? onRedeemRewards,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            Text(
              'Số dư SPA của bạn',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '${spaBalance.toStringAsFixed(0)} SPA',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'SPA là điểm thưởng bạn nhận được khi tham gia thách đấu. '
              'Sử dụng SPA để đổi phần thưởng hấp dẫn từ câu lạc bộ!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Đóng'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      if (onRedeemRewards != null) {
                        onRedeemRewards();
                      } else() {
                        navigateToUserSpaRewards(
                          context,
                          clubId: clubId,
                          clubName: clubName,
                        );
                      }
                    },
                    child: const Text('Đổi thưởng'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Show SPA bonus earned notification
  static void showSpaBonusEarnedSnackBar(
    BuildContext context, {
    required double spaAmount,
    required String activity,
    required String clubId,
    required String clubName,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.emoji_events,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bạn đã nhận SPA!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('+${spaAmount.toStringAsFixed(0)} SPA từ $activity'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Xem',
          textColor: Colors.white,
          onPressed: () => navigateToUserSpaRewards(
            context,
            clubId: clubId,
            clubName: clubName,
          ),
        ),
      ),
    );
  }

  /// Show SPA reward redeemed notification
  static void showSpaRewardRedeemedSnackBar(
    BuildContext context, {
    required String rewardName,
    required double spaCost,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.card_giftcard,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Đổi thưởng thành công!',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('$rewardName (-${spaCost.toStringAsFixed(0)} SPA)'),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  /// Create SPA balance display widget
  static Widget buildSpaBalanceChip({
    required double balance,
    VoidCallback? onTap,
    bool showLabel = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 16,
              color: Colors.blue.shade700,
            ),
            const SizedBox(width: 4),
            Text(
              '${balance.toStringAsFixed(0)}${showLabel ? " SPA" : ''}',
              style: TextStyle(
                color: Colors.blue.shade700,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Create floating SPA button for quick access
  static Widget buildFloatingSpaButton({
    required BuildContext context,
    required double balance,
    required String clubId,
    required String clubName,
    VoidCallback? onPressed,
  }) {
    return FloatingActionButton.extended(
      onPressed: onPressed ?? () => navigateToUserSpaRewards(
        context,
        clubId: clubId,
        clubName: clubName,
      ),
      backgroundColor: Colors.blue,
      icon: const Icon(Icons.account_balance_wallet),
      label: Text('${balance.toStringAsFixed(0)} SPA'),
    );
  }
}