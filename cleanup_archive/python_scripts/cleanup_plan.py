#!/usr/bin/env python3
"""
Kế hoạch dọn dẹp workspace SaboArena V3
"""

def create_cleanup_plan():
    print("🧹 KẾ HOẠCH DỌN DẸP WORKSPACE SABOARENA V3")
    print("=" * 60)
    
    cleanup_plan = {
        "immediate_cleanup": {
            "description": "File có thể xóa ngay lập tức",
            "categories": [
                {
                    "name": "Python cache files (.pyc)",
                    "count": 937,
                    "command": "find . -name '*.pyc' -delete",
                    "safe": True
                },
                {
                    "name": "Debug files",
                    "count": 12,
                    "pattern": "debug_*.py, debug_*.dart",
                    "safe": True
                },
                {
                    "name": "Old backup files",
                    "count": 6,
                    "pattern": "*_old.*, *_backup.*",
                    "safe": True
                }
            ]
        },
        "careful_review": {
            "description": "File cần xem xét kỹ trước khi xóa",
            "categories": [
                {
                    "name": "Check/Test scripts",
                    "count": 158,
                    "pattern": "check_*.py, test_*.py, analyze_*.py",
                    "note": "Có thể là development tools cần thiết"
                },
                {
                    "name": "SQL migration files",
                    "count": 139,
                    "pattern": "*.sql",
                    "note": "Cần thiết cho database schema"
                }
            ]
        },
        "organize": {
            "description": "File cần tổ chức lại",
            "actions": [
                "Tạo thư mục /scripts/ cho các utility scripts",
                "Tạo thư mục /migrations/ cho SQL files",
                "Tạo thư mục /docs/ cho Markdown files",
                "Archive các file test vào /tests/"
            ]
        }
    }
    
    print("🚀 HÀNH ĐỘNG ƯU TIÊN:")
    print("-" * 30)
    print("1. Xóa 937 file .pyc (Python cache) - TIẾT KIỆM NGAY")
    print("2. Xóa debug files và backup files - 18 files")
    print("3. Tổ chức lại folder structure")
    print("4. Archive các development scripts")
    
    print("\n💾 TIẾT KIỆM DUNG LƯỢNG DỰ KIẾN:")
    print("-" * 30)
    print("- Python cache files: ~50-100MB")
    print("- Debug/backup files: ~5-10MB")
    print("- Tổng tiết kiệm: ~55-110MB")
    
    print("\n📁 CẤU TRÚC ĐỀ XUẤT SAU KHI DỌN DẸP:")
    print("-" * 30)
    print("""
    /workspaces/saboarenav3/
    ├── lib/                    # Core Flutter app
    ├── assets/                 # App assets
    ├── scripts/               # Development scripts (NEW)
    │   ├── database/          # DB scripts
    │   ├── analysis/          # Analysis scripts  
    │   └── utilities/         # Utility scripts
    ├── migrations/            # SQL migrations (NEW)
    ├── docs/                  # Documentation (NEW)
    ├── tests/                 # Test files (NEW)
    └── archive/               # Old/unused files
    """)
    
    return cleanup_plan

if __name__ == "__main__":
    create_cleanup_plan()