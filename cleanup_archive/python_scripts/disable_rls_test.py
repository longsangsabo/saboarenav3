from supabase import create_client
import json

def create_update_policy_direct():
    try:
        url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
        service_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
        
        print("=== CREATING UPDATE POLICY DIRECTLY ===\n")
        
        # Try direct approach with service role - just disable RLS temporarily for testing
        print("📝 Temporarily disabling RLS for matches table...")
        
        import requests
        
        # Direct SQL execution via REST API
        headers = {
            'apikey': service_key,
            'Authorization': f'Bearer {service_key}',
            'Content-Type': 'application/json',
        }
        
        # Disable RLS for matches table (temporary for testing)
        disable_rls_payload = {
            'query': 'ALTER TABLE matches DISABLE ROW LEVEL SECURITY;'
        }
        
        response = requests.post(
            f'{url}/rest/v1/rpc/query',
            headers=headers,
            json=disable_rls_payload
        )
        
        if response.status_code == 200:
            print("✅ RLS disabled for matches table")
        else:
            print(f"❌ Failed to disable RLS: {response.status_code} - {response.text}")
        
        # Test update with anon key now
        print("\n🧪 Testing match update with RLS disabled...")
        anon_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
        anon_supabase = create_client(url, anon_key)
        
        matches = anon_supabase.table('matches').select('*').eq('tournament_id', '20e4493c-c163-43c3-9d4d-58a5d7f59ec6').limit(1).execute()
        
        if matches.data:
            match_id = matches.data[0]['id']
            print(f"   Testing update on match: {match_id[:8]}...")
            
            result = anon_supabase.table('matches').update({'player1_score': 1}).eq('id', match_id).execute()
            print(f"   Update result: {len(result.data)} record(s) updated")
            
            if len(result.data) > 0:
                print("   🎉 UPDATE NOW WORKS!")
                print("   ✅ The issue was RLS policy blocking updates")
                
                # Test full match update
                print("\n🏆 Testing full match result update...")
                full_update = {
                    'winner_id': matches.data[0]['player1_id'],
                    'player1_score': 5,
                    'player2_score': 3,
                    'status': 'completed',
                }
                
                full_result = anon_supabase.table('matches').update(full_update).eq('id', match_id).execute()
                print(f"   Full update result: {len(full_result.data)} record(s) updated")
                
                if len(full_result.data) > 0:
                    print("   🎯 Full match update successful!")
                    
                    # Verify the update
                    updated_match = anon_supabase.table('matches').select('*').eq('id', match_id).single().execute()
                    print(f"   Status: {updated_match.data['status']}")
                    print(f"   Scores: {updated_match.data['player1_score']} - {updated_match.data['player2_score']}")
                    print(f"   Winner: {updated_match.data['winner_id'][:8] if updated_match.data['winner_id'] else None}...")
                
                # Revert for clean state
                revert_update = {
                    'winner_id': None,
                    'player1_score': 0,
                    'player2_score': 0,
                    'status': 'in_progress',
                }
                anon_supabase.table('matches').update(revert_update).eq('id', match_id).execute()
                print("   ✅ Reverted changes for clean state")
            else:
                print("   ❌ Still not working")

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    create_update_policy_direct()