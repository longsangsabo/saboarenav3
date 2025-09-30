import 'package:flutter/material.dart';

import '../../../models/club.dart';
import '../../../models/club_member.dart';
import '../../../models/club_tournament.dart';
import '../../../services/supabase_service.dart';
import '../../../routes/app_routes.dart';

class ClubDetailSection extends StatefulWidget {
  final Club club;

  const ClubDetailSection({
    super.key,
    required this.club,
  });

  @override
  State<ClubDetailSection> createState() => _ClubDetailSectionState();
}

class _ClubDetailSectionState extends State<ClubDetailSection>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isJoined = false;
  bool _isLoading = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCurrentUser();
  }
  
  Future<void> _loadCurrentUser() async {
    try {
      final user = SupabaseService.instance.getCurrentUser();
      setState(() {
        _currentUserId = user?.id;
      });
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Club basic info header
        _buildClubHeader(colorScheme),

        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: colorScheme.primary,
          indicatorWeight: 2,
          isScrollable: true,
          labelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          tabs: const [
            Tab(text: 'Thông tin'),
            Tab(text: 'Thành viên'),
            Tab(text: 'Giải đấu'),
            Tab(text: 'Hình ảnh'),
          ],
        ),

        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildInfoTab(colorScheme),
              _buildMembersTab(colorScheme),
              _buildTournamentsTab(colorScheme),
              _buildPhotosTab(colorScheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClubHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Club avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              image: widget.club.profileImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(widget.club.profileImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: widget.club.profileImageUrl == null
                  ? colorScheme.surfaceContainerHighest
                  : null,
            ),
            child: widget.club.profileImageUrl == null
                ? Icon(
                    Icons.business,
                    size: 24,
                    color: colorScheme.onSurfaceVariant,
                  )
                : null,
          ),

          const SizedBox(width: 16),

          // Club basic info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Club name
                Text(
                  widget.club.name,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 8),

                // Rating and members
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: Colors.amber,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.club.rating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Address
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.club.address ?? 'Không có địa chỉ',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurface.withOpacity(0.6),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action buttons
          Column(
            children: [
              _buildJoinLeaveButton(colorScheme),
              if (_isClubOwnerOrAdmin()) ...[
                const SizedBox(height: 8),
                _buildStaffManagementButton(colorScheme),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJoinLeaveButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleJoinLeave,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isJoined ? colorScheme.error : colorScheme.primary,
          foregroundColor: _isJoined ? colorScheme.onError : colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _isLoading
            ? SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _isJoined ? colorScheme.onError : colorScheme.onPrimary,
                  ),
                ),
              )
            : Text(
                _isJoined ? 'Rời khỏi' : 'Tham gia',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }

  Future<void> _handleJoinLeave() async {
    if (_isJoined) {
      // Show confirmation dialog for leaving
      final shouldLeave = await _showLeaveConfirmDialog();
      if (shouldLeave == true) {
        await _leaveClub();
      }
    } else {
      await _joinClub();
    }
  }

  Future<bool?> _showLeaveConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rời khỏi câu lạc bộ'),
        content: Text(
          'Bạn có chắc chắn muốn rời khỏi câu lạc bộ "${widget.club.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Rời khỏi'),
          ),
        ],
      ),
    );
  }

  Future<void> _joinClub() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isJoined = true;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tham gia câu lạc bộ "${widget.club.name}"'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tham gia câu lạc bộ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _leaveClub() async {
    setState(() => _isLoading = true);

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 1));
      
      setState(() {
        _isJoined = false;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã rời khỏi câu lạc bộ "${widget.club.name}"'),
          ),
        );
      }
    } catch (error) {
      setState(() => _isLoading = false);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi khi rời câu lạc bộ: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if current user is club owner or admin
  bool _isClubOwnerOrAdmin() {
    if (_currentUserId == null) return false;
    
    // Check if user is club owner
    if (widget.club.ownerId == _currentUserId) return true;
    
    // Check if user is admin member (this would need to query the database)
    // For now, just check ownership
    return false;
  }

  Widget _buildStaffManagementButton(ColorScheme colorScheme) {
    return SizedBox(
      height: 32,
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pushNamed(
            context, 
            AppRoutes.clubStaffManagementScreen,
            arguments: {'clubId': widget.club.id},
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.secondary,
          foregroundColor: colorScheme.onSecondary,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        icon: const Icon(Icons.people_alt, size: 16),
        label: const Text(
          'Quản lý nhân viên',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Description
          Text(
            'Mô tả',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.club.description ?? 'Không có mô tả',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.8),
              height: 1.6, // Better line height for readability
            ),
          ),

          const SizedBox(height: 24),

          // Facilities
          Text(
            'Tiện ích',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _getMockFacilities().map((facility) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  facility,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Opening hours
          Text(
            'Giờ mở cửa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '6:00 - 23:00 (Thứ 2 - Chủ nhật)',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),

          const SizedBox(height: 24),

          // Contact info
          Text(
            'Thông tin liên hệ',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Icon(
                Icons.phone,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '0123 456 789',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Row(
            children: [
              Icon(
                Icons.email,
                size: 20,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'contact@${widget.club.name.toLowerCase().replaceAll(' ', '')}.com',
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembersTab(ColorScheme colorScheme) {
    final members = _getMockMembers();

    return Column(
      children: [
        // Stats header
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tổng thành viên',
                  members.length.toString(),
                  Icons.people,
                  colorScheme,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Đang hoạt động',
                  members.where((m) => m.isActive).length.toString(),
                  Icons.person_outline,
                  colorScheme,
                ),
              ),
            ],
          ),
        ),

        // Members list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: members.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final member = members[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                leading: CircleAvatar(
                  radius: 24,
                  backgroundImage: member.userAvatar != null
                      ? NetworkImage(member.userAvatar!)
                      : null,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                  child: member.userAvatar == null
                      ? Icon(
                          Icons.person,
                          color: colorScheme.onSurfaceVariant,
                        )
                      : null,
                ),
                title: Text(
                  member.userName ?? 'Tên người dùng',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: member.roleColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.roleDisplayName,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                trailing: (member.isOnline ?? false)
                    ? Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentsTab(ColorScheme colorScheme) {
    final tournaments = <ClubTournament>[];

    return Column(
      children: [
        // Filter tabs
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tất cả', true, colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Sắp tới', false, colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Đang diễn ra', false, colorScheme),
              const SizedBox(width: 8),
              _buildFilterChip('Đã kết thúc', false, colorScheme),
            ],
          ),
        ),

        // Tournaments list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tournaments.length,
            itemBuilder: (context, index) {
              final tournament = tournaments[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tournament header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tournament.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: tournament.statusColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              tournament.statusDisplayName,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Tournament details
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tournament.startDate.day}/${tournament.startDate.month}/${tournament.startDate.year}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(
                            Icons.people,
                            size: 16,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${tournament.currentParticipants}/${tournament.maxParticipants}',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Prize info
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            tournament.prizeDescription != null 
                                ? 'Giải thưởng: ${tournament.prizeDescription}' 
                                : 'Không có giải thưởng',
                            style: TextStyle(
                              fontSize: 14,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),

                      if (tournament.isRegistrationOpen) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              // TODO: Handle tournament registration
                            },
                            child: const Text('Đăng ký tham gia'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab(ColorScheme colorScheme) {
    final photos = _getMockPhotos();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        return GestureDetector(
          onTap: () => _showPhotoDialog(photo),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: NetworkImage(photo),
                fit: BoxFit.cover,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPhotoDialog(String photoUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: const Text('Hình ảnh'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Image.network(
              photoUrl,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 32,
            color: colorScheme.primary,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, ColorScheme colorScheme) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        // TODO: Implement filter logic
      },
      selectedColor: colorScheme.primaryContainer,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
      ),
    );
  }

  // Mock data methods
  List<String> _getMockFacilities() {
    return [
      'WiFi miễn phí',
      'Bãi đỗ xe',
      'Quầy bar',
      'Phòng VIP',
      'Điều hòa',
      'Camera an ninh',
    ];
  }

  // Removed unused method _getCurrentUser

  List<ClubMember> _getMockMembers() {
    return [
      ClubMember(
        id: '1',
        clubId: widget.club.id,
        userId: 'user1',
        userName: 'Nguyễn Văn A',
        role: 'owner',
        joinedAt: DateTime.now().subtract(const Duration(days: 365)),
        isActive: true,
        userAvatar: 'https://picsum.photos/100/100?random=1',
        isOnline: true,
      ),
      ClubMember(
        id: '2',
        clubId: widget.club.id,
        userId: 'user2',
        userName: 'Trần Thị B',
        role: 'admin', 
        joinedAt: DateTime.now().subtract(const Duration(days: 180)),
        isActive: true,
        userAvatar: 'https://picsum.photos/100/100?random=2',
        isOnline: true,
      ),
      ClubMember(
        id: '3',
        clubId: widget.club.id,
        userId: 'user3',
        userName: 'Lê Văn C',
        role: 'member',
        joinedAt: DateTime.now().subtract(const Duration(days: 90)),
        isActive: false,
        isOnline: false,
      ),
    ];
  }

  List<ClubTournament> _getMockTournaments() {
    final now = DateTime.now();
    return [
      ClubTournament(
        id: '1',
        clubId: widget.club.id,
        name: 'Giải vô địch câu lạc bộ',
        description: 'Giải đấu thường niên của câu lạc bộ',
        startDate: now.add(const Duration(days: 15)),
        endDate: now.add(const Duration(days: 17)),
        maxParticipants: 32,
        currentParticipants: 18,
        entryFee: 100000,
        prizeDescription: '5.000.000 VNĐ',
        status: 'upcoming',
        tournamentType: 'knockout',
        createdAt: now.subtract(const Duration(days: 30)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      ClubTournament(
        id: '2',  
        clubId: widget.club.id,
        name: 'Giải giao hữu tháng 3',
        description: 'Giải đấu giao hữu hàng tháng',
        startDate: now.subtract(const Duration(days: 5)),
        endDate: now.add(const Duration(days: 2)),
        maxParticipants: 16,
        currentParticipants: 16,
        entryFee: 50000,
        prizeDescription: '1.000.000 VNĐ',
        status: 'ongoing',
        tournamentType: 'round_robin',
        createdAt: now.subtract(const Duration(days: 20)),
        updatedAt: now.subtract(const Duration(hours: 2)),
      ),
    ];
  }

  List<String> _getMockPhotos() {
    return List.generate(
      12,
      (index) => 'https://picsum.photos/400/300?random=${index + 10}',
    );
  }
}