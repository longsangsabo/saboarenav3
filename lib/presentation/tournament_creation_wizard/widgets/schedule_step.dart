import 'package:flutter/material.dart';
import 'package:sabo_arena/theme/theme_extensions.dart';
import 'package:sabo_arena/utils/size_extensions.dart';

class ScheduleStep extends StatefulWidget {
  const ScheduleStep({super.key});

} 
  final Map<String, dynamic> data;
  final Function(Map<String, dynamic>) onDataChanged;

  const ScheduleStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  _ScheduleStepState createState() => _ScheduleStepState();
}

class _ScheduleStepState extends State<ScheduleStep>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  DateTime _registrationStartDate = DateTime.now();
  DateTime _registrationEndDate = DateTime.now().add(Duration(days: 7));
  DateTime _tournamentStartDate = DateTime.now().add(Duration(days: 8));
  DateTime _tournamentEndDate = DateTime.now().add(Duration(days: 15));
  
  String _matchScheduling = 'flexible';
  int _matchDuration = 60;
  int _breakTime = 15;
  int _dailyMatches = 3;
  bool _useTimeSlots = false;
  List<TimeSlot> _timeSlots = [];

  final List<int> _matchDurationOptions = [30, 45, 60, 90, 120];
  final List<int> _breakTimeOptions = [5, 10, 15, 30];
  final List<int> _dailyMatchesOptions = [1, 2, 3, 4, 5, 6, 8, 10];

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
    _registrationStartDate = widget.data['registrationStartDate'] ?? DateTime.now();
    _registrationEndDate = widget.data['registrationEndDate'] ?? DateTime.now().add(Duration(days: 7));
    _tournamentStartDate = widget.data['tournamentStartDate'] ?? DateTime.now().add(Duration(days: 8));
    _tournamentEndDate = widget.data['tournamentEndDate'] ?? DateTime.now().add(Duration(days: 15));
    _matchScheduling = widget.data['matchScheduling'] ?? 'flexible';
    _matchDuration = widget.data['matchDuration'] ?? 60;
    _breakTime = widget.data['breakTime'] ?? 15;
    _dailyMatches = widget.data['dailyMatches'] ?? 3;
    _timeSlots = (widget.data['timeSlots'] as List<dynamic>?)?.map((slot) => 
        TimeSlot.fromMap(slot as Map<String, dynamic>)).toList() ?? [];
    _useTimeSlots = _timeSlots.isNotEmpty;

    if (_timeSlots.isEmpty) {
      _initializeDefaultTimeSlots();
    }
  }

  void _initializeDefaultTimeSlots() {
    _timeSlots = [
      TimeSlot(
        id: '1',
        start: '08:00',
        end: '12:00',
        label: 'Buổi sáng',
        maxMatches: 2,
        enabled: true,
      ),
      TimeSlot(
        id: '2',
        start: '13:00',
        end: '17:00',
        label: 'Buổi chiều',
        maxMatches: 2,
        enabled: true,
      ),
      TimeSlot(
        id: '3',
        start: '18:00',
        end: '22:00',
        label: 'Buổi tối',
        maxMatches: 3,
        enabled: true,
      ),
    ];
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
                _buildSectionTitle("Thời gian đăng ký", Icons.how_to_reg_outlined),
                SizedBox(height: 16.v),
                _buildRegistrationPeriod(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Thời gian thi đấu", Icons.event_outlined),
                SizedBox(height: 16.v),
                _buildTournamentPeriod(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Lịch trình thi đấu", Icons.schedule_outlined),
                SizedBox(height: 16.v),
                _buildMatchSchedulingOptions(),
                
                SizedBox(height: 24.v),
                _buildSectionTitle("Cài đặt trận đấu", Icons.settings_outlined),
                SizedBox(height: 16.v),
                _buildMatchSettings(),
                
                if (_matchScheduling == 'fixed') ...[
                  SizedBox(height: 24.v),
                  _buildSectionTitle("Khung giờ thi đấu", Icons.access_time_outlined),
                  SizedBox(height: 16.v),
                  _buildTimeSlots(),
                ],
                
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

  Widget _buildRegistrationPeriod() {
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
        children: [
          _buildDateSelector(
            label: "Mở đăng ký",
            date: _registrationStartDate,
            onDateChanged: (date) {
              setState(() {
                _registrationStartDate = date;
                // Auto-adjust end date if needed
                if (_registrationEndDate.isBefore(date)) {
                  _registrationEndDate = date.add(Duration(days: 1));
                }
              });
              _updateData();
            },
            minDate: DateTime.now(),
          ),
          
          SizedBox(height: 16.v),
          
          _buildDateSelector(
            label: "Đóng đăng ký",
            date: _registrationEndDate,
            onDateChanged: (date) {
              setState(() {
                _registrationEndDate = date;
                // Auto-adjust tournament start if needed
                if (_tournamentStartDate.isBefore(date)) {
                  _tournamentStartDate = date.add(Duration(days: 1));
                }
              });
              _updateData();
            },
            minDate: _registrationStartDate.add(Duration(days: 1)),
          ),
          
          SizedBox(height: 12.v),
          
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: appTheme.blue50,
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: appTheme.blue600,
                  size: 16.adaptSize,
                ),
                SizedBox(width: 8.h),
                Expanded(
                  child: Text(
                    "Thời gian đăng ký: ${_registrationEndDate.difference(_registrationStartDate).inDays} ngày",
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: appTheme.blue600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTournamentPeriod() {
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
        children: [
          _buildDateSelector(
            label: "Bắt đầu giải đấu",
            date: _tournamentStartDate,
            onDateChanged: (date) {
              setState(() {
                _tournamentStartDate = date;
                // Auto-adjust end date if needed
                if (_tournamentEndDate.isBefore(date)) {
                  _tournamentEndDate = date.add(Duration(days: 1));
                }
              });
              _updateData();
            },
            minDate: _registrationEndDate.add(Duration(days: 1)),
          ),
          
          SizedBox(height: 16.v),
          
          _buildDateSelector(
            label: "Kết thúc giải đấu",
            date: _tournamentEndDate,
            onDateChanged: (date) {
              setState(() {
                _tournamentEndDate = date;
              });
              _updateData();
            },
            minDate: _tournamentStartDate.add(Duration(days: 1)),
          ),
          
          SizedBox(height: 12.v),
          
          Container(
            padding: EdgeInsets.all(12.h),
            decoration: BoxDecoration(
              color: appTheme.green50,
              borderRadius: BorderRadius.circular(8.h),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: appTheme.green600,
                  size: 16.adaptSize,
                ),
                SizedBox(width: 8.h),
                Expanded(
                  child: Text(
                    "Thời gian thi đấu: ${_tournamentEndDate.difference(_tournamentStartDate).inDays} ngày",
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: appTheme.green600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector({
    required String label,
    required DateTime date,
    required Function(DateTime) onDateChanged,
    DateTime? minDate,
    DateTime? maxDate,
  }) {
    return InkWell(
      onTap: () => _selectDate(date, onDateChanged, minDate, maxDate),
      borderRadius: BorderRadius.circular(8.h),
      child: Container(
        padding: EdgeInsets.all(12.h),
        decoration: BoxDecoration(
          border: Border.all(color: appTheme.gray300),
          borderRadius: BorderRadius.circular(8.h),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              color: appTheme.gray600,
              size: 20.adaptSize,
            ),
            SizedBox(width: 12.h),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12.fSize,
                      color: appTheme.gray600,
                    ),
                  ),
                  Text(
                    "${date.day}/${date.month}/${date.year}",
                    style: TextStyle(
                      fontSize: 16.fSize,
                      fontWeight: FontWeight.w600,
                      color: appTheme.gray900,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: appTheme.gray400,
              size: 16.adaptSize,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSchedulingOptions() {
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
            "Chọn cách sắp xếp lịch thi đấu:",
            style: TextStyle(
              fontSize: 14.fSize,
              fontWeight: FontWeight.w600,
              color: appTheme.gray700,
            ),
          ),
          SizedBox(height: 16.v),
          
          _buildSchedulingOption(
            value: 'flexible',
            title: 'Linh hoạt',
            description: 'Người chơi tự sắp xếp thời gian thi đấu với nhau',
            icon: Icons.schedule_outlined,
            pros: ['Tiện lợi cho người chơi', 'Ít công việc tổ chức'],
            cons: ['Có thể kéo dài thời gian', 'Khó kiểm soát tiến độ'],
          ),
          
          SizedBox(height: 12.v),
          
          _buildSchedulingOption(
            value: 'fixed',
            title: 'Cố định',
            description: 'Lịch thi đấu được sắp xếp theo khung giờ cố định',
            icon: Icons.event_note_outlined,
            pros: ['Kiểm soát tốt tiến độ', 'Chuyên nghiệp hơn'],
            cons: ['Khó sắp xếp cho người chơi', 'Cần nhiều công việc tổ chức'],
          ),
        ],
      ),
    );
  }

  Widget _buildSchedulingOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
    required List<String> pros,
    required List<String> cons,
  }) {
    final isSelected = _matchScheduling == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _matchScheduling = value;
        });
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
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.h),
                  decoration: BoxDecoration(
                    color: (isSelected ? appTheme.blue600 : appTheme.gray600).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6.h),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? appTheme.blue600 : appTheme.gray600,
                    size: 20.adaptSize,
                  ),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.fSize,
                          fontWeight: FontWeight.bold,
                          color: appTheme.gray900,
                        ),
                      ),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 13.fSize,
                          color: appTheme.gray600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: EdgeInsets.all(4.h),
                    decoration: BoxDecoration(
                      color: appTheme.blue600,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16.adaptSize,
                    ),
                  ),
              ],
            ),
            
            SizedBox(height: 12.v),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Ưu điểm:",
                        style: TextStyle(
                          fontSize: 11.fSize,
                          fontWeight: FontWeight.w600,
                          color: appTheme.green600,
                        ),
                      ),
                      ...pros.map((pro) => Text(
                        "• $pro",
                        style: TextStyle(
                          fontSize: 10.fSize,
                          color: appTheme.gray600,
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(width: 12.h),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Nhược điểm:",
                        style: TextStyle(
                          fontSize: 11.fSize,
                          fontWeight: FontWeight.w600,
                          color: appTheme.orange600,
                        ),
                      ),
                      ...cons.map((con) => Text(
                        "• $con",
                        style: TextStyle(
                          fontSize: 10.fSize,
                          color: appTheme.gray600,
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchSettings() {
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
        children: [
          _buildSettingsSelector(
            title: "Thời gian tối đa mỗi trận",
            subtitle: "phút",
            value: _matchDuration,
            options: _matchDurationOptions,
            onChanged: (value) {
              setState(() {
                _matchDuration = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 20.v),
          
          _buildSettingsSelector(
            title: "Thời gian nghỉ giữa các trận",
            subtitle: "phút",
            value: _breakTime,
            options: _breakTimeOptions,
            onChanged: (value) {
              setState(() {
                _breakTime = value;
              });
              _updateData();
            },
          ),
          
          SizedBox(height: 20.v),
          
          _buildSettingsSelector(
            title: "Số trận tối đa mỗi ngày",
            subtitle: "trận",
            value: _dailyMatches,
            options: _dailyMatchesOptions,
            onChanged: (value) {
              setState(() {
                _dailyMatches = value;
              });
              _updateData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSelector({
    required String title,
    required String subtitle,
    required int value,
    required List<int> options,
    required Function(int) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14.fSize,
            fontWeight: FontWeight.w600,
            color: appTheme.gray700,
          ),
        ),
        SizedBox(height: 8.v),
        
        Wrap(
          spacing: 8.h,
          children: options.map((option) {
            final isSelected = value == option;
            return InkWell(
              onTap: () => onChanged(option),
              borderRadius: BorderRadius.circular(20.h),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.v),
                decoration: BoxDecoration(
                  color: isSelected ? appTheme.blue600 : appTheme.gray100,
                  borderRadius: BorderRadius.circular(20.h),
                ),
                child: Text(
                  "$option $subtitle",
                  style: TextStyle(
                    color: isSelected ? Colors.white : appTheme.gray700,
                    fontWeight: FontWeight.w600,
                    fontSize: 13.fSize,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeSlots() {
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
                "Khung giờ thi đấu trong ngày",
                style: TextStyle(
                  fontSize: 14.fSize,
                  fontWeight: FontWeight.w600,
                  color: appTheme.gray700,
                ),
              ),
              TextButton.icon(
                onPressed: _addTimeSlot,
                icon: Icon(Icons.add, size: 16.adaptSize),
                label: Text("Thêm"),
                style: TextButton.styleFrom(
                  foregroundColor: appTheme.blue600,
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12.v),
          
          ...(_timeSlots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: 12.v),
              padding: EdgeInsets.all(12.h),
              decoration: BoxDecoration(
                color: slot.enabled ? appTheme.blue50 : appTheme.gray50,
                borderRadius: BorderRadius.circular(8.h),
                border: Border.all(
                  color: slot.enabled ? appTheme.blue200 : appTheme.gray200,
                ),
              ),
              child: Row(
                children: [
                  Switch(
                    value: slot.enabled,
                    onChanged: (enabled) {
                      setState(() {
                        _timeSlots[index] = slot.copyWith(enabled: enabled);
                      });
                      _updateData();
                    },
                    thumbColor: appTheme.blue600,
                  ),
                  
                  SizedBox(width: 12.h),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slot.label,
                          style: TextStyle(
                            fontSize: 14.fSize,
                            fontWeight: FontWeight.w600,
                            color: slot.enabled ? appTheme.gray900 : appTheme.gray500,
                          ),
                        ),
                        Text(
                          "${slot.start} - ${slot.end} (${slot.maxMatches} trận)",
                          style: TextStyle(
                            fontSize: 12.fSize,
                            color: slot.enabled ? appTheme.gray600 : appTheme.gray400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  IconButton(
                    onPressed: () => _editTimeSlot(index),
                    icon: Icon(Icons.edit_outlined),
                    iconSize: 20.adaptSize,
                    color: appTheme.gray600,
                  ),
                  
                  IconButton(
                    onPressed: () => _removeTimeSlot(index),
                    icon: Icon(Icons.delete_outline),
                    iconSize: 20.adaptSize,
                    color: appTheme.red600,
                  ),
                ],
              ),
            );
          })),
          
          if (_timeSlots.isEmpty)
            Container(
              padding: EdgeInsets.all(20.h),
              child: Center(
                child: Text(
                  "Chưa có khung giờ nào. Nhấn 'Thêm' để tạo khung giờ mới.",
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

  Future<void> _selectDate(
    DateTime currentDate, 
    Function(DateTime) onDateChanged,
    DateTime? minDate,
    DateTime? maxDate,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: minDate ?? DateTime.now(),
      lastDate: maxDate ?? DateTime.now().add(Duration(days: 365)),
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

    if (picked != null && picked != currentDate) {
      onDateChanged(picked);
    }
  }

  void _addTimeSlot() {
    showDialog(
      context: context,
      builder: (context) => TimeSlotDialog(
        onSave: (timeSlot) {
          setState(() {
            _timeSlots.add(timeSlot);
          });
          _updateData();
        },
      ),
    );
  }

  void _editTimeSlot(int index) {
    showDialog(
      context: context,
      builder: (context) => TimeSlotDialog(
        timeSlot: _timeSlots[index],
        onSave: (timeSlot) {
          setState(() {
            _timeSlots[index] = timeSlot;
          });
          _updateData();
        },
      ),
    );
  }

  void _removeTimeSlot(int index) {
    setState(() {
      _timeSlots.removeAt(index);
    });
    _updateData();
  }

  void _updateData() {
    widget.onDataChanged({
      'registrationStartDate': _registrationStartDate,
      'registrationEndDate': _registrationEndDate,
      'tournamentStartDate': _tournamentStartDate,
      'tournamentEndDate': _tournamentEndDate,
      'matchScheduling': _matchScheduling,
      'matchDuration': _matchDuration,
      'breakTime': _breakTime,
      'dailyMatches': _dailyMatches,
      'timeSlots': _timeSlots.map((slot) => slot.toMap()).toList(),
    });
  }
}

class TimeSlot {
  final String id;
  final String start;
  final String end;
  final String label;
  final int maxMatches;
  final bool enabled;

  TimeSlot({
    required this.id,
    required this.start,
    required this.end,
    required this.label,
    required this.maxMatches,
    this.enabled = true,
  });

  TimeSlot copyWith({
    String? id,
    String? start,
    String? end,
    String? label,
    int? maxMatches,
    bool? enabled,
  }) {
    return TimeSlot(
      id: id ?? this.id,
      start: start ?? this.start,
      end: end ?? this.end,
      label: label ?? this.label,
      maxMatches: maxMatches ?? this.maxMatches,
      enabled: enabled ?? this.enabled,
    );
  }

  Map<String, dynamic> toMap() {
    return() {
      'id': id,
      'start': start,
      'end': end,
      'label': label,
      'maxMatches': maxMatches,
      'enabled': enabled,
    };
  }

  static TimeSlot fromMap(Map<String, dynamic> map) {
    return TimeSlot(
      id: map['id'],
      start: map['start'],
      end: map['end'],
      label: map['label'],
      maxMatches: map['maxMatches'],
      enabled: map['enabled'] ?? true,
    );
  }
}

class TimeSlotDialog extends StatefulWidget {
  const TimeSlotDialog({super.key});

} 
  final TimeSlot? timeSlot;
  final Function(TimeSlot) onSave;

  const TimeSlotDialog({
    super.key,
    this.timeSlot,
    required this.onSave,
  });

  @override
  _TimeSlotDialogState createState() => _TimeSlotDialogState();
}

class _TimeSlotDialogState extends State<TimeSlotDialog> {
  final TextEditingController _labelController = TextEditingController();
  String _startTime = '08:00';
  String _endTime = '12:00";
  int _maxMatches = 2;

  @override
  void initState() {
    super.initState();
    if (widget.timeSlot != null) {
      _labelController.text = widget.timeSlot!.label;
      _startTime = widget.timeSlot!.start;
      _endTime = widget.timeSlot!.end;
      _maxMatches = widget.timeSlot!.maxMatches;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.timeSlot == null ? "Thêm khung giờ" : "Sửa khung giờ"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: InputDecoration(
              labelText: "Tên khung giờ",
              border: OutlineInputBorder(),
            ),
          ),
          SizedBox(height: 16.v),
          
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(true),
                  child: Container(
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: appTheme.gray300),
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Từ", style: TextStyle(fontSize: 12.fSize)),
                        Text(_startTime, style: TextStyle(fontSize: 16.fSize)),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16.h),
              Expanded(
                child: InkWell(
                  onTap: () => _selectTime(false),
                  child: Container(
                    padding: EdgeInsets.all(12.h),
                    decoration: BoxDecoration(
                      border: Border.all(color: appTheme.gray300),
                      borderRadius: BorderRadius.circular(4.h),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Đến", style: TextStyle(fontSize: 12.fSize)),
                        Text(_endTime, style: TextStyle(fontSize: 16.fSize)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16.v),
          
          TextField(
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: "Số trận tối đa",
              border: OutlineInputBorder(),
            ),
            controller: TextEditingController(text: _maxMatches.toString()),
            onChanged: (value) {
              _maxMatches = int.tryParse(value) ?? 2;
            },
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

  void _selectTime(bool isStart) async {
    final currentTime = isStart ? _startTime : _endTime;
    final timeParts = currentTime.split(":');
    
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
      ),
    );

    if (picked != null) {
      final timeString = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      setState(() {
        if (isStart) {
          _startTime = timeString;
        } else {
          () {
          _endTime = timeString;
        }
      
        }});
    }
  }

  void _save() {
    if (_labelController.text.isEmpty) return;
    
    final timeSlot = TimeSlot(
      id: widget.timeSlot?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: _labelController.text,
      start: _startTime,
      end: _endTime,
      maxMatches: _maxMatches,
      enabled: widget.timeSlot?.enabled ?? true,
    );
    
    widget.onSave(timeSlot);
    Navigator.of(context).pop();
  }
}
