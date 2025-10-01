#!/usr/bin/env python3
"""
Sửa tất cả các lỗi Flutter compatibility nâng cao
"""
import os
import re

def fix_advanced_flutter_issues():
    workspace_path = "/workspaces/saboarenav3"
    
    print("🔧 SỬA CÁC LỖI FLUTTER NÂNG CAO")
    print("=" * 50)
    
    fixes = 0
    
    # Fix 1: thumbColor phải là WidgetStateProperty
    print("1. Sửa thumbColor -> WidgetStateProperty...")
    thumb_color_files = [
        "lib/presentation/club_settings_screen/operating_hours_screen.dart",
        "lib/presentation/club_settings_screen/club_rules_screen.dart", 
        "lib/presentation/club_settings_screen/pricing_settings_screen.dart",
        "lib/presentation/club_settings_screen/payment_settings_screen.dart",
        "lib/presentation/club_settings_screen/membership_policy_screen.dart"
    ]
    
    for file_path in thumb_color_files:
        full_path = os.path.join(workspace_path, file_path)
        if os.path.exists(full_path):
            try:
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace thumbColor: Color with WidgetStateProperty
                if 'thumbColor: AppTheme.primaryLight' in content:
                    content = content.replace(
                        'thumbColor: AppTheme.primaryLight',
                        'thumbColor: WidgetStateProperty.all(AppTheme.primaryLight)'
                    )
                    
                    with open(full_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"✅ Fixed thumbColor in {file_path}")
                    fixes += 1
                    
            except Exception as e:
                print(f"❌ Error fixing {file_path}: {e}")
    
    # Fix 2: ErrorWidget requires exception parameter
    print("\n2. Sửa ErrorWidget constructor...")
    error_widget_files = [
        "lib/presentation/club_owner/active_shift_screen.dart",
        "lib/presentation/club_owner/shift_history_screen.dart"
    ]
    
    for file_path in error_widget_files:
        full_path = os.path.join(workspace_path, file_path)
        if os.path.exists(full_path):
            try:
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace ErrorWidget() with ErrorWidget('Error message')
                if 'return ErrorWidget(' in content and 'ErrorWidget()' in content:
                    content = content.replace(
                        'return ErrorWidget(',
                        'return ErrorWidget(\'Lỗi tải dữ liệu\')'
                    )
                    content = content.replace('ErrorWidget()', '')
                    
                    with open(full_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"✅ Fixed ErrorWidget in {file_path}")
                    fixes += 1
                    
            except Exception as e:
                print(f"❌ Error fixing {file_path}: {e}")
    
    # Fix 3: LoadingWidget không tồn tại - thay bằng CircularProgressIndicator
    print("\n3. Sửa LoadingWidget -> CircularProgressIndicator...")
    loading_files = [
        "lib/presentation/club_owner/active_shift_screen.dart",
        "lib/presentation/club_owner/shift_history_screen.dart", 
        "lib/presentation/club_owner/shift_analytics_screen.dart"
    ]
    
    for file_path in loading_files:
        full_path = os.path.join(workspace_path, file_path)
        if os.path.exists(full_path):
            try:
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace LoadingWidget with CircularProgressIndicator
                if 'LoadingWidget(message:' in content:
                    content = re.sub(
                        r'LoadingWidget\(message: [^)]+\)',
                        'Center(child: CircularProgressIndicator())',
                        content
                    )
                    
                    with open(full_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f"✅ Fixed LoadingWidget in {file_path}")
                    fixes += 1
                    
            except Exception as e:
                print(f"❌ Error fixing {file_path}: {e}")
    
    # Fix 4: Supabase RPC call syntax 
    print("\n4. Sửa Supabase RPC calls...")
    rpc_files = ["lib/services/attendance_service.dart"]
    
    for file_path in rpc_files:
        full_path = os.path.join(workspace_path, file_path)
        if os.path.exists(full_path):
            try:
                with open(full_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Fix RPC parameters - remove extra positional arguments
                content = re.sub(
                    r'\.rpc\(\'([^\']+)\', \{([^}]+)\}\)',
                    r'.rpc(\'\1\', \2)',
                    content
                )
                
                with open(full_path, 'w', encoding='utf-8') as f:
                    f.write(content)
                print(f"✅ Fixed RPC calls in {file_path}")
                fixes += 1
                
            except Exception as e:
                print(f"❌ Error fixing {file_path}: {e}")
    
    print(f"\n🎉 Hoàn thành! Đã sửa {fixes} lỗi Flutter nâng cao")
    return fixes

if __name__ == "__main__":
    fix_advanced_flutter_issues()