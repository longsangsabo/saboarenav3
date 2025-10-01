import 'package:flutter/material.dart';
import 'package:sabo_arena/services/user_service.dart';
import 'package:sabo_arena/models/club.dart';
import 'package:sabo_arena/services/club_service.dart';
import 'package:sabo_arena/core/constants/ranking_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class RankRegistrationScreen extends StatefulWidget {
  const RankRegistrationScreen({super.key});

} 
  final String clubId;

  const RankRegistrationScreen({
    super.key,
    required this.clubId,
  });

  @override
  State<RankRegistrationScreen> createState() => _RankRegistrationScreenState();
}

class _RankRegistrationScreenState extends State<RankRegistrationScreen> {
  final UserService _userService = UserService.instance;
  final ClubService _clubService = ClubService.instance;
  
  Club? _club;
  bool _isLoading = true;
  String? _currentRank;
  bool _hasRankRequest = false;
  Map<String, dynamic>? _pendingRequest;
  
  final _formKey = GlobalKey<FormState>();
  String _selectedRank = 'K'; // Default to first available rank
  final TextEditingController _experienceController = TextEditingController();
  final TextEditingController _achievementsController = TextEditingController();
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _reasonController = TextEditingController();
  
  // Image upload for tournament evidence
  final List<File> _evidenceImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploadingImages = false;
  
  // Verification method selection
  String _verificationMethod = 'evidence'; // 'evidence' or 'test_at_club'

