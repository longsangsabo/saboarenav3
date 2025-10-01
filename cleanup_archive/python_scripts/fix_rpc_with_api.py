import requests
import json

# Supabase Configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def execute_sql_script():
    print("🔄 Recreating RPC functions with correct column names...")
    
    # Define the corrected SQL commands
    sql_commands = [
        # Drop existing functions
        "DROP FUNCTION IF EXISTS public.update_match_result(uuid, uuid, integer, integer);",
        "DROP FUNCTION IF EXISTS public.update_match_result(p_match_id uuid, p_winner_id uuid, p_player1_score integer, p_player2_score integer);",
        "DROP FUNCTION IF EXISTS public.start_match(uuid);",
        
        # Create corrected update_match_result function
        """CREATE OR REPLACE FUNCTION public.update_match_result(
            p_match_id uuid,
            p_winner_id uuid,
            p_player1_score integer,
            p_player2_score integer
        )
        RETURNS json
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        DECLARE
            result_data json;
        BEGIN
            -- Update the match with new scores and winner
            UPDATE public.matches 
            SET 
                player1_score = p_player1_score,
                player2_score = p_player2_score,
                winner_id = p_winner_id,
                status = 'completed',
                updated_at = now()
            WHERE id = p_match_id;
            
            -- Check if update was successful
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Match not found with ID: %', p_match_id;
            END IF;
            
            -- Return success response
            SELECT json_build_object(
                'success', true,
                'match_id', p_match_id,
                'winner_id', p_winner_id,
                'player1_score', p_player1_score,
                'player2_score', p_player2_score,
                'message', 'Match result updated successfully'
            ) INTO result_data;
            
            RETURN result_data;
        END;
        $$;""",
        
        # Create start_match function
        """CREATE OR REPLACE FUNCTION public.start_match(
            p_match_id uuid
        )
        RETURNS json
        LANGUAGE plpgsql
        SECURITY DEFINER
        AS $$
        DECLARE
            result_data json;
        BEGIN
            -- Update match status to 'in_progress'
            UPDATE public.matches 
            SET 
                status = 'in_progress',
                updated_at = now()
            WHERE id = p_match_id;
            
            -- Check if update was successful
            IF NOT FOUND THEN
                RAISE EXCEPTION 'Match not found with ID: %', p_match_id;
            END IF;
            
            -- Return success response
            SELECT json_build_object(
                'success', true,
                'match_id', p_match_id,
                'status', 'in_progress',
                'message', 'Match started successfully'
            ) INTO result_data;
            
            RETURN result_data;
        END;
        $$;""",
        
        # Grant permissions
        "GRANT EXECUTE ON FUNCTION public.update_match_result(uuid, uuid, integer, integer) TO anon;",
        "GRANT EXECUTE ON FUNCTION public.update_match_result(uuid, uuid, integer, integer) TO authenticated;",
        "GRANT EXECUTE ON FUNCTION public.start_match(uuid) TO anon;",
        "GRANT EXECUTE ON FUNCTION public.start_match(uuid) TO authenticated;"
    ]
    
    # Execute each command via REST API
    headers = {
        'apikey': SUPABASE_ANON_KEY,
        'Authorization': f'Bearer {SUPABASE_ANON_KEY}',
        'Content-Type': 'application/json'
    }
    
    for i, sql in enumerate(sql_commands):
        print(f"Executing command {i+1}/{len(sql_commands)}...")
        
        try:
            # Try to execute via RPC (if available)
            payload = {'sql': sql}
            response = requests.post(
                f"{SUPABASE_URL}/rest/v1/rpc/exec_sql",
                headers=headers,
                json=payload
            )
            
            if response.status_code == 200:
                print(f"✅ Command {i+1} executed successfully")
            else:
                print(f"❌ Command {i+1} failed: {response.text}")
                
        except Exception as e:
            print(f"❌ Error executing command {i+1}: {e}")
    
    print("\n🎉 RPC function recreation completed!")

def test_function():
    print("\n🔍 Testing the updated function...")
    
    from supabase import create_client, Client
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_ANON_KEY)
    
    try:
        result = supabase.rpc('update_match_result', {
            'p_match_id': '95e93231-86c5-4cc7-b970-179f4bc14da3',
            'p_winner_id': '734f24dd-db05-4b56-bc68-7221cca4c4c5',
            'p_player1_score': 1,
            'p_player2_score': 0
        }).execute()
        
        print("✅ Function test successful!")
        print(f"Result: {result.data}")
        
    except Exception as e:
        print(f"❌ Function test failed: {e}")

if __name__ == "__main__":
    execute_sql_script()
    test_function()