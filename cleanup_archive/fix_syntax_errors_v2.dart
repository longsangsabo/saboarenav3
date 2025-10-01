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
    String originalContent = content;
    
    // Fix all class declarations with ()
    content = content.replaceAllMapped(
      RegExp(r'class\s+(\w+)\s*\(\)\s*\{'),
      (match) => 'class ${match.group(1)} {'
    );
    
    // Fix enum declarations with ()
    content = content.replaceAllMapped(
      RegExp(r'enum\s+(\w+)\s*\(\)\s*\{'),
      (match) => 'enum ${match.group(1)} {'
    );
    
    // Fix extension declarations with ()
    content = content.replaceAllMapped(
      RegExp(r'extension\s+(\w+)\s+on\s+(\w+)\s*\(\)\s*\{'),
      (match) => 'extension ${match.group(1)} on ${match.group(2)} {'
    );
    
    // Fix mixin declarations with ()
    content = content.replaceAllMapped(
      RegExp(r'with\s+(\w+)\s*\(\)'),
      (match) => 'with ${match.group(1)}'
    );
    
    // Fix }() { patterns
    content = content.replaceAllMapped(
      RegExp(r'\}\s*\(\)\s*\{'),
      (match) => '} {'
    );
    
    // Fix finally() patterns
    content = content.replaceAll('finally()', 'finally');
    
    // Fix specific patterns that remain
    content = content.replaceAll('} {', '} ');
    
    if (content != originalContent) {
      await file.writeAsString(content);
      print('Fixed syntax errors in: ${file.path}');
    }
    
  } catch (e) {
    print('Error processing ${file.path}: $e');
  }
}