  final List<String> _rankOptions = RankingConstants.RANK_ORDER;
  // Rank descriptions using official constants
  Map<String, String> get _rankDescriptions() {
    final Map<String, String> descriptions = {};
    for (final rank in RankingConstants.RANK_ORDER) {
      final details = RankingConstants.RANK_DETAILS[rank];
      final eloRange = RankingConstants.RANK_ELO_RANGES[rank];
      if (details != null && eloRange != null) {
        final name = details['name'] ?? '';
        final description = details['description'] ?? '';
        final minElo = eloRange['min'] ?? 0;
        final maxElo = eloRange['max'] ?? 0;
        
        descriptions[rank] = '$name - $minElo-$maxElo ELO\n$description';
      }
    }
    return descriptions;
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _experienceController.dispose();
    _achievementsController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final club = await _clubService.getClubById(widget.clubId);
      
      // Check if user has pending rank request for this club
      final pendingRequest = await _userService.getPendingRankRequest(widget.clubId);
      final hasRequest = pendingRequest != null;
      
      // TODO: Load user's current rank in this club 
      final currentRank = null; // await _userService.getUserRankInClub(widget.clubId);
      
      setState(() {
        _club = club;
        _currentRank = currentRank;
        _hasRankRequest = hasRequest;
        _pendingRequest = pendingRequest;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải thông tin: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Image picker methods for tournament evidence
  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        imageQuality: 70,
      );
      
      if (pickedFiles.isNotEmpty) {
        setState(() {
          _evidenceImages.addAll(
            pickedFiles.map((xFile) => File(xFile.path)).toList()
          );
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi chọn ảnh: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _evidenceImages.removeAt(index);
    });
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: Colors.green[700],
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Colors.green[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildVerificationContent() {
    List<Widget> widgets = [];
    
    if (_verificationMethod == 'evidence') {
      widgets.addAll([
        Text(
          'Hình ảnh bằng chứng',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tải lên kết quả thi đấu, bảng xếp hạng, hoặc chứng chỉ từ các giải đấu trong 3-6 tháng gần đây',
                  style: TextStyle(
                    color: Colors.amber[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              OutlinedButton.icon(
                onPressed: _pickImages,
                icon: Icon(Icons.add_photo_alternate_outlined),
                label: Text('Thêm hình ảnh'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              if (_evidenceImages.isNotEmpty) ...[
                SizedBox(height: 16),
                Text(
                  '${_evidenceImages.length} hình ảnh đã chọn',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _evidenceImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              _evidenceImages[index],
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
              if (_isUploadingImages) ...[
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Đang tải hình ảnh...'),
                  ],
                ),
              ],
            ],
          ),
        ),
      ]);
    } else if (_verificationMethod == 'test_at_club') {
      widgets.addAll([
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: Colors.green[700], size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Test hạng tại club',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[800],
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Text(
                'Khi chọn phương thức này:',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green[800],
                ),
              ),
              SizedBox(height: 8),
              _buildBulletPoint('Club sẽ liên hệ với bạn để sắp xếp lịch test'),
              _buildBulletPoint('Bạn sẽ thi đấu trực tiếp với HLV hoặc thành viên có hạng tương đương'),
              _buildBulletPoint('Kết quả test sẽ được đánh giá ngay tại chỗ'),
              _buildBulletPoint('Phí test (nếu có) sẽ được thông báo khi hẹn lịch'),
            ],
          ),
        ),
      ]);
    }
    
    return widgets;
  }

  Future<void> _submitRankRequest() async {
    if (!_formKey.currentState!.validate()) return;

    // Additional validation for evidence method
    if (_verificationMethod == 'evidence' && _evidenceImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng tải lên ít nhất 1 hình ảnh bằng chứng'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload evidence images first if verification method is evidence and images are selected
      List<String> imageUrls = [];
      if (_verificationMethod == 'evidence' && _evidenceImages.isNotEmpty) {
        setState(() => _isUploadingImages = true);
        
        for (File image in _evidenceImages) {
          try {
            final String fileName = 'rank_evidence_${DateTime.now().millisecondsSinceEpoch}_${path.basename(image.path)}';
            final result = await _userService.uploadImage(image, fileName);
            if (result['success'] == true && result['url'] != null) {
              imageUrls.add(result['url']);
            }
          } catch (e) {
            debugPrint('Error uploading image: $e');
          }
        }
        
        setState(() => _isUploadingImages = false);
      }

      // Combine all info into notes
      final notes = '''
Rank mong muốn: $_selectedRank
Lý do xin hạng: ${_reasonController.text}
Phương thức xác nhận: ${_verificationMethod == 'evidence' ? "Upload hình ảnh chứng minh" : 'Test hạng trực tiếp tại club'}
Kinh nghiệm: ${_experienceController.text}
Thành tích: ${_achievementsController.text}
Ghi chú: ${_commentsController.text}
${imageUrls.isNotEmpty ? "\nHình ảnh bằng chứng: ${imageUrls.length} ảnh đã tải lên" : ''}
'''.trim();

      final result = await _userService.requestRankRegistration(
        clubId: widget.clubId,
        notes: notes,
        evidenceUrls: imageUrls,
      );

      setState(() => _isLoading = false);

      if (result['success'] == true) {
        // Reload data to update UI state
        await _loadData();
        // Show success dialog
        _showSuccessDialog(result);
      } else {
        () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Có lỗi xảy ra'),
            backgroundColor: Colors.red,
          ),
        );
      }
    
      }} catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi gửi yêu cầu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Colors.green.shade600,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'Yêu cầu đã được gửi!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Yêu cầu đăng ký rank của bạn đã được gửi thành công. Admin câu lạc bộ sẽ xem xét và phản hồi trong thời gian sớm nhất.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, 
                         color: Colors.blue.shade600, 
                         size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bạn có thể kiểm tra trạng thái yêu cầu bất cứ lúc nào bằng cách quay lại trang này.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog only
                // Stay on current screen to show the updated status
              },
              child: Text(
                'Xem trạng thái',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showRequestHistory() async {
    try {
      final requests = await _userService.getUserRankRequests(); 
      
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Lịch sử yêu cầu đăng ký rank',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Expanded(
                child: requests.isEmpty 
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, 
                               size: 48, 
                               color: Colors.grey[400]),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có yêu cầu nào',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        final request = requests[index];
                        return _buildRequestHistoryItem(request);
                      },
                    ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi khi tải lịch sử: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildRequestHistoryItem(Map<String, dynamic> request) {
    final club = request['club'];
    final status = request['status'] ?? 'unknown';
    final requestTime = request['requested_at'];
    final formattedTime = requestTime != null 
        ? DateTime.parse(requestTime).toLocal().toString().substring(0, 16)
        : 'Không xác định';
    
    Color statusColor;
    String statusText;
    IconData statusIcon;
    
    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusText = 'Chờ duyệt';
        statusIcon = Icons.schedule;
        break;
      case 'approved':
        statusColor = Colors.green;
        statusText = 'Đã duyệt';
        statusIcon = Icons.check_circle;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusText = 'Bị từ chối';
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.grey;
        statusText = 'Không xác định';
        statusIcon = Icons.help_outline;
    }
    
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    club != null ? club['name'] : 'Câu lạc bộ không xác định',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      SizedBox(width: 4),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
              'Thời gian: $formattedTime',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Đăng ký Rank'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey[900],
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _hasRankRequest
              ? _buildExistingRequestView()
              : _currentRank != null
                  ? _buildHasRankView()
                  : _buildRegistrationForm(),
    );
  }

  Widget _buildExistingRequestView() {
    final requestTime = _pendingRequest?['requested_at'];
    final formattedTime = requestTime != null 
        ? DateTime.parse(requestTime).toLocal().toString().substring(0, 16)
        : 'Không xác định';
    
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.orange.shade200, width: 2),
                    ),
                    child: Icon(
                      Icons.schedule,
                      size: 48,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Yêu cầu đang chờ xử lý',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Yêu cầu đăng ký rank của bạn đã được gửi thành công và đang chờ admin câu lạc bộ xét duyệt.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Request details card
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, 
                                 size: 20, 
                                 color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text(
                              'Thông tin yêu cầu',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildInfoRow('Thời gian gửi:', formattedTime),
                        _buildInfoRow('Trạng thái:', 'Chờ duyệt'),
                        _buildInfoRow('Câu lạc bộ:', _club?.name ?? 'Đang tải...'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Action buttons
          Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _loadData(),
                  icon: Icon(Icons.refresh),
                  label: Text('Kiểm tra lại'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _showRequestHistory,
                  icon: Icon(Icons.history),
                  label: Text('Xem lịch sử yêu cầu'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Đóng'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHasRankView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _currentRank!,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Rank hiện tại của bạn',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Bạn đã có rank $_currentRank tại club ${_club?.name}.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Đóng'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Club info
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: _club?.coverImageUrl != null
                        ? NetworkImage(_club!.coverImageUrl!)
                        : null,
                    child: _club?.coverImageUrl == null
                        ? Icon(Icons.sports, size: 30)
                        : null,
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _club?.name ?? 'Club',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Đăng ký rank tại club này',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Rank selection
            Text(
              'Chọn rank mong muốn',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: _rankOptions.map((rank) {
                  final description = _rankDescriptions[rank]!;
                  final parts = description.split('\n');
                  return RadioListTile<String>(
                    title: Text(
                      'Rank $rank',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parts[0], // ELO range part
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        if (parts.length > 1)
                          Text(
                            parts[1], // Skill level part
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                    value: rank,
                    groupValue: _selectedRank,
                    onChanged: (value) {
                      setState(() => _selectedRank = value!);
                    },
                  );
                }).toList(),
              ),
            ),

            SizedBox(height: 24),

            // Reason for requesting this rank
            Text(
              'Lý do xin hạng này',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _reasonController,
              decoration: InputDecoration(
                hintText: 'Vì sao bạn nghĩ mình xứng đáng với hạng $_selectedRank?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng giải thích lý do xin hạng này';
                }
                return null;
              },
            ),

            SizedBox(height: 24),

            // Verification method selection
            Text(
              'Cách thức xác nhận hạng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                children: [
                  RadioListTile<String>(
                    title: Text(
                      'Upload hình ảnh chứng minh',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Tải lên kết quả giải đấu, chứng chỉ, hoặc ảnh chụp thành tích gần đây',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: 'evidence',
                    groupValue: _verificationMethod,
                    onChanged: (value) {
                      setState(() => _verificationMethod = value!);
                    },
                  ),
                  Divider(height: 1),
                  RadioListTile<String>(
                    title: Text(
                      'Test hạng trực tiếp tại club',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      'Hẹn lịch để test hạng trực tiếp với HLV/Admin tại club',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    value: 'test_at_club',
                    groupValue: _verificationMethod,
                    onChanged: (value) {
                      setState(() => _verificationMethod = value!);
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Conditional content based on verification method
            ..._buildVerificationContent(),

            SizedBox(height: 24),

            // Experience
            Text(
              'Kinh nghiệm chơi billiards',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _experienceController,
              decoration: InputDecoration(
                hintText: 'Mô tả về kinh nghiệm chơi billiards của bạn...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Vui lòng mô tả kinh nghiệm của bạn';
                }
                return null;
              },
            ),

            SizedBox(height: 16),

            // Achievements
            Text(
              'Thành tích đạt được (nếu có)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _achievementsController,
              decoration: InputDecoration(
                hintText: 'Các giải thưởng, thành tích nổi bật...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),

            SizedBox(height: 16),

            // Comments
            Text(
              'Ghi chú thêm',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _commentsController,
              decoration: InputDecoration(
                hintText: 'Thông tin bổ sung khác...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              maxLines: 2,
            ),



            SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isLoading || _hasRankRequest) ? null : _submitRankRequest,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: _hasRankRequest ? Colors.grey : null,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        _hasRankRequest ? "Đã gửi yêu cầu" : 'Gửi yêu cầu đăng ký',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),

            SizedBox(height: 16),

            // Info note
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[600],
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Yêu cầu đăng ký rank sẽ được admin của club xem xét và phê duyệt. Bạn sẽ nhận được thông báo khi có kết quả.',
                      style: TextStyle(
                        color: Colors.blue[800],
                        fontSize: 12,
                      ),
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
}
