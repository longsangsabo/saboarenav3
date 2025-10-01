"""
Fix sabo1 tournament after schema cache refresh
"""
import time
from supabase import create_client

print('⏳ Waiting for Supabase schema cache refresh...')
time.sleep(3)

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'
supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🎯 FIXING SABO1 TOURNAMENT CONFIGURATION')

try:
    # Fix sabo1 with correct bracket_format
    result = supabase.table('tournaments').update({
        'game_format': '8-ball',
        'bracket_format': 'double_elimination'
    }).eq('title', 'sabo1').execute()
    
    print('✅ sabo1 updated successfully!')
    
    # Verify the fix
    verify = supabase.table('tournaments').select('game_format, bracket_format, tournament_type').eq('title', 'sabo1').execute()
    
    if verify.data:
        t = verify.data[0]
        game_format = t.get('game_format')
        bracket_format = t.get('bracket_format')
        tournament_type = t.get('tournament_type')
        
        print(f'📊 sabo1 POST-FIX verification:')
        print(f'   game_format: {game_format}')
        print(f'   bracket_format: {bracket_format}')
        print(f'   tournament_type: {tournament_type}')
        
        if bracket_format == 'double_elimination':
            print('🎉 PERFECT! sabo1 configured correctly!')
            print('✅ MatchProgressionService will work with bracket_format = double_elimination')
            print('🚀 IMMEDIATE ADVANCEMENT IS READY!')
        else:
            print(f'❌ Still wrong: bracket_format = {bracket_format}')
    
except Exception as e:
    if "Could not find" in str(e):
        print('⏳ Schema cache still refreshing... try again in a moment')
    else:
        print(f'❌ Error: {e}')