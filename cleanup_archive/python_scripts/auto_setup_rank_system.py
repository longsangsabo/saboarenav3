#!/usr/bin/env python3
"""
Tự động chạy SQL scripts để thiết lập hệ thống rank/ELO automation
"""

import requests
import json
from datetime import datetime
import time

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SUPABASE_SERVICE_KEY,
    "Authorization": f"Bearer {SUPABASE_SERVICE_KEY}",
    "Content-Type": "application/json"
}

def execute_sql(sql_command, description="SQL Command"):
    """Thực thi SQL command trực tiếp"""
    print(f"🔧 Executing: {description}")
    
    try:
        # Method 1: Sử dụng PostgREST để thực thi SQL
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/execute_sql",
            headers=headers,
            json={"sql": sql_command}
        )
        
        if response.status_code in [200, 201]:
            print(f"✅ Success: {description}")
            return True
        else:
            print(f"❌ Method 1 failed: {response.text}")
            
            # Method 2: Thử với edge functions
            edge_response = requests.post(
                f"{SUPABASE_URL}/functions/v1/execute-sql",
                headers=headers,
                json={"query": sql_command}
            )
            
            if edge_response.status_code in [200, 201]:
                print(f"✅ Success (Edge): {description}")
                return True
            else:
                print(f"❌ Method 2 also failed: {edge_response.text}")
                
                # Method 3: Thử với direct database connection thông qua HTTP
                direct_response = requests.post(
                    f"{SUPABASE_URL}/database/execute",
                    headers=headers,
                    json={"sql": sql_command}
                )
                
                if direct_response.status_code in [200, 201]:
                    print(f"✅ Success (Direct): {description}")
                    return True
                else:
                    print(f"❌ All methods failed for: {description}")
                    return False
                    
    except Exception as e:
        print(f"❌ Exception executing {description}: {e}")
        return False

def add_columns_to_club_members():
    """Thêm cột confirmed_rank và approval_status vào club_members"""
    sql_commands = [
        {
            "sql": "ALTER TABLE club_members ADD COLUMN IF NOT EXISTS confirmed_rank VARCHAR(5);",
            "desc": "Add confirmed_rank column"
        },
        {
            "sql": "ALTER TABLE club_members ADD COLUMN IF NOT EXISTS approval_status VARCHAR(20) DEFAULT 'pending';",
            "desc": "Add approval_status column"
        }
    ]
    
    success_count = 0
    for cmd in sql_commands:
        if execute_sql(cmd["sql"], cmd["desc"]):
            success_count += 1
        time.sleep(1)
    
    return success_count == len(sql_commands)

def create_update_function():
    """Tạo function update_user_rank_from_club_confirmation"""
    sql = """
CREATE OR REPLACE FUNCTION update_user_rank_from_club_confirmation()
RETURNS TRIGGER AS $$
BEGIN  
    RAISE LOG 'Rank trigger called: user_id=%, approval_status=%, confirmed_rank=%', 
        NEW.user_id, NEW.approval_status, NEW.confirmed_rank;
    
    IF NEW.approval_status = 'approved' AND NEW.confirmed_rank IS NOT NULL AND NEW.confirmed_rank != '' THEN
        UPDATE users 
        SET 
            rank = NEW.confirmed_rank,
            elo_rating = CASE NEW.confirmed_rank
                WHEN 'A' THEN 1800
                WHEN 'B' THEN 1600  
                WHEN 'C' THEN 1400
                WHEN 'D' THEN 1200
                WHEN 'E' THEN 1000
                ELSE elo_rating
            END,
            updated_at = NOW()
        WHERE id = NEW.user_id;
        
        RAISE LOG 'Updated user % rank to % with ELO %', 
            NEW.user_id, NEW.confirmed_rank, 
            CASE NEW.confirmed_rank
                WHEN 'A' THEN 1800
                WHEN 'B' THEN 1600  
                WHEN 'C' THEN 1400
                WHEN 'D' THEN 1200
                WHEN 'E' THEN 1000
                ELSE 0
            END;
    ELSE
        RAISE LOG 'No rank update needed: approval_status=%, confirmed_rank=%', 
            NEW.approval_status, NEW.confirmed_rank;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
"""
    
    return execute_sql(sql, "Create update function")

