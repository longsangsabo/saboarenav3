import 'dart:io';

void main() async {
  final libDir = Directory('lib');
  
  await for (final entity in libDir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await fixSyntaxErrors(entity);
    }
  }
}

Future<void> fixSyntaxErrors(File file) async {
  try {
    String content = await file.readAsString();
    bool changed = false;
    
    // Fix common syntax errors
    final fixes = [
      // Fix class declarations with ()
      RegExp(r'class\s+\w+\s+extends\s+\w+\(\)\s*\{'),
      RegExp(r'class\s+\w+\s+with\s+\w+\(\)\s*\{'),
      RegExp(r'enum\s+\w+\(\)\s*\{'),
      RegExp(r'extension\s+\w+\s+on\s+\w+\(\)\s*\{'),
      
      // Fix async method declarations
      RegExp(r'async\(\)\s*\{'),
      RegExp(r'try\(\)\s*\{'),
      
      // Fix closing braces with ()
      RegExp(r'\}\(\)\s*\{'),
    ];
    
    String originalContent = content;
    
    // Fix class/enum/extension declarations
    content = content.replaceAllMapped(
      RegExp(r'(class\s+\w+\s+extends\s+\w+)\(\)(\s*\{)'),
      (match) => '${match.group(1)}${match.group(2)}'
    );
    
    content = content.replaceAllMapped(
      RegExp(r'(class\s+\w+\s+with\s+\w+)\(\)(\s*\{)'),
      (match) => '${match.group(1)}${match.group(2)}'
    );
    
    content = content.replaceAllMapped(
      RegExp(r'(enum\s+\w+)\(\)(\s*\{)'),
      (match) => '${match.group(1)}${match.group(2)}'
    );
    
    content = content.replaceAllMapped(
      RegExp(r'(extension\s+\w+\s+on\s+\w+)\(\)(\s*\{)'),
      (match) => '${match.group(1)}${match.group(2)}'
    );
    
    // Fix async methods
    content = content.replaceAll('async()', 'async');
    content = content.replaceAll('try()', 'try');
    
    // Fix closing braces
    content = content.replaceAll('}()', '}');
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Fixed syntax errors in: ${file.path}');
      changed = true;
    }
    
  } catch (e) {
    print('Error processing ${file.path}: $e');
  }
}