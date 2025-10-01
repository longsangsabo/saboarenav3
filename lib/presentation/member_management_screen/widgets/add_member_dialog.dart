import 'package:flutter/material.dart';
import '../../../models/member_data.dart';

class AddMemberDialog extends StatefulWidget() {
  final String clubId;
  final Function(MemberData) onMemberAdded;

  const AddMemberDialog({
    super.key,
    required this.clubId,
    required this.onMemberAdded,
  });

  @override
  _AddMemberDialogState createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog>
    with TickerProviderStateMixin() {
  late TabController _tabController;
  
  // Form controllers
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _csvController = TextEditingController();
  
  MembershipType _selectedMembershipType = MembershipType.regular;
  bool _isLoading = false;
  final String _selectedTab = 'single'; // single, bulk, invite

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _csvController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(maxHeight: 600),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Thêm thành viên mới',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
            
            // Tab bar
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.person),
                    text: 'Thêm 1 người',
                  ),
                  Tab(
                    icon: Icon(Icons.people),
                    text: 'Thêm nhiều',
                  ),
                  Tab(
                    icon: Icon(Icons.email),
                    text: 'Mời tham gia',
                  ),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSingleMemberTab(),
                  _buildBulkMemberTab(),
                  _buildInviteTab(),
                ],
              ),
            ),
            
            // Action buttons
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: Text('Hủy'),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleAddMember,
                      child: _isLoading
                          ? SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(_getActionButtonText()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSingleMemberTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Username field
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Tên đăng nhập *',
              hintText: 'Nhập tên đăng nhập',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Email field
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              hintText: 'Nhập email (tùy chọn)',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.emailAddress,
          ),
          
          SizedBox(height: 16),
          
          // Name field
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên',
              hintText: 'Nhập họ và tên (tùy chọn)',
              prefixIcon: Icon(Icons.badge),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Phone field
          TextFormField(
            controller: _phoneController,
            decoration: InputDecoration(
              labelText: 'Số điện thoại',
              hintText: 'Nhập số điện thoại (tùy chọn)',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
            keyboardType: TextInputType.phone,
          ),
          
          SizedBox(height: 16),
          
          // Membership type
          Text(
            'Loại thành viên',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            children: MembershipType.values.map((type) {
              return ChoiceChip(
                selected: _selectedMembershipType == type,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMembershipType = type;
                    });
                  }
                },
                label: Text(_getMembershipTypeLabel(type)),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              );
            }).toList(),
          ),
          
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Thành viên sẽ nhận được thông báo mời tham gia câu lạc bộ qua email hoặc trong ứng dụng.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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

  Widget _buildBulkMemberTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thêm nhiều thành viên cùng lúc',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Nhập danh sách thành viên, mỗi dòng một người theo định dạng: username,email,name',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          SizedBox(height: 16),
          
          TextFormField(
            controller: _csvController,
            decoration: InputDecoration(
              labelText: 'Danh sách thành viên',
              hintText: 'user1,user1@email.com,Nguyễn Văn A\nuser2,user2@email.com,Trần Thị B',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              alignLabelWithHint: true,
            ),
            maxLines: 8,
          ),
          
          SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _uploadCSVFile,
                  icon: Icon(Icons.upload_file),
                  label: Text('Tải file CSV'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _downloadTemplate,
                  icon: Icon(Icons.download),
                  label: Text('Tải mẫu'),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.help_outline, size: 16, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'Hướng dẫn định dạng:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• Mỗi dòng là một thành viên\n• Định dạng: username,email,name\n• Email và tên có thể để trống\n• Ví dụ: user1,user1@email.com,Nguyễn Văn A',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mời thành viên tham gia',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          
          SizedBox(height: 8),
          
          Text(
            'Tạo liên kết mời hoặc gửi email mời trực tiếp đến thành viên mới.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          
          SizedBox(height: 24),
          
          // Invite link section
          Container(
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
                    Icon(Icons.link, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Liên kết mời',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'https://saboarena.com/invite/abc123',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _copyInviteLink,
                        icon: Icon(Icons.copy, size: 20),
                        tooltip: 'Sao chép liên kết',
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _generateNewLink,
                        icon: Icon(Icons.refresh),
                        label: Text('Tạo link mới'),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _shareInviteLink,
                        icon: Icon(Icons.share),
                        label: Text('Chia sẻ'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Email invite section
          Container(
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
                    Icon(Icons.email, color: Theme.of(context).colorScheme.primary),
                    SizedBox(width: 8),
                    Text(
                      'Mời qua email',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 12),
                
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Địa chỉ email',
                    hintText: 'Nhập email của thành viên',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                
                SizedBox(height: 12),
                
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Tin nhắn tùy chỉnh (tùy chọn)',
                    hintText: 'Thêm tin nhắn cá nhân...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
                
                SizedBox(height: 12),
                
                ElevatedButton.icon(
                  onPressed: _sendEmailInvite,
                  icon: Icon(Icons.send),
                  label: Text('Gửi lời mời'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 44),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getActionButtonText() {
    switch (_tabController.index) {
      case 0:
        return 'Thêm thành viên';
      case 1:
        return 'Thêm tất cả';
      case 2:
        return 'Gửi lời mời';
      default:
        return 'Thêm';
    }
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

  Future<void> _handleAddMember() async() {
    setState(() => _isLoading = true);
    
    try() {
      // Simulate API call
      await Future.delayed(Duration(seconds: 2));
      
      // Create mock member data based on current tab
      MemberData newMember = _createMockMember();
      
      widget.onMemberAdded(newMember);
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thêm thành viên thành công!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi thêm thành viên!'),
          backgroundColor: Colors.red,
        ),
      );
    } finally() {
      setState(() => _isLoading = false);
    }
  }

  MemberData _createMockMember() {
    final now = DateTime.now();
    return MemberData(
      id: 'new_member_${now.millisecondsSinceEpoch}',
      user: UserInfo(
        id: 'user_${now.millisecondsSinceEpoch}',
        avatar: 'https://images.unsplash.com/photo-1580000000000?w=100&h=100&fit=crop&crop=face',
        name: _nameController.text.isNotEmpty ? _nameController.text : _usernameController.text,
        username: _usernameController.text,
        rank: 'beginner',
        elo: 1000,
        isOnline: false,
      ),
      membershipInfo: MembershipInfo(
        membershipId: 'MB${1000 + now.millisecond}',
        joinDate: now,
        status: 'pending',
        type: _selectedMembershipType.toString().split('.').last,
        autoRenewal: false,
      ),
      activityStats: ActivityStats(
        activityScore: 0,
        winRate: 0.0,
        totalMatches: 0,
        lastActive: now,
        tournamentsJoined: 0,
      ),
    );
  }

  void _uploadCSVFile() {
    // Implementation for CSV file upload
  }

  void _downloadTemplate() {
    // Implementation for downloading CSV template
  }

  void _copyInviteLink() {
    // Implementation for copying invite link
  }

  void _generateNewLink() {
    // Implementation for generating new invite link
  }

  void _shareInviteLink() {
    // Implementation for sharing invite link
  }

  void _sendEmailInvite() {
    // Implementation for sending email invite
  }
}