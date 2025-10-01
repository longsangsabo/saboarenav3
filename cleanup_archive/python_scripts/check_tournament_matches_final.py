import os
from supabase import create_client, Client

# Configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase: Client = create_client(SUPABASE_URL, SERVICE_KEY)

print("🔍 Checking matches table for tournament matches...")

try:
    # Get matches where match_type is 'tournament'
    result = supabase.table('matches').select("*").eq('match_type', 'tournament').execute()
    
    print(f"📊 Found {len(result.data)} tournament matches:")
    for match in result.data:
        print(f"  - Match ID: {match['id'][:8]}...")
        print(f"    Tournament: {match['tournament_id'][:8]}...")
        print(f"    Players: {match['player1_id'][:8]}... vs {match['player2_id'][:8] if match['player2_id'] else 'None'}...")
        print(f"    Round: {match['round_number']}, Match: {match['match_number']}")
        print(f"    Status: {match['status']}")
        print(f"    Type: {match['match_type']}")
        print("    ---")

except Exception as e:
    print(f"❌ Error checking tournament matches: {e}")

print("🏆 Checking all recent matches...")

try:
    # Get all matches from today
    from datetime import datetime
    today = datetime.now().strftime('%Y-%m-%d')
    
    result = supabase.table('matches').select("*").gte('created_at', today).execute()
    
    print(f"📊 Found {len(result.data)} matches created today:")
    for match in result.data:
        print(f"  - Match ID: {match['id'][:8]}...")
        print(f"    Type: {match['match_type']}")
        print(f"    Status: {match['status']}")
        print(f"    Created: {match['created_at']}")
        print("    ---")

except Exception as e:
    print(f"❌ Error checking recent matches: {e}")