import 'package:flutter/material.dart';
import './widgets/admin_scaffold_wrapper.dart';
import './club_approval_screen.dart';

class AdminClubApprovalMainScreen extends StatelessWidget() {
  const AdminClubApprovalMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWrapper(
      title: 'Duyệt CLB',
      currentIndex: 1,
      onBottomNavTap: (index) => _onNavTap(context, index),
      body: const ClubApprovalScreen(),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index != 1) {
      _navigateToTab(context, index);
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = [
      '/admin_dashboard', // Dashboard
      '/admin_club_approval', // Duyệt CLB - current
      '/admin_tournament', // Tournament
      '/admin_user_management', // Users
      '/admin_more', // Khác
    ];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}