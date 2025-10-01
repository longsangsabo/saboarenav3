import 'dart:io';

void main() async {
  final criticalFiles = [
    'lib/services/tournament_cache_service.dart',
    'lib/services/tournament_cache_service_complete.dart', 
    'lib/models/match.dart',
    'lib/services/supabase_service.dart',
    'lib/routes/app_routes.dart',
  ];

  for (final filePath in criticalFiles) {
    final file = File(filePath);
    if (await file.exists()) {
      await fixCriticalErrors(file);
    }
  }
}

Future<void> fixCriticalErrors(File file) async {
  try {
    String content = await file.readAsString();
    String originalContent = content;
    
    // Fix Map literal syntax issues caused by cleanup
    content = content.replaceAllMapped(
      RegExp(r"(\s+)'([^']+)':\s*([^,\n]+),\s*"),
      (match) {
        String key = match.group(2)!;
        String value = match.group(3)!;
        return '      \'$key\': $value,\n';
      }
    );
    
    // Fix return Map syntax
    content = content.replaceAllMapped(
      RegExp(r'return\(\)\s*\{([^}]+)\}'),
      (match) {
        String mapContent = match.group(1)!;
        return 'return {\n$mapContent    }';
      }
    );
    
    // Fix method body issues
    content = content.replaceAll('async() {', 'async {');
    content = content.replaceAll('try() {', 'try {');
    content = content.replaceAll('} finally() {', '} finally {');
    
    // Fix missing return statements in Map functions
    if (content.contains('Future<Map<String, int>>') && 
        !content.contains('return {')) {
      content = content.replaceAll(
        RegExp(r'(\s+)\'([^\']+)\': ([^,\n]+),\n(\s+)\'([^\']+)\': ([^,\n]+),\n(\s+)\'([^\']+)\': ([^,\n]+),'),
        (match) => '    return {\n      \'${match.group(2)}\': ${match.group(3)},\n      \'${match.group(5)}\': ${match.group(6)},\n      \'${match.group(8)}\': ${match.group(9)},\n    };'
      );
    }
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Fixed critical errors in: ${file.path}');
    }
    
  } catch (e) {
    print('Error processing ${file.path}: $e');
  }
}