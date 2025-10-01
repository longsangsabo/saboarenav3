import 'package:flutter/material.dart';
import './widgets/admin_scaffold_wrapper.dart';
import '../admin_tournament_management_screen/admin_tournament_management_screen.dart';

class AdminTournamentMainScreen extends StatelessWidget() {
  const AdminTournamentMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AdminScaffoldWrapper(
      title: 'Tournament',
      currentIndex: 2,
      onBottomNavTap: (index) => _onNavTap(context, index),
      body: const AdminTournamentManagementScreen(),
    );
  }

  void _onNavTap(BuildContext context, int index) {
    if (index != 2) {
      _navigateToTab(context, index);
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final routes = [
      '/admin_dashboard', // Dashboard
      '/admin_club_approval', // Duyệt CLB
      '/admin_tournament', // Tournament - current
      '/admin_user_management', // Users
      '/admin_more', // Khác
    ];
    
    if (index >= 0 && index < routes.length) {
      Navigator.pushReplacementNamed(context, routes[index]);
    }
  }
}