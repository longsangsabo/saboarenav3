import 'package:flutter/material.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:sabo_arena/utils/size_extensions.dart';

class PrizesStep extends StatefulWidget {
  const PrizesStep({super.key});

} 
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const PrizesStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  _PrizesStepState createState() => _PrizesStepState();
}

class _PrizesStepState extends State<PrizesStep>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Prize pool settings
  String _prizeSource = 'entry_fees'; // entry_fees, sponsor, hybrid
  double _totalPrizePool = 0;
  double _sponsorContribution = 0;
  double _organizerFee = 10; // percentage
  
  // Prize distribution
  String _distributionTemplate = 'winner_takes_all';
  List<PrizeDistribution> _customDistribution = [];
  
  // Additional prizes
  List<AdditionalPrize> _additionalPrizes = [];
  
  // Sponsorship
  List<Sponsor> _sponsors = [];
  bool _allowSponsors = true;
  String _sponsorshipBenefits = '';

  final Map<String, String> _prizeSourceLabels = {
    "entry_fees": 'Từ phí tham gia',
    "sponsor": 'Từ nhà tài trợ',
    "hybrid": 'Kết hợp cả hai',
  };

  final Map<String, String> _distributionTemplateLabels = {
    "winner_takes_all": 'Người thắng nhận tất cả',
    "top_3": 'Top 3 (50%-30%-20%)',
    "top_5": 'Top 5 (40%-25%-20%-10%-5%)',
    "equal_split": 'Chia đều cho Top 8',
    "custom": 'Tùy chỉnh',
  };

  final Map<String, List<double>> _distributionTemplates = {
    'winner_takes_all': [100],
    'top_3': [50, 30, 20],
    'top_5': [40, 25, 20, 10, 5],
    'equal_split': [12.5, 12.5, 12.5, 12.5, 12.5, 12.5, 12.5, 12.5],
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
    _calculatePrizePool();
    _animationController.forward();
  }

  void _initializeData() {
    _prizeSource = widget.data['prizeSource'] ?? 'entry_fees';
    _sponsorContribution = widget.data['sponsorContribution'] ?? 0.0;
    _organizerFee = widget.data['organizerFee'] ?? 10.0;
    _distributionTemplate = widget.data['distributionTemplate'] ?? 'winner_takes_all';
    _allowSponsors = widget.data['allowSponsors'] ?? true;
    _sponsorshipBenefits = widget.data['sponsorshipBenefits'] ?? '';
    
    _customDistribution = (widget.data['customDistribution'] as List<dynamic>?)?.map((dist) => 
        PrizeDistribution.fromMap(dist as Map<String, dynamic>)).toList() ?? [];
    
    _additionalPrizes = (widget.data['additionalPrizes'] as List<dynamic>?)?.map((prize) => 
        AdditionalPrize.fromMap(prize as Map<String, dynamic>)).toList() ?? [];
        
    _sponsors = (widget.data['sponsors'] as List<dynamic>?)?.map((sponsor) => 
        Sponsor.fromMap(sponsor as Map<String, dynamic>)).toList() ?? [];
  }

  void _calculatePrizePool() {
    // Get entry fee and participant count from previous steps
    final entryFee = widget.data['entryFee'] ?? 0.0;
    final maxParticipants = widget.data['maxParticipants'] ?? 16;
    
    double fromEntryFees = 0;
    if (_prizeSource == 'entry_fees' || _prizeSource == 'hybrid') {
      final totalFromFees = entryFee * maxParticipants;
      fromEntryFees = totalFromFees * (100 - _organizerFee) / 100;
    }
    
    double fromSponsors = 0;
    if (_prizeSource == 'sponsor' || _prizeSource == 'hybrid') {
      fromSponsors = _sponsorContribution + _sponsors.fold(0.0, (sum, sponsor) => sum + sponsor.amount);
    }
    
    setState(() {
      _totalPrizePool = fromEntryFees + fromSponsors;
    });
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
                _buildPrizePoolOverview(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Nguồn giải thưởng", Icons.account_balance_wallet_outlined),
                SizedBox(height: 16.v),
                _buildPrizeSourceConfig(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Phân chia giải thưởng", Icons.workspace_premium_outlined),
                SizedBox(height: 16.v),
                _buildPrizeDistribution(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Giải thưởng bổ sung", Icons.card_giftcard_outlined),
                SizedBox(height: 16.v),
                _buildAdditionalPrizes(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Tài trợ", Icons.handshake_outlined),
                SizedBox(height: 16.v),
                _buildSponsorshipConfig(),
                
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

  Widget _buildPrizePoolOverview() {
    return Container(
      padding: EdgeInsets.all(20.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [appTheme.blue600, appTheme.blue800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.h),
        boxShadow: [
          BoxShadow(
            color: appTheme.blue600.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
                      "Tổng giải thưởng",
                      style: TextStyle(
                        fontSize: 16.fSize,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      "${(_totalPrizePool / 1000).toStringAsFixed(0)}K VNĐ",
                      style: TextStyle(
                        fontSize: 28.fSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          if (_totalPrizePool > 0) ...[
            SizedBox(height: 16.v),
            Container(
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8.h),
              ),
              child: _buildPrizeBreakdown(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrizeBreakdown() {
    final entryFee = widget.data['entryFee'] ?? 0.0;
    final maxParticipants = widget.data['maxParticipants'] ?? 16;
    final totalFromFees = entryFee * maxParticipants;
    final fromEntryFees = totalFromFees * (100 - _organizerFee) / 100;
    final organizerTake = totalFromFees - fromEntryFees;
    final fromSponsors = _sponsorContribution + _sponsors.fold(0.0, (sum, sponsor) => sum + sponsor.amount);
    
    return Column(
      children: [
        if (_prizeSource == 'entry_fees' || _prizeSource == 'hybrid') ...[
          _buildBreakdownRow("Từ phí tham gia", fromEntryFees, Colors.white),
          if (organizerTake > 0)
            _buildBreakdownRow("Phí tổ chức", organizerTake, Colors.white.withOpacity(0.7)),
        ],
        if (_prizeSource == 'sponsor' || _prizeSource == 'hybrid') ...[
          if (_sponsorContribution > 0)
            _buildBreakdownRow("Đóng góp tổ chức", _sponsorContribution, Colors.white),
          ..._sponsors.map((sponsor) => 
            _buildBreakdownRow("Tài trợ: ${sponsor.name}", sponsor.amount, Colors.white)),
        ],
      ],
    );
  }

  Widget _buildBreakdownRow(String label, double amount, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.v),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.fSize,
              color: color,
            ),
          ),
          Text(
            "${(amount / 1000).toStringAsFixed(0)}K",
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeSourceConfig() {
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
            "Chọn nguồn tài chính:",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 16.v),
          
          ...(_prizeSourceLabels.entries.map((entry) {
            return _buildSourceOption(entry.key, entry.value);
          })),
          
          if (_prizeSource == 'entry_fees' || _prizeSource == 'hybrid') ...[
            SizedBox(height: 20.v),
            _buildOrganizerFeeSlider(),
          ],
          
          if (_prizeSource == 'sponsor' || _prizeSource == 'hybrid') ...[
            SizedBox(height: 20.v),
            _buildSponsorContributionInput(),
          ],
        ],
      ),
    );
  }

  Widget _buildSourceOption(String value, String label) {
    final isSelected = _prizeSource == value;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.v),
      child: InkWell(
        onTap: () {
          setState(() {
            _prizeSource = value;
          });
          _calculatePrizePool();
          _updateData();
        },
        borderRadius: BorderRadius.circular(8.h),
        child: Container(
          padding: EdgeInsets.all(12.h),
          decoration: BoxDecoration(
            color: isSelected ? appTheme.blue50 : appTheme.gray50,
            borderRadius: BorderRadius.circular(8.h),
            border: Border.all(
              color: isSelected ? appTheme.blue600 : appTheme.gray200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.h),
                decoration: BoxDecoration(
                  color: isSelected ? appTheme.blue600 : appTheme.gray300,
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
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? appTheme.blue800 : appTheme.gray700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrganizerFeeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Phí tổ chức: ${_organizerFee.toInt()}%",
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            color: appTheme.gray700,
          ),
        ),
        SizedBox(height: 8.v),
        
        Slider(
          value: _organizerFee,
          min: 0,
          max: 30,
          divisions: 30,
          activeColor: appTheme.blue600,
          onChanged: (value) {
            setState(() {
              _organizerFee = value;
            });
            _calculatePrizePool();
            _updateData();
          },
        ),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("0%", style: TextStyle(fontSize: 11.fSize, color: appTheme.gray500)),
            Text("30%", style: TextStyle(fontSize: 11.fSize, color: appTheme.gray500)),
          ],
        ),
        
        SizedBox(height: 8.v),
        
        Container(
          padding: EdgeInsets.all(8.h),
          decoration: BoxDecoration(
            color: appTheme.orange50,
            borderRadius: BorderRadius.circular(6.h),
          ),
          child: Text(
            "Phí này dùng để chi trả chi phí tổ chức, quản lý và vận hành giải đấu",
            style: TextStyle(
              fontSize: 11.fSize,
              color: appTheme.orange600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSponsorContributionInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Đóng góp từ ban tổ chức:",
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            color: appTheme.gray700,
          ),
        ),
        SizedBox(height: 8.v),
        
        TextField(
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Số tiền (VNĐ)",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.h),
            ),
            prefixIcon: Icon(Icons.attach_money_outlined),
          ),
          controller: TextEditingController(text: _sponsorContribution.toInt().toString()),
          onChanged: (value) {
            _sponsorContribution = double.tryParse(value) ?? 0;
            _calculatePrizePool();
            _updateData();
          },
        ),
      ],
    );
  }

  Widget _buildPrizeDistribution() {
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
            "Chọn cách chia giải:",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 16.v),
          
          ...(_distributionTemplateLabels.entries.map((entry) {
            return _buildDistributionOption(entry.key, entry.value);
          })),
          
          if (_distributionTemplate != 'custom') ...[
            SizedBox(height: 16.v),
            _buildDistributionPreview(),
          ],
          
          if (_distributionTemplate == 'custom') ...[
            SizedBox(height: 16.v),
            _buildCustomDistribution(),
          ],
        ],
      ),
    );
  }

  Widget _buildDistributionOption(String value, String label) {
    final isSelected = _distributionTemplate == value;
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.v),
      child: InkWell(
        onTap: () {
          setState(() {
            _distributionTemplate = value;
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
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14.fSize,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? appTheme.green800 : appTheme.gray700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDistributionPreview() {
    final percentages = _distributionTemplates[_distributionTemplate] ?? [];
    
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.green50,
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Phân chia chi tiết:",
            style: TextStyle(
              fontSize: 12.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.green700,
            ),
          ),
          SizedBox(height: 8.v),
          
          ...percentages.asMap().entries.map((entry) {
            final position = entry.key + 1;
            final percentage = entry.value;
            final amount = _totalPrizePool * percentage / 100;
            
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 2.v),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Hạng $position:",
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: appTheme.green700,
                    ),
                  ),
                  Text(
                    "${percentage.toStringAsFixed(1)}% (${(amount / 1000).toStringAsFixed(0)}K)",
                    style: TextStyle(
                      fontSize: 12.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.green700,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCustomDistribution() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Phân chia tùy chỉnh:",
              style: TextStyle(
                fontSize: 12.fSize,
                fontWeight: FontWeight.w600,
                color: appTheme.gray700,
              ),
            ),
            TextButton.icon(
              onPressed: _addCustomDistribution,
              icon: Icon(Icons.add, size: 16.adaptSize),
              label: Text("Thêm hạng"),
              style: TextButton.styleFrom(
                foregroundColor: appTheme.blue600,
              ),
            ),
          ],
        ),
        
        ...(_customDistribution.asMap().entries.map((entry) {
          final index = entry.key;
          final dist = entry.value;
          
          return Container(
            margin: EdgeInsets.only(bottom: 8.v),
            padding: EdgeInsets.all(8.h),
            decoration: BoxDecoration(
              color: appTheme.gray50,
              borderRadius: BorderRadius.circular(6.h),
              border: Border.all(color: appTheme.gray200),
            ),
            child: Row(
              children: [
                Text("Hạng ${index + 1}:", style: TextStyle(fontSize: 12.fSize)),
                SizedBox(width: 8.h),
                
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: "%",
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 4.v),
                    ),
                    controller: TextEditingController(text: dist.percentage.toString()),
                    onChanged: (value) {
                      final percentage = double.tryParse(value) ?? 0;
                      setState(() {
                        _customDistribution[index] = dist.copyWith(percentage: percentage);
                      });
                      _updateData();
                    },
                  ),
                ),
                
                SizedBox(width: 8.h),
                
                IconButton(
                  onPressed: () => _removeCustomDistribution(index),
                  icon: Icon(Icons.delete_outline),
                  iconSize: 16.adaptSize,
                  color: appTheme.red600,
                ),
              ],
            ),
          );
        })),
        
        if (_customDistribution.isEmpty)
          Container(
            padding: EdgeInsets.all(16.h),
            child: Center(
              child: Text(
                "Nhấn 'Thêm hạng' để tạo phân chia tùy chỉnh",
                style: TextStyle(
                  fontSize: 12.fSize,
                  color: appTheme.gray500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAdditionalPrizes() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Giải thưởng phụ",
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray700,
                ),
              ),
              TextButton.icon(
                onPressed: _addAdditionalPrize,
                icon: Icon(Icons.add, size: 16.adaptSize),
                label: Text("Thêm giải"),
                style: TextButton.styleFrom(
                  foregroundColor: appTheme.blue600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.v),
          
          ...(_additionalPrizes.map((prize) {
            return Container(
              margin: EdgeInsets.only(bottom: 12.v),
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: appTheme.purple50,
                borderRadius: BorderRadius.circular(8.h),
                border: Border.all(color: appTheme.purple200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(6.h),
                    decoration: BoxDecoration(
                      color: appTheme.purple100,
                      borderRadius: BorderRadius.circular(6.h),
                    ),
                    child: Icon(
                      _getPrizeIcon(prize.type),
                      color: appTheme.purple600,
                      size: 20.adaptSize,
                    ),
                  ),
                  
                  SizedBox(width: 12.h),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          prize.title,
                          style: TextStyle(
                            fontSize: 14.fSize,
                            fontWeight: FontWeight.w600,
                            color: appTheme.gray900,
                          ),
                        ),
                        Text(
                          prize.description,
                          style: TextStyle(
                            fontSize: 12.fSize,
                            color: appTheme.gray600,
                          ),
                        ),
                        if (prize.value > 0)
                          Text(
                            "Giá trị: ${(prize.value / 1000).toStringAsFixed(0)}K VNĐ",
                            style: TextStyle(
                              fontSize: 11.fSize,
                              color: appTheme.purple600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () => _removeAdditionalPrize(prize),
                    icon: Icon(Icons.delete_outline),
                    iconSize: 20.adaptSize,
                    color: appTheme.red600,
                  ),
                ],
              ),
            );
          })),
          
          if (_additionalPrizes.isEmpty)
            Container(
              padding: EdgeInsets.all(20.h),
              child: Center(
                child: Text(
                  "Thêm các giải thưởng phụ như Best Shot, Fair Play, MVP...",
                  style: TextStyle(
                    fontSize: 14.fSize,
                    color: appTheme.gray500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSponsorshipConfig() {
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Cho phép tài trợ",
                      style: TextStyle(
                        fontSize: 14.fSize,
                        fontWeight: FontWeight.w600,
                        color: appTheme.gray900,
                      ),
                    ),
                    Text(
                      "Mở cơ hội cho các nhà tài trợ tham gia",
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: appTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ),
              
              Switch(
                value: _allowSponsors,
                onChanged: (value) {
                  setState(() {
                    _allowSponsors = value;
                  });
                  _updateData();
                },
                thumbColor: appTheme.blue600,
              ),
            ],
          ),
          
          if (_allowSponsors) ...[
            SizedBox(height: 20.v),
            
            TextField(
              decoration: InputDecoration(
                labelText: "Quyền lợi nhà tài trợ",
                hintText: "Logo trên banner, giới thiệu trong lễ khai mạc...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.h),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 3,
              controller: TextEditingController(text: _sponsorshipBenefits),
              onChanged: (value) {
                _sponsorshipBenefits = value;
                _updateData();
              },
            ),
            
            SizedBox(height: 20.v),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Danh sách nhà tài trợ:",
                  style: TextStyle(
                    fontSize: 12.fSize,
                    fontWeight: FontWeight.w600,
                    color: appTheme.gray700,
                  ),
                ),
                TextButton.icon(
                  onPressed: _addSponsor,
                  icon: Icon(Icons.add, size: 16.adaptSize),
                  label: Text("Thêm"),
                  style: TextButton.styleFrom(
                    foregroundColor: appTheme.blue600,
                  ),
                ),
              ],
            ),
            
            ...(_sponsors.map((sponsor) {
              return Container(
                margin: EdgeInsets.only(bottom: 8.v),
                padding: EdgeInsets.all(12.h),
                decoration: BoxDecoration(
                  color: appTheme.green50,
                  borderRadius: BorderRadius.circular(8.h),
                  border: Border.all(color: appTheme.green200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sponsor.name,
                            style: TextStyle(
                              fontSize: 14.fSize,
                              fontWeight: FontWeight.w600,
                              color: appTheme.gray900,
                            ),
                          ),
                          Text(
                            "Tài trợ: ${(sponsor.amount / 1000).toStringAsFixed(0)}K VNĐ",
                            style: TextStyle(
                              fontSize: 12.fSize,
                              color: appTheme.green600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    IconButton(
                      onPressed: () => _removeSponsor(sponsor),
                      icon: Icon(Icons.delete_outline),
                      iconSize: 20.adaptSize,
                      color: appTheme.red600,
                    ),
                  ],
                ),
              );
            })),
            
            if (_sponsors.isEmpty)
              Container(
                padding: EdgeInsets.all(16.h),
                child: Center(
                  child: Text(
                    "Chưa có nhà tài trợ nào",
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: appTheme.gray500,
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  IconData _getPrizeIcon(String type) {
    switch (type) {
      case 'trophy': return Icons.emoji_events;
      case 'medal': return Icons.military_tech;
      case 'certificate': return Icons.card_membership;
      case 'voucher': return Icons.local_offer;
      case 'product': return Icons.card_giftcard;
      default: return Icons.star;
    }
  }

  void _addCustomDistribution() {
    setState(() {
      _customDistribution.add(PrizeDistribution(
        position: _customDistribution.length + 1,
        percentage: 0,
      ));
    });
  }

  void _removeCustomDistribution(int index) {
    setState(() {
      _customDistribution.removeAt(index);
    });
    _updateData();
  }

  void _addAdditionalPrize() {
    showDialog(
      context: context,
      builder: (context) => AdditionalPrizeDialog(
        onSave: (prize) {
          setState(() {
            _additionalPrizes.add(prize);
          });
          _updateData();
        },
      ),
    );
  }

  void _removeAdditionalPrize(AdditionalPrize prize) {
    setState(() {
      _additionalPrizes.remove(prize);
    });
    _updateData();
  }

  void _addSponsor() {
    showDialog(
      context: context,
      builder: (context) => SponsorDialog(
        onSave: (sponsor) {
          setState(() {
            _sponsors.add(sponsor);
          });
          _calculatePrizePool();
          _updateData();
        },
      ),
    );
  }

  void _removeSponsor(Sponsor sponsor) {
    setState(() {
      _sponsors.remove(sponsor);
    });
    _calculatePrizePool();
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'prizeSource': _prizeSource,
      'totalPrizePool': _totalPrizePool,
      'sponsorContribution': _sponsorContribution,
      'organizerFee': _organizerFee,
      'distributionTemplate': _distributionTemplate,
      'customDistribution': _customDistribution.map((dist) => dist.toMap()).toList(),
      'additionalPrizes': _additionalPrizes.map((prize) => prize.toMap()).toList(),
      'sponsors': _sponsors.map((sponsor) => sponsor.toMap()).toList(),
      'allowSponsors': _allowSponsors,
      'sponsorshipBenefits': _sponsorshipBenefits,
    });
  }
}

// Supporting Classes
class PrizeDistribution {
  final int position;
  final double percentage;

  PrizeDistribution({required this.position, required this.percentage});

  PrizeDistribution copyWith({int? position, double? percentage}) {
    return PrizeDistribution(
      position: position ?? this.position,
      percentage: percentage ?? this.percentage,
    );
  }

  Map<String, dynamic> toMap() {
    return {'position': position, 'percentage': percentage};
  }

  static PrizeDistribution fromMap(Map<String, dynamic> map) {
    return PrizeDistribution(position: map['position'], percentage: map['percentage']);
  }
}

class AdditionalPrize {
  final String id;
  final String title;
  final String description;
  final String type;
  final double value;

  AdditionalPrize({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    this.value = 0,
  });

  Map<String, dynamic> toMap() {
    return() {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      'value': value,
    };
  }

  static AdditionalPrize fromMap(Map<String, dynamic> map) {
    return AdditionalPrize(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      type: map['type'],
      value: map['value'] ?? 0.0,
    );
  }
}

class Sponsor {
  final String id;
  final String name;
  final double amount;

  Sponsor({required this.id, required this.name, required this.amount});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'amount': amount};
  }

  static Sponsor fromMap(Map<String, dynamic> map) {
    return Sponsor(id: map['id'], name: map['name'], amount: map['amount']);
  }
}

// Dialog Classes
class AdditionalPrizeDialog extends StatefulWidget {
  const AdditionalPrizeDialog({super.key});

} 
  final Function(AdditionalPrize) onSave;

  const AdditionalPrizeDialog({super.key, required this.onSave});

  @override
  _AdditionalPrizeDialogState createState() => _AdditionalPrizeDialogState();
}

