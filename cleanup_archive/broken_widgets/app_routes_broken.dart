import 'package:flutter/material.dart';
// Temporarily disable broken screen imports
// import '../presentation/splash_screen/splash_screen.dart';
// import '../presentation/onboarding_screen/onboarding_screen.dart';

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
        adminDashboardScreen: (context) => const AdminDashboardScreen(),
        adminMainScreen: (context) => const AdminMainScreen(),
        clubApprovalScreen: (context) => const AdminClubApprovalMainScreen(),
        adminTournamentScreen: (context) => const AdminTournamentMainScreen(),
        adminUserManagementScreen: (context) =>
            const AdminUserManagementMainScreen(),
        adminMoreScreen: (context) => const AdminMoreMainScreen(),
        myClubsScreen: (context) => const MyClubsScreen(),
        clubSelectionScreen: (context) => ClubSelectionScreen(),
        attendanceScreen: (context) => const AttendanceScreen(),
        attendanceDashboard: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final clubId = (args?['clubId'] as String?) ?? '';
          final clubName = (args?['clubName'] as String?) ?? '';
          return ClubAttendanceDashboard(clubId: clubId, clubName: clubName);
        },
        clubAttendanceDashboard: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final clubId = (args?['clubId'] as String?) ?? '';
          final clubName = (args?['clubName'] as String?) ?? '';
          return ClubAttendanceDashboard(clubId: clubId, clubName: clubName);
        },
        shiftReportingDashboard: (context) {
          final args = ModalRoute.of(context)?.settings.arguments
              as Map<String, dynamic>?;
          final clubId = (args?['clubId'] as String?) ?? '';
          return ShiftReportingDashboard(clubId: clubId);
        },
        demoQRScreen: (context) => const DemoQRCodeScreen(),
        // clubStaffManagementScreen: (context) {
        //   final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        //   final clubId = args?['clubId'] ?? '';
        //   return ClubStaffManagementScreen(clubId: clubId);
        // },
        // messagingScreen: (context) => const MessagingScreen(),
        // clubDashboardScreen: (context) => const ClubDashboardScreenSimple(clubId: ''),
      };
}
