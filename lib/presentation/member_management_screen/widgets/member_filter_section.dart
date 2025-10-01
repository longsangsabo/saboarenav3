import 'package:flutter/material.dart';
import '../../../models/member_data.dart';

class MemberFilterSection extends StatefulWidget {
  const MemberFilterSection({super.key});

} 
  final TabController controller;
  final String selectedFilter;
  final Function(String) onFilterChanged;
  final Map<String, int> memberCounts;
  final bool showAdvanced;
  final Function(AdvancedFilters) onAdvancedFiltersChanged;

  const MemberFilterSection({
    super.key,
    required this.controller,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.memberCounts,
    required this.showAdvanced,
    required this.onAdvancedFiltersChanged,
  });

  @override
  _MemberFilterSectionState createState() => _MemberFilterSectionState();
}

class _MemberFilterSectionState extends State<MemberFilterSection>
    with TickerProviderStateMixin {
  late AnimationController _advancedController;
  late Animation<double> _advancedAnimation;
  
  AdvancedFilters _currentFilters = AdvancedFilters();
  
  final List<_FilterTab> _filterTabs = [
    _FilterTab('all', 'Tất cả', Icons.people),
    _FilterTab('active', 'Hoạt động', Icons.check_circle),
    _FilterTab('new', 'Thành viên mới', Icons.new_releases),
    _FilterTab('inactive', 'Không hoạt động', Icons.pause_circle),
    _FilterTab('pending', 'Chờ duyệt', Icons.pending),
  ];

  @override
  void initState() {
    super.initState();
    _advancedController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    
    _advancedAnimation = CurvedAnimation(
      parent: _advancedController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _advancedController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MemberFilterSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.showAdvanced != oldWidget.showAdvanced) {
      if (widget.showAdvanced) {
        _advancedController.forward();
      } else {
        _advancedController.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildBasicFilters(),
        
        SizeTransition(
          sizeFactor: _advancedAnimation,
          axisAlignment: -1,
          child: _buildAdvancedFilters(),
        ),
      ],
    );
  }

  Widget _buildBasicFilters() {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _filterTabs.length,
        itemBuilder: (context, index) {
          final tab = _filterTabs[index];
          final isSelected = widget.selectedFilter == tab.key;
          final count = widget.memberCounts[tab.key] ?? 0;

          return Padding(
            padding: EdgeInsets.only(right: 8),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 200),
              child: FilterChip(
                selected: isSelected,
                onSelected: (_) => widget.onFilterChanged(tab.key),
                avatar: Icon(
                  tab.icon,
                  size: 16,
                  color: isSelected
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                label: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: isSelected
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    children: [
                      TextSpan(text: tab.label),
                      TextSpan(
                        text: ' ($count)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                backgroundColor: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary,
                checkmarkColor: Theme.of(context).colorScheme.onPrimary,
                side: BorderSide(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                labelPadding: EdgeInsets.only(left: 4),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAdvancedFilters() {
    return Container(
      margin: EdgeInsets.only(top: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.filter_alt,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 8),
              Text(
                'Bộ lọc nâng cao',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _clearAdvancedFilters,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
                child: Text('Xóa bộ lọc'),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _buildMembershipTypeFilter(),
              _buildRankRangeFilter(),
              _buildJoinDateFilter(),
              _buildActivityLevelFilter(),
              _buildEloRangeFilter(),
            ],
          ),
          
          SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: _clearAdvancedFilters,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('Đặt lại'),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: _applyAdvancedFilters,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('Áp dụng'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipTypeFilter() {
    return _FilterGroup(
      title: 'Loại thành viên',
      child: Wrap(
        spacing: 8,
        children: MembershipType.values.map((type) {
          final isSelected = _currentFilters.membershipTypes.contains(type);
          return FilterChip(
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: [..._currentFilters.membershipTypes, type],
                    minRank: _currentFilters.minRank,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels,
                    minElo: _currentFilters.minElo,
                    maxElo: _currentFilters.maxElo,
                  );
                } else {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes.where((t) => t != type).toList(),
                    minRank: _currentFilters.minRank,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels,
                    minElo: _currentFilters.minElo,
                    maxElo: _currentFilters.maxElo,
                  );
                }
              });
            },
            label: Text(_getMembershipTypeLabel(type)),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildRankRangeFilter() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.4, // Fixed width for Wrap
      child: _FilterGroup(
        title: 'Xếp hạng',
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              value: _currentFilters.minRank,
              decoration: InputDecoration(
                labelText: 'Từ',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              items: ['beginner', 'amateur', 'intermediate', 'advanced', 'professional'].map((rank) {
                return DropdownMenuItem(
                  value: rank,
                  child: Text(_getRankLabelFromString(rank), style: TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes,
                    minRank: value,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels,
                    minElo: _currentFilters.minElo,
                    maxElo: _currentFilters.maxElo,
                  );
                });
              },
            ),
            SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _currentFilters.maxRank,
              decoration: InputDecoration(
                labelText: 'Đến',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                isDense: true,
              ),
              items: ['beginner', 'amateur', 'intermediate', 'advanced', 'professional'].map((rank) {
                return DropdownMenuItem(
                  value: rank,
                  child: Text(_getRankLabelFromString(rank), style: TextStyle(fontSize: 12)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes,
                    minRank: _currentFilters.minRank,
                    maxRank: value,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels,
                    minElo: _currentFilters.minElo,
                    maxElo: _currentFilters.maxElo,
                  );
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinDateFilter() {
    return _FilterGroup(
      title: 'Ngày tham gia',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Từ ngày',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, true),
              controller: TextEditingController(
                text: _currentFilters.joinStartDate != null
                    ? "${_currentFilters.joinStartDate!.day}/${_currentFilters.joinStartDate!.month}/${_currentFilters.joinStartDate!.year}"
                    : '',
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'Đến ngày',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              readOnly: true,
              onTap: () => _selectDate(context, false),
              controller: TextEditingController(
                text: _currentFilters.joinEndDate != null
                    ? "${_currentFilters.joinEndDate!.day}/${_currentFilters.joinEndDate!.month}/${_currentFilters.joinEndDate!.year}"
                    : '',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityLevelFilter() {
    final activityLevels = ['Rất hoạt động', 'Hoạt động', 'Ít hoạt động', 'Không hoạt động'];
    
    return _FilterGroup(
      title: 'Mức độ hoạt động',
      child: Wrap(
        spacing: 8,
        children: activityLevels.map((level) {
          final isSelected = _currentFilters.activityLevels.contains(level);
          return FilterChip(
            selected: isSelected,
            onSelected: (selected) {
              setState(() {
                if (selected) {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes,
                    minRank: _currentFilters.minRank,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: [..._currentFilters.activityLevels, level],
                    minElo: _currentFilters.minElo,
                    maxElo: _currentFilters.maxElo,
                  );
                } else {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes,
                    minRank: _currentFilters.minRank,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels.where((l) => l != level).toList(),
                    minElo: _currentFilters.minElo,
                    maxElo: _currentFilters.maxElo,
                  );
                }
              });
            },
            label: Text(level),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEloRangeFilter() {
    return _FilterGroup(
      title: 'Phạm vi ELO',
      child: Row(
        children: [
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'ELO tối thiểu',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final elo = int.tryParse(value);
                setState(() {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes,
                    minRank: _currentFilters.minRank,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels,
                    minElo: elo,
                    maxElo: _currentFilters.maxElo,
                  );
                });
              },
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              decoration: InputDecoration(
                labelText: 'ELO tối đa',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final elo = int.tryParse(value);
                setState(() {
                  _currentFilters = AdvancedFilters(
                    membershipTypes: _currentFilters.membershipTypes,
                    minRank: _currentFilters.minRank,
                    maxRank: _currentFilters.maxRank,
                    joinStartDate: _currentFilters.joinStartDate,
                    joinEndDate: _currentFilters.joinEndDate,
                    activityLevels: _currentFilters.activityLevels,
                    minElo: _currentFilters.minElo,
                    maxElo: elo,
                  );
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date != null) {
      setState(() {
        if (isStartDate) {
          _currentFilters = AdvancedFilters(
            membershipTypes: _currentFilters.membershipTypes,
            minRank: _currentFilters.minRank,
            maxRank: _currentFilters.maxRank,
            joinStartDate: date,
            joinEndDate: _currentFilters.joinEndDate,
            activityLevels: _currentFilters.activityLevels,
            minElo: _currentFilters.minElo,
            maxElo: _currentFilters.maxElo,
          );
        } else {
          _currentFilters = AdvancedFilters(
            membershipTypes: _currentFilters.membershipTypes,
            minRank: _currentFilters.minRank,
            maxRank: _currentFilters.maxRank,
            joinStartDate: _currentFilters.joinStartDate,
            joinEndDate: date,
            activityLevels: _currentFilters.activityLevels,
            minElo: _currentFilters.minElo,
            maxElo: _currentFilters.maxElo,
          );
        }
      });
    }
  }

  void _clearAdvancedFilters() {
    setState(() {
      _currentFilters = AdvancedFilters();
    });
    widget.onAdvancedFiltersChanged(_currentFilters);
  }

  void _applyAdvancedFilters() {
    widget.onAdvancedFiltersChanged(_currentFilters);
  }

  String _getMembershipTypeLabel(MembershipType type) {
    switch (type) {
      case MembershipType.regular:
        return 'Thường';
      case MembershipType.vip:
        return 'VIP';
      case MembershipType.premium:
        return 'Premium';
    }
  }

  String _getRankLabel(RankType rank) {
    switch (rank) {
      case RankType.beginner:
        return 'Mới bắt đầu';
      case RankType.amateur:
        return 'Nghiệp dư';
      case RankType.intermediate:
        return 'Trung bình';
      case RankType.advanced:
        return 'Nâng cao';
      case RankType.professional:
        return 'Chuyên nghiệp';
    }
  }

  String _getRankLabelFromString(String rank) {
    switch (rank) {
      case 'beginner':
        return 'Mới bắt đầu';
      case 'amateur':
        return 'Nghiệp dư';
      case 'intermediate':
        return 'Trung bình';
      case 'advanced':  
        return 'Nâng cao';
      case 'professional':
        return 'Chuyên nghiệp';
      default:
        return 'Không xác định';
    }
  }
}

class _FilterTab {
  final String key;
  final String label;
  final IconData icon;

  _FilterTab(this.key, this.label, this.icon);
}

class _FilterGroup extends StatelessWidget {
  final String title;
  final Widget child;

  const _FilterGroup({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
        SizedBox(height: 8),
        child,
      ],
    );
  }
}
