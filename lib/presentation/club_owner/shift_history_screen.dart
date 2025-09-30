import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_models.dart';
import '../../services/mock_shift_reporting_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ShiftHistoryScreen extends StatefulWidget {
  final String clubId;

  const ShiftHistoryScreen({
    Key? key,
    required this.clubId,
  }) : super(key: key);

  @override
  State<ShiftHistoryScreen> createState() => _ShiftHistoryScreenState();
}

class _ShiftHistoryScreenState extends State<ShiftHistoryScreen> {
  final MockShiftReportingService _shiftService = MockShiftReportingService();
  
  bool _isLoading = true;
  String? _error;
  List<ShiftReport> _reports = [];
  String _selectedStatus = 'all';
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _loadShiftHistory();
  }

  Future<void> _loadShiftHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final reports = await _shiftService.getClubShiftReports(
        widget.clubId,
        startDate: _selectedDateRange?.start,
        endDate: _selectedDateRange?.end,
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );

      setState(() {
        _reports = reports;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
    );

    if (range != null) {
      setState(() {
        _selectedDateRange = range;
      });
      _loadShiftHistory();
    }
  }

  void _filterByStatus(String status) {
    setState(() {
      _selectedStatus = status;
    });
    _loadShiftHistory();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải lịch sử ca...');
    }

    if (_error != null) {
      return ErrorWidget(
        message: _error!,
        onRetry: _loadShiftHistory,
      );
    }

    return Column(
      children: [
        // Filter controls
        _buildFilterControls(),
        
        // Reports list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadShiftHistory,
            child: _reports.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _reports.length,
                    itemBuilder: (context, index) {
                      final report = _reports[index];
                      return _buildReportCard(report);
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Status filter
          Row(
            children: [
              const Text('Trạng thái: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildStatusChip('all', 'Tất cả'),
                      const SizedBox(width: 8),
                      _buildStatusChip('draft', 'Nháp'),
                      const SizedBox(width: 8),
                      _buildStatusChip('submitted', 'Đã gửi'),
                      const SizedBox(width: 8),
                      _buildStatusChip('approved', 'Đã duyệt'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Date range filter
          Row(
            children: [
              const Text('Thời gian: ', style: TextStyle(fontWeight: FontWeight.bold)),
              Expanded(
                child: InkWell(
                  onTap: _selectDateRange,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.date_range, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          _selectedDateRange != null
                              ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                              : 'Chọn khoảng thời gian',
                          style: TextStyle(
                            color: _selectedDateRange != null ? Colors.black : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_selectedDateRange != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _selectedDateRange = null;
                    });
                    _loadShiftHistory();
                  },
                  icon: const Icon(Icons.clear, size: 20),
                  tooltip: 'Xóa bộ lọc',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, String label) {
    final isSelected = _selectedStatus == status;
    
    return GestureDetector(
      onTap: () => _filterByStatus(status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.indigo : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử ca làm việc',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Hoàn thành một vài ca để xem lịch sử tại đây',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard(ShiftReport report) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final dateFormatter = DateFormat('dd/MM/yyyy');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(report.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(report.status),
                    style: TextStyle(
                      color: _getStatusColor(report.status),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  dateFormatter.format(report.createdAt),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Financial summary
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Doanh Thu',
                    formatter.format(report.totalRevenue),
                    Icons.trending_up,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Chi Phí',
                    formatter.format(report.totalExpenses),
                    Icons.trending_down,
                    Colors.red,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Lợi Nhuận',
                    formatter.format(report.netProfit),
                    Icons.account_balance_wallet,
                    report.netProfit >= 0 ? Colors.blue : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Performance indicators
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem('Bàn phục vụ', '${report.tablesServed}'),
                ),
                Expanded(
                  child: _buildMetricItem('Tỉ lệ LN', '${report.profitMargin.toStringAsFixed(1)}%'),
                ),
                Expanded(
                  child: _buildMetricItem('Hiệu suất', report.performanceRating),
                ),
              ],
            ),
            
            // Cash discrepancy warning
            if (report.hasCashDiscrepancy) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  border: Border.all(color: Colors.orange.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.orange.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Chênh lệch tiền mặt: ${formatter.format(report.cashVariance)}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.grey;
      case 'submitted':
        return Colors.orange;
      case 'reviewed':
        return Colors.blue;
      case 'approved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'draft':
        return 'NHÁP';
      case 'submitted':
        return 'ĐÃ GỬI';
      case 'reviewed':
        return 'ĐANG DUYỆT';
      case 'approved':
        return 'ĐÃ DUYỆT';
      default:
        return status.toUpperCase();
    }
  }
}