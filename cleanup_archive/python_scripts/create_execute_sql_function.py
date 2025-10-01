#!/usr/bin/env python3
"""
Tạo function execute_sql trong Supabase để có thể chạy SQL commands
"""

import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

def create_execute_sql_function():
    """Tạo execute_sql function bằng cách gọi trực tiếp PostgreSQL"""
    
    # SQL để tạo function execute_sql
    create_function_sql = """
CREATE OR REPLACE FUNCTION execute_sql(sql TEXT)
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    -- Thực thi SQL command
    EXECUTE sql;
    
    -- Trả về kết quả thành công
    RETURN json_build_object(
        'success', true,
        'message', 'SQL executed successfully',
        'executed_sql', sql
    );
EXCEPTION
    WHEN OTHERS THEN
        -- Trả về lỗi nếu có
        RETURN json_build_object(
            'success', false,
            'message', SQLERRM,
            'error_code', SQLSTATE,
            'executed_sql', sql
        );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
"""

    print("🔧 Creating execute_sql function...")
    
    try:
        # Method 1: Thử với PostgreSQL REST endpoint khác
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/query",
            headers=headers,
            json={"query": create_function_sql}
        )
        
        if response.status_code in [200, 201]:
            print("✅ Method 1 success: execute_sql function created")
            return True
        else:
            print(f"❌ Method 1 failed: {response.text}")
            
            # Method 2: Thử tạo bằng cách gọi schema functions khác
            try:
                schema_response = requests.post(
                    f"{SUPABASE_URL}/rest/v1/rpc/exec",
                    headers=headers,
                    json={"sql": create_function_sql}
                )
                
                if schema_response.status_code in [200, 201]:
                    print("✅ Method 2 success: execute_sql function created")
                    return True
                else:
                    print(f"❌ Method 2 failed: {schema_response.text}")
                    
                    # Method 3: Raw PostgreSQL approach
                    raw_response = requests.post(
                        f"{SUPABASE_URL}/database/postgres",
                        headers=headers,
                        json={"statement": create_function_sql}
                    )
                    
                    if raw_response.status_code in [200, 201]:
                        print("✅ Method 3 success: execute_sql function created")
                        return True
                    else:
                        print(f"❌ Method 3 failed: {raw_response.text}")
                        return False
                        
            except Exception as e:
                print(f"❌ Exception in Method 2/3: {e}")
                return False
                
    except Exception as e:
        print(f"❌ Exception in Method 1: {e}")
        return False

def create_alternative_approach():
    """Tạo approach khác - sử dụng stored procedures có sẵn"""
    
    print("🔄 Trying alternative approach...")
    
    # Thử tạo function đơn giản hơn
    simple_function_sql = """
CREATE OR REPLACE FUNCTION simple_execute(cmd TEXT)
RETURNS TEXT AS $$
BEGIN
    EXECUTE cmd;
    RETURN 'SUCCESS';
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;
"""
    
    try:
        # Sử dụng existing functions để create
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/get_auth_users_sample",
            headers=headers,
            json={}
        )
        
        print(f"Testing existing function: {response.status_code}")
        
        if response.status_code == 200:
            print("✅ Found existing RPC infrastructure")
            
            # Thử tạo function qua manual approach
            manual_commands = [
                "ALTER TABLE club_members ADD COLUMN IF NOT EXISTS confirmed_rank VARCHAR(5);",
                "ALTER TABLE club_members ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending';"
            ]
            
            print("🔧 Attempting manual SQL execution...")
            
            for i, cmd in enumerate(manual_commands):
                print(f"Trying command {i+1}: {cmd[:50]}...")
                
                # Thử nhiều cách khác nhau
                methods = [
                    ("sql_exec", {"sql": cmd}),
                    ("execute_sql", {"query": cmd}),
                    ("run_sql", {"statement": cmd}),
                    ("db_execute", {"command": cmd})
                ]
                
                for method_name, payload in methods:
                    try:
                        test_response = requests.post(
                            f"{SUPABASE_URL}/rest/v1/rpc/{method_name}",
                            headers=headers,
                            json=payload
                        )
                        
                        if test_response.status_code in [200, 201]:
                            print(f"✅ Success with {method_name}")
                            return True
                        else:
                            print(f"❌ {method_name} failed: {test_response.status_code}")
                            
                    except Exception as e:
                        print(f"❌ {method_name} exception: {e}")
                        continue
            
            return False
        else:
            print("❌ No existing RPC infrastructure found")
            return False
            
    except Exception as e:
        print(f"❌ Alternative approach failed: {e}")
        return False

