#!/usr/bin/env python3
import os
import re

def fix_dart_issues(directory):
    """Fix various Dart compilation issues"""
    dart_files = []
    
    # Find all .dart files
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    print(f"Processing {len(dart_files)} Dart files")
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix Timer import issue
            if 'Timer.periodic' in content or 'Timer(' in content:
                if 'import \'dart:async\';' not in content:
                    # Add import at the top after other imports
                    import_index = content.find('import \'package:')
                    if import_index != -1:
                        content = content[:import_index] + "import 'dart:async';\n" + content[import_index:]
            
            # Fix Icons.payment_off to Icons.money_off
            content = content.replace('Icons.payment_off', 'Icons.money_off')
            
            # Fix undefined bankCode011
            content = content.replace('$bankCode011', '$bankCode')
            
            # Fix RPC calls with proper syntax
            content = re.sub(r'_supabase\.rpc\(([^,]+),\s*\{', r'_supabase.rpc(\1, parameters: {', content)
            
            # Fix .eq method usage
            content = re.sub(r'query\.eq\(', r'query.eq(', content)
            content = re.sub(r'\.from\(\'([^\']+)\'\)\.select\(\'([^\']+)\'\)\.eq\(([^)]+)\)', r'.from(\'\1\').select(\'\2\').eq(\3)', content)
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"Fixed: {file_path}")
                
        except Exception as e:
            print(f"Error processing {file_path}: {e}")

if __name__ == "__main__":
    fix_dart_issues("/workspaces/saboarenav3/lib")