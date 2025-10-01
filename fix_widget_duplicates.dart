import 'dart:io';

void main() async {
  await fixWidgetFile('lib/widgets/custom_error_widget.dart');
  await fixWidgetFile('lib/widgets/custom_image_widget.dart');
  await fixWidgetFile('lib/widgets/custom_icon_widget.dart');
}

Future<void> fixWidgetFile(String filePath) async {
  final file = File(filePath);
  if (!await file.exists()) return;

  try {
    String content = await file.readAsString();
    
    // Remove duplicate class declarations and constructors
    content = removeDuplicateClassDeclarations(content);
    content = removeDuplicateConstructors(content);
    content = removeDuplicateMethods(content);
    
    await file.writeAsString(content);
    print('Fixed widget structure: $filePath');
    
  } catch (e) {
    print('Error processing $filePath: $e');
  }
}

String removeDuplicateClassDeclarations(String content) {
  final lines = content.split('\n');
  final result = <String>[];
  final seenClasses = <String>{};
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final classMatch = RegExp(r'class\s+(\w+)\s+extends').firstMatch(line);
    
    if (classMatch != null) {
      final className = classMatch.group(1)!;
      if (seenClasses.contains(className)) {
        // Skip duplicate class - find its closing brace
        int braceCount = 0;
        for (int j = i; j < lines.length; j++) {
          if (lines[j].contains('{')) braceCount++;
          if (lines[j].contains('}')) braceCount--;
          if (braceCount == 0 && j > i) {
            i = j; // Skip to end of duplicate class
            break;
          }
        }
        continue;
      }
      seenClasses.add(className);
    }
    
    result.add(line);
  }
  
  return result.join('\n');
}

String removeDuplicateConstructors(String content) {
  final lines = content.split('\n');
  final result = <String>[];
  final seenConstructors = <String>{};
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final constructorMatch = RegExp(r'const\s+(\w+)\s*\(').firstMatch(line);
    
    if (constructorMatch != null) {
      final constructorName = constructorMatch.group(1)!;
      if (seenConstructors.contains(constructorName)) {
        // Skip duplicate constructor
        while (i < lines.length && !lines[i].contains('});')) {
          i++;
        }
        if (i < lines.length) i++; // Skip the }); line too
        continue;
      }
      seenConstructors.add(constructorName);
    }
    
    result.add(line);
  }
  
  return result.join('\n');
}

String removeDuplicateMethods(String content) {
  final lines = content.split('\n');
  final result = <String>[];
  final seenMethods = <String>{};
  
  for (int i = 0; i < lines.length; i++) {
    final line = lines[i];
    final methodMatch = RegExp(r'Widget\s+(\w+)\s*\(').firstMatch(line);
    
    if (methodMatch != null) {
      final methodName = methodMatch.group(1)!;
      if (seenMethods.contains(methodName)) {
        // Skip duplicate method - find its closing brace
        int braceCount = 0;
        for (int j = i; j < lines.length; j++) {
          if (lines[j].contains('{')) braceCount++;
          if (lines[j].contains('}')) braceCount--;
          if (braceCount == 0 && j > i) {
            i = j; // Skip to end of duplicate method
            break;
          }
        }
        continue;
      }
      seenMethods.add(methodName);
    }
    
    result.add(line);
  }
  
  return result.join('\n');
}