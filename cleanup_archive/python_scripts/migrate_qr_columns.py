import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def run_sql_migration(sql_content):
    """Execute SQL migration via Supabase REST API"""
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    print("🔧 Running SQL Migration...")
    print("=" * 30)
    
    try:
        # Use rpc to execute raw SQL
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
            headers=headers,
            json={"sql": sql_content}
        )
        
        if response.status_code == 200:
            print("✅ SQL Migration executed successfully!")
            return True
        else:
            print(f"❌ Migration failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"💥 Exception running migration: {e}")
        return False

def execute_qr_migration():
    """Execute the QR columns migration"""
    
    sql_migration = """
    -- Add QR columns to existing users table
    ALTER TABLE users 
    ADD COLUMN IF NOT EXISTS user_code TEXT UNIQUE,
    ADD COLUMN IF NOT EXISTS qr_data TEXT;
    
    -- Add index for faster QR lookups
    CREATE INDEX IF NOT EXISTS idx_users_user_code ON users(user_code);
    CREATE INDEX IF NOT EXISTS idx_users_qr_data ON users(qr_data);
    """
    
    print("🚀 SABO Arena - QR Migration")
    print("Adding QR columns to users table")
    print("=" * 40)
    
    success = run_sql_migration(sql_migration)
    
    if success:
        print("\n✅ QR Migration Complete!")
        print("📋 Added columns:")
        print("   • user_code (TEXT UNIQUE)")
        print("   • qr_data (TEXT)")
        print("   • Indexes for fast lookup")
        return True
    else:
        print("\n❌ Migration failed!")
        return False

def verify_columns():
    """Verify that QR columns were added"""
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    print("\n🔍 Verifying QR Columns...")
    print("=" * 30)
    
    try:
        # Try to select the new columns
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id,full_name,user_code,qr_data&limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            print("✅ QR columns verified successfully!")
            data = response.json()
            if data:
                user = data[0]
                print(f"   👤 Sample user: {user.get('full_name', 'N/A')}")
                print(f"   🔢 user_code: {user.get('user_code', 'NULL')}")
                print(f"   📱 qr_data: {user.get('qr_data', 'NULL')}")
            return True
        else:
            print(f"❌ Verification failed: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"💥 Exception: {e}")
        return False

def add_qr_to_first_user():
    """Add QR code to the first user for testing"""
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
    }
    
    print("\n📋 Adding QR code to first user...")
    print("=" * 35)
    
    try:
        # Get first user
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            users = response.json()
            if users:
                user = users[0]
                user_id = user['id']
                
                print(f"👤 Found user: {user.get('full_name', 'N/A')}")
                
                # Add QR data
                qr_update = {
                    "user_code": "SABO123456",
                    "qr_data": "SABO123456"
                }
                
                update_response = requests.patch(
                    f"{SUPABASE_URL}/rest/v1/users?id=eq.{user_id}",
                    headers=headers,
                    json=qr_update
                )
                
                if update_response.status_code == 200:
                    print("✅ QR code added successfully!")
                    print(f"   🔢 Code: SABO123456")
                    return True
                else:
                    print(f"❌ Failed to add QR: {update_response.text}")
                    return False
            else:
                print("❌ No users found")
                return False
        else:
            print(f"❌ Error getting users: {response.text}")
            return False
            
    except Exception as e:
        print(f"💥 Exception: {e}")
        return False

def test_qr_lookup():
    """Test QR code lookup"""
    
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    print("\n🔍 Testing QR Code Lookup...")
    print("=" * 30)
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?user_code=eq.SABO123456&select=id,full_name,email,user_code,skill_level",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            if data:
                user = data[0]
                print("🎉 QR LOOKUP SUCCESS!")
                print(f"   👤 User: {user.get('full_name', 'N/A')}")
                print(f"   📧 Email: {user.get('email', 'N/A')}")
                print(f"   🏆 Skill: {user.get('skill_level', 'N/A')}")
                print(f"   🔢 QR Code: {user.get('user_code', 'N/A')}")
                return True
            else:
                print("❌ No user found with QR code")
                return False
        else:
            print(f"❌ API Error: {response.status_code} - {response.text}")
            return False
            
    except Exception as e:
        print(f"💥 Exception: {e}")
        return False

if __name__ == "__main__":
    print("🚀 SABO Arena - QR Column Migration")
    print("=" * 40)
    
    # Step 1: Execute migration
    migration_success = execute_qr_migration()
    
    if migration_success:
        # Step 2: Verify columns exist
        verify_success = verify_columns()
        
        if verify_success:
            # Step 3: Add test QR code
            qr_add_success = add_qr_to_first_user()
            
            if qr_add_success:
                # Step 4: Test lookup
                lookup_success = test_qr_lookup()
                
                if lookup_success:
                    print("\n" + "=" * 40)
                    print("🎉 QR SYSTEM READY!")
                    print("✅ Columns added")
                    print("✅ QR code assigned")  
                    print("✅ Lookup working")
                    print("📱 Ready for Flutter app!")
                    print("=" * 40)
                else:
                    print("\n❌ QR lookup failed")
            else:
                print("\n❌ Failed to add QR code")
        else:
            print("\n❌ Column verification failed")
    else:
        print("\n❌ Migration failed")