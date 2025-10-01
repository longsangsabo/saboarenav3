#!/usr/bin/env python3
import os
import re

def fix_string_issues(directory):
    """Fix string quotation and syntax issues in Dart files"""
    dart_files = []
    
    # Find all .dart files
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    print(f"Processing {len(dart_files)} Dart files for string issues")
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix common string issues
            # Remove extra quotes and fix string endings
            content = re.sub(r"'([^']*)'([^'])", r"'\1'\2", content)  # Fix dangling quotes
            
            # Fix switch keyword usage in strings
            content = content.replace("'switch'", "'status'")
            
            # Fix single quotes in strings that should be double quotes
            content = re.sub(r"'([^']*)'(\s*:\s*['\"])", r'"\1"\2', content)
            
            # Fix unmatched parentheses in RPC calls
            content = re.sub(r'_supabase\.rpc\(([^,]+),\s*parameters:\s*\{([^}]+)\}([^)])', r'_supabase.rpc(\1, parameters: {\2})', content)
            
            # Fix function calls with missing parentheses
            content = re.sub(r'(\w+)\s*\{\s*$', r'\1() {', content, flags=re.MULTILINE)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed strings in: {file_path}")
                
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_string_issues("/workspaces/saboarenav3/lib")