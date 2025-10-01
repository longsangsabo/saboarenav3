#!/usr/bin/env python3
import os
import re

def fix_sizer_in_file(filepath):
    """Fix Sizer usage in a single file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Remove Sizer import
    content = re.sub(r"import 'package:sizer/sizer\.dart';\n", '', content)
    
    # Replace common Sizer patterns with fixed values
    replacements = {
        # Size patterns - replace with reasonable fixed values
        r'(\d+)\.w': r'\1.0',  # width
        r'(\d+)\.h': r'\1.0',  # height 
        r'(\d+)\.sp': r'\1.0', # font size
        
        # Handle decimal values
        r'(\d+\.\d+)\.w': r'\1',
        r'(\d+\.\d+)\.h': r'\1', 
        r'(\d+\.\d+)\.sp': r'\1',
        
        # Convert EdgeInsets with .w/.h to fixed values
        r'EdgeInsets\.all\((\d+)\.0\)': r'const EdgeInsets.all(\1)',
        r'EdgeInsets\.symmetric\(horizontal: (\d+)\.0, vertical: (\d+)\.0\)': r'const EdgeInsets.symmetric(horizontal: \1, vertical: \2)',
        r'EdgeInsets\.only\(([^)]+)\.0([^)]*)\)': lambda m: f"const EdgeInsets.only({m.group(1)}{m.group(2)})",
        
        # Fix SizedBox
        r'SizedBox\(width: (\d+)\.0\)': r'SizedBox(width: \1)',
        r'SizedBox\(height: (\d+)\.0\)': r'const SizedBox(height: \1)',
        
        # Fix TextStyle fontSize
        r'fontSize: (\d+)\.0,': r'fontSize: \1,',
    }
    
    for pattern, replacement in replacements.items():
        content = re.sub(pattern, replacement, content)
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed: {filepath}")

def main():
    find_opponents_dir = "/workspaces/sabo_arena/lib/presentation/find_opponents_screen"
    
    # Process all dart files in find_opponents_screen
    for root, dirs, files in os.walk(find_opponents_dir):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                fix_sizer_in_file(filepath)

if __name__ == "__main__":
    main()