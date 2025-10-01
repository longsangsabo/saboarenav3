import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/app_export.dart';
import '../../core/utils/sabo_rank_system.dart';
import '../../core/constants/ranking_constants.dart';

import './widgets/club_header_widget.dart';
import './widgets/club_info_section_widget.dart';
import './widgets/club_members_widget.dart';
import './widgets/club_photo_gallery_widget.dart';
import './widgets/club_tournaments_widget.dart';
import '../tournament_creation_wizard/tournament_creation_wizard.dart';
import '../rank_registration_screen/rank_registration_screen.dart';

class ClubProfileScreen extends StatefulWidget() {
  const ClubProfileScreen({super.key});

  @override
  State<ClubProfileScreen> createState() => _ClubProfileScreenState();
}

class _ClubProfileScreenState extends State<ClubProfileScreen>
    with TickerProviderStateMixin() {
  late ScrollController _scrollController;
  late TabController _tabController;
  
  // User profile data for rank checking
  Map<String, dynamic>? _userData;
  bool _isLoadingUser = false;

  // Mock data for club profile
  final Map<String, dynamic> _clubData = {
    "id": 1,
    "name": "Billiards Club Sài Gòn",
    "location": "Quận 1, TP. Hồ Chí Minh",
    "address": "123 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh",
    "memberCount": 156,
    "isMember": false,
    "isOwner": false,
    "coverImage":
        "https://images.unsplash.com/photo-1578662996442-48f60103fc96?fm=jpg&q=60&w=3000",
    "logo":
        "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fm=jpg&q=60&w=3000",
    "description":
        "Câu lạc bộ billiards hàng đầu tại Sài Gòn với hơn 20 năm kinh nghiệm. Chúng tôi cung cấp môi trường chơi chuyên nghiệp với các bàn bi-a chất lượng cao và không gian thoải mái cho các thành viên.",
    "phone": "0901234567",
    "email": "contact@billiardsclubsg.com",
    "amenities": [
      {"name": "20 bàn Pool", "icon": "sports_bar"},
      {"name": "10 bàn Carom", "icon": "sports_bar"},
      {"name": "Phòng VIP", "icon": "star"},
      {"name": "Quầy bar", "icon": "local_bar"},
      {"name": "WiFi miễn phí", "icon": "wifi"},
      {"name": "Điều hòa", "icon": "ac_unit"},
      {"name": "Bãi đỗ xe", "icon": "local_parking"},
      {"name": "Camera an ninh", "icon": "security"},
    ],
    "operatingHours": {
      "Thứ 2 - Thứ 6": "08:00 - 23:00",
      "Thứ 7 - Chủ nhật": "07:00 - 24:00",
      "Ngày lễ": "07:00 - 24:00",
    },
    "rating": 4.8,
    "reviewCount": 234,
  };

  final List<String> _clubPhotos = [
    "https://images.unsplash.com/photo-1578662996442-48f60103fc96?fm=jpg&q=60&w=3000",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fm=jpg&q=60&w=3000",
    "https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?fm=jpg&q=60&w=3000",
    "https://images.unsplash.com/photo-1578662996442-48f60103fc96?fm=jpg&q=60&w=3000",
    "https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fm=jpg&q=60&w=3000",
    "https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?fm=jpg&q=60&w=3000",
  ];

  final List<Map<String, dynamic>> _clubMembers = [
    {
      "id": 1,
      "name": "Nguyễn Văn An",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank A",
      "role": "owner",
      "isOnline": true,
      "joinDate": "2023-01-15",
    },
    {
      "id": 2,
      "name": "Trần Thị Bình",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank B",
      "role": "admin",
      "isOnline": false,
      "joinDate": "2023-02-20",
    },
    {
      "id": 3,
      "name": "Lê Minh Cường",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank C",
      "role": "member",
      "isOnline": true,
      "joinDate": "2023-03-10",
    },
    {
      "id": 4,
      "name": "Phạm Thị Dung",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank B",
      "role": "member",
      "isOnline": false,
      "joinDate": "2023-04-05",
    },
    {
      "id": 5,
      "name": "Hoàng Văn Em",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank A",
      "role": "member",
      "isOnline": true,
      "joinDate": "2023-05-12",
    },
    {
      "id": 6,
      "name": "Ngô Thị Phương",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank C",
      "role": "member",
      "isOnline": false,
      "joinDate": "2023-06-18",
    },
    {
      "id": 7,
      "name": "Đặng Minh Giang",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank B",
      "role": "member",
      "isOnline": true,
      "joinDate": "2023-07-22",
    },
    {
      "id": 8,
      "name": "Vũ Thị Hoa",
      "avatar":
          "https://cdn.pixabay.com/photo/2015/03/04/22/35/avatar-659652_640.png",
      "rank": "Rank A",
      "role": "member",
      "isOnline": false,
      "joinDate": "2023-08-30",
    },
  ];

  final List<Map<String, dynamic>> _clubTournaments = [
    {
      "id": 1,
      "name": "Giải Billiards Mùa Xuân 2024",
      "format": "8-Ball Pool",
      "status": "upcoming",
      "startDate": "2024-03-15T09:00:00Z",
      "endDate": "2024-03-17T18:00:00Z",
      "participants": 24,
      "maxParticipants": 32,
      "prizePool": "10.000.000 VNĐ",
      "entryFee": "200.000 VNĐ",
      "description":
          "Giải đấu 8-Ball Pool dành cho các thành viên câu lạc bộ và khách mời.",
    },
    {
      "id": 2,
      "name": "Giải Carom Hàng Tháng",
      "format": "3-Cushion Carom",
      "status": "ongoing",
      "startDate": "2024-02-20T19:00:00Z",
      "endDate": "2024-02-25T22:00:00Z",
      "participants": 16,
      "maxParticipants": 16,
      "prizePool": "5.000.000 VNĐ",
      "entryFee": "150.000 VNĐ",
      "description": "Giải đấu Carom 3 băng hàng tháng cho các thành viên.",
    },
    {
      "id": 3,
      "name": "Giải Vô Địch Câu Lạc Bộ 2023",
      "format": "9-Ball Pool",
      "status": "completed",
      "startDate": "2023-12-10T08:00:00Z",
      "endDate": "2023-12-15T20:00:00Z",
      "participants": 48,
      "maxParticipants": 48,
      "prizePool": "20.000.000 VNĐ",
      "entryFee": "300.000 VNĐ",
      "description": "Giải đấu lớn nhất trong năm của câu lạc bộ.",
      "winner": "Nguyễn Văn An",
    },
  ];

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
  }
  
  Future<void> _loadUserData() async() {
    setState(() {
      _isLoadingUser = true;
    });
    
    try() {
      // Load current user data from Supabase
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final response = await Supabase.instance.client
            .from('users')
            .select('*')
            .eq('id', user.id)
            .single();
        
        setState(() {
          _userData = response;
        });
      }
    } catch (error) {
      debugPrint('Error loading user data: $error');
    } finally() {
      setState(() {
        _isLoadingUser = false;
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Club Header with Cover Image
          ClubHeaderWidget(
            clubData: _clubData,
            isOwner: _clubData["isOwner"] as bool,
            onEditPressed: _handleEditClub,
            onJoinTogglePressed: _handleJoinToggle,
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 3.h),

                // Club Info Section
                ClubInfoSectionWidget(
                  clubData: _clubData,
                ),

                SizedBox(height: 3.h),

                // User Rank Status Section
                _buildUserRankSection(context),

                SizedBox(height: 3.h),

                // Photo Gallery
                ClubPhotoGalleryWidget(
                  photos: _clubPhotos,
                  onViewAll: _handleViewAllPhotos,
                ),

                SizedBox(height: 3.h),

                // Members Section
                ClubMembersWidget(
                  members: _clubMembers,
                  isOwner: _clubData["isOwner"] as bool,
                  onViewAll: _handleViewAllMembers,
                  onMemberTap: _handleMemberTap,
                ),

                SizedBox(height: 3.h),

                // Tournaments Section
                ClubTournamentsWidget(
                  tournaments: _clubTournaments,
                  isOwner: _clubData["isOwner"] as bool,
                  onViewAll: _handleViewAllTournaments,
                  onCreateTournament: _handleCreateTournament,
                  onTournamentTap: _handleTournamentTap,
                ),

                SizedBox(height: 3.h),

                // Rating and Reviews Section
                _buildRatingSection(context),

                SizedBox(height: 10.h), // Bottom padding for navigation
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.grey.withOpacity(0.2),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3, // Club tab
            selectedItemColor: Colors.green,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            elevation: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              _handleBottomNavTap(AppRoutes.homeFeedScreen);
              break;
            case 1:
              _handleBottomNavTap(AppRoutes.findOpponentsScreen);
              break;
            case 2:
              _handleBottomNavTap(AppRoutes.tournamentListScreen);
              break;
            case 3:
              // Already on club
              break;
            case 4:
              _handleBottomNavTap(AppRoutes.userProfileScreen);
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

  Widget _buildRatingSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final rating = _clubData["rating"] as double;
    final reviewCount = _clubData["reviewCount"] as int;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Đánh giá',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: _handleViewAllReviews,
                child: Text(
                  'Xem tất cả',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Text(
                rating.toString(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return CustomIconWidget(
                        iconName:
                            index < rating.floor() ? "star" : 'star_border',
                        color: Colors.amber,
                        size: 4.w,
                      );
                    }),
                  ),
                  Text(
                    '$reviewCount đánh giá',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _handleWriteReview,
            icon: CustomIconWidget(
              iconName: 'rate_review',
              color: colorScheme.onPrimary,
              size: 4.w,
            ),
            label: const Text('Viết đánh giá'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              minimumSize: Size(double.infinity, 6.h),
            ),
          ),
        ],
      ),
    );
  }

  void _handleEditClub() {
    // Navigate to club edit screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa câu lạc bộ'),
        content: const Text(
            'Chức năng chỉnh sửa thông tin câu lạc bộ sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleJoinToggle() {
    setState(() {
      final isMember = _clubData["isMember"] as bool;
      _clubData["isMember"] = !isMember;
      if (!isMember) {
        _clubData["memberCount"] = (_clubData["memberCount"] as int) + 1;
      } else() {
        _clubData["memberCount"] = (_clubData["memberCount"] as int) - 1;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _clubData["isMember"] as bool
              ? "Đã tham gia câu lạc bộ thành công!"
              : 'Đã rời khỏi câu lạc bộ!',
        ),
      ),
    );
  }

  void _handleViewAllPhotos() {
    // Navigate to photo gallery screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thư viện ảnh'),
        content: const Text('Chức năng xem tất cả ảnh sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleViewAllMembers() {
    // Navigate to members list screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Danh sách thành viên'),
        content:
            const Text('Chức năng xem tất cả thành viên sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleMemberTap(Map<String, dynamic> member) {
    Navigator.pushNamed(context, '/user-profile-screen');
  }

  void _handleViewAllTournaments() {
    Navigator.pushNamed(
      context, 
      AppRoutes.tournamentListScreen,
      arguments: {'clubId': _clubData['id'].toString()}, // Pass club ID as filter
    );
  }

  void _handleCreateTournament() {
    // Navigate to tournament creation wizard
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentCreationWizard(
          clubId: _clubData['id'].toString(),
        ),
      ),
    ).then((result) {
      if (result != null && result is Map<String, dynamic>) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Giải đấu đã được tạo thành công!'),
            backgroundColor: Colors.green,
          ),
        );
        // Refresh tournament list
        setState(() {});
      }
    });
  }

  void _handleTournamentTap(Map<String, dynamic> tournament) {
    Navigator.pushNamed(context, '/tournament-detail-screen');
  }

  Widget _buildUserRankSection(BuildContext context) {
    if (_isLoadingUser) {
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Center(
          child: CircularProgressIndicator(
            color: AppTheme.lightTheme.colorScheme.primary,
          ),
        ),
      );
    }

    if (_userData == null) {
      return SizedBox.shrink();
    }

    // Kiểm tra xem user có rank từ database hay không
    final userRank = _userData!["rank"] as String?;
    final hasRank = userRank != null && userRank.isNotEmpty && userRank != 'unranked';
    final currentElo = _userData!["elo_rating"] as int? ?? 1200;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.lightTheme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: hasRank 
              ? SaboRankSystem.getRankColor(RankingConstants.getRankFromElo(currentElo)).withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.military_tech,
                color: hasRank 
                    ? SaboRankSystem.getRankColor(RankingConstants.getRankFromElo(currentElo))
                    : Colors.orange,
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Trạng thái Rank',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      hasRank 
                          ? "Bạn đã có rank chính thức"
                          : 'Bạn chưa đăng ký rank chính thức',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (!hasRank)
                Container(
                  padding: EdgeInsets.all(1.w),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.priority_high,
                    color: Colors.white,
                    size: 4.w,
                  ),
                ),
            ],
          ),
          
          SizedBox(height: 3.h),
          
          // Rank info or registration prompt
          if (hasRank) ...[
            _buildRankInfo(userRank, currentElo),
          ] else ...[
            _buildRankRegistrationPrompt(),
          ],
        ],
      ),
    );
  }

  Widget _buildRankInfo(String rank, int elo) {
    final rankColor = SaboRankSystem.getRankColor(RankingConstants.getRankFromElo(elo));
    final skillDescription = SaboRankSystem.getRankSkillDescription(RankingConstants.getRankFromElo(elo));
    
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: rankColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: rankColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rank hiện tại: $rank',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: rankColor,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'ELO: $elo',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  skillDescription,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRankRegistrationPrompt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Để tham gia các trận đấu ranked tại club này, bạn cần đăng ký rank chính thức.',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'Lợi ích khi có rank:',
                style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.orange.shade800,
                ),
              ),
              SizedBox(height: 1.h),
              ...[
                '• Tham gia các trận đấu ranked',
                '• Theo dõi ELO rating chính xác',
                '• Tham gia giải đấu chính thức',
                '• Xem thống kê chi tiết',
              ].map((benefit) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Text(
                  benefit,
                  style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                    color: Colors.orange.shade700,
                  ),
                ),
              )),
            ],
          ),
        ),
        
        SizedBox(height: 2.h),
        
        // Registration button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _showRankRegistrationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 2.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.how_to_reg, size: 5.w),
                SizedBox(width: 2.w),
                Text(
                  'Đăng ký Rank ngay',
                  style: AppTheme.lightTheme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showRankRegistrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(
          'Đăng ký Rank Chính thức',
          style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Việc đăng ký rank sẽ giúp bạn:',
              style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDialogBenefit('🏆', 'Tham gia các trận đấu ranked'),
                  _buildDialogBenefit('📊', 'Theo dõi ELO rating chính xác'),
                  _buildDialogBenefit('🎯', 'Tham gia giải đấu chính thức'),
                  _buildDialogBenefit('📈', 'Xem thống kê chi tiết'),
                  _buildDialogBenefit('🏅', 'Cạnh tranh với players khác'),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              'Bạn có muốn đăng ký rank ngay bây giờ không?',
              style: AppTheme.lightTheme.textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Để sau',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRankRegistration();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
            ),
            child: Text('Đăng ký ngay'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogBenefit(String emoji, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 4.w)),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRankRegistration() {
    // Use mock club ID since this screen uses mock data
    final clubId = _clubData["id"].toString();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RankRegistrationScreen(clubId: clubId),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh user data if rank request was submitted
        _loadUserData();
      }
    });
  }

  void _handleViewAllReviews() {
    // Navigate to reviews screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tất cả đánh giá'),
        content:
            const Text('Chức năng xem tất cả đánh giá sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleWriteReview() {
    // Show review dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Viết đánh giá'),
        content: const Text('Chức năng viết đánh giá sẽ được triển khai.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  void _handleBottomNavTap(String route) {
    if (route != AppRoutes.clubProfileScreen) {
      Navigator.pushReplacementNamed(context, route);
    }
  }
}
