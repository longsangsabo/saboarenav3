import 'package:flutter/material.dart';
// import 'package:sabo_arena/core/app_export.dart';


class RequirementsStep extends StatefulWidget() {
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const RequirementsStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  _RequirementsStepState createState() => _RequirementsStepState();
}

class _RequirementsStepState extends State<RequirementsStep>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Rank requirements
  bool _hasRankRequirement = false;
  String _minRank = 'beginner';
  String _maxRank = 'pro';
  
  // Membership requirements
  bool _clubMembersOnly = false;
  bool _requireVerification = true;
  
  // Age requirements
  bool _hasAgeRequirement = false;
  int _minAge = 16;
  int _maxAge = 99;
  
  // Skill requirements
  bool _hasSkillRequirement = false;
  int _minExperience = 1; // years
  double _minRating = 1000;
  
  // Additional rules
  List<TournamentRule> _customRules = [];
  bool _requireEquipment = true;
  bool _allowSubstitutes = false;
  bool _requireDeposit = false;
  double _depositAmount = 100000;

  final List<String> _ranks = [
    'beginner', 'amateur', 'intermediate', 'advanced', 'expert', 'pro'
  ];

  final Map<String, String> _rankLabels = {
    "beginner": 'Người mới',
    "amateur": 'Nghiệp dư',
    "intermediate": 'Trung bình',
    "advanced": 'Khá',
    "expert": 'Giỏi',
    "pro": 'Chuyên nghiệp',
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
    _hasRankRequirement = widget.data['hasRankRequirement'] ?? false;
    _minRank = widget.data['minRank'] ?? 'beginner';
    _maxRank = widget.data['maxRank'] ?? 'pro';
    _clubMembersOnly = widget.data['clubMembersOnly'] ?? false;
    _requireVerification = widget.data['requireVerification'] ?? true;
    _hasAgeRequirement = widget.data['hasAgeRequirement'] ?? false;
    _minAge = widget.data['minAge'] ?? 16;
    _maxAge = widget.data['maxAge'] ?? 99;
    _hasSkillRequirement = widget.data['hasSkillRequirement'] ?? false;
    _minExperience = widget.data['minExperience'] ?? 1;
    _minRating = widget.data['minRating'] ?? 1000.0;
    _requireEquipment = widget.data['requireEquipment'] ?? true;
    _allowSubstitutes = widget.data['allowSubstitutes'] ?? false;
    _requireDeposit = widget.data['requireDeposit'] ?? false;
    _depositAmount = widget.data['depositAmount'] ?? 100000.0;
    
    _customRules = (widget.data['customRules'] as List<dynamic>?)?.map((rule) => 
        TournamentRule.fromMap(rule as Map<String, dynamic>)).toList() ?? [];
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
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle("Yêu cầu xếp hạng", Icons.military_tech_outlined),
                SizedBox(height: 16),
                _buildRankRequirements(),
                
                SizedBox(height: 24),
                _buildSectionTitle("Yêu cầu thành viên", Icons.group_outlined),
                SizedBox(height: 16),
                _buildMembershipRequirements(),
                
                SizedBox(height: 24),
                _buildSectionTitle("Yêu cầu độ tuổi", Icons.cake_outlined),
                SizedBox(height: 16),
                _buildAgeRequirements(),
                
                SizedBox(height: 24),
                _buildSectionTitle("Yêu cầu kỹ năng", Icons.emoji_events_outlined),
                SizedBox(height: 16),
                _buildSkillRequirements(),
                
                SizedBox(height: 24),
                _buildSectionTitle("Quy tắc khác", Icons.rule_outlined),
                SizedBox(height: 16),
                _buildAdditionalRules(),
                
                SizedBox(height: 24),
                _buildSectionTitle("Quy tắc tùy chỉnh", Icons.add_task_outlined),
                SizedBox(height: 16),
                _buildCustomRules(),
                
                SizedBox(height: 100), // Space for navigation buttons
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
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50] ?? Colors.blue,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.blue[600] ?? Colors.blue,
            size: 20,
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[900] ?? Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildRankRequirements() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900] ?? Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleRow(
            title: "Giới hạn theo xếp hạng",
            subtitle: "Chỉ cho phép người chơi trong khoảng xếp hạng nhất định",
            value: _hasRankRequirement,
            onChanged: (value) {
              setState(() {
                _hasRankRequirement = value;
              });
              _updateData();
            },
          ),
          
          if (_hasRankRequirement) ...[
            SizedBox(height: 20),
            _buildRankSelector(),
            
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50] ?? Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600] ?? Colors.blue,
                    size: 16,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Chỉ người chơi từ ${_rankLabels[_minRank]} đến ${_rankLabels[_maxRank]} mới có thể tham gia",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600] ?? Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRankSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Chọn khoảng xếp hạng:",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700] ?? Colors.grey,
          ),
        ),
        SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Từ:",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600] ?? Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _minRank,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _ranks.map((rank) {
                      return DropdownMenuItem(
                        value: rank,
                        child: Text(_rankLabels[rank]!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _minRank = value!;
                        // Ensure max rank is not lower than min rank
                        final minIndex = _ranks.indexOf(_minRank);
                        final maxIndex = _ranks.indexOf(_maxRank);
                        if (maxIndex < minIndex) {
                          _maxRank = _minRank;
                        }
                      });
                      _updateData();
                    },
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Đến:",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600] ?? Colors.grey,
                    ),
                  ),
                  SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: _maxRank,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _ranks.where((rank) {
                      return _ranks.indexOf(rank) >= _ranks.indexOf(_minRank);
                    }).map((rank) {
                      return DropdownMenuItem(
                        value: rank,
                        child: Text(_rankLabels[rank]!),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _maxRank = value!;
                      });
                      _updateData();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMembershipRequirements() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900] ?? Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            title: "Chỉ thành viên club",
            subtitle: "Chỉ cho phép thành viên của club tham gia",
            value: _clubMembersOnly,
            onChanged: (value) {
              setState(() {
                _clubMembersOnly = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 16),
          
          _buildToggleRow(
            title: "Yêu cầu xác minh tài khoản",
            subtitle: "Người chơi phải xác minh danh tính trước khi tham gia",
            value: _requireVerification,
            onChanged: (value) {
              setState(() {
                _requireVerification = value;
              });
              _updateData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAgeRequirements() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900] ?? Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleRow(
            title: "Giới hạn độ tuổi",
            subtitle: "Chỉ cho phép người chơi trong độ tuổi nhất định",
            value: _hasAgeRequirement,
            onChanged: (value) {
              setState(() {
                _hasAgeRequirement = value;
              });
              _updateData();
            },
          ),
          
          if (_hasAgeRequirement) ...[
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildAgeInput(
                    label: "Tuổi tối thiểu",
                    value: _minAge,
                    onChanged: (value) {
                      setState(() {
                        _minAge = value;
                        if (_maxAge < _minAge) {
                          _maxAge = _minAge;
                        }
                      });
                      _updateData();
                    },
                  ),
                ),
                
                SizedBox(width: 16),
                
                Expanded(
                  child: _buildAgeInput(
                    label: "Tuổi tối đa",
                    value: _maxAge,
                    onChanged: (value) {
                      setState(() {
                        _maxAge = value;
                        if (_minAge > _maxAge) {
                          _minAge = _maxAge;
                        }
                      });
                      _updateData();
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAgeInput({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600] ?? Colors.grey,
          ),
        ),
        SizedBox(height: 4),
        
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: value > 10 ? () => onChanged(value - 1) : null,
                icon: Icon(Icons.remove, size: 16),
                color: Colors.grey[600] ?? Colors.grey,
              ),
              
              Expanded(
                child: Text(
                  "$value tuổi",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[900] ?? Colors.black,
                  ),
                ),
              ),
              
              IconButton(
                onPressed: value < 99 ? () => onChanged(value + 1) : null,
                icon: Icon(Icons.add, size: 16),
                color: Colors.grey[600] ?? Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkillRequirements() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900] ?? Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildToggleRow(
            title: "Yêu cầu kỹ năng tối thiểu",
            subtitle: "Đặt yêu cầu về kinh nghiệm và rating",
            value: _hasSkillRequirement,
            onChanged: (value) {
              setState(() {
                _hasSkillRequirement = value;
              });
              _updateData();
            },
          ),
          
          if (_hasSkillRequirement) ...[
            SizedBox(height: 20),
            
            Text(
              "Kinh nghiệm tối thiểu:",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700] ?? Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              children: [1, 2, 3, 5, 10].map((years) {
                final isSelected = _minExperience == years;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _minExperience = years;
                    });
                    _updateData();
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[600] ?? Colors.blue : Colors.grey[100]!,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "$years năm",
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey[700] ?? Colors.grey,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 20),
            
            Text(
              "Rating tối thiểu: ${_minRating.toInt()}",
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700] ?? Colors.grey,
              ),
            ),
            SizedBox(height: 8),
            
            Slider(
              value: _minRating,
              min: 500,
              max: 3000,
              divisions: 25,
              activeColor: Colors.blue[600] ?? Colors.blue,
              onChanged: (value) {
                setState(() {
                  _minRating = value;
                });
                _updateData();
              },
            ),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("500", style: TextStyle(fontSize: 11, color: Colors.grey[500]!)),
                Text("3000", style: TextStyle(fontSize: 11, color: Colors.grey[500]!)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalRules() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900] ?? Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildToggleRow(
            title: "Yêu cầu thiết bị riêng",
            subtitle: "Người chơi phải mang thiết bị thi đấu riêng",
            value: _requireEquipment,
            onChanged: (value) {
              setState(() {
                _requireEquipment = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 16),
          
          _buildToggleRow(
            title: "Cho phép thay thế",
            subtitle: "Người chơi có thể gửi người khác thi đấu thay",
            value: _allowSubstitutes,
            onChanged: (value) {
              setState(() {
                _allowSubstitutes = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 16),
          
          _buildToggleRow(
            title: "Yêu cầu đặt cọc",
            subtitle: "Người chơi phải đặt cọc để đảm bảo tham gia",
            value: _requireDeposit,
            onChanged: (value) {
              setState(() {
                _requireDeposit = value;
              });
              _updateData();
            },
          ),
          
          if (_requireDeposit) ...[
            SizedBox(height: 16),
            
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Số tiền đặt cọc (VNĐ)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.attach_money_outlined),
              ),
              controller: TextEditingController(text: _depositAmount.toInt().toString()),
              onChanged: (value) {
                _depositAmount = double.tryParse(value) ?? 100000;
                _updateData();
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomRules() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey[900] ?? Colors.black.withOpacity(0.06),
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
                "Quy tắc tùy chỉnh",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700] ?? Colors.grey,
                ),
              ),
              TextButton.icon(
                onPressed: _addCustomRule,
                icon: Icon(Icons.add, size: 16),
                label: Text("Thêm quy tắc"),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue[600] ?? Colors.blue,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          ...(_customRules.asMap().entries.map((entry) {
            final index = entry.key;
            final rule = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50]!,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: rule.isRequired ? Colors.red[100]! : Colors.blue[100]!,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      rule.isRequired ? Icons.warning_outlined : Icons.info_outline,
                      color: rule.isRequired ? Colors.red[600]! : Colors.blue[600] ?? Colors.blue,
                      size: 16,
                    ),
                  ),
                  
                  SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          rule.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[900] ?? Colors.black,
                          ),
                        ),
                        if (rule.description.isNotEmpty)
                          Text(
                            rule.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600] ?? Colors.grey,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () => _editCustomRule(index),
                    icon: Icon(Icons.edit_outlined),
                    iconSize: 20,
                    color: Colors.grey[600] ?? Colors.grey,
                  ),
                  
                  IconButton(
                    onPressed: () => _removeCustomRule(index),
                    icon: Icon(Icons.delete_outline),
                    iconSize: 20,
                    color: Colors.red[600]!,
                  ),
                ],
              ),
            );
          })),
          
          if (_customRules.isEmpty)
            Container(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  "Chưa có quy tắc tùy chỉnh nào. Nhấn 'Thêm quy tắc' để tạo mới.",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500]!,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
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
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[900] ?? Colors.black,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600] ?? Colors.grey,
                ),
              ),
            ],
          ),
        ),
        
        Switch(
          value: value,
          onChanged: onChanged,
          thumbColor: Colors.blue[600] ?? Colors.blue,
        ),
      ],
    );
  }

  void _addCustomRule() {
    showDialog(
      context: context,
      builder: (context) => CustomRuleDialog(
        onSave: (rule) {
          setState(() {
            _customRules.add(rule);
          });
          _updateData();
        },
      ),
    );
  }

  void _editCustomRule(int index) {
    showDialog(
      context: context,
      builder: (context) => CustomRuleDialog(
        rule: _customRules[index],
        onSave: (rule) {
          setState(() {
            _customRules[index] = rule;
          });
          _updateData();
        },
      ),
    );
  }

  void _removeCustomRule(int index) {
    setState(() {
      _customRules.removeAt(index);
    });
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'hasRankRequirement': _hasRankRequirement,
      'minRank': _minRank,
      'maxRank': _maxRank,
      'clubMembersOnly': _clubMembersOnly,
      'requireVerification': _requireVerification,
      'hasAgeRequirement': _hasAgeRequirement,
      'minAge': _minAge,
      'maxAge': _maxAge,
      'hasSkillRequirement': _hasSkillRequirement,
      'minExperience': _minExperience,
      'minRating': _minRating,
      'requireEquipment': _requireEquipment,
      'allowSubstitutes': _allowSubstitutes,
      'requireDeposit': _requireDeposit,
      'depositAmount': _depositAmount,
      'customRules': _customRules.map((rule) => rule.toMap()).toList(),
    });
  }
}

