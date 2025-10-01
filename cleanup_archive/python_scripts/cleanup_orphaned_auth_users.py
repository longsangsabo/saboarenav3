import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    "apikey": SERVICE_ROLE_KEY,
    "Authorization": f"Bearer {SERVICE_ROLE_KEY}",
    "Content-Type": "application/json"
}

def cleanup_orphaned_auth_users():
    print("🧹 CLEANUP: Remove orphaned auth users")
    print("="*50)
    
    # Get all auth users
    try:
        response = requests.get(
            f"{SUPABASE_URL}/auth/v1/admin/users",
            headers=headers
        )
        
        if response.status_code != 200:
            print(f"❌ Cannot get auth users: {response.text}")
            return
        
        auth_data = response.json()
        auth_users = auth_data.get('users', [])
        print(f"📊 Found {len(auth_users)} auth users")
        
        # Get all public users
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/users?select=id",
            headers=headers
        )
        
        if response.status_code != 200:
            print(f"❌ Cannot get public users: {response.text}")
            return
        
        public_users = response.json()
        public_user_ids = {user['id'] for user in public_users}
        print(f"📊 Found {len(public_user_ids)} public users")
        
        # Find orphaned auth users
        orphaned_count = 0
        for auth_user in auth_users:
            auth_id = auth_user['id']
            email = auth_user.get('email', '')
            
            if auth_id not in public_user_ids:
                print(f"🗑️  Deleting orphaned auth user: {email} ({auth_id})")
                
                # Delete auth user
                try:
                    delete_response = requests.delete(
                        f"{SUPABASE_URL}/auth/v1/admin/users/{auth_id}",
                        headers=headers
                    )
                    
                    if delete_response.status_code in [200, 204]:
                        orphaned_count += 1
                        print(f"   ✅ Deleted successfully")
                    else:
                        print(f"   ❌ Delete failed: {delete_response.text[:100]}")
                        
                except Exception as e:
                    print(f"   ❌ Delete exception: {e}")
        
        print(f"\n🎉 Cleanup complete! Removed {orphaned_count} orphaned auth users")
        
    except Exception as e:
        print(f"❌ Cleanup failed: {e}")

if __name__ == "__main__":
    cleanup_orphaned_auth_users()