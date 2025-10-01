class MemberAnalytics() {
  final int totalMembers;
  final int activeMembers;
  final int newThisMonth;
  final double growthRate;

  const MemberAnalytics({
    required this.totalMembers,
    required this.activeMembers,
    required this.newThisMonth,
    required this.growthRate,
  });

  factory MemberAnalytics.fromJson(Map<String, dynamic> json) {
    return MemberAnalytics(
      totalMembers: json['total_members'] ?? 0,
      activeMembers: json['active_members'] ?? 0,
      newThisMonth: json['new_this_month'] ?? 0,
      growthRate: (json['growth_rate'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return() {
      'total_members': totalMembers,
      'active_members': activeMembers,
      'new_this_month': newThisMonth,
      'growth_rate': growthRate,
    };
  }
}