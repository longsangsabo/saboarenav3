import 'package:flutter/material.dart';
import './widgets/admin_scaffold_wrapper.dart';
import './admin_user_management_screen.dart';

class AdminUserManagementMainScreen extends StatelessWidget() {
  const AdminUserManagementMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWrapper(
      title: 'Quản lý Users',
      currentIndex: 3,
      onBottomNavTap: (index) => _onNavTap(context, index),
      body: const AdminUserManagementScreen(),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index != 3) {
      _navigateToTab(context, index);
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = [
      '/admin_dashboard', // Dashboard
      '/admin_club_approval', // Duyệt CLB
      '/admin_tournament', // Tournament
      '/admin_user_management', // Users - current
      '/admin_more', // Khác
    ];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}