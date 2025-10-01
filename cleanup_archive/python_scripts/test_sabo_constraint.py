from supabase import create_client

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🧪 TESTING SABO FORMAT SUPPORT AFTER DATABASE UPDATE')
print('=' * 60)

# Test formats we want to support
sabo_formats = [
    'sabo_de16',
    'sabo_de32', 
    'sabo_se16',
    'sabo_se32',
    'sabo_double_elimination'
]

# Get existing tournament data for test
tournaments = supabase.table('tournaments').select('club_id, organizer_id').limit(1).execute()
if not tournaments.data:
    print('❌ No tournaments found to get test data')
    exit()

club_id = tournaments.data[0]['club_id']
organizer_id = tournaments.data[0]['organizer_id']

print(f'✅ Using test data: club_id={club_id[:8]}..., organizer_id={organizer_id[:8]}...')
print('')

success_count = 0
total_formats = len(sabo_formats)

for format_name in sabo_formats:
    print(f'🎯 Testing format: {format_name}')
    
    test_data = {
        'club_id': club_id,
        'organizer_id': organizer_id,
        'title': f'Test {format_name.upper()}',
        'description': f'Testing {format_name} format constraint',
        'start_date': '2025-10-01T00:00:00Z',
        'registration_deadline': '2025-09-30T00:00:00Z',
        'max_participants': 16 if '16' in format_name else 32,
        'entry_fee': 0,
        'prize_pool': 0,
        'bracket_format': format_name,  # Direct SABO format usage
        'game_format': '8-ball',
        'status': 'upcoming',
        'current_participants': 0
    }
    
    try:
        response = supabase.table('tournaments').insert(test_data).execute()
        
        if response.data:
            tournament_id = response.data[0]['id']
            print(f'   ✅ SUCCESS! Tournament created: {tournament_id[:8]}...')
            
            # Clean up immediately
            supabase.table('tournaments').delete().eq('id', tournament_id).execute()
            print(f'   🧹 Test tournament cleaned up')
            success_count += 1
        
    except Exception as e:
        error_str = str(e)
        if 'check_bracket_format' in error_str:
            print(f'   ❌ BLOCKED by constraint - format not yet supported')
        else:
            print(f'   ⚠️  Other error: {error_str[:80]}...')
    
    print('')

print('=' * 60)
print(f'📊 RESULTS: {success_count}/{total_formats} SABO formats supported')

if success_count == total_formats:
    print('🎉 ALL SABO FORMATS WORKING!')
    print('✅ Database constraint has been updated successfully')
    print('✅ Flutter app can now create SABO DE16 tournaments')
    print('')
    print('🚀 READY TO TEST IN FLUTTER APP:')
    print('   - Open app in Chrome')
    print('   - Create new tournament')
    print('   - Select "SABO DE16" format')
    print('   - Tournament will be created with sabo_de16 logic!')
    
elif success_count > 0:
    print(f'⚠️  PARTIAL SUCCESS: {success_count} formats working')
    print('   Some SABO formats are supported, others may need constraint update')
    
else:
    print('❌ NO SABO FORMATS WORKING')
    print('   Database constraint still needs to be updated')
    print('')
    print('🔧 SOLUTION:')
    print('1. Execute EXECUTE_IN_SUPABASE_SQL.sql in Supabase Dashboard')
    print('2. Run this test again to verify')
    print('3. Then SABO DE16 will work in Flutter app')

print('')
print('💡 IMPORTANT DIFFERENCE:')
print('   - sabo_de16 ≠ double_elimination (different logic)')
print('   - sabo_de16: SABO specific 16-player DE with unique rules')
print('   - double_elimination: Standard double elimination format')
print('   - Each needs separate implementation in bracket services')