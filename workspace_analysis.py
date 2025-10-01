#!/usr/bin/env python3
"""
Phân tích chi tiết workspace để xem file nào cần thiết và file nào có thể dọn dẹp
"""
import os
import json
from collections import defaultdict

def analyze_workspace():
    workspace_path = "/workspaces/saboarenav3"
    
    # Phân loại file theo extension
    file_types = defaultdict(list)
    duplicate_files = defaultdict(list)
    
    # File patterns có thể dọn dẹp
    cleanup_patterns = [
        'check_',
        'analyze_',
        'test_',
        'debug_',
        'temp_',
        'backup_',
        'old_',
        'copy_',
        '_old',
        '_backup',
        '_temp',
        '_test'
    ]
    
    total_files = 0
    cleanup_candidates = []
    
    for root, dirs, files in os.walk(workspace_path):
        # Skip some directories
        skip_dirs = ['.git', '.dart_tool', 'build', 'node_modules', '.vscode']
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        
        for file in files:
            full_path = os.path.join(root, file)
            rel_path = os.path.relpath(full_path, workspace_path)
            
            total_files += 1
            
            # Phân loại theo extension
            ext = os.path.splitext(file)[1].lower()
            file_types[ext].append(rel_path)
            
            # Tìm file có thể dọn dẹp
            filename_lower = file.lower()
            for pattern in cleanup_patterns:
                if pattern in filename_lower:
                    cleanup_candidates.append(rel_path)
                    break
    
    # Tạo báo cáo
    print("🔍 PHÂN TÍCH WORKSPACE SABOARENA V3")
    print("=" * 50)
    print(f"📊 Tổng số file: {total_files}")
    print()
    
    print("📁 PHÂN LOẠI THEO LOẠI FILE:")
    print("-" * 30)
    important_exts = ['.dart', '.py', '.sql', '.md', '.yaml', '.json']
    for ext in sorted(file_types.keys()):
        count = len(file_types[ext])
        if ext in important_exts or count > 10:
            print(f"{ext:8} : {count:4} files")
    print()
    
    print("🧹 FILE CÓ THỂ DỌN DẸP:")
    print("-" * 30)
    print(f"Tổng số file có thể dọn dẹp: {len(cleanup_candidates)}")
    
    # Nhóm theo pattern
    pattern_groups = defaultdict(list)
    for file in cleanup_candidates:
        filename = os.path.basename(file).lower()
        for pattern in cleanup_patterns:
            if pattern in filename:
                pattern_groups[pattern].append(file)
                break
    
    for pattern, files in pattern_groups.items():
        if files:
            print(f"\n📋 Files with '{pattern}' pattern ({len(files)} files):")
            for file in sorted(files)[:5]:  # Show first 5
                print(f"   - {file}")
            if len(files) > 5:
                print(f"   ... and {len(files) - 5} more")
    
    print("\n" + "=" * 50)
    print("💡 KHUYẾN NGHỊ:")
    print("- Có thể dọn dẹp các file test/debug/temp để giảm clutter")
    print("- Nên tổ chức code thành module rõ ràng hơn")
    print("- Xem xét việc archive các file cũ không dùng")
    
    return {
        'total_files': total_files,
        'file_types': dict(file_types),
        'cleanup_candidates': cleanup_candidates,
        'pattern_groups': dict(pattern_groups)
    }

if __name__ == "__main__":
    analyze_workspace()