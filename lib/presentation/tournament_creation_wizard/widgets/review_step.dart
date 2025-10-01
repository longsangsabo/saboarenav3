import 'package:flutter/material.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:sabo_arena/utils/size_extensions.dart';

class ReviewStep extends StatefulWidget {
  const ReviewStep({super.key});

} 
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;
  final VoidCallback onPublish;

  const ReviewStep({
    super.key,
    required this.data,
    required this.onDataChanged,
    required this.onPublish,
  });

  @override
  _ReviewStepState createState() => _ReviewStepState();
}

class _ReviewStepState extends State<ReviewStep>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isPublishing = false;
  String _publishOption = 'public'; // public, private, draft
  bool _notifyMembers = true;
  bool _allowEarlyRegistration = false;
  String _additionalNotes = '';

  final Map<String, String> _publishOptions = {
    "public": 'Công khai',
    "private": 'Riêng tư',
    "draft": 'Bản nháp',
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _initializeData();
    _animationController.forward();
  }

  void _initializeData() {
    _publishOption = widget.data['publishOption'] ?? 'public';
    _notifyMembers = widget.data['notifyMembers'] ?? true;
    _allowEarlyRegistration = widget.data['allowEarlyRegistration'] ?? false;
    _additionalNotes = widget.data['additionalNotes'] ?? '';
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTournamentSummary(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Thông tin cơ bản", Icons.info_outline),
                SizedBox(height: 16.v),
                _buildBasicInfoSummary(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Lịch trình", Icons.schedule_outlined),
                SizedBox(height: 16.v),
                _buildScheduleSummary(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Yêu cầu tham gia", Icons.rule_outlined),
                SizedBox(height: 16.v),
                _buildRequirementsSummary(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Giải thưởng", Icons.emoji_events_outlined),
                SizedBox(height: 16.v),
                _buildPrizesSummary(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Tùy chọn xuất bản", Icons.publish_outlined),
                SizedBox(height: 16.v),
                _buildPublishOptions(),
                
                SizedBox(height: 32.v),
                _buildPublishButton(),
                
                SizedBox(height: 100.v), // Space for navigation buttons
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8.h),
          decoration: BoxDecoration(
            color: appTheme.blue50,
            borderRadius: BorderRadius.circular(8.h),
          ),
          child: Icon(
            icon,
            color: appTheme.blue600,
            size: 20.adaptSize,
          ),
        ),
        SizedBox(width: 12.h),
        Text(
          title,
          style: TextStyle(
            fontSize: 18.fSize,
            fontWeight: FontWeight.bold,
            color: appTheme.gray900,
          ),
        ),
      ],
    );
  }

  Widget _buildTournamentSummary() {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appTheme.green600, appTheme.green800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.green600.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.white,
                size: 32.adaptSize,
              ),
              SizedBox(width: 16.h),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Giải đấu sẵn sàng!",
                      style: TextStyle(
                        fontSize: 16.fSize,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      widget.data['tournamentName'] ?? 'Tên giải đấu',
                      style: TextStyle(
                        fontSize: 24.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.v),
          
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    "Người chơi",
                    "${widget.data['maxParticipants'] ?? 16}",
                    Icons.people_outline,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    "Phí tham gia",
                    "${((widget.data['entryFee'] ?? 0) / 1000).toStringAsFixed(0)}K",
                    Icons.attach_money,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    "Giải thưởng",
                    "${((widget.data['totalPrizePool'] ?? 0) / 1000).toStringAsFixed(0)}K",
                    Icons.star_outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.8), size: 20.adaptSize),
        SizedBox(height: 4.v),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.fSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.fSize,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildBasicInfoSummary() {
    return _buildSummaryCard([
      _buildInfoRow("Tên giải đấu", widget.data['tournamentName'] ?? 'Chưa đặt tên'),
      _buildInfoRow("Loại bi", _getGameTypeLabel(widget.data['gameType'] ?? '8-ball')),
      _buildInfoRow("Thể thức", _getTournamentTypeLabel(widget.data['tournamentType'] ?? 'single-elimination')),
      _buildInfoRow("Số người", "${widget.data['maxParticipants'] ?? 16} người"),
      _buildInfoRow("Phí tham gia", "${((widget.data['entryFee'] ?? 0) / 1000).toStringAsFixed(0)}K VNĐ"),
    ]);
  }

  Widget _buildScheduleSummary() {
    final registrationStart = widget.data['registrationStartDate'] as DateTime?;
    final registrationEnd = widget.data['registrationEndDate'] as DateTime?;
    final tournamentStart = widget.data['tournamentStartDate'] as DateTime?;
    final tournamentEnd = widget.data['tournamentEndDate'] as DateTime?;

    return _buildSummaryCard([
      _buildInfoRow(
        "Đăng ký",
        "${_formatDate(registrationStart)} - ${_formatDate(registrationEnd)}",
      ),
      _buildInfoRow(
        "Thi đấu",
        "${_formatDate(tournamentStart)} - ${_formatDate(tournamentEnd)}",
      ),
      _buildInfoRow("Lịch trình", _getSchedulingLabel(widget.data['matchScheduling'] ?? 'flexible')),
      _buildInfoRow("Thời gian/trận", "${widget.data['matchDuration'] ?? 60} phút"),
      _buildInfoRow("Trận/ngày", "${widget.data['dailyMatches'] ?? 3} trận"),
    ]);
  }

  Widget _buildRequirementsSummary() {
    List<Widget> requirements = [];

    if (widget.data['hasRankRequirement'] == true) {
      final minRank = widget.data['minRank'] ?? 'beginner';
      final maxRank = widget.data['maxRank'] ?? 'pro';
      requirements.add(_buildInfoRow("Xếp hạng", "$minRank - $maxRank"));
    }

    if (widget.data['hasAgeRequirement'] == true) {
      final minAge = widget.data['minAge'] ?? 16;
      final maxAge = widget.data['maxAge'] ?? 99;
      requirements.add(_buildInfoRow("Độ tuổi", "$minAge - $maxAge tuổi"));
    }

    if (widget.data['clubMembersOnly'] == true) {
      requirements.add(_buildInfoRow("Thành viên", "Chỉ thành viên club"));
    }

    if (widget.data['requireVerification'] == true) {
      requirements.add(_buildInfoRow("Xác minh", "Bắt buộc xác minh tài khoản"));
    }

    if (widget.data['requireDeposit'] == true) {
      final deposit = widget.data['depositAmount'] ?? 100000;
      requirements.add(_buildInfoRow("Đặt cọc", "${(deposit / 1000).toStringAsFixed(0)}K VNĐ"));
    }

    if (requirements.isEmpty) {
      requirements.add(_buildInfoRow("Yêu cầu", "Không có yêu cầu đặc biệt"));
    }

    return _buildSummaryCard(requirements);
  }

  Widget _buildPrizesSummary() {
    final totalPrize = widget.data['totalPrizePool'] ?? 0.0;
    final prizeSource = widget.data['prizeSource'] ?? 'entry_fees';
    final distribution = widget.data['distributionTemplate'] ?? 'winner_takes_all';

    List<Widget> prizeInfo = [
      _buildInfoRow("Tổng giải thưởng", "${(totalPrize / 1000).toStringAsFixed(0)}K VNĐ"),
      _buildInfoRow("Nguồn", _getPrizeSourceLabel(prizeSource)),
      _buildInfoRow("Phân chia", _getDistributionLabel(distribution)),
    ];

    if (widget.data['organizerFee'] != null && widget.data['organizerFee'] > 0) {
      prizeInfo.add(_buildInfoRow("Phí tổ chức", "${widget.data['organizerFee'].toInt()}%"));
    }

    final additionalPrizes = widget.data['additionalPrizes'] as List<dynamic>? ?? [];
    if (additionalPrizes.isNotEmpty) {
      prizeInfo.add(_buildInfoRow("Giải phụ", "${additionalPrizes.length} giải thưởng"));
    }

    final sponsors = widget.data['sponsors'] as List<dynamic>? ?? [];
    if (sponsors.isNotEmpty) {
      prizeInfo.add(_buildInfoRow("Nhà tài trợ", "${sponsors.length} tài trợ"));
    }

    return _buildSummaryCard(prizeInfo);
  }

  Widget _buildSummaryCard(List<Widget> children) {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.v),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100.h,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13.fSize,
                color: appTheme.gray600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13.fSize,
                fontWeight: FontWeight.w600,
                color: appTheme.gray900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPublishOptions() {
    return Container(
      padding: EdgeInsets.all(16.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Chế độ xuất bản:",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 16.v),
          
          ...(_publishOptions.entries.map((entry) {
            return _buildPublishOption(entry.key, entry.value);
          })),
          
          SizedBox(height: 20.v),
          
          _buildToggleOption(
            title: "Thông báo cho thành viên",
            subtitle: "Gửi thông báo đến tất cả thành viên club",
            value: _notifyMembers,
            onChanged: (value) {
              setState(() {
                _notifyMembers = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 16.v),
          
          _buildToggleOption(
            title: "Cho phép đăng ký sớm",
            subtitle: "Thành viên có thể đăng ký trước ngày mở đăng ký",
            value: _allowEarlyRegistration,
            onChanged: (value) {
              setState(() {
                _allowEarlyRegistration = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 20.v),
          
          TextField(
            decoration: InputDecoration(
              labelText: "Ghi chú thêm",
              hintText: "Thông tin bổ sung cho người tham gia...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.h),
              ),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            controller: TextEditingController(text: _additionalNotes),
            onChanged: (value) {
              _additionalNotes = value;
              _updateData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPublishOption(String value, String label) {
    final isSelected = _publishOption == value;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.v),
      child: InkWell(
        onTap: () {
          setState(() {
            _publishOption = value;
          });
          _updateData();
        },
        borderRadius: BorderRadius.circular(8.h),
        child: Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: isSelected ? appTheme.green50 : appTheme.gray50,
            borderRadius: BorderRadius.circular(8.h),
            border: Border.all(
              color: isSelected ? appTheme.green600 : appTheme.gray200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.h),
                decoration: BoxDecoration(
                  color: isSelected ? appTheme.green600 : appTheme.gray300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 12.adaptSize,
                ),
              ),
              
              SizedBox(width: 12.h),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? appTheme.green800 : appTheme.gray700,
                      ),
                    ),
                    Text(
                      _getPublishOptionDescription(value),
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: isSelected ? appTheme.green600 : appTheme.gray500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToggleOption({
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray900,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.fSize,
                  color: appTheme.gray600,
                ),
              ),
            ],
          ),
        ),
        
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: appTheme.blue600,
        ),
      ],
    );
  }

  Widget _buildPublishButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isPublishing ? null : _handlePublish,
        style: ElevatedButton.styleFrom(
          backgroundColor: appTheme.green600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.v),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.h),
          ),
          elevation: 8,
        ),
        child: _isPublishing
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20.adaptSize,
                    height: 20.adaptSize,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 12.h),
                  Text(
                    "Đang xuất bản...",
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.publish, size: 24.adaptSize),
                  SizedBox(width: 12.h),
                  Text(
                    _getPublishButtonText(),
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return "Chưa đặt";
    return "${date.day}/${date.month}/${date.year}";
  }

  String _getGameTypeLabel(String gameType) {
    switch (gameType) {
      case '8-ball': return '8-Ball Pool';
      case '9-ball': return '9-Ball Pool';
      case '10-ball': return '10-Ball Pool';
      default: return gameType;
    }
  }

  String _getTournamentTypeLabel(String tournamentType) {
    switch (tournamentType) {
      case 'single-elimination': return 'Loại trực tiếp';
      case 'double-elimination': return 'Loại kép';
      case 'round-robin': return 'Vòng tròn';
      default: return tournamentType;
    }
  }

  String _getSchedulingLabel(String scheduling) {
    switch (scheduling) {
      case 'flexible': return 'Linh hoạt';
      case 'fixed': return 'Cố định';
      default: return scheduling;
    }
  }

  String _getPrizeSourceLabel(String source) {
    switch (source) {
      case 'entry_fees': return 'Từ phí tham gia';
      case 'sponsor': return 'Từ nhà tài trợ';
      case 'hybrid': return 'Kết hợp cả hai';
      default: return source;
    }
  }

  String _getDistributionLabel(String distribution) {
    switch (distribution) {
      case 'winner_takes_all': return 'Người thắng nhận tất cả';
      case 'top_3': return 'Top 3 (50%-30%-20%)';
      case 'top_5': return 'Top 5';
      case 'equal_split': return 'Chia đều Top 8';
      case 'custom': return 'Tùy chỉnh';
      default: return distribution;
    }
  }

  String _getPublishOptionDescription(String option) {
    switch (option) {
      case 'public': return 'Mọi người đều có thể xem và tham gia';
      case 'private': return 'Chỉ những người được mời mới tham gia được';
      case 'draft': return 'Lưu bản nháp, chưa công bố';
      default: return '';
    }
  }

  String _getPublishButtonText() {
    switch (_publishOption) {
      case 'public': return 'Xuất bản giải đấu';
      case 'private': return 'Tạo giải đấu riêng tư';
      case 'draft': return 'Lưu bản nháp';
      default: return 'Xuất bản';
    }
  }

  Future<void> _handlePublish() async {
    setState(() {
      _isPublishing = true;
    });

    try {
      // Simulate publishing process
      await Future.delayed(Duration(seconds: 2));
      
      // Call the publish callback
      widget.onPublish();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8.h),
                Text(_getSuccessMessage()),
              ],
            ),
            backgroundColor: appTheme.green600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.h),
            ),
          ),
        );
      }
    } catch (error) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 8.h),
                Text("Có lỗi xảy ra khi xuất bản giải đấu"),
              ],
            ),
            backgroundColor: appTheme.red600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.h),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPublishing = false;
        });
      }
    }
  }

  String _getSuccessMessage() {
    switch (_publishOption) {
      case 'public': return 'Giải đấu đã được xuất bản thành công!';
      case 'private': return 'Giải đấu riêng tư đã được tạo!';
      case 'draft': return 'Bản nháp đã được lưu!';
      default: return 'Thành công!';
    }
  }

  void _updateData() {
    widget.onDataChanged({
      'publishOption': _publishOption,
      'notifyMembers': _notifyMembers,
      'allowEarlyRegistration': _allowEarlyRegistration,
      'additionalNotes': _additionalNotes,
    });
  }
}