def create_trigger():
    """Tạo trigger"""
    sql_commands = [
        {
            "sql": "DROP TRIGGER IF EXISTS trigger_update_user_rank ON club_members;",
            "desc": "Drop existing trigger"
        },
        {
            "sql": """
CREATE TRIGGER trigger_update_user_rank
    AFTER UPDATE ON club_members
    FOR EACH ROW
    EXECUTE FUNCTION update_user_rank_from_club_confirmation();
""",
            "desc": "Create new trigger"
        }
    ]
    
    success_count = 0
    for cmd in sql_commands:
        if execute_sql(cmd["sql"], cmd["desc"]):
            success_count += 1
        time.sleep(1)
    
    return success_count == len(sql_commands)

def create_confirm_rank_function():
    """Tạo function confirm_user_rank cho admin"""
    sql = """
CREATE OR REPLACE FUNCTION confirm_user_rank(
    p_user_id UUID,
    p_club_id UUID, 
    p_confirmed_rank VARCHAR(5)
)
RETURNS JSON AS $$
DECLARE
    result JSON;
    elo_value INTEGER;
BEGIN
    IF p_confirmed_rank NOT IN ('A', 'B', 'C', 'D', 'E') THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Invalid rank. Must be A, B, C, D, or E'
        );
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM club_members 
        WHERE user_id = p_user_id AND club_id = p_club_id
    ) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'User is not a member of this club'
        );
    END IF;
    
    UPDATE club_members 
    SET 
        confirmed_rank = p_confirmed_rank,
        approval_status = 'approved'
    WHERE user_id = p_user_id AND club_id = p_club_id;
    
    elo_value := CASE p_confirmed_rank
        WHEN 'A' THEN 1800
        WHEN 'B' THEN 1600  
        WHEN 'C' THEN 1400
        WHEN 'D' THEN 1200
        WHEN 'E' THEN 1000
    END;
    
    RETURN json_build_object(
        'success', true,
        'message', format('User rank confirmed as %s with ELO %s', p_confirmed_rank, elo_value),
        'rank', p_confirmed_rank,
        'elo', elo_value
    );
END;
$$ LANGUAGE plpgsql;
"""
    
    return execute_sql(sql, "Create confirm_user_rank function")

def create_get_users_function():
    """Tạo function get_users_without_rank"""
    sql = """
CREATE OR REPLACE FUNCTION get_users_without_rank()
RETURNS TABLE (
    user_id UUID,
    display_name TEXT,
    club_name TEXT,
    membership_status TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        u.id,
        u.display_name,
        c.name,
        cm.status
    FROM users u
    JOIN club_members cm ON u.id = cm.user_id
    JOIN clubs c ON cm.club_id = c.id
    WHERE u.rank IS NULL
    AND cm.status = 'active'
    ORDER BY u.display_name;
END;
$$ LANGUAGE plpgsql;
"""
    
    return execute_sql(sql, "Create get_users_without_rank function")

def setup_test_data():
    """Thiết lập dữ liệu test"""
    print("🧪 Setting up test data...")
    
    try:
        # Lấy user và club để tạo membership
        user_response = requests.get(f"{SUPABASE_URL}/rest/v1/users?limit=1", headers=headers)
        club_response = requests.get(f"{SUPABASE_URL}/rest/v1/clubs?limit=1", headers=headers)
        
        if user_response.status_code == 200 and club_response.status_code == 200:
            users = user_response.json()
            clubs = club_response.json()
            
            if users and clubs:
                user_id = users[0]['id']
                club_id = clubs[0]['id']
                
                # Kiểm tra membership đã tồn tại chưa
                check_response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{user_id}&club_id=eq.{club_id}",
                    headers=headers
                )
                
                if check_response.status_code == 200 and not check_response.json():
                    # Tạo membership mới
                    membership_data = {
                        "user_id": user_id,
                        "club_id": club_id,
                        "status": "active",
                        "role": "member"
                    }
                    
                    create_response = requests.post(
                        f"{SUPABASE_URL}/rest/v1/club_members",
                        headers=headers,
                        json=membership_data
                    )
                    
                    if create_response.status_code in [200, 201]:
                        print("✅ Created test membership")
                        return True
                    else:
                        print(f"❌ Failed to create membership: {create_response.text}")
                        return False
                else:
                    print("✅ Test membership already exists")
                    return True
            else:
                print("❌ No users or clubs found")
                return False
        else:
            print("❌ Failed to get users/clubs")
            return False
            
    except Exception as e:
        print(f"❌ Error setting up test data: {e}")
        return False