class _AdditionalPrizeDialogState extends State<AdditionalPrizeDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _valueController = TextEditingController();
  String _type = 'trophy';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Thêm giải thưởng phụ"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: "Tên giải thưởng *", border: OutlineInputBorder()),
          ),
          SizedBox(height: 16.v),
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(labelText: "Mô tả", border: OutlineInputBorder()),
            maxLines: 2,
          ),
          SizedBox(height: 16.v),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: InputDecoration(labelText: "Loại giải", border: OutlineInputBorder()),
            items: [
              DropdownMenuItem(value: 'trophy', child: Text("Cúp")),
              DropdownMenuItem(value: 'medal', child: Text("Huy chương")),
              DropdownMenuItem(value: 'certificate', child: Text("Giấy khen")),
              DropdownMenuItem(value: 'voucher', child: Text("Voucher")),
              DropdownMenuItem(value: 'product', child: Text("Sản phẩm")),
            ],
            onChanged: (value) => setState(() => _type = value!),
          ),
          SizedBox(height: 16.v),
          TextField(
            controller: _valueController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Giá trị (VNĐ)", border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty) {
              widget.onSave(AdditionalPrize(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: _titleController.text,
                description: _descriptionController.text,
                type: _type,
                value: double.tryParse(_valueController.text) ?? 0,
              ));
              Navigator.pop(context);
            }
          },
          child: Text("Lưu"),
        ),
      ],
    );
  }
}

class SponsorDialog extends StatefulWidget {
  const SponsorDialog({super.key});

} 
  final Function(Sponsor) onSave;

  const SponsorDialog({super.key, required this.onSave});

  @override
  _SponsorDialogState createState() => _SponsorDialogState();
}

class _SponsorDialogState extends State<SponsorDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Thêm nhà tài trợ"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Tên nhà tài trợ *", border: OutlineInputBorder()),
          ),
          SizedBox(height: 16.v),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(labelText: "Số tiền tài trợ (VNĐ) *", border: OutlineInputBorder()),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text("Hủy")),
        ElevatedButton(
          onPressed: () {
            if (_nameController.text.isNotEmpty && _amountController.text.isNotEmpty) {
              widget.onSave(Sponsor(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text,
                amount: double.tryParse(_amountController.text) ?? 0,
              ));
              Navigator.pop(context);
            }
          },
          child: Text("Lưu"),
        ),
      ],
    );
  }
}