class TournamentRule() {
  final String id;
  final String title;
  final String description;
  final bool isRequired;

  TournamentRule({
    required this.id,
    required this.title,
    required this.description,
    this.isRequired = false,
  });

  TournamentRule copyWith({
    String? id,
    String? title,
    String? description,
    bool? isRequired,
  }) {
    return TournamentRule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return() {
      'id': id,
      'title': title,
      'description': description,
      'isRequired': isRequired,
    };
  }

  static TournamentRule fromMap(Map<String, dynamic> map) {
    return TournamentRule(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      isRequired: map['isRequired'] ?? false,
    );
  }
}

class CustomRuleDialog extends StatefulWidget() {
  final TournamentRule? rule;
  final Function(TournamentRule) onSave;

  const CustomRuleDialog({
    super.key,
    this.rule,
    required this.onSave,
  });

  @override
  _CustomRuleDialogState createState() => _CustomRuleDialogState();
}

class _CustomRuleDialogState extends State<CustomRuleDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isRequired = false;

  @override
  void initState() {
    super.initState();
    if (widget.rule != null) {
      _titleController.text = widget.rule!.title;
      _descriptionController.text = widget.rule!.description;
      _isRequired = widget.rule!.isRequired;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.rule == null ? "Thêm quy tắc" : "Sửa quy tắc"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: "Tiêu đề quy tắc *",
              border: OutlineInputBorder(),
            ),
            maxLines: 1,
          ),
          
          SizedBox(height: 16),
          
          TextField(
            controller: _descriptionController,
            decoration: InputDecoration(
              labelText: "Mô tả chi tiết",
              border: OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
          ),
          
          SizedBox(height: 16),
          
          CheckboxListTile(
            value: _isRequired,
            onChanged: (value) {
              setState(() {
                _isRequired = value ?? false;
              });
            },
            title: Text("Bắt buộc"),
            subtitle: Text("Người chơi bắt buộc phải tuân thủ quy tắc này"),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text("Hủy"),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text("Lưu"),
        ),
      ],
    );
  }

  void _save() {
    if (_titleController.text.isEmpty) return;
    
    final rule = TournamentRule(
      id: widget.rule?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      isRequired: _isRequired,
    );
    
    widget.onSave(rule);
    Navigator.of(context).pop();
  }
}