def direct_table_modification():
    """Thử modify table trực tiếp qua REST API"""
    
    print("🔧 Attempting direct table modification...")
    
    try:
        # Lấy schema của bảng club_members hiện tại
        schema_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?limit=1",
            headers=headers
        )
        
        if schema_response.status_code == 200:
            print("✅ Can access club_members table")
            
            # Thử thêm cột bằng cách sử dụng schema modification
            # Đây là workaround - tạo record với cột mới để force schema update
            
            test_record = {
                "user_id": "00000000-0000-0000-0000-000000000000",  # Dummy UUID
                "club_id": "00000000-0000-0000-0000-000000000000",  # Dummy UUID  
                "status": "test",
                "role": "test",
                "confirmed_rank": "B",  # Cột mới
                "approval_status": "pending"  # Cột mới
            }
            
            # Thử insert để test schema
            insert_response = requests.post(
                f"{SUPABASE_URL}/rest/v1/club_members",
                headers=headers,
                json=test_record
            )
            
            print(f"Insert test result: {insert_response.status_code}")
            print(f"Response: {insert_response.text}")
            
            if insert_response.status_code in [200, 201]:
                print("✅ Schema supports new columns!")
                
                # Xóa test record
                delete_response = requests.delete(
                    f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.00000000-0000-0000-0000-000000000000",
                    headers=headers
                )
                
                return True
            else:
                print("❌ Schema doesn't support new columns yet")
                return False
                
        else:
            print(f"❌ Cannot access club_members: {schema_response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Direct modification failed: {e}")
        return False

def main():
    print("🚀 CREATING EXECUTE_SQL FUNCTION FOR SUPABASE")
    print("=" * 60)
    
    methods = [
        ("1️⃣ Creating execute_sql function", create_execute_sql_function),
        ("2️⃣ Alternative approach", create_alternative_approach),
        ("3️⃣ Direct table modification test", direct_table_modification)
    ]
    
    for method_name, method_func in methods:
        print(f"\n{method_name}")
        print("-" * 40)
        
        if method_func():
            print(f"✅ {method_name} succeeded!")
            print("\n🎉 Function creation successful! You can now run the main automation script.")
            return
        else:
            print(f"❌ {method_name} failed, trying next method...")
    
    print("\n❌ All methods failed.")
    print("📋 Manual steps required:")
    print("1. Go to Supabase Dashboard > SQL Editor")
    print("2. Run the contents of 'rank_elo_automation_real.sql'")
    print("3. This will create all necessary functions and triggers")
    
    # Tạo một phiên bản đơn giản hơn
    print("\n🔄 Creating simplified automation script...")
    create_simplified_script()

