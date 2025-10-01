from supabase import create_client

def apply_update_policy_with_service_role():
    try:
        url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
        # Use service role key for admin operations
        service_key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
        supabase = create_client(url, service_key)

        print("=== APPLYING MATCH UPDATE POLICY (SERVICE ROLE) ===\n")
        
        # Simple policy that allows all updates for now (we can make it more restrictive later)
        update_policy_sql = """
        DROP POLICY IF EXISTS "Allow updating matches for participants" ON matches;
        DROP POLICY IF EXISTS "Allow updating matches" ON matches;
        
        CREATE POLICY "Allow updating matches" ON matches 
        FOR UPDATE 
        TO public 
        USING (true);
        """
        
        print("📝 Creating update policy for matches...")
        result = supabase.rpc('exec_sql', {'sql': update_policy_sql}).execute()
        print("✅ Update policy created!")
        
        # Test with anon key now
        print("\n🧪 Testing match update with anon key...")
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
                # Revert
                anon_supabase.table('matches').update({'player1_score': 0}).eq('id', match_id).execute()
                print("   ✅ Test complete, reverted changes")
            else:
                print("   ❌ Still not working")

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    apply_update_policy_with_service_role()