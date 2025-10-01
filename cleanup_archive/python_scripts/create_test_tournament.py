from supabase import create_client
import uuid
from datetime import datetime

url = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
key = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'
supabase = create_client(url, key)

def create_test_tournament():
    print('🏆 Creating new test tournament for complete testing...')
    
    # Get available users  
    users_result = supabase.table('users').select('id, username, full_name').limit(8).execute()
    
    if len(users_result.data) < 8:
        print(f'❌ Need at least 8 users, found only {len(users_result.data)}')
        return None
        
    print(f'✅ Found {len(users_result.data)} users')
    for user in users_result.data:
        print(f'   - {user.get("full_name", "N/A")} ({user.get("username", "N/A")})')
    
    # Create new tournament
    tournament_id = str(uuid.uuid4())
    tournament_data = {
        'id': tournament_id,
        'name': f'Test Tournament {datetime.now().strftime("%H:%M")}',
        'format': 'single_elimination',
        'status': 'active',
        'created_at': datetime.now().isoformat(),
        'max_participants': 8,
        'current_participants': len(users_result.data)
    }
    
    tournament_result = supabase.table('tournaments').insert(tournament_data).execute()
    
    # Add participants
    participants = []
    for user in users_result.data:
        participants.append({
            'tournament_id': tournament_id,
            'user_id': user['id'],
            'status': 'confirmed'
        })
    
    participants_result = supabase.table('tournament_participants').insert(participants).execute()
    
    print(f'✅ Created tournament: {tournament_id}')
    print(f'✅ Added {len(participants)} participants')
    print()
    print('🎯 Next steps:')
    print('1. Open app and navigate to this tournament')
    print('2. Generate bracket (this will create R1 matches)')
    print('3. Test player names display')
    print('4. Test score input with +/- buttons') 
    print('5. Complete matches to test bracket progression')
    
    return tournament_id

if __name__ == '__main__':
    create_test_tournament()