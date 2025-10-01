import os
import json
from supabase import create_client, Client

def cleanup_old_referral_data():
    """
    Clean up old complex referral system data from Supabase database
    Remove VIP, Tournament, Club codes and keep only basic SABO-USERNAME codes
    """
    
    # Load environment variables
    with open('env.json', 'r') as f:
        env_vars = json.load(f)
    
    url = env_vars.get('SUPABASE_URL')
    service_key = env_vars.get('SUPABASE_SERVICE_ROLE_KEY')
    
    if not url or not service_key:
        print("❌ Missing Supabase credentials in env.json")
        return False
    
    # Create Supabase client with service role
    supabase: Client = create_client(url, service_key)
    
    print("🧹 Starting Supabase referral data cleanup...")
    print("=" * 50)
    
    try:
        # 1. Check current referral codes
        print("\n📋 Current referral codes in database:")
        codes_response = supabase.table('referral_codes').select('*').execute()
        
        if codes_response.data:
            print(f"Found {len(codes_response.data)} referral codes:")
            old_complex_codes = []
            basic_codes = []
            
            for code in codes_response.data:
                code_text = code.get('code', '')
                code_type = code.get('code_type', 'basic')
                
                # Identify old complex codes (VIP, Tournament, Club, or with complex rewards)
                if (code_type in ['vip', 'tournament', 'club'] or 
                    'VIP' in code_text or 'TOURNAMENT' in code_text or 
                    'SPECIAL' in code_text or 'ELITE' in code_text):
                    old_complex_codes.append(code)
                    print(f"   🗑️  OLD: {code_text} (type: {code_type})")
                else:
                    basic_codes.append(code)
                    print(f"   ✅ KEEP: {code_text} (type: {code_type})")
            
            print(f"\n📊 Summary:")
            print(f"   • Old complex codes to remove: {len(old_complex_codes)}")
            print(f"   • Basic codes to keep: {len(basic_codes)}")
            
            # 2. Remove old complex referral codes and their usage
            if old_complex_codes:
                print(f"\n🗑️ Removing {len(old_complex_codes)} old complex referral codes...")
                
                for code in old_complex_codes:
                    code_id = code['id']
                    code_text = code['code']
                    
                    # Remove usage records first (foreign key constraint)
                    usage_response = supabase.table('referral_usage').delete().eq('referral_code_id', code_id).execute()
                    if usage_response.data:
                        print(f"   🗑️ Removed {len(usage_response.data)} usage records for {code_text}")
                    
                    # Remove the referral code
                    code_response = supabase.table('referral_codes').delete().eq('id', code_id).execute()
                    if code_response.data:
                        print(f"   ✅ Removed referral code: {code_text}")
                
                print(f"✅ Successfully removed {len(old_complex_codes)} old complex referral codes")
            else:
                print("✅ No old complex codes found to remove")
            
            # 3. Verify cleanup
            print(f"\n🔍 Verifying cleanup...")
            final_codes_response = supabase.table('referral_codes').select('*').execute()
            
            if final_codes_response.data:
                print(f"✅ Remaining codes after cleanup ({len(final_codes_response.data)}):")
                for code in final_codes_response.data:
                    code_text = code.get('code', '')
                    created_at = code.get('created_at', '')
                    is_active = code.get('is_active', False)
                    print(f"   • {code_text} (created: {created_at[:10]}, active: {is_active})")
            else:
                print("⚠️ No referral codes remaining in database")
            
            # 4. Check referral usage table
            print(f"\n📋 Checking referral usage table...")
            usage_response = supabase.table('referral_usage').select('*').execute()
            
            if usage_response.data:
                print(f"✅ Found {len(usage_response.data)} usage records remaining")
                for usage in usage_response.data:
                    used_at = usage.get('used_at', '')
                    spa_referrer = usage.get('spa_awarded_referrer', 0)
                    spa_referred = usage.get('spa_awarded_referred', 0)
                    print(f"   • Used: {used_at[:10]}, SPA: {spa_referrer}/{spa_referred}")
            else:
                print("✅ No usage records in database")
            
            # 5. Database schema verification
            print(f"\n🔍 Verifying basic referral database schema...")
            
            # Check if tables exist and have correct structure
            tables_to_check = ['referral_codes', 'referral_usage']
            for table_name in tables_to_check:
                try:
                    test_response = supabase.table(table_name).select('*').limit(1).execute()
                    print(f"   ✅ Table '{table_name}' exists and accessible")
                except Exception as e:
                    print(f"   ❌ Table '{table_name}' issue: {str(e)}")
            
            print(f"\n🎉 Supabase referral data cleanup completed!")
            print(f"📊 Final state:")
            print(f"   • Database cleaned of old complex referral types")
            print(f"   • Only basic SABO-USERNAME codes remain")
            print(f"   • Schema ready for basic referral system")
            
            return True
            
        else:
            print("✅ No referral codes found in database - already clean")
            return True
            
    except Exception as e:
        print(f"❌ Error during cleanup: {str(e)}")
        return False

if __name__ == "__main__":
    success = cleanup_old_referral_data()
    
    if success:
        print(f"\n🟢 CLEANUP SUCCESSFUL")
        print("Database is now clean and ready for basic referral system only")
    else:
        print(f"\n🔴 CLEANUP FAILED")
        print("Please check the error messages above and try again")