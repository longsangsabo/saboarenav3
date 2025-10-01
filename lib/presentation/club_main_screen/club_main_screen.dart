import 'package:flutter/material.dart';

import '../../models/club.dart';
import '../../services/club_service.dart';
import '../../routes/app_routes.dart';
import 'widgets/horizontal_club_list.dart';
import 'widgets/club_detail_section.dart';

class ClubMainScreen extends StatefulWidget {
  const ClubMainScreen({super.key});

@override
  State<ClubMainScreen> createState() => _ClubMainScreenState();
}

class _ClubMainScreenState extends State<ClubMainScreen> {
  Club? _selectedClub;
  List<Club> _clubs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClubs();
  }

  void _loadClubs() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load clubs from Supabase
      final clubs = await ClubService.instance.getClubs(limit: 10);
      
      setState(() {
        _clubs = clubs;
        _selectedClub = clubs.isNotEmpty ? clubs.first : null;
        _isLoading = false;
      });
    } catch (error) {
      // If Supabase fails, fallback to mock data
      debugPrint('Error loading clubs from Supabase: $error');
      setState(() {
        _clubs = _getMockClubs();
        _selectedClub = _clubs.isNotEmpty ? _clubs.first : null;
        _isLoading = false;
      });
    }
  }

  void _onClubSelected(Club club) {
    setState(() {
      _selectedClub = club;
    });
  }

  void _handleBottomNavTap(String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  void _showRegisterClubDialog() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.verified_outlined,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Xác thực quyền sở hữu',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chỉ chủ sở hữu hoặc quản lý câu lạc bộ mới có thể đăng ký',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'Để đảm bảo tính xác thực, bạn cần cung cấp:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildVerificationRequirement(
                '📋', 
                'Giấy phép kinh doanh',
                'Giấy phép kinh doanh có tên bạn hoặc câu lạc bộ'
              ),
              _buildVerificationRequirement(
                '🏢', 
                'Địa chỉ cụ thể',
                'Địa chỉ thực tế của câu lạc bộ (có thể xác minh)'
              ),
              _buildVerificationRequirement(
                '📞', 
                'Số điện thoại liên hệ',
                'SĐT chính thức của câu lạc bộ để xác minh'
              ),
              _buildVerificationRequirement(
                '🆔', 
                'CCCD/CMND',
                'Chứng minh nhân dân của người đại diện'
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Quy trình xác thực:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildProcessStep('1', 'Gửi thông tin và tài liệu'),
                    _buildProcessStep('2', 'Admin sẽ xác minh trong 1-2 ngày'),
                    _buildProcessStep('3', 'Thông báo kết quả qua email/SMS'),
                    _buildProcessStep('4', 'Kích hoạt câu lạc bộ nếu hợp lệ'),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Lợi ích sau khi xác thực:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildBenefitItem('⭐', 'Huy hiệu "Đã xác thực" tin cậy'),
                    _buildBenefitItem('�', 'Ưu tiên hiển thị trong tìm kiếm'),
                    _buildBenefitItem('�', 'Công cụ quản lý chuyên nghiệp'),
                    _buildBenefitItem('💰', 'Tăng khả năng thu hút khách hàng'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Hủy',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showVerificationAgreement();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Tôi hiểu và đồng ý'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToRegisterClubForm() {
    Navigator.pushNamed(context, '/club_registration_screen');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Câu lạc bộ',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(context, '/my_clubs');
              },
              icon: Icon(
                Icons.store,
                color: colorScheme.primary,
                size: 24,
              ),
              tooltip: 'CLB của tôi',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _showRegisterClubDialog,
              icon: Icon(
                Icons.add_business,
                color: colorScheme.primary,
                size: 24,
              ),
              tooltip: 'Đăng ký câu lạc bộ',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Top section: Horizontal Club List (1/3 screen)
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.25,
                  child: HorizontalClubList(
                    clubs: _clubs,
                    selectedClub: _selectedClub,
                    onClubSelected: _onClubSelected,
                  ),
                ),

                // Divider
                Container(
                  height: 1,
                  color: colorScheme.outline.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),

                // Bottom section: Club Detail (2/3 screen)
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.1, 0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOut,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: _selectedClub != null
                        ? ClubDetailSection(
                            key: ValueKey(_selectedClub!.id),
                            club: _selectedClub!,
                          )
                        : Center(
                            key: const ValueKey('empty'),
                            child: Text(
                              'Chọn một câu lạc bộ để xem chi tiết',
                              style: TextStyle(
                                fontSize: 16,
                                color: colorScheme.onSurface.withOpacity(0.6),
                              ),
                            ),
                          ),
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

  // Helper methods for verification dialog
  Widget _buildVerificationRequirement(String icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            icon,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessStep(String number, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationAgreement() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.assignment_outlined,
              color: colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Cam kết xác thực',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tôi cam kết rằng:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              
              const SizedBox(height: 12),
              
              _buildCommitmentItem('✓', 'Tôi là chủ sở hữu hoặc người được ủy quyền đại diện cho câu lạc bộ này'),
              _buildCommitmentItem('✓', 'Tất cả thông tin tôi cung cấp là chính xác và có thể xác minh'),
              _buildCommitmentItem('✓', 'Tôi có đủ tài liệu chứng minh quyền sở hữu/quản lý câu lạc bộ'),
              _buildCommitmentItem('✓', 'Tôi đồng ý với quy trình xác minh của Sabo Arena'),
              _buildCommitmentItem('✓', 'Tôi hiểu rằng thông tin sai lệch sẽ dẫn đến từ chối đăng ký'),
              
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.gavel,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Lưu ý: Việc cung cấp thông tin sai lệch hoặc giả mạo có thể dẫn đến khóa tài khoản vĩnh viễn.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Quay lại',
              style: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _navigateToRegisterClubForm();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: const Text('Tôi cam kết và tiếp tục'),
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentItem(String checkmark, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            checkmark,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Mock data for testing
  List<Club> _getMockClubs() {
    return [
      Club(
        id: '1',
        ownerId: 'owner1',
        name: 'Billiards Club Sài Gòn',
        description: 'Câu lạc bộ billiards hàng đầu tại Sài Gòn với hơn 20 năm kinh nghiệm.',
        address: '123 Nguyễn Huệ, Phường Bến Nghé, Quận 1, TP. Hồ Chí Minh',
        phone: '0901234567',
        email: 'contact@billiardsclubsg.com',
        coverImageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?fm=jpg&q=60&w=3000',
        profileImageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fm=jpg&q=60&w=3000',
        totalTables: 30,
        isVerified: true,
        isActive: true,
        approvalStatus: 'approved',
        rating: 4.8,
        totalReviews: 234,
        createdAt: DateTime.now().subtract(const Duration(days: 365)),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: '2',
        ownerId: 'owner2',
        name: 'Pool Center Hà Nội',
        description: 'Trung tâm bi-a hiện đại với không gian rộng rãi và thoáng mát.',
        address: '456 Hoàng Diệu, Ba Đình, Hà Nội',
        phone: '0912345678',
        email: 'info@poolcenterhn.com',
        coverImageUrl: 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?fm=jpg&q=60&w=3000',
        profileImageUrl: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?fm=jpg&q=60&w=3000',
        totalTables: 25,
        isVerified: true,
        isActive: true,
        approvalStatus: 'approved',
        rating: 4.6,
        totalReviews: 189,
        createdAt: DateTime.now().subtract(const Duration(days: 200)),
        updatedAt: DateTime.now(),
      ),
      Club(
        id: '3',
        ownerId: 'owner3',
        name: 'Elite Billiards Đà Nẵng',
        description: 'Câu lạc bộ cao cấp dành cho những người yêu thích billiards.',
        address: '789 Trần Phú, Hải Châu, Đà Nẵng',
        phone: '0923456789',
        email: 'contact@elitebilliardsdn.com',
        coverImageUrl: 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?fm=jpg&q=60&w=3000',
        profileImageUrl: 'https://images.unsplash.com/photo-1606107557195-0e29a4b5b4aa?fm=jpg&q=60&w=3000',
        totalTables: 20,
        isVerified: true,
        isActive: true,
        approvalStatus: 'approved',
        rating: 4.9,
        totalReviews: 156,
        createdAt: DateTime.now().subtract(const Duration(days: 150)),
        updatedAt: DateTime.now(),
      ),
    ];
  }
}

