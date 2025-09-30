import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/shift_models.dart';
import '../../services/shift_reporting_service.dart';
import '../../services/mock_shift_reporting_service.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/error_widget.dart';

class ActiveShiftScreen extends StatefulWidget {
  final ShiftSession shiftSession;
  final VoidCallback onShiftEnded;

  const ActiveShiftScreen({
    Key? key,
    required this.shiftSession,
    required this.onShiftEnded,
  }) : super(key: key);

  @override
  State<ActiveShiftScreen> createState() => _ActiveShiftScreenState();
}

class _ActiveShiftScreenState extends State<ActiveShiftScreen>
    with TickerProviderStateMixin {
  final MockShiftReportingService _shiftService = MockShiftReportingService();
  
  late TabController _tabController;
  bool _isLoading = false;
  String? _error;
  
  List<ShiftTransaction> _transactions = [];
  List<ShiftInventory> _inventory = [];
  List<ShiftExpense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadShiftData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShiftData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final results = await Future.wait([
        _shiftService.getShiftTransactions(widget.shiftSession.id),
        _shiftService.getShiftInventory(widget.shiftSession.id),
        _shiftService.getShiftExpenses(widget.shiftSession.id),
      ]);

      setState(() {
        _transactions = results[0] as List<ShiftTransaction>;
        _inventory = results[1] as List<ShiftInventory>;
        _expenses = results[2] as List<ShiftExpense>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _endShift() async {
    try {
      final result = await showDialog<double>(
        context: context,
        builder: (context) => _EndShiftDialog(),
      );

      if (result != null) {
        await _shiftService.endShift(
          widget.shiftSession.id,
          closingCash: result,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ca làm việc đã kết thúc thành công!'),
            backgroundColor: Colors.green,
          ),
        );

        widget.onShiftEnded();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi kết thúc ca: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingWidget(message: 'Đang tải dữ liệu ca...');
    }

    if (_error != null) {
      return ErrorWidget(
        message: _error!,
        onRetry: _loadShiftData,
      );
    }

    return Column(
      children: [
        // Shift header
        _buildShiftHeader(),
        
        // Tab bar
        TabBar(
          controller: _tabController,
          labelColor: Colors.indigo,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.indigo,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Tổng Quan'),
            Tab(icon: Icon(Icons.receipt), text: 'Giao Dịch'),
            Tab(icon: Icon(Icons.inventory), text: 'Kho'),
            Tab(icon: Icon(Icons.money_off), text: 'Chi Phí'),
          ],
        ),
        
        // Tab content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(),
              _buildTransactionsTab(),
              _buildInventoryTab(),
              _buildExpensesTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShiftHeader() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final timeFormatter = DateFormat('HH:mm dd/MM/yyyy');
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade600, Colors.indigo.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.circle, color: Colors.white, size: 8),
                    SizedBox(width: 6),
                    Text(
                      'ĐANG HOẠT ĐỘNG',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _endShift,
                icon: const Icon(Icons.stop_circle, color: Colors.white),
                tooltip: 'Kết thúc ca',
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Text(
            'Ca làm việc ${widget.shiftSession.shiftDate.day}/${widget.shiftSession.shiftDate.month}/${widget.shiftSession.shiftDate.year}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          Text(
            'Bắt đầu: ${widget.shiftSession.actualStartTime != null ? timeFormatter.format(widget.shiftSession.actualStartTime!) : 'Chưa bắt đầu'}',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Quick stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStat(
                  'Doanh Thu',
                  formatter.format(widget.shiftSession.totalRevenue),
                  Icons.trending_up,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickStat(
                  'Tiền Mặt',
                  formatter.format(widget.shiftSession.cashRevenue),
                  Icons.money,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildQuickStat(
                  'Giao Dịch',
                  '${_transactions.length}',
                  Icons.receipt_long,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return RefreshIndicator(
      onRefresh: _loadShiftData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Revenue breakdown
            _buildSectionCard(
              'Phân Tích Doanh Thu',
              Icons.analytics,
              [
                _buildRevenueBreakdown(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Payment methods
            _buildSectionCard(
              'Phương Thức Thanh Toán',
              Icons.payment,
              [
                _buildPaymentMethodBreakdown(),
              ],
            ),
            const SizedBox(height: 16),
            
            // Recent activity
            _buildSectionCard(
              'Hoạt Động Gần Đây',
              Icons.history,
              [
                _buildRecentActivity(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.indigo),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBreakdown() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    final totalExpenses = _expenses.fold(0.0, (sum, expense) => sum + expense.amount);
    final netProfit = widget.shiftSession.totalRevenue - totalExpenses;
    
    return Column(
      children: [
        _buildStatRow('Tổng Doanh Thu', formatter.format(widget.shiftSession.totalRevenue), Colors.green),
        _buildStatRow('Tổng Chi Phí', formatter.format(totalExpenses), Colors.red),
        const Divider(),
        _buildStatRow('Lợi Nhuận', formatter.format(netProfit), netProfit >= 0 ? Colors.blue : Colors.red, bold: true),
      ],
    );
  }

  Widget _buildPaymentMethodBreakdown() {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Column(
      children: [
        _buildStatRow('Tiền Mặt', formatter.format(widget.shiftSession.cashRevenue), Colors.green),
        _buildStatRow('Thẻ', formatter.format(widget.shiftSession.cardRevenue), Colors.blue),
        _buildStatRow('Chuyển Khoản', formatter.format(widget.shiftSession.digitalRevenue), Colors.purple),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final recentTransactions = _transactions.take(5).toList();
    
    if (recentTransactions.isEmpty) {
      return const Text('Chưa có giao dịch nào');
    }
    
    return Column(
      children: recentTransactions.map((transaction) {
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: transaction.isRevenue ? Colors.green : Colors.red,
            child: Icon(
              transaction.isRevenue ? Icons.add : Icons.remove,
              color: Colors.white,
            ),
          ),
          title: Text(transaction.description),
          subtitle: Text(DateFormat('HH:mm').format(transaction.recordedAt)),
          trailing: Text(
            NumberFormat.currency(locale: 'vi_VN', symbol: '₫').format(transaction.amount),
            style: TextStyle(
              color: transaction.isRevenue ? Colors.green : Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      children: [
        // Add transaction button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddTransactionDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Giao Dịch'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Transactions list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadShiftData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _transactions.length,
              itemBuilder: (context, index) {
                final transaction = _transactions[index];
                return _buildTransactionCard(transaction);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(ShiftTransaction transaction) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: transaction.isRevenue ? Colors.green : Colors.red,
          child: Icon(
            transaction.isRevenue ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${transaction.category} • ${transaction.paymentMethod}'),
            if (transaction.tableNumber != null)
              Text('Bàn ${transaction.tableNumber}'),
            Text(DateFormat('HH:mm dd/MM').format(transaction.recordedAt)),
          ],
        ),
        trailing: Text(
          formatter.format(transaction.amount),
          style: TextStyle(
            color: transaction.isRevenue ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Column(
      children: [
        // Add inventory button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddInventoryDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Hàng Hóa'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Inventory list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadShiftData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _inventory.length,
              itemBuilder: (context, index) {
                final item = _inventory[index];
                return _buildInventoryCard(item);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryCard(ShiftInventory item) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.itemName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    item.category.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: _buildInventoryStat('Đầu ca', '${item.openingStock} ${item.unit}'),
                ),
                Expanded(
                  child: _buildInventoryStat('Đã bán', '${item.totalSold} ${item.unit}'),
                ),
                Expanded(
                  child: _buildInventoryStat('Hỏng', '${item.stockWasted} ${item.unit}'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Doanh thu: ${formatter.format(item.revenueGenerated)}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (item.unitPrice != null)
                  Text(
                    'Giá: ${formatter.format(item.unitPrice!)}/${item.unit}',
                    style: const TextStyle(color: Colors.grey),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesTab() {
    return Column(
      children: [
        // Add expense button
        Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: _showAddExpenseDialog,
            icon: const Icon(Icons.add),
            label: const Text('Thêm Chi Phí'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        
        // Expenses list
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadShiftData,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _expenses.length,
              itemBuilder: (context, index) {
                final expense = _expenses[index];
                return _buildExpenseCard(expense);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(ShiftExpense expense) {
    final formatter = NumberFormat.currency(locale: 'vi_VN', symbol: '₫');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: expense.isApproved ? Colors.green : Colors.orange,
          child: Icon(
            expense.isApproved ? Icons.check : Icons.pending,
            color: Colors.white,
          ),
        ),
        title: Text(expense.description),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${expense.expenseType.toUpperCase()} • ${expense.paymentMethod}'),
            if (expense.vendorName != null)
              Text('Nhà cung cấp: ${expense.vendorName}'),
            Text(DateFormat('HH:mm dd/MM').format(expense.recordedAt)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter.format(expense.amount),
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            if (!expense.isApproved && expense.needsApproval)
              const Text(
                'Cần duyệt',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  // Dialog methods would go here...
  void _showAddTransactionDialog() {
    // Implementation for adding transaction
  }

  void _showAddInventoryDialog() {
    // Implementation for adding inventory
  }

  void _showAddExpenseDialog() {
    // Implementation for adding expense
  }
}

class _EndShiftDialog extends StatefulWidget {
  @override
  State<_EndShiftDialog> createState() => _EndShiftDialogState();
}

class _EndShiftDialogState extends State<_EndShiftDialog> {
  final _closingCashController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _closingCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Kết Thúc Ca Làm Việc'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Vui lòng nhập số tiền mặt cuối ca để hoàn tất báo cáo.'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _closingCashController,
              decoration: const InputDecoration(
                labelText: 'Tiền mặt cuối ca (₫)',
                prefixIcon: Icon(Icons.money),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Vui lòng nhập số tiền cuối ca';
                }
                if (double.tryParse(value!) == null) {
                  return 'Số tiền không hợp lệ';
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop(context, double.parse(_closingCashController.text));
            }
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Kết Thúc Ca'),
        ),
      ],
    );
  }
}