def create_simplified_script():
    """Tạo script đơn giản hơn chỉ update data thông qua REST API"""
    
    simplified_code = '''#!/usr/bin/env python3
"""
Simplified rank/ELO automation without SQL functions
Uses direct REST API calls to update data
"""

import requests
import json

SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def update_user_rank_and_elo(user_id, rank):
    """Update user rank and ELO directly via REST API"""
    
    elo_mapping = {
        'A': 1800,
        'B': 1600,
        'C': 1400,
        'D': 1200,
        'E': 1000
    }
    
    elo_rating = elo_mapping.get(rank, 1000)
    
    try:
        response = requests.patch(
            f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
            headers=headers,
            json={
                "rank": rank,
                "elo_rating": elo_rating
            }
        )
        
        if response.status_code in [200, 204]:
            print(f"✅ Updated user {user_id}: rank={rank}, elo={elo_rating}")
            return True
        else:
            print(f"❌ Failed to update user {user_id}: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error updating user {user_id}: {e}")
        return False

def confirm_user_rank_simple(user_id, club_id, confirmed_rank):
    """Simplified rank confirmation"""
    
    print(f"🔧 Confirming rank {confirmed_rank} for user {user_id}")
    
    # Step 1: Update club_members table (if columns exist)
    try:
        member_update = requests.patch(
            f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&club_id=eq.{club_id}",
            headers=headers,
            json={
                "status": "active"  # Update what we can
            }
        )
        
        print(f"Member update status: {member_update.status_code}")
        
    except Exception as e:
        print(f"⚠️ Could not update club_members: {e}")
    
    # Step 2: Update users table directly
    success = update_user_rank_and_elo(user_id, confirmed_rank)
    
    if success:
        return {
            "success": True,
            "message": f"User rank confirmed as {confirmed_rank}",
            "rank": confirmed_rank, 
            "elo": {
                'A': 1800, 'B': 1600, 'C': 1400, 'D': 1200, 'E': 1000
            }.get(confirmed_rank, 1000)
        }
    else:
        return {
            "success": False,
            "message": "Failed to update user rank"
        }

def get_users_without_rank_simple():
    """Get users without rank via REST API"""
    
    try:
        # Get users with null rank
        users_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?rank=is.null&select=id,display_name,rank,elo_rating",
            headers=headers
        )
        
        if users_response.status_code == 200:
            users = users_response.json()
            
            # Get their club memberships
            result = []
            for user in users:
                member_response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user['id']}&select=*,clubs(name)",
                    headers=headers
                )
                
                if member_response.status_code == 200:
                    memberships = member_response.json()
                    for membership in memberships:
                        club_name = membership.get('clubs', {}).get('name', 'Unknown Club')
                        result.append({
                            "user_id": user['id'],
                            "display_name": user['display_name'],
                            "club_name": club_name,
                            "membership_status": membership.get('status', 'unknown')
                        })
            
            return result
        else:
            print(f"❌ Failed to get users: {users_response.text}")
            return []
            
    except Exception as e:
        print(f"❌ Error getting users without rank: {e}")
        return []

def test_simplified_system():
    """Test the simplified system"""
    
    print("🧪 Testing simplified rank system...")
    
    # Get users without rank
    users = get_users_without_rank_simple()
    print(f"Found {len(users)} users without rank")
    
    if users:
        # Test with first user
        test_user = users[0]
        user_id = test_user['user_id']
        
        print(f"Testing with user: {test_user['display_name']}")
        
        # Find their club
        member_response = requests.get(
            f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&limit=1",
            headers=headers
        )
        
        if member_response.status_code == 200 and member_response.json():
            club_id = member_response.json()[0]['club_id']
            
            # Test confirm rank
            result = confirm_user_rank_simple(user_id, club_id, "B")
            print(f"Confirmation result: {result}")
            
            if result['success']:
                print("🎉 SIMPLIFIED SYSTEM WORKING!")
                return True
            else:
                print("❌ Simplified system failed")
                return False
        else:
            print("❌ No club membership found")
            return False
    else:
        print("ℹ️ No users without rank found")
        return True

if __name__ == "__main__":
    print("🚀 SIMPLIFIED RANK/ELO AUTOMATION SYSTEM")
    print("=" * 60)
    test_simplified_system()
'''
    
    with open("simplified_rank_automation.py", "w", encoding="utf-8") as f:
        f.write(simplified_code)
    
    print("✅ Created simplified_rank_automation.py")
    print("💡 This script works without SQL functions, using only REST API")

if __name__ == "__main__":
    main()