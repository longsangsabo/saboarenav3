#!/usr/bin/env python3
"""
Sửa các lỗi Flutter compatibility để chạy được trên Chrome
"""
import os
import re
import glob

def fix_flutter_compatibility():
    workspace_path = "/workspaces/saboarenav3"
    
    # Tìm tất cả file Dart
    dart_files = []
    for root, dirs, files in os.walk(workspace_path):
        # Skip build và .dart_tool
        dirs[:] = [d for d in dirs if d not in ['.dart_tool', 'build', '.git', '.venv']]
        for file in files:
            if file.endswith('.dart'):
                dart_files.append(os.path.join(root, file))
    
    print(f"🔧 SỬA CÁC LỖI FLUTTER COMPATIBILITY")
    print(f"Tìm thấy {len(dart_files)} file Dart")
    print("=" * 50)
    
    fixes_applied = 0
    
    for file_path in dart_files:
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_content = content
            
            # Fix 1: DropdownButtonFormField initialValue -> value
            if 'DropdownButtonFormField' in content and 'initialValue:' in content:
                # Chỉ sửa trong context của DropdownButtonFormField
                pattern = r'(DropdownButtonFormField[^}]*?)initialValue:'
                content = re.sub(pattern, r'\1value:', content, flags=re.MULTILINE | re.DOTALL)
            
            # Fix 2: Switch activeThumbColor -> thumbColor
            if 'Switch(' in content and 'activeThumbColor:' in content:
                content = content.replace('activeThumbColor:', 'thumbColor:')
            
            # Fix 3: Remove geolocator problematic imports nếu có
            if 'geolocator_android' in content:
                print(f"⚠️  Geolocator issue in: {file_path}")
            
            if content != original_content:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                fixes_applied += 1
                print(f"✅ Fixed: {os.path.relpath(file_path, workspace_path)}")
                
        except Exception as e:
            print(f"❌ Error processing {file_path}: {e}")
    
    print(f"\n🎉 Hoàn thành! Đã sửa {fixes_applied} files")
    return fixes_applied

if __name__ == "__main__":
    fix_flutter_compatibility()