#!/usr/bin/env python3
import os
import re

def fix_color_methods(directory):
    """Fix all .withValues(alpha: X) to .withOpacity(X) in Dart files"""
    dart_files = []
    
    # Find all .dart files
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    print(f"Found {len(dart_files)} Dart files")
    
    fixed_count = 0
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Replace .withValues(alpha: X) with .withOpacity(X)
            pattern = r'\.withValues\(alpha:\s*([0-9.]+)\)'
            replacement = r'.withOpacity(\1)'
            
            new_content = re.sub(pattern, replacement, content)
            
            if new_content != content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(new_content)
                print(f"Fixed: {file_path}")
                fixed_count += 1
                
        except Exception as e:
            print(f"Error processing {file_path}: {e}")
    
    print(f"Fixed {fixed_count} files")

if __name__ == "__main__":
    fix_color_methods("/workspaces/saboarenav3/lib")