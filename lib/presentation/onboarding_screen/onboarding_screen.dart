import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';

class OnboardingScreen extends StatefulWidget() {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late List<OnboardingData> _onboardingData;
  String _selectedRole = ""; // "player" or "club_owner"

  @override
  void initState() {
    super.initState();
    _initializeOnboardingData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeOnboardingData() {
    _onboardingData = [
      OnboardingData(
        title: "BẠN LÀ AI ???",
        description: "",
        imagePath: "assets/images/billiard_ball.svg",
        showRoleSelection: true,
      ),
    ];
  }

  void _setRoleSpecificData(String role) {
    setState(() {
      _selectedRole = role;

      if (role == "player") {
        _onboardingData = [
          _onboardingData[0], // Keep role selection screen
          OnboardingData(
            title: "TÌM BẠN CHƠI BIDA !!",
            description:
                "Bạn muốn chơi bida, nhưng đối của bạn bận cả rồi !!! Hmm..\nĐể SABO tìm đối cần kèo cho bạn nha!!!",
            imagePath: "assets/images/find_opponent.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "ĐÁNH GIẢI ĐỂ NÂNG TRÌNH !!",
            description:
                "Tham gia các giải đấu phong trào hàng tuần bạn sẽ có cơ hội cọ sát với các cơ thủ cùng trình độ !!\nVà nhận về vô vàn phần quà hấp dẫn !!",
            imagePath: "assets/images/tournament.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "CHẾ ĐỘ THÁCH ĐẤU !!",
            description:
                "Chế độ thách đấu giúp bạn giao lưu với các cơ thủ kinh nghiệm, qua đó bạn sẽ có cơ hội học hỏi và cải thiện kỹ năng của mình !!",
            imagePath: "assets/images/challenge.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "LƯU TRỮ THÀNH TÍCH VÀ\nLỊCH SỬ THI ĐẤU !!",
            description:
                "SABO giúp lưu trữ lịch sử thi đấu và thành tích chơi bida của bạn, giúp bạn thống kê và theo dõi quá trình tiến bộ của mình !!\n\nVÀ RẤT NHIỀU TÍNH NĂNG HẤP DẪN KHÁC ĐANG ĐỢI BẠN KHÁM PHÁ !!",
            imagePath: "assets/images/achievements.svg",
            showRoleSelection: false,
          ),
        ];
      } else if (role == "club_owner") {
        _onboardingData = [
          _onboardingData[0], // Keep role selection screen
          OnboardingData(
            title: "CHUYỂN ĐỔI SỐ CHO\nCLB CỦA BẠN !!",
            description:
                "SABO liên tục phát triển tính năng giúp bạn chỉ cần sử dụng nền tảng là đã giản tiếp chuyển đổi số cho CLB của mình !!\n\nĐừng để CLB của bạn bị bỏ lại phía sau trong thị trường cạnh tranh như hiện tại !!",
            imagePath: "assets/images/digital_transformation.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "KẾT NỐI CỘNG ĐỒNG\nCÓ CÙNG SỞ THÍCH BIDA !!",
            description:
                "SABO có nhiều tính năng giúp CLB kết nối trực tiếp đến người chơi bida mà không cần bạn phải chi quá nhiều chi phí cho quảng cáo!\n\nNgười chơi khi đã được xác minh hạng sẽ được tham gia mọi giải đấu tại các CLB có sử dụng nền tảng. Giúp CLB của bạn thu hút khách hàng mới ở khắp mọi nơi.",
            imagePath: "assets/images/community.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "TỔ CHỨC GIẢI ĐẤU\nDỄ DÀNG !!",
            description:
                "SABO giúp bạn tổ chức, quản lý, quảng bá các giải đấu cấp CLB một cách dễ dàng, thuận lợi và tối ưu mọi chi phí !!",
            imagePath: "assets/images/tournament_management.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "THU HÚT & GIỮ CHÂN\nTHÀNH VIÊN !!",
            description:
                "Thành viên CLB có cơ hội thi đấu thường xuyên, có lộ trình nâng hạng rõ ràng\nCác cơ thủ sẽ cảm thấy gắn bó hơn vì được cập nhật bảng xếp hạng chung, không chỉ chơi tại CLB !!",
            imagePath: "assets/images/member_retention.svg",
            showRoleSelection: false,
          ),
          OnboardingData(
            title: "TỐI ƯU CHI PHÍ MARKETING\n& QUẢNG CÁO !",
            description:
                "Sử dụng nền tảng SABO sẽ giúp bạn không phải tốn quá nhiều công sức, chi phí cho việc thiết kế poster, bài post, marketing và quảng cáo mà vẫn giúp CLB tiếp cận được cộng đồng người chơi bida !!\n\nVÀ RẤT NHIỀU TÍNH NĂNG HẤP DẪN KHÁC ĐANG ĐỢI BẠN KHÁM PHÁ !!",
            imagePath: "assets/images/marketing.svg",
            showRoleSelection: false,
          ),
        ];
      }
    });
  }

  void _nextPage() {
    if (_currentPage < _onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else() {
      _finishOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async() {
    try() {
      // Mark onboarding as completed and save user role
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_onboarding', true);
      await prefs.setString('user_role', _selectedRole);
      debugPrint('✅ Onboarding: Marked as completed with role: $_selectedRole');

      // Navigate to login
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
        debugPrint('✅ Onboarding: Navigation to login completed');
      }
    } catch (e) {
      debugPrint('❌ Onboarding: Error saving completion status: $e');
      // Still navigate to login even if saving fails
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.loginScreen);
      }
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FFFE),
              Color(0xFFE4F5F0),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -18.w,
              right: -12.w,
              child: _DecorativeCircle(
                diameter: 48.w,
                color: AppTheme.primaryLight.withOpacity(0.08),
              ),
            ),
            Positioned(
              bottom: -24.w,
              left: -20.w,
              child: _DecorativeCircle(
                diameter: 62.w,
                color: AppTheme.secondaryLight.withOpacity(0.06),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (_currentPage > 0)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryLight
                                      .withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _previousPage,
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: AppTheme.primaryLight,
                                size: 18.sp,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 12.w),
                        ElevatedButton(
                          onPressed: _skipOnboarding,
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor:
                                Colors.white.withOpacity(0.9),
                            foregroundColor: AppTheme.primaryLight,
                            padding: EdgeInsets.symmetric(
                                horizontal: 6.w, vertical: 1.6.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: GoogleFonts.montserrat(
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4,
                            ),
                          ),
                          child: Text(
                            _currentPage == _onboardingData.length - 1
                                ? "Bắt đầu"
                                : "Bỏ qua",
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentPage = index;
                        });
                      },
                      itemCount: _onboardingData.length,
                      itemBuilder: (context, index) {
                        final data = _onboardingData[index];

                        if (data.showRoleSelection) {
                          return _buildRoleSelectionPage(data);
                        } else() {
                          return _buildContentPage(data);
                        }
                      },
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 4.h, top: 2.5.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_currentPage > 0)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryLight
                                      .withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _previousPage,
                              icon: Icon(
                                Icons.arrow_back_ios_new,
                                color: AppTheme.primaryLight,
                                size: 17.sp,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 10.w),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          child: Row(
                            children: List.generate(
                              _onboardingData.length,
                              (index) => AnimatedContainer(
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOut,
                                width: _currentPage == index ? 6.w : 2.2.w,
                                height: 0.9.h,
                                margin: EdgeInsets.symmetric(horizontal: 1.w),
                                decoration: BoxDecoration(
                                  color: _currentPage == index
                                      ? AppTheme.primaryLight
                                      : AppTheme.primaryLight
                                          .withOpacity(0.25),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (_currentPage < _onboardingData.length - 1)
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryLight
                                      .withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: IconButton(
                              onPressed: _nextPage,
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: AppTheme.primaryLight,
                                size: 17.sp,
                              ),
                            ),
                          )
                        else
                          SizedBox(width: 10.w),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSelectionPage(OnboardingData data) {
    final bool isPlayerSelected = _selectedRole == "player";
    final bool isClubOwnerSelected = _selectedRole == "club_owner";

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 5.h),

            // SABO ARENA Logo
            TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 1000),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (0.1 * value),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      width: 44.w,
                      height: 44.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1F2C3E),
                            Color(0xFF0B141F),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 14),
                          ),
                        ],
                        border: Border.all(
                          color: Colors.white.withOpacity(0.12),
                          width: 1.4.w,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(2.4.w),
                        child: ClipOval(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    AppTheme.accentLight.withOpacity(0.6),
                                width: 0.6.w,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/sabo-arena.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: 4.h),

            // Title
            Text(
              data.title,
              style: GoogleFonts.montserrat(
                fontSize: 23.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryLight,
                letterSpacing: 1.1,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 1.8.h),

            Text(
              "Chọn vai trò để cá nhân hóa trải nghiệm của bạn trên SABO.",
              style: GoogleFonts.openSans(
                fontSize: 11.5.sp,
                color: AppTheme.textSecondaryLight.withOpacity(0.9),
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 6.h),

            // Role selection
            Row(
              children: [
                Expanded(
                  child: _RoleOptionCard(
                    icon: Icons.sports_martial_arts,
                    title: 'Người chơi',
                    isSelected: isPlayerSelected,
                    onTap: () {
                      _setRoleSpecificData("player");
                      _nextPage();
                    },
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: _RoleOptionCard(
                    icon: Icons.apartment,
                    title: 'Chủ CLB',
                    isSelected: isClubOwnerSelected,
                    onTap: () {
                      _setRoleSpecificData("club_owner");
                      _nextPage();
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildContentPage(OnboardingData data) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      child: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.5.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.92),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryLight.withOpacity(0.12),
                    blurRadius: 32,
                    offset: const Offset(0, 24),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 52.w,
                    height: 28.h,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _buildIllustration(_currentPage),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    data.title,
                    style: GoogleFonts.montserrat(
                      fontSize: 19.sp,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryLight,
                      letterSpacing: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    data.description,
                    style: GoogleFonts.openSans(
                      fontSize: 12.5.sp,
                      color: AppTheme.textSecondaryLight.withOpacity(0.9),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(int pageIndex) {
    if (_selectedRole == "player") {
      return _buildPlayerIllustration(pageIndex);
    } else if (_selectedRole == "club_owner") {
      return _buildClubOwnerIllustration(pageIndex);
    }
    return Container();
  }

  Widget _buildPlayerIllustration(int pageIndex) {
    switch (pageIndex) {
      case 1: // Find opponents
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green[100]!,
                Colors.green[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Mountains and path illustration
              Positioned(
                bottom: 10.h,
                left: 10.w,
                right: 10.w,
                child: Container(
                  height: 20.h,
                  decoration: BoxDecoration(
                    color: Colors.green[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Stack(
                    children: [
                      // Path
                      Positioned(
                        bottom: 0,
                        left: 20,
                        right: 20,
                        child: Container(
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                      ),
                      // Person icon
                      Positioned(
                        bottom: 8.h,
                        left: 30,
                        child: Icon(
                          Icons.person_search,
                          size: 8.w,
                          color: const Color(0xFF4A7C59),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      case 2: // Tournaments
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange[100]!,
                Colors.orange[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.emoji_events,
              size: 30.w,
              color: Colors.orange[600],
            ),
          ),
        );
      case 3: // Challenge mode
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red[100]!,
                Colors.red[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.sports_mma,
              size: 30.w,
              color: Colors.red[600],
            ),
          ),
        );
      case 4: // Statistics
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.blue[100]!,
                Colors.blue[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.analytics,
              size: 30.w,
              color: Colors.blue[600],
            ),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildClubOwnerIllustration(int pageIndex) {
    switch (pageIndex) {
      case 1: // Digital transformation
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.purple[100]!,
                Colors.purple[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.transform,
              size: 30.w,
              color: Colors.purple[600],
            ),
          ),
        );
      case 2: // Community connection
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.teal[100]!,
                Colors.teal[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.groups,
              size: 30.w,
              color: Colors.teal[600],
            ),
          ),
        );
      case 3: // Tournament management
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange[100]!,
                Colors.orange[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.event_available,
              size: 30.w,
              color: Colors.orange[600],
            ),
          ),
        );
      case 4: // Member retention
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo[100]!,
                Colors.indigo[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.favorite,
              size: 30.w,
              color: Colors.indigo[600],
            ),
          ),
        );
      case 5: // Marketing optimization
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.amber[100]!,
                Colors.amber[50]!,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Center(
            child: Icon(
              Icons.campaign,
              size: 30.w,
              color: Colors.amber[700],
            ),
          ),
        );
      default:
        return Container();
    }
  }
}

class _DecorativeCircle extends StatelessWidget() {
  final double diameter;
  final Color color;

  const _DecorativeCircle({
    required this.diameter,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _RoleOptionCard extends StatelessWidget() {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleOptionCard({
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    colors: [
                      AppTheme.primaryLight,
                      AppTheme.secondaryLight,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isSelected ? null : Colors.white.withOpacity(0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isSelected
                  ? Colors.transparent
                  : AppTheme.primaryLight.withOpacity(0.15),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppTheme.primaryLight.withOpacity(0.22)
                    : Colors.black.withOpacity(0.04),
                blurRadius: isSelected ? 30 : 16,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(3.5.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white
                      : AppTheme.primaryLight.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 16.w,
                  color: isSelected
                      ? AppTheme.primaryLight
                      : AppTheme.primaryLight,
                ),
              ),
              SizedBox(height: 2.5.h),
              Text(
                title,
                style: GoogleFonts.montserrat(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : AppTheme.primaryLight,
                  letterSpacing: 0.6,
                ),
              ),
              SizedBox(height: 0.8.h),
              Text(
                isSelected ? "Đã chọn" : 'Khám phá trải nghiệm phù hợp',
                style: GoogleFonts.openSans(
                  fontSize: 9.5.sp,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Colors.white.withOpacity(0.85)
                      : AppTheme.textSecondaryLight.withOpacity(0.9),
                  height: 1.3,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingData() {
  final String title;
  final String description;
  final String imagePath;
  final bool showRoleSelection;

  OnboardingData({
    required this.title,
    required this.description,
    required this.imagePath,
    required this.showRoleSelection,
  });
}
