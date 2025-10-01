import 'package:flutter/material.dart';

class OperatingHoursEditor extends StatefulWidget {
  const OperatingHoursEditor({super.key});

} 
  final Map<String, Map<String, String>>? initialHours;
  final Function(Map<String, Map<String, String>>) onHoursChanged;

  const OperatingHoursEditor({
    super.key,
    this.initialHours,
    required this.onHoursChanged,
  });

  @override
  State<OperatingHoursEditor> createState() => _OperatingHoursEditorState();
}

class _OperatingHoursEditorState extends State<OperatingHoursEditor> {
  Map<String, Map<String, String>> _operatingHours = {};

  final List<String> _daysOfWeek = [
    'Thứ 2',
    'Thứ 3', 
    'Thứ 4',
    'Thứ 5',
    'Thứ 6',
    'Thứ 7',
    'Chủ nhật',
  ];

  @override
  void initState() {
    super.initState();
    _operatingHours = widget.initialHours ?? {};
    // Initialize with default values if empty
    if (_operatingHours.isEmpty) {
      for (String day in _daysOfWeek) {
        _operatingHours[day] = {
          "open": '08:00',
          "close": '22:00',
          "isOpen": 'true',
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Giờ hoạt động',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: _daysOfWeek.map((day) => _buildDayRow(day)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildDayRow(String day) {
    final dayData = _operatingHours[day] ?? {
      "open": '08:00',
      "close": '22:00', 
      "isOpen": 'true',
    };
    
    final isOpen = dayData['isOpen'] == 'true';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              day,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: (value) {
              setState(() {
                _operatingHours[day] = {
                  ..._operatingHours[day]!,
                  'isOpen': value.toString(),
                };
              });
              widget.onHoursChanged(_operatingHours);
            },
          ),
          const SizedBox(width: 16),
          if (isOpen) ...[
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: dayData['open'],
                      decoration: const InputDecoration(
                        labelText: 'Mở cửa',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        _operatingHours[day] = {
                          ..._operatingHours[day]!,
                          'open': value,
                        };
                        widget.onHoursChanged(_operatingHours);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: dayData['close'],
                      decoration: const InputDecoration(
                        labelText: 'Đóng cửa',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        _operatingHours[day] = {
                          ..._operatingHours[day]!,
                          'close': value,
                        };
                        widget.onHoursChanged(_operatingHours);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Expanded(
              child: Text(
                'Nghỉ',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
