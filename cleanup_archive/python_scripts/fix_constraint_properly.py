from supabase import create_client
import urllib.parse

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔧 FIXING BRACKET FORMAT CONSTRAINT - PROPER SOLUTION')
print('=' * 60)

# Check current constraint by trying to create test tournaments
print('1️⃣ TESTING CURRENT CONSTRAINT:')

test_formats = [
    'double_elimination',
    'single_elimination', 
    'sabo_de16',
    'sabo_de32',
    'sabo_se16'
]

allowed_formats = []
blocked_formats = []

for fmt in test_formats:
    try:
        # Try to create a test tournament with this format
        test_data = {
            'club_id': 'test',
            'organizer_id': 'test',
            'title': f'Test {fmt}',
            'description': 'Test tournament',
            'start_date': '2025-10-01T00:00:00Z',
            'registration_deadline': '2025-09-30T00:00:00Z',
            'max_participants': 16,
            'entry_fee': 0,
            'prize_pool': 0,
            'bracket_format': fmt,
            'game_format': '8-ball',
            'status': 'upcoming',
            'current_participants': 0
        }
        
        # This will fail if constraint doesn't allow the format
        response = supabase.table('tournaments').insert(test_data).execute()
        
        # If successful, delete the test tournament
        if response.data and len(response.data) > 0:
            tournament_id = response.data[0]['id']
            supabase.table('tournaments').delete().eq('id', tournament_id).execute()
            allowed_formats.append(fmt)
            print(f'   ✅ {fmt} - ALLOWED')
        
    except Exception as e:
        if 'check_bracket_format' in str(e):
            blocked_formats.append(fmt)
            print(f'   ❌ {fmt} - BLOCKED by constraint')
        else:
            print(f'   ⚠️  {fmt} - Other error: {str(e)[:50]}...')

print('')
print('2️⃣ CONSTRAINT ANALYSIS:')
print(f'   ✅ Allowed formats: {allowed_formats}')
print(f'   ❌ Blocked formats: {blocked_formats}')

print('')
print('3️⃣ SOLUTION:')
if blocked_formats:
    print('   Database constraint cần được update để support SABO formats')
    print('   Hiện tại chỉ support:', allowed_formats)
    print('   Cần thêm:', blocked_formats)
    
    print('')
    print('💡 WORKAROUND FOR NOW:')
    print('   - Tạm thời sử dụng "double_elimination" cho DE tournaments') 
    print('   - Lưu format chi tiết trong field khác hoặc metadata')
    print('   - Update constraint sau khi có SQL access')
else:
    print('   All SABO formats are supported!')