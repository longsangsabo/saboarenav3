import 'package:flutter/material.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/home_feed_screen/home_feed_screen.dart';
import '../presentation/tournament_list_screen/tournament_list_screen.dart';
import '../presentation/find_opponents_screen/find_opponents_screen.dart';
import '../presentation/club_main_screen/club_main_screen.dart';
import '../presentation/club_profile_screen/club_profile_screen.dart';
import '../presentation/club_registration_screen/club_registration_screen.dart';
import '../presentation/club_selection_screen/club_selection_screen.dart';
import 'package:sabo_arena/presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/tournament_detail_screen/tournament_detail_screen.dart';
import '../presentation/login_screen.dart';
import '../presentation/register_screen.dart';
import '../presentation/forgot_password_screen.dart';
import '../presentation/admin_dashboard_screen/admin_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_dashboard_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_club_approval_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_tournament_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_user_management_main_screen.dart';
import '../presentation/admin_dashboard_screen/admin_more_main_screen.dart';
import '../presentation/my_clubs_screen/my_clubs_screen.dart';

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
        adminUserManagementScreen: (context) => const AdminUserManagementMainScreen(),
        adminMoreScreen: (context) => const AdminMoreMainScreen(),
        myClubsScreen: (context) => const MyClubsScreen(),
        clubSelectionScreen: (context) => ClubSelectionScreen(),
        // clubDashboardScreen: (context) => const ClubDashboardScreenSimple(clubId: ''),
      };
}
