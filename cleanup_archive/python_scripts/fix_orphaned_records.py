import os
import json
from supabase import create_client, Client

def fix_orphaned_usage_records():
    """Fix orphaned usage records in referral_usage table"""
    
    with open('env.json', 'r') as f:
        env_vars = json.load(f)
    
    url = env_vars.get('SUPABASE_URL')
    service_key = env_vars.get('SUPABASE_SERVICE_ROLE_KEY')
    supabase: Client = create_client(url, service_key)
    
    print("🔧 Fixing orphaned usage records...")
    
    try:
        # Get all referral codes
        codes_response = supabase.table('referral_codes').select('id').execute()
        valid_code_ids = {code['id'] for code in codes_response.data}
        
        # Get all usage records
        usage_response = supabase.table('referral_usage').select('*').execute()
        
        orphaned_count = 0
        for usage in usage_response.data:
            if usage['referral_code_id'] not in valid_code_ids:
                # Delete orphaned record
                supabase.table('referral_usage').delete().eq('id', usage['id']).execute()
                orphaned_count += 1
                print(f"   ✅ Removed orphaned usage record: {usage['id']}")
        
        if orphaned_count == 0:
            print("   ✅ No orphaned records found")
        else:
            print(f"   ✅ Removed {orphaned_count} orphaned usage records")
        
        return True
        
    except Exception as e:
        print(f"❌ Error fixing orphaned records: {str(e)}")
        return False

if __name__ == "__main__":
    fix_orphaned_usage_records()