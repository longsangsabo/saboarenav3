import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/user_profile.dart';
import '../../core/utils/rank_migration_helper.dart';

class RankChangeRequestDialog extends StatefulWidget {
  const RankChangeRequestDialog({super.key});

} 
  final UserProfile userProfile;
  final VoidCallback? onRequestSubmitted;

  const RankChangeRequestDialog({
    super.key,
    required this.userProfile,
    this.onRequestSubmitted,
  });

  @override
  State<RankChangeRequestDialog> createState() =>
      _RankChangeRequestDialogState();
}

class _RankChangeRequestDialogState extends State<RankChangeRequestDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  
  String? _selectedNewRank;
  final List<String> _evidenceFiles = [];
  bool _isSubmitting = false;

  // Danh sách hạng có thể chọn - Sử dụng từ migration helper
  late final List<String> _availableRanks;

  @override
  void initState() {
    super.initState();
    _availableRanks = RankMigrationHelper.getAllNewRankNames();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_vert, color: Colors.blue.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Yêu cầu thay đổi hạng',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Current rank info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.emoji_events, color: Colors.orange.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hạng hiện tại',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        Text(
                          RankMigrationHelper.getNewDisplayName(widget.userProfile.rank),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New rank selection
                      const Text(
                        'Hạng mong muốn *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedNewRank,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, 
                            vertical: 12,
                          ),
                        ),
                        items: _availableRanks
                            .where((rank) => rank != widget.userProfile.rank)
                            .map((rank) => DropdownMenuItem(
                                  value: rank,
                                  child: Text(RankMigrationHelper.getNewDisplayName(rank)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedNewRank = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng chọn hạng mong muốn';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Reason text field
                      const Text(
                        'Lý do yêu cầu thay đổi *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _reasonController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: 'Ví dụ: Tôi đã có nhiều kinh nghiệm thi đấu và đạt được kết quả tốt trong các giải gần đây...',
                          contentPadding: const EdgeInsets.all(16),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Vui lòng nhập lý do yêu cầu thay đổi';
                          }
                          if (value.trim().length < 20) {
                            return 'Lý do phải có ít nhất 20 ký tự';
                          }
                          return null;
                        },
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Evidence section
                      const Text(
                        'Bằng chứng (tuỳ chọn)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Đính kèm hình ảnh hoặc video chứng minh trình độ của bạn',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Evidence upload buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImageFromGallery,
                              icon: const Icon(Icons.photo_library),
                              label: const Text('Chọn ảnh'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _pickImageFromCamera,
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Chụp ảnh'),
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Evidence files list
                      if (_evidenceFiles.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tệp đã chọn (${_evidenceFiles.length}):',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...(_evidenceFiles.map((file) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.attachment,
                                          size: 16,
                                          color: Colors.blue.shade600,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            file.split('/').last,
                                            style: const TextStyle(fontSize: 14),
                                          ),
                                        ),
                                        IconButton(
                                          onPressed: () => _removeEvidence(file),
                                          icon: Icon(
                                            Icons.remove_circle,
                                            size: 20,
                                            color: Colors.red.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ))),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    child: const Text('Huỷ'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Gửi yêu cầu',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _evidenceFiles.add(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chọn ảnh: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.camera);
      
      if (image != null) {
        setState(() {
          _evidenceFiles.add(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Không thể chụp ảnh: $e');
    }
  }

  void _removeEvidence(String filePath) {
    setState(() {
      _evidenceFiles.remove(filePath);
    });
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // TODO: Implement API call to submit rank change request
      // final response = await _rankService.submitRankChangeRequest(
      //   currentRank: widget.userProfile.rank,
      //   requestedRank: _selectedNewRank!,
      //   reason: _reasonController.text.trim(),
      //   evidenceFiles: _evidenceFiles,
      // );

      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        Navigator.of(context).pop();
        _showSuccessSnackBar();
        widget.onRequestSubmitted?.call();
      }
    } catch (e) {
      _showErrorSnackBar('Không thể gửi yêu cầu: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Yêu cầu thay đổi hạng đã được gửi thành công! Câu lạc bộ sẽ xem xét trong thời gian sớm nhất.',
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
