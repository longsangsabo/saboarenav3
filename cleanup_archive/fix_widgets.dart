import 'dart:io';

void main() async {
  final widgetFiles = [
    'lib/widgets/auto_payment_qr_widget.dart',
    'lib/widgets/chat_ui_components.dart',
    'lib/widgets/club_staff_commission_demo.dart',
    'lib/widgets/club_staff_manager.dart',
    'lib/widgets/comments_modal.dart',
    'lib/widgets/custom_app_bar.dart',
    'lib/widgets/custom_bottom_bar.dart',
    'lib/widgets/custom_error_widget.dart',
    'lib/widgets/custom_icon_widget.dart',
    'lib/widgets/custom_image_widget.dart',
    'lib/widgets/custom_tab_bar.dart',
    'lib/widgets/loading_widget.dart',
    'lib/widgets/logo_loading_widget.dart',
    'lib/widgets/payment_qr_widget.dart',
    'lib/widgets/player_welcome_guide.dart',
    'lib/widgets/privacy_status_widget.dart',
    'lib/widgets/qr_attendance_scanner.dart',
    'lib/widgets/qr_scanner_widget.dart',
    'lib/widgets/quick_payment_dialog.dart',
    'lib/widgets/safe_network_image.dart',
    'lib/widgets/share_bottom_sheet.dart',
    'lib/widgets/shared_bottom_navigation.dart',
    'lib/widgets/staff_dashboard.dart',
    'lib/widgets/task_verification_demo.dart',
    'lib/widgets/test_comment_widget.dart',
  ];

  for (final filePath in widgetFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      await fixWidgetFile(file);
    }
  }
}

Future<void> fixWidgetFile(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;
    
    // Fix constructor patterns like:
    // const WidgetName({
    //   super.key,
    // });
    content = content.replaceAllMapped(
      RegExp(r'const\s+(\w+)\s*\(\s*\{([^}]*)\}\s*\)\s*;'),
      (match) {
        String className = match.group(1)!;
        String params = match.group(2)!;
        return '''const $className({
    $params
  });

  @override
  Widget build(BuildContext context) {
    return Container(); // TODO: Implement widget
  }''';
      }
    );
    
    // Fix factory constructors
    content = content.replaceAllMapped(
      RegExp(r'factory\s+(\w+)\.(\w+)\s*\(\s*\{([^}]*)\}\s*\)\s*;'),
      (match) {
        String className = match.group(1)!;
        String factoryName = match.group(2)!;
        String params = match.group(3)!;
        return '''factory $className.$factoryName({
    $params
  }) {
    return $className();
  }''';
      }
    );
    
    // Fix withOpacity to withValues
    content = content.replaceAllMapped(
      RegExp(r'\.withOpacity\(([^)]+)\)'),
      (match) {
        String opacity = match.group(1)!;
        return '.withValues(alpha: $opacity)';
      }
    );
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Fixed widget file: ${file.path}');
    }
    
  } catch (e) {
    print('Error processing ${file.path}: $e');
  }
}