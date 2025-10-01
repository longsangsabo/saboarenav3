#!/usr/bin/env python3
"""
Check matches table schema using Supabase API
"""
import requests
import json

# Supabase configuration
SUPABASE_URL = "https://mogjjvscxjwvhtpkrlqr.supabase.co"
SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ"

def check_schema_via_api():
    """Check if required columns exist by attempting to select them"""
    
    required_columns = [
        'scheduled_at',
        'round', 
        'format',
        'bracket_position',
        'parent_match_id',
        'next_match_id',
        'match_level',
        'is_final',
        'is_third_place'
    ]
    
    print("=== CHECKING MATCHES TABLE SCHEMA VIA API ===")
    
    for column in required_columns:
        try:
            url = f"{SUPABASE_URL}/rest/v1/matches"
            headers = {
                "apikey": SUPABASE_ANON_KEY,
                "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
                "Content-Type": "application/json"
            }
            
            # Try to select just this column with a limit of 1
            params = {
                "select": column,
                "limit": "1"
            }
            
            response = requests.get(url, headers=headers, params=params)
            
            if response.status_code == 200:
                print(f"  ✓ Column '{column}' - EXISTS")
            else:
                error_data = response.json() if response.content else {}
                error_msg = error_data.get('message', 'Unknown error')
                
                if 'does not exist' in error_msg or 'column' in error_msg.lower():
                    print(f"  ✗ Column '{column}' - MISSING")
                else:
                    print(f"  ? Column '{column}' - ERROR: {error_msg}")
                    
        except Exception as e:
            print(f"  ? Column '{column}' - EXCEPTION: {e}")

if __name__ == "__main__":
    check_schema_via_api()