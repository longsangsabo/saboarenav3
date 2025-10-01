import 'dart:io';

/// Script to replace all print() statements with debugPrint() in Flutter project
/// This fixes the "avoid_print" lint warnings
void main() async {
  print('🔧 Starting print() to debugPrint() replacement...\n');
  
  final libDir = Directory('lib');
  if (!libDir.existsSync()) {
    print('❌ lib directory not found!');
    return;
  }

  int totalFiles = 0;
  int modifiedFiles = 0;
  int totalReplacements = 0;

  await processDirectory(libDir, (file, replacements) {
    totalFiles++;
    if (replacements > 0) {
      modifiedFiles++;
      totalReplacements += replacements;
      print('✅ ${file.path}: $replacements replacements');
    }
  });

  print('\n📊 Summary:');
  print('   Total files processed: $totalFiles');
  print('   Files modified: $modifiedFiles');
  print('   Total replacements: $totalReplacements');
  print('\n🎉 Replacement completed!');
}

Future<void> processDirectory(Directory dir, Function(File, int) onFileProcessed) async {
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      final replacements = await processFile(entity);
      onFileProcessed(entity, replacements);
    }
  }
}

Future<int> processFile(File file) async {
  try {
    String content = await file.readAsString();
    final originalContent = content;
    
    // Add debugPrint import if not present and we have print statements
    if (content.contains('print(') && !content.contains('debugPrint')) {
      final lines = content.split('\n');
      int importIndex = -1;
      
      // Find the last import line
      for (int i = 0; i < lines.length; i++) {
        if (lines[i].trimLeft().startsWith('import ')) {
          importIndex = i;
        }
      }
      
      // Add debugPrint import after other imports
      if (importIndex >= 0) {
        lines.insert(importIndex + 1, "import 'package:flutter/foundation.dart';");
        content = lines.join('\n');
      }
    }
    
    // Replace print( with debugPrint(
    int replacements = 0;
    while (content.contains('print(')) {
      content = content.replaceFirst('print(', 'debugPrint(');
      replacements++;
    }
    
    // Only write if content changed
    if (content != originalContent) {
      await file.writeAsString(content);
      return replacements;
    }
    
    return 0;
  } catch (e) {
    print('❌ Error processing ${file.path}: $e');
    return 0;
  }
}