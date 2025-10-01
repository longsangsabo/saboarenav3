from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
ANON_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc5MTk1ODAsImV4cCI6MjA3MzQ5NTU4MH0.u1urXd3uiT0fuqWlJ1Nhp7uJhgdiyOdLSdSWJWczHoQ'

supabase = create_client(SUPABASE_URL, ANON_KEY)

print('🔍 KIỂM TRA FOREIGN KEY CONSTRAINTS')
print('=' * 50)

# Kiểm tra tournament doublesabo1
print('\n1. 🎯 TOURNAMENT doublesabo1:')
tournament = supabase.table('tournaments').select('*').ilike('title', '%doublesabo1%').execute()
if tournament.data:
    tid = tournament.data[0]['id']
    print(f'   Tournament ID: {tid}')
    
    # Kiểm tra user_achievements references
    print('\n2. 🏆 KIỂM TRA USER_ACHIEVEMENTS:')
    try:
        achievements = supabase.table('user_achievements').select('*').eq('tournament_id', tid).execute()
        if achievements.data:
            print(f'   ❌ CÓ {len(achievements.data)} ACHIEVEMENTS ĐANG REFERENCE TOURNAMENT!')
            for i, ach in enumerate(achievements.data[:5], 1):
                print(f'      {i}. User: {ach.get("user_id", "NULL")[:8]}... - Type: {ach.get("achievement_type", "NULL")}')
        else:
            print('   ✅ Không có achievements reference tournament này')
    except Exception as e:
        print(f'   ⚠️ Không thể kiểm tra user_achievements: {e}')
    
    # Kiểm tra tất cả references khác
    print('\n3. 🔗 KIỂM TRA CÁC REFERENCES KHÁC:')
    
    # Tournament participants
    try:
        participants = supabase.table('tournament_participants').select('*').eq('tournament_id', tid).execute()
        print(f'   👥 Tournament Participants: {len(participants.data) if participants.data else 0}')
    except Exception as e:
        print(f'   ⚠️ tournament_participants: {e}')
    
    # Matches
    try:
        matches = supabase.table('matches').select('*').eq('tournament_id', tid).execute()
        print(f'   🏆 Matches: {len(matches.data) if matches.data else 0}')
    except Exception as e:
        print(f'   ⚠️ matches: {e}')
    
    # Tournament invitations
    try:
        invitations = supabase.table('tournament_invitations').select('*').eq('tournament_id', tid).execute()
        print(f'   📧 Tournament Invitations: {len(invitations.data) if invitations.data else 0}')
    except Exception as e:
        print(f'   ⚠️ tournament_invitations: {e}')
    
    # Clubs tournaments
    try:
        clubs = supabase.table('clubs_tournaments').select('*').eq('tournament_id', tid).execute()
        print(f'   🏢 Clubs Tournaments: {len(clubs.data) if clubs.data else 0}')
    except Exception as e:
        print(f'   ⚠️ clubs_tournaments: {e}')

print('\n4. 💡 GIẢI PHÁP FIX FOREIGN KEY:')
print('   🎯 CẦN TẠO SQL SCRIPT ĐỂ:')
print('   1. Xóa tất cả user_achievements có tournament_id = doublesabo1')
print('   2. Xóa tất cả dependencies khác')
print('   3. Cuối cùng xóa tournament')
print('   4. Hoặc cấu hình CASCADE DELETE cho foreign keys')