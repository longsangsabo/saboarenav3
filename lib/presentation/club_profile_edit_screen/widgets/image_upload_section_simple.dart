import 'package:flutter/material.dart';

class ImageUploadSection extends StatefulWidget {
  const ImageUploadSection({super.key});

} 
  final String coverImageUrl;
  final String logoImageUrl;
  final Function(String) onCoverChanged;
  final Function(String) onLogoChanged;

  const ImageUploadSection({
    super.key,
    required this.coverImageUrl,
    required this.logoImageUrl,
    required this.onCoverChanged,
    required this.onLogoChanged,
  });

  @override
  State<ImageUploadSection> createState() => _ImageUploadSectionState();
}

class _ImageUploadSectionState extends State<ImageUploadSection> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hình ảnh club',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 8),
              Text(
                'Cover Photo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  // TODO: Implement image picker
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tính năng upload ảnh đang được phát triển')),
                  );
                },
                child: const Text('Chọn ảnh'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: 120,
          width: 120,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.business,
                size: 32,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 4),
              Text(
                'Logo',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
