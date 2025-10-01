from supabase import create_client
import psycopg2

SUPABASE_URL = 'https://mogjjvscxjwvhtpkrlqr.supabase.co'
SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1vZ2pqdnNjeGp3dmh0cGtybHFyIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc1NzkxOTU4MCwiZXhwIjoyMDczNDk1NTgwfQ.T2ntQv-z2EL4mkGb9b3QyXM3dT8pAOFSPKvqWPd7Xoo'

supabase = create_client(SUPABASE_URL, SERVICE_KEY)

print('🔧 FIXING BRACKET FORMAT CONSTRAINT - ALTERNATIVE APPROACH')
print('=' * 60)

# Instead of changing constraint, let's see what values are allowed
# and use the right format names

# First check existing formats
print('1️⃣ CHECKING EXISTING FORMATS:')
tournaments = supabase.table('tournaments').select('bracket_format').execute()
existing_formats = set()
for t in tournaments.data:
    if t['bracket_format']:
        existing_formats.add(t['bracket_format'])

print('✅ Current formats in database:')
for fmt in sorted(existing_formats):
    print(f'   - {fmt}')

print('')
print('2️⃣ SOLUTION: USE CORRECT FORMAT NAMES')
print('   Instead of "DE16", use existing format name from database')
print('   Most likely: "double_elimination" for DE tournaments')
print('')
print('💡 FOR UI: Map "DE16" → "double_elimination" in Flutter code')
print('💡 FOR UI: Add player_count=16 separately')