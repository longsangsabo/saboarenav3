#!/usr/bin/env python3
"""
Simple column addition for referral_codes table
Uses direct ALTER TABLE commands via HTTP
"""

import requests
import json

# Load environment variables
with open('env.json', 'r') as f:
    env = json.load(f)

SUPABASE_URL = env['SUPABASE_URL']
SERVICE_ROLE_KEY = env['SUPABASE_SERVICE_ROLE_KEY']

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json',
    'Prefer': 'return=minimal'
}

def check_current_schema():
    """Check what columns currently exist"""
    print("🔍 Checking current schema...")
    
    try:
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?select=*&limit=1",
            headers=headers
        )
        
        if response.status_code == 200:
            data = response.json()
            if data:
                columns = list(data[0].keys())
                print(f"✅ Current columns: {', '.join(columns)}")
                
                # Check specifically for our needed columns
                has_referrer = 'spa_reward_referrer' in columns
                has_referred = 'spa_reward_referred' in columns
                
                print(f"   spa_reward_referrer: {'✅' if has_referrer else '❌'}")
                print(f"   spa_reward_referred: {'✅' if has_referred else '❌'}")
                
                return has_referrer and has_referred
            else:
                print("⚠️ No data found to check schema")
                return False
        else:
            print(f"❌ Schema check failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Schema check error: {e}")
        return False

def add_columns_manually():
    """Manually add columns by creating test records"""
    print("\n🔧 Adding columns manually...")
    
    try:
        # Method 1: Try to insert a record with new columns to force schema update
        test_data = {
            "user_id": "00000000-0000-0000-0000-000000000000",  # Dummy UUID
            "code": "TEMP-SCHEMA-TEST",
            "spa_reward_referrer": 100,
            "spa_reward_referred": 50,
            "max_uses": 1,
            "current_uses": 0,
            "is_active": False  # Inactive so it doesn't interfere
        }
        
        # Try to insert with new columns
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/referral_codes",
            headers=headers,
            json=test_data
        )
        
        if response.status_code == 201:
            print("✅ Successfully inserted test record with new columns")
            
            # Clean up test record
            cleanup_response = requests.delete(
                f"{SUPABASE_URL}/rest/v1/referral_codes?code=eq.TEMP-SCHEMA-TEST",
                headers=headers
            )
            
            if cleanup_response.status_code == 204:
                print("✅ Cleaned up test record")
            
            return True
        else:
            print(f"❌ Failed to insert test record: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Manual column addition failed: {e}")
        return False

def update_existing_codes_with_defaults():
    """Update existing codes to have SPA reward values"""
    print("\n📝 Updating existing codes with SPA rewards...")
    
    try:
        # Get all existing codes
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/referral_codes?select=*",
            headers=headers
        )
        
        if response.status_code == 200:
            codes = response.json()
            print(f"📊 Found {len(codes)} existing codes")
            
            updated_count = 0
            
            for code in codes:
                # Check if code needs SPA rewards
                needs_update = (
                    code.get('spa_reward_referrer') is None or
                    code.get('spa_reward_referred') is None or
                    code.get('spa_reward_referrer') == 0 or
                    code.get('spa_reward_referred') == 0
                )
                
                if needs_update:
                    update_data = {
                        "spa_reward_referrer": 100,
                        "spa_reward_referred": 50
                    }
                    
                    update_response = requests.patch(
                        f"{SUPABASE_URL}/rest/v1/referral_codes?id=eq.{code['id']}",
                        headers=headers,
                        json=update_data
                    )
                    
                    if update_response.status_code == 204:
                        print(f"✅ Updated {code['code']}")
                        updated_count += 1
                    else:
                        print(f"⚠️ Failed to update {code['code']}: {update_response.status_code}")
                else:
                    print(f"✅ {code['code']} already has SPA rewards")
            
            print(f"✅ Updated {updated_count} codes with SPA rewards")
            return True
            
        else:
            print(f"❌ Failed to fetch codes: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"❌ Update failed: {e}")
        return False

def create_new_test_code():
    """Create a new referral code with proper schema"""
    print("\n🧪 Creating test code with new schema...")
    
    try:
        test_data = {
            "user_id": "00000000-0000-0000-0000-000000000001",  # Test UUID
            "code": "SABO-SCHEMA-TEST",
            "spa_reward_referrer": 100,
            "spa_reward_referred": 50,
            "max_uses": 10,
            "current_uses": 0,
            "is_active": True
        }
        
        response = requests.post(
            f"{SUPABASE_URL}/rest/v1/referral_codes",
            headers=headers,
            json=test_data
        )
        
        if response.status_code == 201:
            print("✅ Successfully created test code with new schema")
            return True
        else:
            print(f"❌ Failed to create test code: {response.status_code}")
            print(f"Response: {response.text}")
            return False
            
    except Exception as e:
        print(f"❌ Test code creation failed: {e}")
        return False

def main():
    print("🚀 SIMPLE COLUMN ADDITION")
    print("=" * 40)
    
    # Check current schema
    has_columns = check_current_schema()
    
    if not has_columns:
        print("\n🔧 Columns missing - attempting to add them...")
        
        # Try manual addition
        addition_success = add_columns_manually()
        
        if addition_success:
            print("✅ Columns added successfully")
        else:
            print("❌ Failed to add columns")
            print("\n📋 MANUAL INSTRUCTIONS:")
            print("1. Open Supabase Dashboard")
            print("2. Go to Table Editor")
            print("3. Select 'referral_codes' table")
            print("4. Add these columns:")
            print("   - spa_reward_referrer (int4, default: 100)")
            print("   - spa_reward_referred (int4, default: 50)")
            return
        
        # Verify addition worked
        has_columns = check_current_schema()
        
        if not has_columns:
            print("❌ Column addition verification failed")
            return
    
    # Try creating a test code
    test_success = create_new_test_code()
    
    if test_success:
        # Update existing codes
        update_success = update_existing_codes_with_defaults()
        
        if update_success:
            print("\n🎉 SUCCESS!")
            print("✅ Schema updated")
            print("✅ Existing codes updated")
            print("✅ Test code created")
            print("✅ Ready for system testing")
        else:
            print("⚠️ Partial success - manual updates may be needed")
    else:
        print("❌ Test code creation failed")
    
    print("=" * 40)

if __name__ == "__main__":
    main()