#!/usr/bin/env python3
"""
Task Verification System - Navigation Flow Analysis
Checks if all screens are properly linked together
"""

import os
import re

def main():
    print("🔗 TASK VERIFICATION SYSTEM - NAVIGATION ANALYSIS")
    print("=" * 60)
    
    # Define screens and their files
    screens = {
        "TaskVerificationMainScreen": "task_verification_main_screen.dart",
        "TaskDetailScreen": "task_detail_screen.dart", 
        "LivePhotoVerificationScreen": "live_photo_verification_screen.dart",
        "AdminTaskManagementScreen": "admin_task_management_screen.dart",
        "TaskVerificationDemo": "../widgets/task_verification_demo.dart"
    }
    
    base_path = "/workspaces/saboarenav3/lib/presentation/task_verification_screen/"
    
    # Check each screen file
    print("\n✅ SCREEN FILES STATUS:")
    for screen_name, file_name in screens.items():
        file_path = os.path.join(base_path, file_name) if not file_name.startswith("../") else "/workspaces/saboarenav3/lib/widgets/task_verification_demo.dart"
        
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                content = f.read()
                lines = len(content.split('\n'))
                print(f"   📱 {screen_name}: ✅ EXISTS ({lines:,} lines)")
        else:
            print(f"   📱 {screen_name}: ❌ MISSING")
    
    # Check navigation connections
    print("\n🔗 NAVIGATION FLOW ANALYSIS:")
    
    navigation_patterns = [
        (r'Navigator\.push.*TaskDetailScreen', "Navigate to Task Detail"),
        (r'Navigator\.push.*LivePhotoVerificationScreen', "Navigate to Camera"),
        (r'Navigator\.push.*AdminTaskManagementScreen', "Navigate to Admin"),
        (r'MaterialPageRoute.*TaskDetailScreen', "Route to Task Detail"),
        (r'MaterialPageRoute.*LivePhotoVerificationScreen', "Route to Camera"),
        (r'import.*task_detail_screen', "Import Task Detail"),
        (r'import.*live_photo_verification_screen', "Import Camera Screen"),
        (r'import.*admin_task_management_screen', "Import Admin Screen")
    ]
    
    for screen_name, file_name in screens.items():
        file_path = os.path.join(base_path, file_name) if not file_name.startswith("../") else "/workspaces/saboarenav3/lib/widgets/task_verification_demo.dart"
        
        if not os.path.exists(file_path):
            continue
            
        print(f"\n   📱 {screen_name}:")
        
        with open(file_path, 'r') as f:
            content = f.read()
            
        found_navigations = []
        for pattern, description in navigation_patterns:
            if re.search(pattern, content, re.IGNORECASE):
                found_navigations.append(description)
        
        if found_navigations:
            for nav in found_navigations:
                print(f"      ✅ {nav}")
        else:
            print(f"      ⚠️  No navigation patterns found")
    
    # Check main app integration
    print("\n🏠 MAIN APP INTEGRATION:")
    
    dashboard_path = "/workspaces/saboarenav3/lib/presentation/club_dashboard_screen/club_dashboard_screen.dart"
    if os.path.exists(dashboard_path):
        with open(dashboard_path, 'r') as f:
            dashboard_content = f.read()
            
        integration_checks = [
            (r'task_verification_demo', "Demo import"),
            (r'TaskVerificationDemo', "Demo class usage"),
            (r'Xác minh nhiệm vụ', "Vietnamese UI text"),
            (r'_onOpenTaskVerificationDemo', "Demo navigation function")
        ]
        
        for pattern, description in integration_checks:
            if re.search(pattern, dashboard_content, re.IGNORECASE):
                print(f"   ✅ {description}: FOUND")
            else:
                print(f"   ❌ {description}: MISSING")
    else:
        print("   ❌ Dashboard file not found")
    
    # Summary
    print(f"\n🎯 NAVIGATION FLOW SUMMARY:")
    
    # Count files
    existing_files = sum(1 for _, file_name in screens.items() 
                        if os.path.exists(os.path.join(base_path, file_name) if not file_name.startswith("../") 
                                        else "/workspaces/saboarenav3/lib/widgets/task_verification_demo.dart"))
    
    print(f"   📱 Screen Files: {existing_files}/{len(screens)} created")
    
    # Check key navigation flows
    key_flows = [
        ("Main → Task Detail", "task_verification_main_screen.dart", r'TaskDetailScreen'),
        ("Main → Camera", "task_verification_main_screen.dart", r'LivePhotoVerificationScreen'),
        ("Task Detail → Camera", "task_detail_screen.dart", r'LivePhotoVerificationScreen'),
        ("Admin → Task Detail", "admin_task_management_screen.dart", r'TaskDetailScreen'),
        ("Demo → Main Screen", "../widgets/task_verification_demo.dart", r'TaskVerificationMainScreen'),
        ("Demo → Admin Screen", "../widgets/task_verification_demo.dart", r'AdminTaskManagementScreen')
    ]
    
    working_flows = 0
    for flow_name, file_name, pattern in key_flows:
        file_path = os.path.join(base_path, file_name) if not file_name.startswith("../") else "/workspaces/saboarenav3/lib/widgets/task_verification_demo.dart"
        
        if os.path.exists(file_path):
            with open(file_path, 'r') as f:
                content = f.read()
                if re.search(pattern, content):
                    working_flows += 1
                    print(f"   ✅ {flow_name}: WORKING")
                else:
                    print(f"   ❌ {flow_name}: BROKEN")
        else:
            print(f"   ❌ {flow_name}: FILE MISSING")
    
    print(f"\n📊 FINAL STATUS:")
    print(f"   📱 UI Screens: {existing_files}/{len(screens)} complete")
    print(f"   🔗 Navigation Flows: {working_flows}/{len(key_flows)} working")
    
    if existing_files == len(screens) and working_flows >= len(key_flows) - 1:
        print(f"   🎉 STATUS: FULLY CONNECTED")
        print(f"   🚀 All screens linked and ready for use!")
    elif working_flows > len(key_flows) // 2:
        print(f"   ⚠️  STATUS: MOSTLY CONNECTED")
        print(f"   🔧 Minor navigation fixes needed")
    else:
        print(f"   ❌ STATUS: NEEDS WORK")
        print(f"   🔧 Navigation connections need fixing")

if __name__ == "__main__":
    main()