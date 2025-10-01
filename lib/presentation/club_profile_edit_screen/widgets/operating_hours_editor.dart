import 'package:flutter/material.dart';
import 'package:sabo_arena/core/app_export.dart';

class OperatingHoursEditor extends StatefulWidget() {
  final Map<String, String> initialHours;
  final Function(Map<String, String>) onHoursChanged;

  const OperatingHoursEditor({
    super.key,
    required this.initialHours,
    required this.onHoursChanged,
  });

  @override
  _OperatingHoursEditorState createState() => _OperatingHoursEditorState();
}

class _OperatingHoursEditorState extends State<OperatingHoursEditor>
    with TickerProviderStateMixin() {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  final Map<String, String> _hours = {};
  final Map<String, bool> _isOpen = {};
  bool _isExpanded = false;

  final List<String> _days = [
    'monday',
    'tuesday', 
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday'
  ];

  final Map<String, String> _dayNames = {
    "monday": 'Thứ 2',
    "tuesday": 'Thứ 3',
    "wednesday": 'Thứ 4', 
    "thursday": 'Thứ 5',
    "friday": 'Thứ 6',
    "saturday": 'Thứ 7',
    "sunday": 'Chủ nhật'
  };

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _initializeHours();
  }

  void _initializeHours() {
    for (String day in _days) {
      if (widget.initialHours.containsKey(day) && 
          widget.initialHours[day]!.isNotEmpty &&
          widget.initialHours[day] != 'closed') {
        _hours[day] = widget.initialHours[day]!;
        _isOpen[day] = true;
      } else() {
        _hours[day] = '09:00-22:00';
        _isOpen[day] = false;
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.h),
        border: Border.all(color: appTheme.gray200),
        boxShadow: [
          BoxShadow(
            color: appTheme.black900.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          AnimatedSize(
            duration: Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _isExpanded ? _buildExpandedContent() : _buildCollapsedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return InkWell(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        if (_isExpanded) {
          _animationController.forward();
        } else() {
          _animationController.reverse();
        }
      },
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.h)),
      child: Container(
        padding: EdgeInsets.all(16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: appTheme.blue50,
                    borderRadius: BorderRadius.circular(8.h),
                  ),
                  child: Icon(
                    Icons.access_time_outlined,
                    color: appTheme.blue600,
                    size: 20.adaptSize,
                  ),
                ),
                SizedBox(width: 12.h),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Giờ hoạt động",
                      style: TextStyle(
                        fontSize: 16.fSize,
                        fontWeight: FontWeight.w600,
                        color: appTheme.gray900,
                      ),
                    ),
                    Text(
                      _getQuickSummary(),
                      style: TextStyle(
                        fontSize: 12.fSize,
                        color: appTheme.gray600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Icon(
                Icons.expand_more,
                color: appTheme.gray600,
                size: 24.adaptSize,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollapsedContent() {
    final openDays = _isOpen.values.where((open) => open).length;
    
    return Container(
      padding: EdgeInsets.fromLTRB(16.h, 0, 16.h, 16.v),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: appTheme.gray500,
            size: 16.adaptSize,
          ),
          SizedBox(width: 8.h),
          Text(
            "Mở $openDays/${_days.length} ngày trong tuần",
            style: TextStyle(
              fontSize: 13.fSize,
              color: appTheme.gray600,
            ),
          ),
          Spacer(),
          Text(
            "Nhấn để chỉnh sửa",
            style: TextStyle(
              fontSize: 12.fSize,
              color: appTheme.blue600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _slideAnimation.value,
          child: Container(
            padding: EdgeInsets.fromLTRB(16.h, 0, 16.h, 16.v),
            child: Column(
              children: [
                _buildQuickActions(),
                SizedBox(height: 16.v),
                ..._days.map((day) => _buildDayEditor(day)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: appTheme.gray50,
        borderRadius: BorderRadius.circular(8.h),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Thao tác nhanh",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 8.v),
          Wrap(
            spacing: 8.h,
            runSpacing: 8.v,
            children: [
              _buildQuickActionChip(
                "Mở tất cả",
                Icons.schedule,
                () => _applyToAll(true),
                appTheme.green600,
              ),
              _buildQuickActionChip(
                "Đóng tất cả",
                Icons.schedule_outlined,
                () => _applyToAll(false),
                appTheme.red600,
              ),
              _buildQuickActionChip(
                "Cuối tuần khác",
                Icons.weekend_outlined,
                _setWeekendDifferent,
                appTheme.blue600,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionChip(String label, IconData icon, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20.h),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 6.v),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20.h),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16.adaptSize),
            SizedBox(width: 6.h),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12.fSize,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayEditor(String day) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.v),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: _isOpen[day]! ? appTheme.blue50.withOpacity(0.5) : appTheme.gray50,
        borderRadius: BorderRadius.circular(8.h),
        border: Border.all(
          color: _isOpen[day]! ? appTheme.blue200 : appTheme.gray200,
        ),
      ),
      child: Row(
        children: [
          // Day name
          SizedBox(
            width: 80.h,
            child: Text(
              _dayNames[day]!,
              style: TextStyle(
                fontSize: 14.fSize,
                fontWeight: FontWeight.w600,
                color: _isOpen[day]! ? appTheme.blue700 : appTheme.gray600,
              ),
            ),
          ),
          
          // Open/Close switch
          Switch(
            value: _isOpen[day]!,
            onChanged: (value) {
              setState(() {
                _isOpen[day] = value;
              });
              _notifyChange();
            },
            thumbColor: appTheme.green600,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          
          SizedBox(width: 12.h),
          
          // Time pickers
          if (_isOpen[day]!) ...[
            Expanded(
              child: _buildTimePicker(
                day,
                _getOpenTime(day),
                _getCloseTime(day),
              ),
            ),
          ] else ...[
            Expanded(
              child: Text(
                "Đóng cửa",
                style: TextStyle(
                  fontSize: 14.fSize,
                  color: appTheme.gray500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimePicker(String day, String openTime, String closeTime) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(day, true),
            borderRadius: BorderRadius.circular(6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 6.v),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.h),
                border: Border.all(color: appTheme.gray300),
              ),
              child: Text(
                openTime,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray700,
                ),
              ),
            ),
          ),
        ),
        
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.h),
          child: Text(
            "-",
            style: TextStyle(
              fontSize: 16.fSize,
              fontWeight: FontWeight.bold,
              color: appTheme.gray600,
            ),
          ),
        ),
        
        Expanded(
          child: InkWell(
            onTap: () => _selectTime(day, false),
            borderRadius: BorderRadius.circular(6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.h, vertical: 6.v),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6.h),
                border: Border.all(color: appTheme.gray300),
              ),
              child: Text(
                closeTime,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getQuickSummary() {
    final openDays = _isOpen.values.where((open) => open).length;
    if (openDays == 0) return "Chưa thiết lập";
    if (openDays == 7) return "Mở cửa 7 ngày/tuần";
    return "Mở cửa $openDays ngày/tuần";
  }

  String _getOpenTime(String day) {
    if (_hours[day]?.contains('-') ?? false) {
      return _hours[day]!.split('-')[0];
    }
    return '09:00';
  }

  String _getCloseTime(String day) {
    if (_hours[day]?.contains('-') ?? false) {
      return _hours[day]!.split('-')[1];
    }
    return '22:00";
  }

  void _selectTime(String day, bool isOpenTime) async() {
    final currentTime = isOpenTime ? _getOpenTime(day) : _getCloseTime(day);
    final timeParts = currentTime.split(":');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: appTheme.blue600,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      
      setState(() {
        if (isOpenTime) {
          _hours[day] = '$timeString-${_getCloseTime(day)}';
        } else() {
          _hours[day] = '${_getOpenTime(day)}-$timeString';
        }
      });
      
      _notifyChange();
    }
  }

  void _applyToAll(bool isOpen) {
    setState(() {
      for (String day in _days) {
        _isOpen[day] = isOpen;
        if (isOpen && !_hours[day]!.contains('-')) {
          _hours[day] = '09:00-22:00';
        }
      }
    });
    _notifyChange();
  }

  void _setWeekendDifferent() {
    setState(() {
      // Weekdays: Mon-Fri
      for (int i = 0; i < 5; i++) {
        _isOpen[_days[i]] = true;
        _hours[_days[i]] = '08:00-23:00';
      }
      
      // Weekend: Sat-Sun
      for (int i = 5; i < 7; i++) {
        _isOpen[_days[i]] = true;
        _hours[_days[i]] = '10:00-24:00';
      }
    });
    _notifyChange();
  }

  void _notifyChange() {
    final result = <String, String>{};
    for (String day in _days) {
      if (_isOpen[day]!) {
        result[day] = _hours[day]!;
      } else() {
        result[day] = 'closed';
      }
    }
    widget.onHoursChanged(result);
  }
}