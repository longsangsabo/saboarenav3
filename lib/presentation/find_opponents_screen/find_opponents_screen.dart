import 'package:flutter/material.dart';

import '../../models/user_profile.dart';
import '../../services/user_service.dart';
import '../../services/location_service.dart';
import '../../helpers/privacy_helper.dart';
import '../../routes/app_routes.dart';

import './widgets/filter_bottom_sheet.dart';
import './widgets/competitive_play_tab.dart';
import './widgets/social_play_tab.dart';
import '../../widgets/qr_scanner_widget.dart';

class FindOpponentsScreen extends StatefulWidget() {
  const FindOpponentsScreen({super.key});

  @override
  State<FindOpponentsScreen> createState() => _FindOpponentsScreenState();
}

class _FindOpponentsScreenState extends State<FindOpponentsScreen>
    with TickerProviderStateMixin() {
  final UserService _userService = UserService.instance;
  final LocationService _locationService = LocationService.instance;

  List<UserProfile> _socialPlayers = [];
  List<UserProfile> _competitivePlayers = [];
  bool _isLoading = true;
  String? _errorMessage;
  bool _isMapView = false;
  String _selectedSkillLevel = 'all';
  double _radiusKm = 10.0;
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPlayers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPlayers() async() {
    try() {
      if (mounted) {
        setState(() {
          _isLoading = true;
          _errorMessage = null;
        });
      }

      // 1. Get current user's position
      final position = await _locationService.getCurrentPosition();

      // 2. Find nearby opponents using the new service method
      final players = await _userService.findOpponentsNearby(
        latitude: position.latitude,
        longitude: position.longitude,
        radiusInKm: _radiusKm,
      );

      // 3. Filter by skill level if selected
      final skillFilteredPlayers = _selectedSkillLevel == 'all'
          ? players
          : players.where((p) => p.skillLevel == _selectedSkillLevel).toList();

      // 4. Apply privacy filters for both social and competitive
      final playersJson = skillFilteredPlayers.map((p) => p.toJson()).toList();
      
      // Filter for social feed (tab "giao lưu")
      final socialFilteredPlayers = await PrivacyHelper.filterUsersForPublicDisplay(
        playersJson,
        'social_feed',
      );
      
      // Filter for challenge list (tab "thách đấu")
      final challengeFilteredPlayers = await PrivacyHelper.filterUsersForPublicDisplay(
        playersJson,
        'challenge_list',
      );

      // 5. Convert back to UserProfile objects
      final finalSocialPlayers = socialFilteredPlayers
          .map((json) => UserProfile.fromJson(json))
          .toList();
          
      final finalCompetitivePlayers = challengeFilteredPlayers
          .map((json) => UserProfile.fromJson(json))
          .toList();

      if (mounted) {
        setState(() {
          _socialPlayers = finalSocialPlayers;
          _competitivePlayers = finalCompetitivePlayers;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = error.toString();
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tải danh sách đối thủ: $_errorMessage')),
        );
      }
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => FilterBottomSheet(
        currentFilters: {
          'skillLevel': _selectedSkillLevel,
          'distance': _radiusKm,
        },
        onFiltersChanged: (filters) {
          if (mounted) {
            setState(() {
              _selectedSkillLevel = filters['skillLevel'] ?? 'all';
              _radiusKm = filters['distance'] ?? 10.0;
            });
            _loadPlayers();
          }
        },
      ),
    );
  }

  void _handleNavigation(String route) {
    if (route != AppRoutes.findOpponentsScreen) {
      Navigator.pushReplacementNamed(context, route);
    }
  }

  void _showQRScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRScannerWidget(
          onUserFound: (Map<String, dynamic> userData) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Đã tìm thấy người chơi: ${userData['fullName'] ?? 'Không rõ tên'}'),
                duration: Duration(seconds: 3),
              ),
            );
            // Optionally navigate to user profile or add to opponents list
            Navigator.pushNamed(
              context, 
              AppRoutes.userProfileScreen,
              arguments: {'userId': userData['id']},
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tìm đối thủ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.tune),
          ),
          IconButton(
            onPressed: () {
              if (mounted) {
                setState(() => _isMapView = !_isMapView);
              }
            },
            icon: Icon(_isMapView ? Icons.list : Icons.map),
          ),
          IconButton(
            onPressed: _showQRScanner,
            icon: const Icon(Icons.qr_code_scanner),
            tooltip: 'Quét QR để tìm người chơi',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).primaryColor,
          unselectedLabelColor: Colors.grey[600],
          indicatorColor: Theme.of(context).primaryColor,
          tabs: const [
            Tab(
              icon: Icon(Icons.emoji_events),
              text: 'Thách đấu',
            ),
            Tab(
              icon: Icon(Icons.groups),
              text: 'Giao lưu',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CompetitivePlayTab(
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            players: _competitivePlayers,
            isMapView: _isMapView,
            onRefresh: _loadPlayers,
          ),
          SocialPlayTab(
            isLoading: _isLoading,
            errorMessage: _errorMessage,
            players: _socialPlayers,
            isMapView: _isMapView,
            onRefresh: _loadPlayers,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 1, // Find opponents tab
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
            onTap: (index) {
              switch (index) {
                case 0:
                  _handleNavigation(AppRoutes.homeFeedScreen);
                  break;
                case 1:
                  // Already on find opponents
                  break;
                case 2:
                  _handleNavigation(AppRoutes.tournamentListScreen);
                  break;
                case 3:
                  _handleNavigation(AppRoutes.clubMainScreen);
                  break;
                case 4:
                  _handleNavigation(AppRoutes.userProfileScreen);
                  break;
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Trang chủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Đối thủ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events_outlined),
                activeIcon: Icon(Icons.emoji_events),
                label: 'Giải đấu',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.business_outlined),
                activeIcon: Icon(Icons.business),
                label: 'Câu lạc bộ',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: 'Cá nhân',
              ),
            ],
          ),
        ),
      ),
    );
  }


}