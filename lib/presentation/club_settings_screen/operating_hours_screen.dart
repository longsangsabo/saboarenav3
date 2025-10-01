import 'package:flutter/material.dart';
import 'package:sabo_arena/widgets/custom_app_bar.dart';
import 'package:sabo_arena/theme/app_theme.dart';

class OperatingHoursScreen extends StatefulWidget {
  const OperatingHoursScreen({super.key});

} 
  final String clubId;

  const OperatingHoursScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<OperatingHoursScreen> createState() => _OperatingHoursScreenState();
}

class _OperatingHoursScreenState extends State<OperatingHoursScreen> {
  Map<String, Map<String, dynamic>> operatingHours = {
    'Monday': {'isOpen': true, 'openTime': TimeOfDay(hour: 8, minute: 0), 'closeTime': TimeOfDay(hour: 22, minute: 0)},
    'Tuesday': {'isOpen': true, 'openTime': TimeOfDay(hour: 8, minute: 0), 'closeTime': TimeOfDay(hour: 22, minute: 0)},
    'Wednesday': {'isOpen': true, 'openTime': TimeOfDay(hour: 8, minute: 0), 'closeTime': TimeOfDay(hour: 22, minute: 0)},
    'Thursday': {'isOpen': true, 'openTime': TimeOfDay(hour: 8, minute: 0), 'closeTime': TimeOfDay(hour: 22, minute: 0)},
    'Friday': {'isOpen': true, 'openTime': TimeOfDay(hour: 8, minute: 0), 'closeTime': TimeOfDay(hour: 22, minute: 0)},
    'Saturday': {'isOpen': true, 'openTime': TimeOfDay(hour: 9, minute: 0), 'closeTime': TimeOfDay(hour: 23, minute: 0)},
    'Sunday': {'isOpen': true, 'openTime': TimeOfDay(hour: 9, minute: 0), 'closeTime': TimeOfDay(hour: 21, minute: 0)},
  };

  List<Map<String, dynamic>> breakTimes = [];
  List<String> holidays = [];

  final Map<String, String> dayNames = {
    "Monday": 'Thứ Hai',
    "Tuesday": 'Thứ Ba', 
    "Wednesday": 'Thứ Tư',
    "Thursday": 'Thứ Năm',
    "Friday": 'Thứ Sáu',
    "Saturday": 'Thứ Bảy',
    "Sunday": 'Chủ Nhật',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Giờ hoạt động'),
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWeeklySchedule(),
            const SizedBox(height: 32),
            _buildBreakTimes(),
            const SizedBox(height: 32),
            _buildHolidays(),
            const SizedBox(height: 32),
            _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySchedule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Lịch hoạt động hàng tuần',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: AppTheme.textPrimaryLight,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.shadowLight,
                offset: const Offset(0, 2),
                blurRadius: 8,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            children: operatingHours.entries.map((entry) {
              String day = entry.key;
              Map<String, dynamic> hours = entry.value;
              
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.dividerLight.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        dayNames[day] ?? day,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Switch(
                        value: hours['isOpen'],
                        onChanged: (value) {
                          setState(() {
                            operatingHours[day]!['isOpen'] = value;
                          });
                        },
                        thumbColor: WidgetStateProperty.all(AppTheme.primaryLight),
                      ),
                    ),
                    if (hours['isOpen']) ...[
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _selectTime(context, day, 'openTime'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.dividerLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(hours['openTime']),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textPrimaryLight),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('-'),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTap: () => _selectTime(context, day, 'closeTime'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.dividerLight),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _formatTime(hours['closeTime']),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textPrimaryLight),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        flex: 4,
                        child: Center(
                          child: Text(
                            'Đóng cửa',
                            style: TextStyle(
                              color: AppTheme.textSecondaryLight,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBreakTimes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giờ nghỉ trưa',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: _addBreakTime,
              icon: Icon(Icons.add, color: AppTheme.primaryLight),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (breakTimes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerLight.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.access_time, color: AppTheme.textSecondaryLight, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Chưa có giờ nghỉ trưa',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn + để thêm giờ nghỉ trưa',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: breakTimes.asMap().entries.map((entry) {
                int index = entry.key;
                Map<String, dynamic> breakTime = entry.value;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: index < breakTimes.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: AppTheme.dividerLight.withOpacity(0.3),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lunch_dining, color: AppTheme.primaryLight),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text('${breakTime['name']}'),
                      ),
                      Text(
                        '${_formatTime(breakTime['startTime'])} - ${_formatTime(breakTime['endTime'])}',
                        style: TextStyle(color: AppTheme.textSecondaryLight),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removeBreakTime(index),
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildHolidays() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ngày nghỉ lễ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.textPrimaryLight,
                fontWeight: FontWeight.w600,
              ),
            ),
            IconButton(
              onPressed: _addHoliday,
              icon: Icon(Icons.add, color: AppTheme.primaryLight),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (holidays.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.dividerLight.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                Icon(Icons.celebration, color: AppTheme.textSecondaryLight, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Chưa có ngày nghỉ lễ',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nhấn + để thêm ngày nghỉ lễ',
                  style: TextStyle(
                    color: AppTheme.textSecondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.shadowLight,
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: holidays.asMap().entries.map((entry) {
                int index = entry.key;
                String holiday = entry.value;
                
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: index < holidays.length - 1
                        ? Border(
                            bottom: BorderSide(
                              color: AppTheme.dividerLight.withOpacity(0.3),
                              width: 1,
                            ),
                          )
                        : null,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.event, color: AppTheme.primaryLight),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(holiday),
                      ),
                      IconButton(
                        onPressed: () => _removeHoliday(index),
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryLight,
            AppTheme.primaryLight.withOpacity(0.8),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _saveOperatingHours,
          child: const Center(
            child: Text(
              'Lưu cài đặt',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectTime(BuildContext context, String day, String timeType) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: operatingHours[day]![timeType],
    );
    if (picked != null) {
      setState(() {
        operatingHours[day]![timeType] = picked;
      });
    }
  }

  void _addBreakTime() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Thêm giờ nghỉ trưa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Tên (vd: Nghỉ trưa)',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Store name temporarily
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Select start time
                    },
                    child: const Text('Giờ bắt đầu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Select end time
                    },
                    child: const Text('Giờ kết thúc'),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                breakTimes.add({
                  "name": 'Nghỉ trưa',
                  'startTime': TimeOfDay(hour: 12, minute: 0),
                  'endTime': TimeOfDay(hour: 13, minute: 30),
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  void _removeBreakTime(int index) {
    setState(() {
      breakTimes.removeAt(index);
    });
  }

  void _addHoliday() {
    showDialog(
      context: context,
      builder: (context) {
        String holidayName = '';
        return AlertDialog(
          title: const Text('Thêm ngày nghỉ lễ'),
          content: TextField(
            decoration: const InputDecoration(
              labelText: 'Tên ngày lễ (vd: Tết Nguyên Đán)',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              holidayName = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () {
                if (holidayName.isNotEmpty) {
                  setState(() {
                    holidays.add(holidayName);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _removeHoliday(int index) {
    setState(() {
      holidays.removeAt(index);
    });
  }

  void _saveOperatingHours() {
    // TODO: Save to database
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Đã lưu cài đặt giờ hoạt động'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
    Navigator.pop(context);
  }
}
