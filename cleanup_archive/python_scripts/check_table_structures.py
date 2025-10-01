import requests
import json

# Supabase connection details with service role
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_ROLE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

headers = {
    'apikey': SERVICE_ROLE_KEY,
    'Authorization': f'Bearer {SERVICE_ROLE_KEY}',
    'Content-Type': 'application/json'
}

def get_table_structure(table_name):
    print(f"=== STRUCTURE OF TABLE: {table_name} ===\n")
    
    try:
        # Get first few records to understand structure
        response = requests.get(
            f"{SUPABASE_URL}/rest/v1/{table_name}",
            headers=headers,
            params={"select": "*", "limit": "3"}
        )
        
        if response.status_code == 200:
            data = response.json()
            print(f"Sample data from {table_name}:")
            print(json.dumps(data, indent=2, default=str))
            
            if data:
                print(f"\nColumns in {table_name}:")
                for key in data[0].keys():
                    print(f"  - {key}")
        else:
            print(f"Error getting {table_name}: {response.status_code} - {response.text}")
            
    except Exception as e:
        print(f"Error: {e}")

def check_user_tables():
    print("=== CHECKING USER-RELATED TABLES ===\n")
    
    user_tables = ['users', 'users', 'profiles']
    
    for table in user_tables:
        try:
            response = requests.get(
                f"{SUPABASE_URL}/rest/v1/{table}",
                headers=headers,
                params={"select": "*", "limit": "1"}
            )
            
            if response.status_code == 200:
                data = response.json()
                print(f"✅ Table '{table}' exists")
                if data:
                    print(f"   Columns: {list(data[0].keys())}")
                else:
                    print("   (Empty table)")
            else:
                print(f"❌ Table '{table}' does not exist - Status: {response.status_code}")
                
        except Exception as e:
            print(f"❌ Error checking table '{table}': {e}")
        print()

if __name__ == "__main__":
    get_table_structure("clubs")
    print("\n" + "="*50 + "\n")
    get_table_structure("club_members")
    print("\n" + "="*50 + "\n")
    check_user_tables()