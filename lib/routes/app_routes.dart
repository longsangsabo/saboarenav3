import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen.dart';
import '../presentation/register_screen/register_screen.dart';
import '../presentation/forgot_password_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/home_feed_screen/home_feed_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/tournament_list_screen/tournament_list_screen.dart';
import '../presentation/tournament_detail_screen/tournament_detail_screen.dart';
import '../presentation/find_opponents_screen/find_opponents_screen.dart';
import '../presentation/club_main_screen/club_main_screen.dart';
import '../presentation/club_profile_screen/club_profile_screen.dart';
import '../presentation/club_registration_screen/club_registration_screen.dart';
import '../presentation/my_clubs_screen/my_clubs_screen.dart';
import '../presentation/club_selection_screen/club_selection_screen.dart';
import '../presentation/attendance_screen/attendance_screen.dart';

class AppRoutes {
  static const String splashScreen = '/splash';
  static const String onboardingScreen = '/onboarding';
  static const String homeFeedScreen = '/home_feed_screen';
  static const String tournamentListScreen = '/tournament_list_screen';
  static const String findOpponentsScreen = '/find_opponents_screen';
  static const String clubMainScreen = '/club_main_screen';
  static const String clubProfileScreen = '/club_profile_screen';
  static const String clubRegistrationScreen = '/club_registration_screen';
  static const String userProfileScreen = '/user_profile_screen';
  static const String tournamentDetailScreen = '/tournament_detail_screen';
  static const String loginScreen = '/login';
  static const String registerScreen = '/register';
  static const String forgotPasswordScreen = '/forgot-password';
  static const String adminDashboardScreen = '/admin_dashboard';
  static const String adminMainScreen = '/admin_main';
  static const String clubApprovalScreen = '/admin_club_approval';
  static const String adminTournamentScreen = '/admin_tournament';
  static const String adminUserManagementScreen = '/admin_user_management';
  static const String adminMoreScreen = '/admin_more';
  static const String myClubsScreen = '/my_clubs';
  static const String clubDashboardScreen = '/club_dashboard';
  static const String clubSelectionScreen = '/club_selection_screen';
  static const String messagingScreen = '/messaging';
  static const String clubStaffManagementScreen = '/club_staff_management';
  static const String attendanceScreen = '/attendance';
  static const String attendanceDashboard = '/attendance_dashboard';
  static const String clubAttendanceDashboard = '/club_attendance_dashboard';
  static const String shiftReportingDashboard = '/shift_reporting_dashboard';
  static const String demoQRScreen = '/demo_qr';

  static const String initial = splashScreen;

  static Map<String, WidgetBuilder> get routes => {
        splashScreen: (context) => const SplashScreen(),
        // Real implemented screens
        onboardingScreen: (context) => const OnboardingScreen(),
        homeFeedScreen: (context) => const HomeFeedScreen(),
        tournamentListScreen: (context) => const TournamentListScreen(),
        findOpponentsScreen: (context) => const FindOpponentsScreen(),
        clubMainScreen: (context) => const ClubMainScreen(),
        clubProfileScreen: (context) => const ClubProfileScreen(),
        clubRegistrationScreen: (context) => const ClubRegistrationScreen(),
        userProfileScreen: (context) => const UserProfileScreen(),
        tournamentDetailScreen: (context) => const TournamentDetailScreen(),
        loginScreen: (context) => const LoginScreen(),
        registerScreen: (context) => const RegisterScreen(),
        forgotPasswordScreen: (context) => const ForgotPasswordScreen(),
        adminDashboardScreen: (context) => const Scaffold(body: Center(child: Text('Admin Dashboard Screen'))),
        adminMainScreen: (context) => const Scaffold(body: Center(child: Text('Admin Main Screen'))),
        clubApprovalScreen: (context) => const Scaffold(body: Center(child: Text('Club Approval Screen'))),
        adminTournamentScreen: (context) => const Scaffold(body: Center(child: Text('Admin Tournament Screen'))),
        adminUserManagementScreen: (context) => const Scaffold(body: Center(child: Text('Admin User Management Screen'))),
        adminMoreScreen: (context) => const Scaffold(body: Center(child: Text('Admin More Screen'))),
        myClubsScreen: (context) => const Scaffold(body: Center(child: Text('My Clubs Screen'))),
        clubSelectionScreen: (context) => const Scaffold(body: Center(child: Text('Club Selection Screen'))),
        attendanceScreen: (context) => const Scaffold(body: Center(child: Text('Attendance Screen'))),
        demoQRScreen: (context) => const Scaffold(body: Center(child: Text('Demo QR Screen'))),
      };
}