def test_system():
    """Test hệ thống automation"""
    print("\n🧪 Testing automation system...")
    
    try:
        # Test function get_users_without_rank
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/get_users_without_rank",
            headers=headers,
            json={}
        )
        
        if response.status_code == 200:
            users = response.json()
            print(f"✅ Found {len(users)} users without rank")
            
            if users:
                # Test confirm_user_rank với user đầu tiên
                test_user_id = users[0]['user_id']
                
                # Lấy club_id từ membership
                member_response = requests.get(
                    f"{SUPABASE_URL}/rest/v1/club_members?user_id=eq.{test_user_id}&limit=1",
                    headers=headers
                )
                
                if member_response.status_code == 200 and member_response.json():
                    club_id = member_response.json()[0]['club_id']
                    
                    # Test confirm_user_rank
                    confirm_response = requests.post(
                        f"{SUPABASE_URL}/rest/v1/rpc/confirm_user_rank",
                        headers=headers,
                        json={
                            "p_user_id": test_user_id,
                            "p_club_id": club_id,
                            "p_confirmed_rank": "B"
                        }
                    )
                    
                    if confirm_response.status_code == 200:
                        result = confirm_response.json()
                        print(f"✅ Confirm rank result: {result}")
                        
                        # Kiểm tra user đã được cập nhật
                        time.sleep(2)
                        user_check = requests.get(
                            f"{SUPABASE_URL}/rest/v1/users?id=eq.{test_user_id}&select=display_name,rank,elo_rating",
                            headers=headers
                        )
                        
                        if user_check.status_code == 200 and user_check.json():
                            updated_user = user_check.json()[0]
                            rank = updated_user.get('rank')
                            elo = updated_user.get('elo_rating')
                            name = updated_user.get('display_name')
                            
                            print(f"📊 User {name}: rank={rank}, elo={elo}")
                            
                            if rank == 'B' and elo == 1600:
                                print("🎉 AUTOMATION SUCCESS!")
                                return True
                            else:
                                print("⚠️ Automation partially working")
                                return False
                        else:
                            print("❌ Failed to verify user update")
                            return False
                    else:
                        print(f"❌ Confirm rank failed: {confirm_response.text}")
                        return False
                else:
                    print("❌ No membership found for test user")
                    return False
            else:
                print("ℹ️ No users without rank found")
                return True
        else:
            print(f"❌ get_users_without_rank failed: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Error testing system: {e}")
        return False

def main():
    print("🚀 AUTOMATIC SQL EXECUTION FOR RANK/ELO SYSTEM")
    print("=" * 60)
    print("🔑 Using service role to execute SQL directly")
    print("=" * 60)
    
    steps = [
        ("1️⃣ Adding columns to club_members", add_columns_to_club_members),
        ("2️⃣ Creating update function", create_update_function),
        ("3️⃣ Creating trigger", create_trigger),
        ("4️⃣ Creating confirm_user_rank function", create_confirm_rank_function),
        ("5️⃣ Creating get_users_without_rank function", create_get_users_function),
        ("6️⃣ Setting up test data", setup_test_data),
    ]
    
    success_count = 0
    for step_name, step_func in steps:
        print(f"\n{step_name}")
        print("-" * 40)
        
        if step_func():
            success_count += 1
            print(f"✅ {step_name} completed")
        else:
            print(f"❌ {step_name} failed")
            
        time.sleep(1)
    
    print(f"\n📊 SETUP SUMMARY:")
    print(f"✅ Completed: {success_count}/{len(steps)} steps")
    
    if success_count == len(steps):
        print("\n🎉 ALL SETUP COMPLETED!")
        print("Testing the system...")
        
        if test_system():
            print("\n🏆 RANK/ELO AUTOMATION SYSTEM IS FULLY OPERATIONAL!")
            print("\n💡 Usage:")
            print("  • Admin: SELECT confirm_user_rank('user_id', 'club_id', 'B');")
            print("  • Check: SELECT * FROM get_users_without_rank();")
            print("  • Users will automatically get updated rank & ELO")
        else:
            print("\n⚠️ Setup completed but testing failed")
            print("Please check the functions manually")
    else:
        print(f"\n❌ Setup incomplete ({success_count}/{len(steps)})")
        print("Some SQL commands may need to be run manually in Supabase Dashboard")

if __name__ == "__main__":
    main()