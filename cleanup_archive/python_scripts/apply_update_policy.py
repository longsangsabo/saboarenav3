from supabase import create_client

def apply_update_policy():
    try:
        url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
        key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgjgdiyOdLSdSWJWczHoQ'
        supabase = create_client(url, key)

        print("=== APPLYING MATCH UPDATE POLICY ===\n")
        
        # Read SQL policy
        with open('fix_match_update_policy.sql', 'r', encoding='utf-8') as f:
            sql_commands = f.read()
        
        # Split commands by semicolon
        commands = [cmd.strip() for cmd in sql_commands.split(';') if cmd.strip() and not cmd.strip().startswith('--')]
        
        for i, command in enumerate(commands, 1):
            if command:
                print(f"📝 Executing command {i}...")
                print(f"   {command[:50]}...")
                
                try:
                    result = supabase.rpc('exec_sql', {'sql': command}).execute()
                    print(f"   ✅ Command {i} executed successfully")
                except Exception as e:
                    print(f"   ❌ Command {i} failed: {e}")
                    # Try alternative method
                    try:
                        result = supabase.postgrest.rpc('exec_sql', {'sql': command}).execute()
                        print(f"   ✅ Command {i} executed with alternative method")
                    except Exception as e2:
                        print(f"   ❌ Alternative also failed: {e2}")
        
        print(f"\n✅ Policy application complete!")
        
        # Test update again
        print("\n🧪 Testing match update after policy fix...")
        matches = supabase.table('matches').select('*').eq('tournament_id', '20e4493c-c163-43c3-9d4d-58a5d7f59ec6').limit(1).execute()
        
        if matches.data:
            match_id = matches.data[0]['id']
            result = supabase.table('matches').update({'player1_score': 1}).eq('id', match_id).execute()
            print(f"   Update result: {len(result.data)} record(s) updated")
            
            if len(result.data) > 0:
                print("   🎉 UPDATE NOW WORKS!")
                # Revert
                supabase.table('matches').update({'player1_score': 0}).eq('id', match_id).execute()
            else:
                print("   ❌ Still not working - may need service role")

    except Exception as e:
        print(f"❌ Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    apply_update_policy()