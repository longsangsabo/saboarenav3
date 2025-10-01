import os
from supabase import create_client, Client

# Configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SERVICE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo"

supabase: Client = create_client(SUPABASE_URL, SERVICE_KEY)

print("🔍 Checking tournament_matches table...")

try:
    # Get all records from tournament_matches
    result = supabase.table('tournament_matches').select("*").execute()
    
    print(f"📊 Found {len(result.data)} records in tournament_matches:")
    for match in result.data:
        print(f"  - Match ID: {match['id']}")
        print(f"    Tournament: {match['tournament_id']}")
        print(f"    Players: {match['player1_id']} vs {match['player2_id']}")
        print(f"    Round: {match['round_number']}, Match: {match['match_number']}")
        print(f"    Status: {match['match_status']}")
        print("    ---")

except Exception as e:
    print(f"❌ Error checking tournament_matches: {e}")

print("🏆 Checking tournaments table...")

try:
    # Get tournaments to see what we have
    result = supabase.table('tournaments').select("id, tournament_name, status").execute()
    
    print(f"📊 Found {len(result.data)} tournaments:")
    for tournament in result.data:
        print(f"  - {tournament['tournament_name']} ({tournament['id']}) - Status: {tournament['status']}")

except Exception as e:
    print(f"❌ Error checking tournaments: {e}")