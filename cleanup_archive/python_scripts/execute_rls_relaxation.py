#!/usr/bin/env python3
"""
Script để apply RLS relaxation cho club owners
Execute SQL file để điều chỉnh RLS policies
"""

import psycopg2
import os

# Database connection info
DATABASE_URL = "postgresql://postgres.mogjjvscxjwvhtpkrlqr:eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo@aws-0-ap-southeast-1.pooler.supabase.com:6543/postgres"

def main():
    """Apply RLS relaxation SQL"""
    print("🔧 Đang apply RLS relaxation cho club owners...")
    
    try:
        # Kết nối database
        conn = psycopg2.connect(DATABASE_URL)
        conn.autocommit = True
        cursor = conn.cursor()
        
        print("✅ Kết nối database thành công!")
        
        # Đọc SQL file
        sql_file = "relax_rls_for_club_owners.sql"
        if not os.path.exists(sql_file):
            print(f"❌ Không tìm thấy file {sql_file}")
            return
            
        with open(sql_file, 'r', encoding='utf-8') as file:
            sql_content = file.read()
        
        print(f"📄 Đã đọc SQL file: {len(sql_content)} characters")
        
        # Execute SQL
        print("⚡ Đang execute SQL...")
        cursor.execute(sql_content)
        
        print("✅ Đã apply RLS relaxation thành công!")
        
        # Verify bằng cách đếm policies
        cursor.execute("""
            SELECT tablename, COUNT(*) as policy_count
            FROM pg_policies 
            WHERE tablename IN ('tournaments', 'tournament_participants', 'club_members', 'clubs')
            GROUP BY tablename
            ORDER BY tablename;
        """)
        
        print("\n📊 VERIFICATION - Policies per table:")
        results = cursor.fetchall()
        for table, count in results:
            print(f"  • {table}: {count} policies")
        
        # Đóng kết nối
        cursor.close()
        conn.close()
        
        print("\n🎉 HOÀN TẤT! Club owners giờ có toàn quyền truy cập data CLB của họ.")
        print("💡 Có thể test bằng cách login như club owner và truy cập tournament management panel.")
        
    except Exception as e:
        print(f"❌ Lỗi: {e}")

if __name__ == "__main__":
    main()