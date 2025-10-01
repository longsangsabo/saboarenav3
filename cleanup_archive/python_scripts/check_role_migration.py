#!/usr/bin/env python3
"""
Task Verification System - Role Migration Verification
Check if role-based migration was successful
"""

import os

def main():
    print("🔍 TASK VERIFICATION SYSTEM - MIGRATION VERIFICATION")
    print("=" * 60)
    
    base_path = "/workspaces/saboarenav3/lib/presentation/task_verification_screen"
    
    # Expected new structure
    expected_structure = {
        "staff/": [
            "staff_main_screen.dart",
            "live_photo_verification_screen.dart", 
            "staff_task_detail_screen.dart"
        ],
        "admin/": [
            "admin_task_management_screen.dart",
            "admin_task_detail_screen.dart"
        ],
        "shared/": [
            "task_models.dart",
            "task_verification_service.dart",
            "live_photo_verification_service.dart"
        ],
        "demo/": [
            "task_verification_demo.dart"
        ]
    }
    
    print("\n📁 CHECKING NEW FOLDER STRUCTURE:")
    
    total_expected = 0
    total_found = 0
    
    for folder, files in expected_structure.items():
        folder_path = os.path.join(base_path, folder)
        print(f"\n   📂 {folder}")
        
        if os.path.exists(folder_path):
            print(f"      ✅ Folder exists")
            
            for file in files:
                file_path = os.path.join(folder_path, file)
                total_expected += 1
                
                if os.path.exists(file_path):
                    # Get file size
                    size = os.path.getsize(file_path)
                    lines = 0
                    try:
                        with open(file_path, 'r') as f:
                            lines = len(f.readlines())
                    except:
                        pass
                    
                    print(f"      ✅ {file} ({lines} lines, {size:,} bytes)")
                    total_found += 1
                else:
                    print(f"      ❌ {file} - MISSING")
        else:
            print(f"      ❌ Folder does not exist")
            for file in files:
                total_expected += 1
                print(f"      ❌ {file} - MISSING")
    
    print(f"\n📊 MIGRATION SUMMARY:")
    print(f"   📁 Files Expected: {total_expected}")
    print(f"   ✅ Files Found: {total_found}")
    print(f"   📈 Success Rate: {(total_found/total_expected)*100:.1f}%")
    
    # Check old files still exist (should be cleaned up later)
    print(f"\n🗂️  OLD FILES STATUS:")
    old_files = [
        "task_verification_main_screen.dart",
        "live_photo_verification_screen.dart",
        "task_detail_screen.dart", 
        "admin_task_management_screen.dart"
    ]
    
    for file in old_files:
        old_path = os.path.join(base_path, file)
        if os.path.exists(old_path):
            print(f"   📄 {file}: ⚠️  Still exists (can be removed)")
        else:
            print(f"   📄 {file}: ✅ Removed")
    
    # Check imports in key files
    print(f"\n🔗 IMPORT PATH VERIFICATION:")
    
    key_files_to_check = [
        ("staff/staff_main_screen.dart", ["../shared/task_models.dart", "../shared/task_verification_service.dart"]),
        ("admin/admin_task_management_screen.dart", ["../shared/task_models.dart", "../shared/task_verification_service.dart"]),
        ("demo/task_verification_demo.dart", ["../staff/staff_main_screen.dart", "../admin/admin_task_management_screen.dart"])
    ]
    
    for file_path, expected_imports in key_files_to_check:
        full_path = os.path.join(base_path, file_path)
        print(f"\n   📄 {file_path}:")
        
        if os.path.exists(full_path):
            with open(full_path, 'r') as f:
                content = f.read()
                
            for expected_import in expected_imports:
                if expected_import in content:
                    print(f"      ✅ Import: {expected_import}")
                else:
                    print(f"      ❌ Missing import: {expected_import}")
        else:
            print(f"      ❌ File not found")
    
    # Final status
    if total_found == total_expected:
        print(f"\n🎉 MIGRATION COMPLETE!")
        print(f"   ✅ All files successfully moved to role-based structure")
        print(f"   🎯 Benefits achieved:")
        print(f"      • Clear role separation")
        print(f"      • Better code organization") 
        print(f"      • Improved maintainability")
        print(f"      • Scalable architecture")
    elif total_found >= total_expected * 0.8:
        print(f"\n⚠️  MIGRATION MOSTLY COMPLETE!")
        print(f"   🔧 Minor issues to fix")
        print(f"   📝 Check missing files above")
    else:
        print(f"\n❌ MIGRATION NEEDS WORK!")
        print(f"   🔧 Several files missing or issues found")

if __name__ == "__main__":
    main()